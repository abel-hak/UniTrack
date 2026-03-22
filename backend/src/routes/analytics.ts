import express from "express";
import { z } from "zod";

import { prisma } from "../lib/prisma";
import { requireAuth } from "../lib/auth";
import { jsonError } from "../lib/http";
import {
  courseAverage,
  creditWeightedGpa,
  letterGrade,
  pctToGpaPoints,
  requiredGradeForTarget,
} from "../lib/grades";

const router = express.Router();

const COURSE_SELECT = {
  id: true,
  code: true,
  title: true,
  colorKey: true,
  credits: true,
} as const;

type AssignmentRow = {
  id: string;
  title: string;
  type: string;
  weight: number | null;
  dueAt: Date;
  status: string;
  gradePct: number | null;
  courseId: string;
  course: { id: string; code: string; title: string; colorKey: string; credits: number };
};

// ─── Overview ──────────────────────────────────────────────────

router.get("/overview", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const [assignments, courses] = await Promise.all([
    prisma.assignment.findMany({
      where: { userId: user.id },
      include: { course: { select: COURSE_SELECT } },
      orderBy: { dueAt: "asc" },
    }),
    prisma.course.findMany({
      where: { batchId: user.batchId },
      orderBy: { code: "asc" },
    }),
  ]);

  const byCourse = new Map<string, AssignmentRow[]>();
  for (const a of assignments as AssignmentRow[]) {
    const list = byCourse.get(a.courseId) ?? [];
    list.push(a);
    byCourse.set(a.courseId, list);
  }

  const courseResults = [];
  const gpaInputs: Array<{ credits: number; averagePct: number }> = [];
  let totalCredits = 0;
  let gradedCredits = 0;

  for (const course of courses) {
    totalCredits += course.credits;
    const items = byCourse.get(course.id) ?? [];
    const avg = courseAverage(items);

    const gradedItems = items.filter((a) => a.gradePct != null);
    const earnedWeight = items
      .filter((a) => a.gradePct != null)
      .reduce((s, a) => s + (a.weight ?? 0), 0);
    const totalWeight = items.reduce((s, a) => s + (a.weight ?? 0), 0);

    const entry: Record<string, unknown> = {
      courseId: course.id,
      code: course.code,
      title: course.title,
      credits: course.credits,
      colorKey: course.colorKey,
      average: avg != null ? Math.round(avg * 10) / 10 : null,
      letterGrade: avg != null ? letterGrade(avg) : null,
      gpaPoints: avg != null ? pctToGpaPoints(avg) : null,
      gradedCount: gradedItems.length,
      totalCount: items.length,
      earnedWeight,
      totalWeight,
    };
    courseResults.push(entry);

    if (avg != null) {
      gpaInputs.push({ credits: course.credits, averagePct: avg });
      gradedCredits += course.credits;
    }
  }

  const gpa = creditWeightedGpa(gpaInputs);

  res.json({
    gpa: gpa != null ? Math.round(gpa * 100) / 100 : null,
    letterGrade: gpa != null ? letterGrade((gpa / 4.0) * 100) : null,
    totalCredits,
    gradedCredits,
    courses: courseResults,
  });
});

// ─── Trend ─────────────────────────────────────────────────────

