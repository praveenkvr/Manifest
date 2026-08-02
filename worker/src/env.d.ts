// Secrets are not declared in wrangler.jsonc (they're set via `wrangler secret
// put` / .dev.vars, never committed), so `wrangler types` can't see them.
// Augment the generated Env interface here instead.
interface Env {
  GEMINI_API_KEY?: string;
  OPENAI_API_KEY?: string;
  APP_SHARED_SECRET: string;
}
