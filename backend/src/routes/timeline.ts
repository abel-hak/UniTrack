import express from "express";

import { prisma } from "../lib/prisma";
import { requireAuth } from "../lib/auth";
import { jsonError } from "../lib/http";
import { logger } from "../lib/logger";
import { aiLimiter } from "../lib/rateLimit";
import { generateTodayPlan } from "../lib/ai";

const COURSE_SELECT = {
  id: true,
  code: true,
  title: true,
  colorKey: true,
  credits: true,
} as const;

const router = express.Router();

router.get("/timeline", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const courseId = req.query.courseId as string | undefined;
  const now = new Date();
  const from = new Date(now);
  from.setDate(from.getDate() - 14);
  const to = new Date(now);
  to.setDate(to.getDate() + 60);

  const [assignments, announcements, exams] = await Promise.all([
    prisma.assignment.findMany({
      where: {
        userId: user.id,
        ...(courseId ? { courseId } : {}),
        dueAt: { gte: from, lte: to },
      },
      include: { course: { select: COURSE_SELECT } },
      orderBy: { dueAt: "asc" },
    }),
    prisma.announcement.findMany({
      where: { batchId: user.batchId, createdAt: { gte: from } },
      include: { author: { select: { id: true, name: true, role: true } } },
      orderBy: { createdAt: "desc" },
      take: 50,
    }),
    prisma.exam.findMany({
      where: {
        batchId: user.batchId,
        ...(courseId ? { courseId } : {}),
        startsAt: { gte: from, lte: to },
      },
      include: { course: { select: COURSE_SELECT } },
      orderBy: { startsAt: "asc" },
    }),
  ]);

  res.json({ assignments, announcements, exams });
});

router.post("/ai/today-plan", aiLimiter, async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const now = new Date();
  const to = new Date(now);
  to.setDate(to.getDate() + 7);

  const [assignments, exams] = await Promise.all([
    prisma.assignment.findMany({
      where: {
        userId: user.id,
        status: { in: ["todo", "late"] },
        dueAt: { gte: now, lte: to },
      },
      include: { course: { select: { code: true } } },
      orderBy: { dueAt: "asc" },
      take: 30,
    }),
    prisma.exam.findMany({
      where: {
        batchId: user.batchId,
        startsAt: { gte: now, lte: to },
      },
      include: { course: { select: { code: true } } },
      orderBy: { startsAt: "asc" },
      take: 20,
    }),
  ]);

  if (assignments.length === 0 && exams.length === 0) {
    return res.json({
      plan: {
        items: [],
        note: "You have no upcoming assignments or exams in the next week. This is a good time to review notes or work ahead at your own pace.",
      },
    });
  }

  try {
    const result = await generateTodayPlan({
      assignments: assignments.map((a) => ({
        id: a.id,
        title: a.title,
        courseCode: a.course.code,
        dueAt: a.dueAt.toISOString(),
        status: a.status,
      })),
      exams: exams.map((e) => ({
        id: e.id,
        kind: e.kind,
        courseCode: e.course.code,
        startsAt: e.startsAt.toISOString(),
      })),
    });

    res.json({ plan: result });
  } catch (err) {
    logger.error("ai.today_plan_failed", { error: String(err) });
    return jsonError(
      res,
      500,
      "Failed to generate a plan for today. Please try again later.",
    );
  }
});

export default router;
