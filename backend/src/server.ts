import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import { z } from "zod";

import { prisma } from "./lib/prisma";
import { requestLogger } from "./lib/logger";
import { globalLimiter } from "./lib/rateLimit";

import authRoutes from "./routes/auth";
import courseRoutes from "./routes/courses";
import assignmentRoutes from "./routes/assignments";
import announcementRoutes from "./routes/announcements";
import examRoutes from "./routes/exams";
import timelineRoutes from "./routes/timeline";

const port = z.coerce.number().default(3001).parse(process.env.PORT);

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use(requestLogger());
app.use(globalLimiter);

app.get("/health", (_req, res) => res.json({ ok: true }));

app.get("/batches", async (_req, res) => {
  const batches = await prisma.batch.findMany({
    orderBy: { year: "desc" },
    select: { id: true, name: true, semester: true, year: true },
  });
  res.json({ batches });
});

app.use("/auth", authRoutes);
app.use("/courses", courseRoutes);
app.use("/assignments", assignmentRoutes);
app.use("/batches/:batchId/announcements", announcementRoutes);
app.use("/batches/:batchId/exams", examRoutes);
app.use(timelineRoutes);

app.listen(port, () => {
  console.log(`UniTrack API listening on http://localhost:${port}`);
});
