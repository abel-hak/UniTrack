import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import { z } from "zod";

import { prisma } from "./lib/prisma";
import {
  denyIfNoRole,
  hashPassword,
  requireAuth,
  requireRole,
  signAccessToken,
  verifyPassword,
} from "./lib/auth";
import { jsonError } from "./lib/http";
import { summarizeAnnouncementText, generateTodayPlan } from "./lib/ai";
import {
  announcementCreateSchema,
  assignmentCreateSchema,
  assignmentPatchSchema,
  courseCreateSchema,
  courseUpdateSchema,
  examCreateSchema,
  loginSchema,
  passwordChangeSchema,
  registerSchema,
} from "./lib/validation";

const port = z.coerce.number().default(3001).parse(process.env.PORT);

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use(morgan("dev"));

app.get("/health", (_req, res) => res.json({ ok: true }));

// ─── Auth ────────────────────────────────────────────────────

app.post("/auth/register", async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const { name, email, password, batchId, batch } = parsed.data;

  if (!batchId && !batch) {
    return jsonError(res, 400, "Provide batchId or batch");
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return jsonError(res, 409, "Email already registered");

  let resolvedBatchId: string;

  if (batchId) {
    const batchRow = await prisma.batch.findUnique({ where: { id: batchId } });
    if (!batchRow) return jsonError(res, 404, "Batch not found");
    resolvedBatchId = batchRow.id;
  } else {
    const batchRow = await prisma.batch.upsert({
      where: { name_semester_year: { name: batch!.name, semester: batch!.semester, year: batch!.year } },
      create: { name: batch!.name, semester: batch!.semester, year: batch!.year },
      update: {},
    });
    resolvedBatchId = batchRow.id;
  }

  const passwordHash = await hashPassword(password);
  const user = await prisma.user.create({
    data: {
      name,
      email,
      passwordHash,
      role: "student",
      batchId: resolvedBatchId,
    },
    select: { id: true, name: true, email: true, role: true, batchId: true },
  });

  const token = signAccessToken(user);
  res.status(201).json({ token, user });
});

app.post("/auth/login", async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const { email, password } = parsed.data;
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) return jsonError(res, 401, "Invalid credentials");
  const ok = await verifyPassword(password, user.passwordHash);
  if (!ok) return jsonError(res, 401, "Invalid credentials");

  const safeUser = {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    batchId: user.batchId,
  } as const;
  const token = signAccessToken(safeUser);
  res.json({ token, user: safeUser });
});

app.get("/auth/me", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  res.json({ user });
});

app.patch("/auth/password", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const parsed = passwordChangeSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const fullUser = await prisma.user.findUnique({ where: { id: user.id } });
  if (!fullUser) return jsonError(res, 404, "User not found");

  const ok = await verifyPassword(parsed.data.currentPassword, fullUser.passwordHash);
  if (!ok) return jsonError(res, 401, "Current password is incorrect");

  const newHash = await hashPassword(parsed.data.newPassword);
  await prisma.user.update({
    where: { id: user.id },
    data: { passwordHash: newHash },
  });
  res.json({ ok: true });
});

// ─── Batches ─────────────────────────────────────────────────

app.get("/batches", async (_req, res) => {
  const batches = await prisma.batch.findMany({
    orderBy: { year: "desc" },
    select: { id: true, name: true, semester: true, year: true },
  });
  res.json({ batches });
});

// ─── Courses ─────────────────────────────────────────────────

app.get("/courses", async (req, res) => {
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

app.post("/courses", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (denyIfNoRole(res, requireRole(user, ["admin", "publisher"]))) return;

  const parsed = courseCreateSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");
  if (parsed.data.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");

  const created = await prisma.course.create({
    data: parsed.data,
  });
  res.status(201).json({ course: created });
});

app.patch("/courses/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (denyIfNoRole(res, requireRole(user, ["admin", "publisher"]))) return;

  const parsed = courseUpdateSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const existing = await prisma.course.findUnique({ where: { id: req.params.id } });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");

  const updated = await prisma.course.update({
    where: { id: existing.id },
    data: parsed.data,
  });
  res.json({ course: updated });
});

// ─── Assignments (per-user) ──────────────────────────────────

app.get("/assignments", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const courseId = req.query.courseId as string | undefined;
  const where: Record<string, unknown> = { userId: user.id };
  if (courseId) where.courseId = courseId;

  const assignments = await prisma.assignment.findMany({
    where: where as any,
    orderBy: { dueAt: "asc" },
    include: { course: { select: { id: true, code: true, title: true, colorKey: true } } },
  });
  res.json({ assignments });
});

app.post("/assignments", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const parsed = assignmentCreateSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const course = await prisma.course.findUnique({
    where: { id: parsed.data.courseId },
    select: { id: true, batchId: true },
  });
  if (!course) return jsonError(res, 404, "Course not found");
  if (course.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");

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
  res.status(201).json({ assignment: created });
});

app.patch("/assignments/:id", async (req, res) => {
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
      status: parsed.data.status,
      gradePct: parsed.data.gradePct === null ? null : parsed.data.gradePct,
      weight: parsed.data.weight === null ? null : parsed.data.weight,
      dueAt: parsed.data.dueAt ? new Date(parsed.data.dueAt) : undefined,
    },
  });
  res.json({ assignment: updated });
});

app.delete("/assignments/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const existing = await prisma.assignment.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.userId !== user.id) return jsonError(res, 403, "Forbidden");

  await prisma.assignment.delete({ where: { id: existing.id } });
  res.json({ ok: true });
});

