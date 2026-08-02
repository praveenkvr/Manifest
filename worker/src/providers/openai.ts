import type { AIProvider, GenerateOptions } from "./types";

interface OpenAIChatResponse {
  choices?: { message?: { content?: string } }[];
}

export function createOpenAIProvider(apiKey: string, model = "gpt-5.6-luna"): AIProvider {
  return {
    name: "openai",
    // GPT-5.6 is a reasoning-tier model: it rejects `temperature` outright
    // and wants `max_completion_tokens` instead of the legacy `max_tokens`.
    // `reasoning_effort: "none"` skips invisible thinking tokens entirely —
    // this workload is short creative rewrites, not multi-step logic, so
    // reasoning only added latency without improving output.
    async generate({ system, prompt, maxTokens = 500 }: GenerateOptions) {
      const res = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model,
          messages: [
            ...(system ? [{ role: "system", content: system }] : []),
            { role: "user", content: prompt },
          ],
          max_completion_tokens: maxTokens,
          reasoning_effort: "none",
        }),
      });

      if (!res.ok) {
        throw new Error(`OpenAI error ${res.status}: ${await res.text()}`);
      }

      const data = (await res.json()) as OpenAIChatResponse;
      const text = data.choices?.[0]?.message?.content;
      if (!text) throw new Error("OpenAI: empty response");
      return text.trim();
    },
  };
}