router.get("/trend", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const assignments = (await prisma.assignment.findMany({
    where: { userId: user.id, gradePct: { not: null } },
    include: { course: { select: COURSE_SELECT } },
    orderBy: { dueAt: "asc" },
  })) as AssignmentRow[];

  type CourseState = {
    credits: number;
    sumWeighted: number;
    sumWeight: number;
    simpleGrades: number[];
  };

  const courseState = new Map<string, CourseState>();
  const points: Array<{
    date: string;
    gpa: number;
    label: string;
    pct: number;
  }> = [];

  for (const a of assignments) {
    const grade = a.gradePct!;
    let state = courseState.get(a.courseId);
    if (!state) {
      state = {
        credits: a.course.credits,
        sumWeighted: 0,
        sumWeight: 0,
        simpleGrades: [],
      };
      courseState.set(a.courseId, state);
    }

    if (a.weight != null && a.weight > 0) {
      state.sumWeighted += grade * a.weight;
      state.sumWeight += a.weight;
    } else {
      state.simpleGrades.push(grade);
    }

    let totalPoints = 0;
    let totalCredits = 0;
    for (const cs of courseState.values()) {
      let avg: number | null = null;
      if (cs.sumWeight > 0) {
        avg = cs.sumWeighted / cs.sumWeight;
      } else if (cs.simpleGrades.length > 0) {
        avg =
          cs.simpleGrades.reduce((x, y) => x + y, 0) /
          cs.simpleGrades.length;
      }
      if (avg != null) {
        totalPoints += pctToGpaPoints(avg) * cs.credits;
        totalCredits += cs.credits;
      }
    }

    if (totalCredits > 0) {
      points.push({
        date: a.dueAt.toISOString(),
        gpa: Math.round((totalPoints / totalCredits) * 100) / 100,
        label: `${a.course.code} · ${a.title}`,
        pct: grade,
      });
    }
  }

  res.json({ points });
});

// ─── Target Calculator ─────────────────────────────────────────

const targetSchema = z.object({
  courseId: z.string().min(1),
  targetPct: z.number().min(0).max(100),
});

router.post("/target", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const parsed = targetSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const course = await prisma.course.findUnique({
    where: { id: parsed.data.courseId },
    select: { id: true, code: true, batchId: true },
  });
  if (!course) return jsonError(res, 404, "Course not found");
  if (course.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const assignments = await prisma.assignment.findMany({
    where: { userId: user.id, courseId: course.id },
    select: { gradePct: true, weight: true },
  });

  const graded = assignments
    .filter((a) => a.gradePct != null)
    .map((a) => ({ gradePct: a.gradePct!, weight: a.weight }));
  const ungraded = assignments
    .filter((a) => a.gradePct == null)
    .map((a) => ({ weight: a.weight }));

  const avg = courseAverage(assignments);
  const result = requiredGradeForTarget(
    graded,
    ungraded,
    parsed.data.targetPct,
  );

  res.json({
    courseCode: course.code,
    currentAverage: avg != null ? Math.round(avg * 10) / 10 : null,
    targetPct: parsed.data.targetPct,
    ungradedCount: ungraded.length,
    ...(result ?? { requiredPct: null, achievable: false }),
  });
});

// ─── Projection ────────────────────────────────────────────────

router.get("/projection", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const [assignments, courses] = await Promise.all([
    prisma.assignment.findMany({
      where: { userId: user.id },
      include: { course: { select: COURSE_SELECT } },
    }),
    prisma.course.findMany({
      where: { batchId: user.batchId },
      orderBy: { code: "asc" },
    }),
  ]);

  const byCourse = new Map<string, AssignmentRow[]>();
  for (const a of assignments as AssignmentRow[]) {
    const list = byCourse.get(a.courseId) ?? [];
    list.push(a);
    byCourse.set(a.courseId, list);
  }

  function scenarioGpa(ungradedPct: number) {
    const inputs: Array<{ credits: number; averagePct: number }> = [];

    for (const course of courses) {
      const items = byCourse.get(course.id) ?? [];
      if (items.length === 0) continue;

      const filled = items.map((a) => ({
        gradePct: a.gradePct ?? ungradedPct,
        weight: a.weight,
      }));
      const avg = courseAverage(filled);
      if (avg != null) {
        inputs.push({ credits: course.credits, averagePct: avg });
      }
    }

    return creditWeightedGpa(inputs);
  }

  const currentInputs: Array<{ credits: number; averagePct: number }> = [];
  for (const course of courses) {
    const items = byCourse.get(course.id) ?? [];
    const avg = courseAverage(items);
    if (avg != null) {
      currentInputs.push({ credits: course.credits, averagePct: avg });
    }
  }
  const current = creditWeightedGpa(currentInputs);

  const round = (v: number | null) =>
    v != null ? Math.round(v * 100) / 100 : null;

  res.json({
    current: round(current),
    optimistic: round(scenarioGpa(95)),
    pessimistic: round(scenarioGpa(70)),
  });
});

export default router;