// ─── Announcements (shared per batch) ────────────────────────

app.get("/batches/:batchId/announcements", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");

  const announcements = await prisma.announcement.findMany({
    where: { batchId: user.batchId },
    orderBy: { createdAt: "desc" },
    take: 100,
    include: { author: { select: { id: true, name: true, role: true } } },
  });
  res.json({ announcements });
});

app.post("/batches/:batchId/announcements", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");
  if (denyIfNoRole(res, requireRole(user, ["admin", "publisher"]))) return;

  const parsed = announcementCreateSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const created = await prisma.announcement.create({
    data: {
      batchId: user.batchId,
      authorId: user.id,
      title: parsed.data.title,
      body: parsed.data.body,
    },
    include: { author: { select: { id: true, name: true, role: true } } },
  });
  res.status(201).json({ announcement: created });
});

app.post(
  "/batches/:batchId/announcements/:id/summary",
  async (req, res) => {
    const user = await requireAuth(req);
    if (!user) return jsonError(res, 401, "Unauthorized");
    if (req.params.batchId !== user.batchId) {
      return jsonError(res, 403, "Forbidden");
    }

    const announcement = await prisma.announcement.findUnique({
      where: { id: req.params.id },
    });
    if (!announcement) return jsonError(res, 404, "Not found");
    if (announcement.batchId !== user.batchId) {
      return jsonError(res, 403, "Forbidden");
    }

    // If we have a cached summary, return it directly.
    if (announcement.summaryCache) {
      return res.json({ summary: announcement.summaryCache });
    }

    try {
      const result = await summarizeAnnouncementText(
        announcement.title,
        announcement.body,
      );

      // Persist the summary for future calls.
      await prisma.announcement.update({
        where: { id: announcement.id },
        data: { summaryCache: result as any },
      });

      res.json({ summary: result });
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error(err);
      return jsonError(
        res,
        500,
        "Failed to summarize announcement. Please try again later.",
      );
    }
  },
);

app.delete("/batches/:batchId/announcements/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");
  if (denyIfNoRole(res, requireRole(user, ["admin", "publisher"]))) return;

  const existing = await prisma.announcement.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");

  await prisma.announcement.delete({ where: { id: existing.id } });
  res.json({ ok: true });
});

// ─── Exams (shared per batch) ────────────────────────────────

app.get("/batches/:batchId/exams", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");

  const exams = await prisma.exam.findMany({
    where: { batchId: user.batchId },
    orderBy: { startsAt: "asc" },
    take: 200,
    include: { course: { select: { id: true, code: true, title: true, colorKey: true, credits: true } } },
  });
  res.json({ exams });
});

app.post("/batches/:batchId/exams", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");
  if (denyIfNoRole(res, requireRole(user, ["admin", "publisher"]))) return;

  const parsed = examCreateSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const course = await prisma.course.findUnique({
    where: { id: parsed.data.courseId },
    select: { id: true, batchId: true },
  });
  if (!course) return jsonError(res, 404, "Course not found");
  if (course.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");

  const created = await prisma.exam.create({
    data: {
      batchId: user.batchId,
      courseId: parsed.data.courseId,
      kind: parsed.data.kind,
      startsAt: new Date(parsed.data.startsAt),
      location: parsed.data.location,
      notes: parsed.data.notes,
    },
    include: { course: { select: { id: true, code: true, title: true, colorKey: true, credits: true } } },
  });
  res.status(201).json({ exam: created });
});

app.delete("/batches/:batchId/exams/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");
  if (denyIfNoRole(res, requireRole(user, ["admin", "publisher"]))) return;

  const existing = await prisma.exam.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.batchId !== user.batchId) return jsonError(res, 403, "Forbidden");

  await prisma.exam.delete({ where: { id: existing.id } });
  res.json({ ok: true });
});

// ─── Timeline aggregation ────────────────────────────────────

app.get("/timeline", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const courseId = req.query.courseId as string | undefined;
  const now = new Date();
  const from = new Date(now);
  from.setDate(from.getDate() - 14);
  const to = new Date(now);
  to.setDate(to.getDate() + 60);

  const assignments = await prisma.assignment.findMany({
    where: {
      userId: user.id,
      ...(courseId ? { courseId } : {}),
      dueAt: { gte: from, lte: to },
    },
    include: { course: { select: { id: true, code: true, title: true, colorKey: true } } },
    orderBy: { dueAt: "asc" },
  });

  const announcements = await prisma.announcement.findMany({
    where: { batchId: user.batchId, createdAt: { gte: from } },
    include: { author: { select: { id: true, name: true, role: true } } },
    orderBy: { createdAt: "desc" },
    take: 50,
  });

  const exams = await prisma.exam.findMany({
    where: {
      batchId: user.batchId,
      ...(courseId ? { courseId } : {}),
      startsAt: { gte: from, lte: to },
    },
    include: { course: { select: { id: true, code: true, title: true, colorKey: true } } },
    orderBy: { startsAt: "asc" },
  });

  res.json({ assignments, announcements, exams });
});

app.post("/ai/today-plan", async (req, res) => {
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
    // eslint-disable-next-line no-console
    console.error(err);
    return jsonError(
      res,
      500,
      "Failed to generate a plan for today. Please try again later.",
    );
  }
});

app.listen(port, () => {
  console.log(`UniTrack API listening on http://localhost:${port}`);
});
