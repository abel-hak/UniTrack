import type { Request, Response } from "express";

export function jsonError(res: Response, status: number, message: string) {
  return res.status(status).json({ error: message });
}

export function requireString(
  req: Request,
  key: string,
): string | undefined {
  const v = (req.body as Record<string, unknown> | undefined)?.[key];
  return typeof v === "string" && v.trim().length > 0 ? v.trim() : undefined;
}

