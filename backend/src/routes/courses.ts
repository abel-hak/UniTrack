import express from "express";

import { prisma } from "../lib/prisma";
import { requireAuth } from "../lib/auth";
import { jsonError } from "../lib/http";
import { audit } from "../lib/logger";
import { courseCreateSchema, courseUpdateSchema } from "../lib/validation";

const router = express.Router();

router.get("/", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const batchId = (req.query.batchId as string | undefined) ?? user.batchId;
  if (batchId !== user.batchId) return jsonError(res, 403, "Forbidden");

  const courses = await prisma.course.findMany({
    where: { batchId },
    orderBy: { code: "asc" },
  });
  res.json({ courses });
});

router.post("/", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const parsed = courseCreateSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");
  if (parsed.data.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const created = await prisma.course.create({ data: parsed.data });
  audit("course.create", user.id, { courseId: created.id });
  res.status(201).json({ course: created });
});

router.patch("/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const parsed = courseUpdateSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const existing = await prisma.course.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const updated = await prisma.course.update({
    where: { id: existing.id },
    data: parsed.data,
  });
  audit("course.update", user.id, { courseId: existing.id });
  res.json({ course: updated });
});

router.delete("/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const existing = await prisma.course.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  await prisma.$transaction([
    prisma.assignment.deleteMany({ where: { courseId: existing.id } }),
    prisma.exam.deleteMany({ where: { courseId: existing.id } }),
    prisma.course.delete({ where: { id: existing.id } }),
  ]);
  audit("course.delete", user.id, { courseId: existing.id });
  res.json({ deleted: true });
});

export default router;
