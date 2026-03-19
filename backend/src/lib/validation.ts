import { z } from "zod";

export const roleSchema = z.enum(["admin", "publisher", "student"]);

export const registerSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  password: z.string().min(6),
  batchId: z.string().min(1).optional(),
  batch: z.object({
    name: z.string().min(1),
    semester: z.string().min(1),
    year: z.number().int().min(2000).max(2100),
  }).optional(),
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
  title: z.string().min(1),
  credits: z.number().int().min(1).max(20),
  colorKey: z.string().min(1),
  instructor: z.string().min(1).optional(),
  schedule: z.unknown().optional(),
});

export const courseUpdateSchema = z.object({
  title: z.string().min(1).optional(),
  credits: z.number().int().min(1).max(20).optional(),
  colorKey: z.string().min(1).optional(),
  instructor: z.string().min(1).nullable().optional(),
});

export const assignmentCreateSchema = z.object({
  courseId: z.string().min(1),
  title: z.string().min(1),
  type: z.enum(["assignment", "quiz", "project", "exam"]),
  weight: z.number().int().min(0).max(100).optional(),
  dueAt: z.string().datetime(),
});

export const assignmentPatchSchema = z.object({
  title: z.string().min(1).optional(),
  type: z.enum(["assignment", "quiz", "project", "exam"]).optional(),
  status: z.enum(["todo", "done", "late"]).optional(),
  gradePct: z.number().int().min(0).max(100).nullable().optional(),
  dueAt: z.string().datetime().optional(),
  weight: z.number().int().min(0).max(100).nullable().optional(),
});

export const announcementCreateSchema = z.object({
  title: z.string().min(1),
  body: z.string().min(1),
});

export const examCreateSchema = z.object({
  courseId: z.string().min(1),
  kind: z.enum(["midterm", "final", "quiz", "practical"]),
  startsAt: z.string().datetime(),
  location: z.string().min(1).optional(),
  notes: z.string().min(1).optional(),
});

export const examPatchSchema = z.object({
  kind: z.enum(["midterm", "final", "quiz", "practical"]).optional(),
  startsAt: z.string().datetime().optional(),
  location: z.string().min(1).nullable().optional(),
  notes: z.string().min(1).nullable().optional(),
});

