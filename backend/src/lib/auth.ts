import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import type { Request } from "express";
import { z } from "zod";

import { prisma } from "./prisma";
import { jsonError } from "./http";

const envSchema = z.object({
  JWT_SECRET: z.string().min(16),
  JWT_EXPIRES_IN: z.string().default("7d"),
});

const env = envSchema.parse(process.env);

export type AuthUser = {
  id: string;
  role: "admin" | "publisher" | "student";
  batchId: string;
  name: string;
  email: string;
};

export async function hashPassword(password: string) {
  return bcrypt.hash(password, 10);
}

export async function verifyPassword(password: string, hash: string) {
  return bcrypt.compare(password, hash);
}

export function signAccessToken(payload: AuthUser) {
  return jwt.sign(
    {
      sub: payload.id,
      role: payload.role,
      batchId: payload.batchId,
      name: payload.name,
      email: payload.email,
    },
    env.JWT_SECRET,
    { expiresIn: env.JWT_EXPIRES_IN },
  );
}

const tokenSchema = z.object({
  sub: z.string(),
  role: z.enum(["admin", "publisher", "student"]),
  batchId: z.string(),
  name: z.string(),
  email: z.string(),
  iat: z.number().optional(),
  exp: z.number().optional(),
});

export async function requireAuth(req: Request) {
  const h = req.header("authorization") ?? "";
  const m = /^Bearer\s+(.+)$/.exec(h);
  if (!m) return null;
  const token = m[1]!;
  try {
    const decoded = jwt.verify(token, env.JWT_SECRET);
    const parsed = tokenSchema.safeParse(decoded);
    if (!parsed.success) return null;
    const userId = parsed.data.sub;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true, batchId: true, name: true, email: true },
    });
    if (!user) return null;
    return user as AuthUser;
  } catch {
    return null;
  }
}

export function requireRole(
  user: AuthUser,
  roles: Array<AuthUser["role"]>,
) {
  return roles.includes(user.role);
}

export function denyIfNoRole(
  res: Parameters<typeof jsonError>[0],
  ok: boolean,
) {
  if (ok) return false;
  jsonError(res, 403, "Forbidden");
  return true;
}

