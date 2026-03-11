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

  const courses = [
    { code: "CS 301", title: "Data Structures & Algorithms", credits: 4, colorKey: "teal" },
    { code: "MATH 201", title: "Calculus II", credits: 4, colorKey: "yellow" },
    { code: "ENG 102", title: "Academic Writing", credits: 3, colorKey: "terracotta" },
    { code: "PHYS 150", title: "Physics Mechanics", credits: 4, colorKey: "slate" },
  ] as const;

  for (const c of courses) {
    await prisma.course.upsert({
      where: { batchId_code: { batchId: batch.id, code: c.code } },
      create: { ...c, batchId: batch.id },
      update: { title: c.title, credits: c.credits, colorKey: c.colorKey },
    });
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

