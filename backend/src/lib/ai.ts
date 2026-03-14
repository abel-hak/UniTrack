import { z } from "zod";

const envSchema = z.object({
  GROQ_API_KEY: z.string().min(1),
});

type AiSummaryResult = {
  summary: string;
  keyPoints: string[];
  dates: string[];
};

type TodayPlanItem = {
  title: string;
  reason: string;
  sourceType: "assignment" | "exam";
  sourceId: string;
};

export type TodayPlanResult = {
  items: TodayPlanItem[];
  note: string;
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

export async function generateTodayPlan(input: {
  assignments: Array<{
    id: string;
    title: string;
    courseCode: string;
    dueAt: string;
    status: string;
  }>;
  exams: Array<{
    id: string;
    kind: string;
    courseCode: string;
    startsAt: string;
  }>;
}): Promise<TodayPlanResult> {
  const env = envSchema.safeParse(process.env);
  if (!env.success) {
    throw new Error("GROQ_API_KEY is not set; cannot generate today plan.");
  }

  const apiKey = env.data.GROQ_API_KEY;
  const userContent = `
You are helping a university student decide what to work on today.

Here is their upcoming work in JSON:

${JSON.stringify(input, null, 2)}

Create a focused plan for just TODAY:
- Return 3–5 concrete action items
- Prioritize urgent or soon-due work, but also allow starting early on big items
- Use friendly, encouraging language

Respond ONLY with JSON:
- "items": array of objects with:
  - "title": short actionable label (e.g. "Finish CS 301 problem set questions 1–3")
  - "reason": why this matters today, in 1–2 sentences
  - "sourceType": "assignment" or "exam"
  - "sourceId": the id of the assignment/exam you based it on
- "note": a short closing note (1–2 sentences) with general encouragement.
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
              "You are an academic planning assistant for university students. Always respond with strict JSON only.",
          },
          {
            role: "user",
            content: userContent,
          },
        ],
        temperature: 0.3,
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
    throw new Error("Failed to parse Groq JSON response for today plan.");
  }

  const resultSchema = z.object({
    items: z.array(
      z.object({
        title: z.string(),
        reason: z.string(),
        sourceType: z.enum(["assignment", "exam"]),
        sourceId: z.string(),
      }),
    ),
    note: z.string(),
  });

  const validated = resultSchema.safeParse(parsed);
  if (!validated.success) {
    throw new Error("Groq JSON response did not match TodayPlan schema.");
  }

  return validated.data;
}

