import express from "express";

import { prisma } from "../lib/prisma";
import { requireAuth } from "../lib/auth";
import { jsonError } from "../lib/http";
import { audit } from "../lib/logger";
import { examCreateSchema, examPatchSchema } from "../lib/validation";

const COURSE_SELECT = {
  id: true,
  code: true,
  title: true,
  colorKey: true,
  credits: true,
} as const;

const router = express.Router({ mergeParams: true });

router.get("/", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const exams = await prisma.exam.findMany({
    where: { batchId: user.batchId },
    orderBy: { startsAt: "asc" },
    take: 200,
    include: { course: { select: COURSE_SELECT } },
  });
  res.json({ exams });
});

router.post("/", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const parsed = examCreateSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const course = await prisma.course.findUnique({
    where: { id: parsed.data.courseId },
    select: { id: true, batchId: true },
  });
  if (!course) return jsonError(res, 404, "Course not found");
  if (course.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const created = await prisma.exam.create({
    data: {
      batchId: user.batchId,
      courseId: parsed.data.courseId,
      kind: parsed.data.kind,
      startsAt: new Date(parsed.data.startsAt),
      location: parsed.data.location,
      notes: parsed.data.notes,
    },
    include: { course: { select: COURSE_SELECT } },
  });
  audit("exam.create", user.id, { examId: created.id });
  res.status(201).json({ exam: created });
});

router.patch("/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const parsed = examPatchSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const existing = await prisma.exam.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const updated = await prisma.exam.update({
    where: { id: existing.id },
    data: {
      kind: parsed.data.kind,
      startsAt: parsed.data.startsAt
        ? new Date(parsed.data.startsAt)
        : undefined,
      location: parsed.data.location === null ? null : parsed.data.location,
      notes: parsed.data.notes === null ? null : parsed.data.notes,
    },
    include: { course: { select: COURSE_SELECT } },
  });
  audit("exam.update", user.id, { examId: existing.id });
  res.json({ exam: updated });
});

router.delete("/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const existing = await prisma.exam.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  await prisma.exam.delete({ where: { id: existing.id } });
  audit("exam.delete", user.id, { examId: existing.id });
  res.json({ ok: true });
});

export default router;
