import express from "express";

import { prisma } from "../lib/prisma";
import { denyIfNoRole, requireAuth, requireRole } from "../lib/auth";
import { jsonError } from "../lib/http";
import { audit, logger } from "../lib/logger";
import { aiLimiter } from "../lib/rateLimit";
import { summarizeAnnouncementText } from "../lib/ai";
import { announcementCreateSchema } from "../lib/validation";

const router = express.Router({ mergeParams: true });

router.get("/", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const announcements = await prisma.announcement.findMany({
    where: { batchId: user.batchId },
    orderBy: { createdAt: "desc" },
    take: 100,
    include: { author: { select: { id: true, name: true, role: true } } },
  });
  res.json({ announcements });
});

router.post("/", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");
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
  audit("announcement.create", user.id, { announcementId: created.id });
  res.status(201).json({ announcement: created });
});

router.post("/:id/summary", aiLimiter, async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  const announcement = await prisma.announcement.findUnique({
    where: { id: req.params.id },
  });
  if (!announcement) return jsonError(res, 404, "Not found");
  if (announcement.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  if (announcement.summaryCache) {
    return res.json({ summary: announcement.summaryCache });
  }

  try {
    const result = await summarizeAnnouncementText(
      announcement.title,
      announcement.body,
    );

    await prisma.announcement.update({
      where: { id: announcement.id },
      data: { summaryCache: result as any },
    });

    res.json({ summary: result });
  } catch (err) {
    logger.error("ai.summarize_failed", {
      announcementId: announcement.id,
      error: String(err),
    });
    return jsonError(
      res,
      500,
      "Failed to summarize announcement. Please try again later.",
    );
  }
});

router.delete("/:id", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  if (req.params.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");
  if (denyIfNoRole(res, requireRole(user, ["admin", "publisher"]))) return;

  const existing = await prisma.announcement.findUnique({
    where: { id: req.params.id },
  });
  if (!existing) return jsonError(res, 404, "Not found");
  if (existing.batchId !== user.batchId)
    return jsonError(res, 403, "Forbidden");

  await prisma.announcement.delete({ where: { id: existing.id } });
  audit("announcement.delete", user.id, { announcementId: existing.id });
  res.json({ ok: true });
});

export default router;
