import express from "express";

import { prisma } from "../lib/prisma";
import { requireAuth } from "../lib/auth";
import { jsonError } from "../lib/http";
import { audit } from "../lib/logger";
import {
  assignmentCreateSchema,
  assignmentPatchSchema,
} from "../lib/validation";

const router = express.Router();

router.get("/", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const courseId = req.query.courseId as string | undefined;
  const where: Record<string, unknown> = { userId: user.id };
  if (courseId) where.courseId = courseId;

  const assignments = await prisma.assignment.findMany({
    where: where as any,
    orderBy: { dueAt: "asc" },
    include: {
      course: {
        select: { id: true, code: true, title: true, colorKey: true },
      },
    },
  });
  res.json({ assignments });
});

router.post("/", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const parsed = assignmentCreateSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const course = await prisma.course.findUnique({
    where: { id: parsed.data.courseId },
    select: { id: true, batchId: true },
  });
  if (!course) return jsonError(res, 404, "Course not found");
  if (course.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const created = await prisma.assignment.create({
    data: {
      userId: user.id,
      courseId: parsed.data.courseId,
      title: parsed.data.title,
      type: parsed.data.type,
      weight: parsed.data.weight,
      dueAt: new Date(parsed.data.dueAt),
    },
  });
  audit("assignment.create", user.id, { assignmentId: created.id });
  res.status(201).json({ assignment: created });
});

router.patch("/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const parsed = assignmentPatchSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const existing = await prisma.assignment.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.userId !== user.id) return jsonError(res, 403, "Forbidden");

  const updated = await prisma.assignment.update({
    where: { id: existing.id },
    data: {
      title: parsed.data.title,
      type: parsed.data.type,
      status: parsed.data.status,
      gradePct: parsed.data.gradePct === null ? null : parsed.data.gradePct,
      weight: parsed.data.weight === null ? null : parsed.data.weight,
      dueAt: parsed.data.dueAt ? new Date(parsed.data.dueAt) : undefined,
    },
  });
  audit("assignment.update", user.id, { assignmentId: existing.id });
  res.json({ assignment: updated });
});

router.delete("/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const existing = await prisma.assignment.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.userId !== user.id) return jsonError(res, 403, "Forbidden");

  await prisma.assignment.delete({ where: { id: existing.id } });
  audit("assignment.delete", user.id, { assignmentId: existing.id });
  res.json({ ok: true });
});

export default router;
