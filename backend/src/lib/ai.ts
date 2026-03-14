import { z } from "zod";

const envSchema = z.object({
  GROQ_API_KEY: z.string().min(1),
});

type AiSummaryResult = {
  summary: string;
  keyPoints: string[];
  dates: string[];
};

export async function summarizeAnnouncementText(
  title: string,
  body: string,
): Promise<AiSummaryResult> {
  const env = envSchema.safeParse(process.env);
  if (!env.success) {
    throw new Error("GROQ_API_KEY is not set; cannot summarize.");
  }

  const apiKey = env.data.GROQ_API_KEY;
  const userContent = `
You are an assistant helping university students quickly understand announcements.

ANNOUNCEMENT TITLE:
${title}

ANNOUNCEMENT BODY:
${body}

Return a JSON object with:
- "summary": a concise 2-4 sentence summary in plain language
- "keyPoints": 3-6 short key bullet points (as an array of strings, no numbering)
- "dates": a list of important dates/deadlines mentioned (as an array of strings, might be empty)

Respond with JSON only, no additional text.
`.trim();

  const response = await fetch(
    "https://api.groq.com/openai/v1/chat/completions",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "llama-3.1-8b-instant",
        messages: [
          {
            role: "system",
            content:
              "You summarize university announcements for students. Always respond with strict JSON only.",
          },
          {
            role: "user",
            content: userContent,
          },
        ],
        temperature: 0.2,
      }),
    },
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Failed to call Groq API: ${response.status} ${text.slice(0, 200)}`,
    );
  }

  const json = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
  };

  const raw = json.choices?.[0]?.message?.content;
  if (!raw) {
    throw new Error("Groq response missing content.");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("Failed to parse Groq JSON response.");
  }

  const resultSchema = z.object({
    summary: z.string(),
    keyPoints: z.array(z.string()),
    dates: z.array(z.string()),
  });

  const validated = resultSchema.safeParse(parsed);
  if (!validated.success) {
    throw new Error("Groq JSON response did not match expected schema.");
  }

  return validated.data;
}

