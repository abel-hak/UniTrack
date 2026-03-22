import express from "express";

import { prisma } from "../lib/prisma";
import {
  hashPassword,
  requireAuth,
  signAccessToken,
  verifyPassword,
} from "../lib/auth";
import { jsonError } from "../lib/http";
import { audit } from "../lib/logger";
import { authLimiter } from "../lib/rateLimit";
import {
  loginSchema,
  passwordChangeSchema,
  registerSchema,
} from "../lib/validation";

const router = express.Router();

router.use(authLimiter);

router.post("/register", async (req, res) => {
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
      where: {
        name_semester_year: {
          name: batch!.name,
          semester: batch!.semester,
          year: batch!.year,
        },
      },
      create: {
        name: batch!.name,
        semester: batch!.semester,
        year: batch!.year,
      },
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

  audit("user.register", user.id, { email });
  const token = signAccessToken(user);
  res.status(201).json({ token, user });
});

router.post("/login", async (req, res) => {
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
  audit("user.login", user.id);
  const token = signAccessToken(safeUser);
  res.json({ token, user: safeUser });
});

router.get("/me", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");
  res.json({ user });
});

router.patch("/password", async (req, res) => {
  const user = await requireAuth(req);
  if (!user) return jsonError(res, 401, "Unauthorized");

  const parsed = passwordChangeSchema.safeParse(req.body);
  if (!parsed.success) return jsonError(res, 400, "Invalid payload");

  const fullUser = await prisma.user.findUnique({ where: { id: user.id } });
  if (!fullUser) return jsonError(res, 404, "User not found");

  const ok = await verifyPassword(
    parsed.data.currentPassword,
    fullUser.passwordHash,
  );
  if (!ok) return jsonError(res, 401, "Current password is incorrect");

  const newHash = await hashPassword(parsed.data.newPassword);
  await prisma.user.update({
    where: { id: user.id },
    data: { passwordHash: newHash },
  });
  audit("user.password_change", user.id);
  res.json({ ok: true });
});

export default router;
