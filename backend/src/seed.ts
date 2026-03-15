import "dotenv/config";

import { prisma } from "./lib/prisma";
import { hashPassword } from "./lib/auth";

async function main() {
  const batch = await prisma.batch.upsert({
    where: { name_semester_year: { name: "Batch A", semester: "Spring", year: 2026 } },
    create: { name: "Batch A", semester: "Spring", year: 2026 },
    update: {},
  });

  const adminEmail = "admin@unitrack.dev";
  const existingAdmin = await prisma.user.findUnique({ where: { email: adminEmail } });
  if (!existingAdmin) {
    await prisma.user.create({
      data: {
        name: "Admin",
        email: adminEmail,
        passwordHash: await hashPassword("admin123"),
        role: "admin",
        batchId: batch.id,
      },
    });
  }

  const publisherEmail = "publisher@unitrack.dev";
  const existingPublisher = await prisma.user.findUnique({
    where: { email: publisherEmail },
  });
  if (!existingPublisher) {
    await prisma.user.create({
      data: {
        name: "Publisher",
        email: publisherEmail,
        passwordHash: await hashPassword("publisher123"),
        role: "publisher",
        batchId: batch.id,
      },
    });
  }

  const allowedCodes = [
    "CoSc4022",
    "CoSc4012",
    "CoSc4412",
    "CoSc4112",
    "Hist. 1012",
    "CoSc4212",
    "CoSc4312",
  ] as const;

  await prisma.course.deleteMany({
    where: {
      batchId: batch.id,
      code: { notIn: [...allowedCodes] },
    },
  });

  const courses = [
    { code: "CoSc4022", title: "Mobile Application Development", credits: 3, colorKey: "teal" },
    { code: "CoSc4012", title: "Computer Security", credits: 3, colorKey: "yellow" },
    { code: "CoSc4412", title: "Real Time and Embedded Systems", credits: 3, colorKey: "terracotta" },
    { code: "CoSc4112", title: "Final Year Project II", credits: 3, colorKey: "slate" },
    { code: "Hist. 1012", title: "History of Ethiopia and the Horn", credits: 3, colorKey: "teal" },
    { code: "CoSc4212", title: "Compiler Design", credits: 3, colorKey: "yellow" },
    { code: "CoSc4312", title: "Complexity Theory", credits: 3, colorKey: "terracotta" },
  ] as const;

  for (const c of courses) {
    await prisma.course.upsert({
      where: { batchId_code: { batchId: batch.id, code: c.code } },
      create: { ...c, batchId: batch.id },
      update: { title: c.title, credits: c.credits, colorKey: c.colorKey },
    });
  }

  const studentEmail = "student@unitrack.dev";
  let student = await prisma.user.findUnique({
    where: { email: studentEmail },
  });
  if (!student) {
    student = await prisma.user.create({
      data: {
        name: "Test Student",
        email: studentEmail,
        passwordHash: await hashPassword("student123"),
        role: "student",
        batchId: batch.id,
      },
    });
  }

  const courseList = await prisma.course.findMany({
    where: { batchId: batch.id },
    orderBy: { code: "asc" },
  });

  const now = new Date();
  const sampleItems: Array<{ courseCode: string; title: string; type: "assignment" | "quiz" | "project"; daysFromNow: number }> = [
    { courseCode: "CoSc4022", title: "Flutter lab report", type: "assignment", daysFromNow: 3 },
    { courseCode: "CoSc4022", title: "Mobile quiz 1", type: "quiz", daysFromNow: 5 },
    { courseCode: "CoSc4012", title: "Security quiz 1", type: "quiz", daysFromNow: 5 },
    { courseCode: "CoSc4012", title: "Cryptography assignment", type: "assignment", daysFromNow: 8 },
    { courseCode: "CoSc4412", title: "Embedded project proposal", type: "project", daysFromNow: 7 },
    { courseCode: "CoSc4412", title: "RTOS quiz", type: "quiz", daysFromNow: 4 },
    { courseCode: "CoSc4112", title: "FYP II progress report", type: "assignment", daysFromNow: 10 },
    { courseCode: "CoSc4112", title: "Final report draft", type: "assignment", daysFromNow: 14 },
    { courseCode: "Hist. 1012", title: "Essay draft", type: "assignment", daysFromNow: 4 },
    { courseCode: "Hist. 1012", title: "Midterm quiz", type: "quiz", daysFromNow: 6 },
    { courseCode: "CoSc4212", title: "Parser assignment", type: "assignment", daysFromNow: 6 },
    { courseCode: "CoSc4212", title: "Lexer quiz", type: "quiz", daysFromNow: 3 },
    { courseCode: "CoSc4312", title: "Problem set 2", type: "assignment", daysFromNow: 2 },
    { courseCode: "CoSc4312", title: "Complexity quiz", type: "quiz", daysFromNow: 5 },
  ];

  const existingAssignments = await prisma.assignment.count({
    where: { userId: student!.id },
  });
  if (existingAssignments === 0) {
    for (const s of sampleItems) {
      const course = courseList.find((c) => c.code === s.courseCode);
      if (!course) continue;
      const dueAt = new Date(now);
      dueAt.setDate(dueAt.getDate() + s.daysFromNow);
      await prisma.assignment.create({
        data: {
          userId: student.id,
          courseId: course.id,
          title: s.title,
          type: s.type,
          dueAt,
          status: "todo",
        },
      });
    }
  }

  const anyCourse = await prisma.course.findFirst({ where: { batchId: batch.id } });
  if (anyCourse) {
    const existing = await prisma.announcement.findFirst({ where: { batchId: batch.id } });
    if (!existing) {
      const publisher = await prisma.user.findUnique({ where: { email: publisherEmail } });
      if (publisher) {
        await prisma.announcement.create({
          data: {
            batchId: batch.id,
            authorId: publisher.id,
            title: "Office hours moved to Thursday",
            body: "This week only, office hours will be held on Thursday 3–5 PM instead of Wednesday.",
          },
        });
      }
    }
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    // eslint-disable-next-line no-console
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });

