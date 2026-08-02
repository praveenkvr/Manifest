import { createGeminiProvider } from "./gemini";
import { createOpenAIProvider } from "./openai";
import type { AIProvider, GenerateOptions } from "./types";

export type { AIProvider, GenerateOptions } from "./types";

// Switching or reordering models is a config change: edit AI_PROVIDER in
// wrangler.jsonc (comma-separated priority order), no code touched.
// Adding a new vendor = one file in providers/ + one line in `factories` below.
const factories: Record<string, (env: Env) => AIProvider | null> = {
  gemini: (env) => (env.GEMINI_API_KEY ? createGeminiProvider(env.GEMINI_API_KEY) : null),
  openai: (env) => (env.OPENAI_API_KEY ? createOpenAIProvider(env.OPENAI_API_KEY) : null),
};

export function buildProviderChain(env: Env): AIProvider[] {
  const order = (env.AI_PROVIDER ?? "gemini,openai").split(",").map((s) => s.trim());
  const chain = order
    .map((name) => factories[name]?.(env))
    .filter((provider): provider is AIProvider => Boolean(provider));

  if (chain.length === 0) {
    throw new Error("No AI provider configured — set GEMINI_API_KEY or OPENAI_API_KEY");
  }
  return chain;
}

// Tries providers in priority order; falls through to the next on failure so a
// single vendor outage doesn't take the daily ritual down.
export async function generateWithFallback(env: Env, options: GenerateOptions): Promise<string> {
  const chain = buildProviderChain(env);
  let lastError: unknown;

  for (const provider of chain) {
    try {
      return await provider.generate(options);
    } catch (err) {
      lastError = err;
      console.error(`[ai] provider "${provider.name}" failed`, err);
    }
  }

  throw lastError instanceof Error ? lastError : new Error("All AI providers failed");
}
