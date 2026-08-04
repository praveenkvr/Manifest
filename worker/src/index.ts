import { timingSafeEqual } from "node:crypto";
import { Hono } from "hono";
import { generateWithFallback } from "./providers";
import {
  buildDailyScriptPrompt,
  buildGoalCheckPrompt,
  buildPhrasingSuggestionsPrompt,
  type ManifestationStyle,
} from "./prompts";

const app = new Hono<{ Bindings: Env }>();

function safeEqual(a: string, b: string): boolean {
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  return bufA.length === bufB.length && timingSafeEqual(bufA, bufB);
}

function parseStyle(value: unknown): ManifestationStyle {
  if (value === "water") return "water";
  if (value === "369") return "369";
  return "present";
}

// Telltale signs the model broke format instead of writing an affirmation
// line — a refusal, a meta preamble, or leaked instructions. Checked as a
// substring match against lowercased text, so it's cheap and language-blind
// on purpose: these markers only ever show up when the model slips into
// English meta-commentary, regardless of what language the line should be in.
const REFUSAL_MARKERS = [
  "as an ai", "i cannot", "i can't", "i'm sorry", "i am sorry",
  "here are", "here's", "sure,", "note:", "disclaimer",
];

// Nothing downstream of generateWithFallback checks that the model actually
// followed the prompt's format — this is that check, run before a line ever
// reaches the client. Catches empty responses, wrong line counts, and
// refusals/preambles that would otherwise show up on the ritual screen as if
// they were meant to be read aloud.
function isWellFormedScript(lines: string[], expectedCount: number): boolean {
  if (lines.length !== expectedCount) return false;
  return lines.every((line) => {
    const wordCount = line.split(/\s+/).filter(Boolean).length;
    if (wordCount < 2 || wordCount > 40) return false;
    const lower = line.toLowerCase();
    return !REFUSAL_MARKERS.some((marker) => lower.includes(marker));
  });
}

// Lightweight abuse guard — the app has no user accounts to authenticate, so
// every request just needs to carry the shared secret baked into the client.
// Not a substitute for real auth if this ever needs per-user limits.
app.use("*", async (c, next) => {
  const provided = c.req.header("X-App-Secret");
  if (!c.env.APP_SHARED_SECRET || !provided || !safeEqual(provided, c.env.APP_SHARED_SECRET)) {
    return c.json({ error: "unauthorized" }, 401);
  }
  await next();
});

app.get("/v1/health", (c) => c.json({ ok: true }));

// Every new goal goes through this before it's ever saved on-device: one
// call does double duty as a content-safety check and the onboarding
// reflection, so goal creation still costs a single AI call.
app.post("/v1/reflect", async (c) => {
  const body = await c.req.json<{ goal?: string; style?: string; language?: string }>();
  const goal = body.goal?.trim();
  if (!goal) return c.json({ error: "goal is required" }, 400);

  const { system, prompt } = buildGoalCheckPrompt({
    goal,
    style: parseStyle(body.style),
    language: body.language?.trim() || "en",
  });

  try {
    const text = await generateWithFallback(c.env, { system, prompt });
    const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);
    const [status, ...rest] = lines;

    if (status?.toUpperCase() === "BLOCKED") {
      return c.json({
        allowed: false,
        reason: rest[0] ?? "This goal isn't something Manifest can help with — try reframing it toward something positive for yourself.",
      });
    }

    const [reflection, ...sampleLines] = rest;
    // Sample lines are shown verbatim as "how it might sound" — filter out
    // anything that looks like a broken-format refusal/preamble rather than
    // showing it to the user as if it were an affirmation.
    const cleanSampleLines = sampleLines.filter((line) => {
      const lower = line.toLowerCase();
      return !REFUSAL_MARKERS.some((marker) => lower.includes(marker));
    });
    return c.json({
      allowed: true,
      reflection: reflection ?? text.trim(),
      sampleLines: cleanSampleLines,
    });
  } catch (err) {
    console.error("[reflect] generation failed", err);
    return c.json({ error: "generation_failed" }, 502);
  }
});

// On-demand only (user taps "Need suggestions" while crafting a goal).
app.post("/v1/suggest-phrasing", async (c) => {
  const body = await c.req.json<{ goal?: string; language?: string }>();
  const goal = body.goal?.trim();
  if (!goal) return c.json({ error: "goal is required" }, 400);

  const { system, prompt } = buildPhrasingSuggestionsPrompt({
    goal,
    language: body.language?.trim() || "en",
  });

  try {
    const text = await generateWithFallback(c.env, { system, prompt });
    const suggestions = text.split("\n").map((l) => l.trim()).filter(Boolean);
    return c.json({ suggestions });
  } catch (err) {
    console.error("[suggest-phrasing] generation failed", err);
    return c.json({ error: "generation_failed" }, 502);
  }
});

app.post("/v1/daily-script", async (c) => {
  const body = await c.req.json<{
    goal?: string;
    style?: string;
    language?: string;
    dayNumber?: number;
    recentLines?: string[];
  }>();
  const goal = body.goal?.trim();
  if (!goal) return c.json({ error: "goal is required" }, 400);

  const style = parseStyle(body.style);
  const lineCount = style === "369" ? 1 : 4; // 369 is one line, handwritten repeatedly — not a multi-line script.
  // Bounded so a client can't inflate every request's input tokens — a
  // couple of recent days' worth of lines is plenty for the model to steer
  // away from without cost creeping up over time.
  const recentLines = (Array.isArray(body.recentLines) ? body.recentLines : [])
    .filter((l): l is string => typeof l === "string")
    .map((l) => l.trim())
    .filter(Boolean)
    .slice(-8)
    .map((l) => l.slice(0, 200));
  const { system, prompt } = buildDailyScriptPrompt({
    goal,
    style,
    language: body.language?.trim() || "en",
    dayNumber: Number.isFinite(body.dayNumber) ? Number(body.dayNumber) : 1,
    lineCount,
    recentLines,
  });

  try {
    // One retry before giving up — cheap on Luna, and a single malformed
    // generation shouldn't force the client all the way to its local
    // fallback lines when trying again usually just works.
    for (let attempt = 0; attempt < 2; attempt++) {
      const text = await generateWithFallback(c.env, { system, prompt });
      const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);
      if (isWellFormedScript(lines, lineCount)) {
        return c.json({ lines });
      }
      console.error(`[daily-script] malformed output on attempt ${attempt + 1}`, lines);
    }
    return c.json({ error: "malformed_output" }, 502);
  } catch (err) {
    console.error("[daily-script] generation failed", err);
    return c.json({ error: "generation_failed" }, 502);
  }
});

// Remote kill switch — the app checks this on launch/foreground and only
// initializes PostHog if it's true. Flip ANALYTICS_ENABLED in wrangler.jsonc
// and redeploy to turn analytics off for every install without an app
// update, e.g. if usage-based cost spikes.
app.get("/v1/config", (c) => {
  const raw: string = c.env.ANALYTICS_ENABLED;
  return c.json({ analyticsEnabled: raw !== "false" });
});

// MetricKit crash/hang diagnostics from the app — logged here so they're
// visible via `wrangler tail` without a third-party crash service. Not
// persisted anywhere yet; add D1/KV storage later if you want a queryable
// history instead of just live-tailing.
app.post("/v1/diagnostics", async (c) => {
  const body = await c.req.json().catch(() => null);
  if (!body) return c.json({ error: "invalid body" }, 400);
  console.log("[diagnostics]", JSON.stringify(body));
  return c.json({ ok: true });
});

export default app;
