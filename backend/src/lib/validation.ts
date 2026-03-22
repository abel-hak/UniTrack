import { z } from "zod";

import { stripHtml } from "./sanitize";

const safe = (min = 1) => z.string().min(min).transform(stripHtml);

export const roleSchema = z.enum(["admin", "publisher", "student"]);

export const registerSchema = z.object({
  name: safe(),
  email: z.string().email(),
  password: z.string().min(6),
  batchId: z.string().min(1).optional(),
  batch: z
    .object({
      name: safe(),
      semester: safe(),
      year: z.number().int().min(2000).max(2100),
    })
    .optional(),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const passwordChangeSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(6),
});

export const courseCreateSchema = z.object({
  batchId: z.string().min(1),
  code: z.string().min(1),
  title: safe(),
  credits: z.number().int().min(1).max(20),
  colorKey: z.string().min(1),
  instructor: safe().optional(),
  schedule: z.unknown().optional(),
});

export const courseUpdateSchema = z.object({
  title: safe().optional(),
  credits: z.number().int().min(1).max(20).optional(),
  colorKey: z.string().min(1).optional(),
  instructor: safe().nullable().optional(),
});

export const assignmentCreateSchema = z.object({
  courseId: z.string().min(1),
  title: safe(),
  type: z.enum(["assignment", "quiz", "project", "exam"]),
  weight: z.number().int().min(0).max(100).optional(),
  dueAt: z.string().datetime(),
});

export const assignmentPatchSchema = z.object({
  title: safe().optional(),
  type: z.enum(["assignment", "quiz", "project", "exam"]).optional(),
  status: z.enum(["todo", "done", "late"]).optional(),
  gradePct: z.number().int().min(0).max(100).nullable().optional(),
  dueAt: z.string().datetime().optional(),
  weight: z.number().int().min(0).max(100).nullable().optional(),
});

export const announcementCreateSchema = z.object({
  title: safe(),
  body: safe(),
});

export const examCreateSchema = z.object({
  courseId: z.string().min(1),
  kind: z.enum(["midterm", "final", "quiz", "practical"]),
  startsAt: z.string().datetime(),
  location: safe().optional(),
  notes: safe().optional(),
});

export const examPatchSchema = z.object({
  kind: z.enum(["midterm", "final", "quiz", "practical"]).optional(),
  startsAt: z.string().datetime().optional(),
  location: safe().nullable().optional(),
  notes: safe().nullable().optional(),
});
