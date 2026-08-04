import type { AIProvider, GenerateOptions } from "./types";

interface GeminiResponse {
  candidates?: { content?: { parts?: { text?: string }[] } }[];
}

export function createGeminiProvider(apiKey: string, model = "gemini-2.5-flash"): AIProvider {
  return {
    name: "gemini",
    // Bumped from 0.9 — the primary OpenAI provider ignores temperature
    // entirely (reasoning-tier model), so this is the only knob that adds
    // randomness on top of the recent-lines instruction in the prompt.
    async generate({ system, prompt, maxTokens = 300, temperature = 1.15 }: GenerateOptions) {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: prompt }] }],
          ...(system ? { systemInstruction: { parts: [{ text: system }] } } : {}),
          generationConfig: { maxOutputTokens: maxTokens, temperature },
        }),
      });

      if (!res.ok) {
        throw new Error(`Gemini error ${res.status}: ${await res.text()}`);
      }

      const data = (await res.json()) as GeminiResponse;
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!text) throw new Error("Gemini: empty response");
      return text.trim();
    },
  };
}
