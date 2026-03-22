import type { RequestHandler } from "express";

const isDev = process.env.NODE_ENV !== "production";

type LogLevel = "info" | "warn" | "error";

type LogEntry = {
  timestamp: string;
  level: LogLevel;
  message: string;
  [key: string]: unknown;
};

function write(entry: LogEntry) {
  if (isDev) {
    const { level, message, ...rest } = entry;
    if (message === "request") {
      const color = (rest.status as number) >= 400 ? "\x1b[31m" : "\x1b[32m";
      process.stdout.write(
        `  ${rest.method} ${rest.url} ${color}${rest.status}\x1b[0m ${rest.duration_ms}ms\n`,
      );
      return;
    }
    const meta = Object.keys(rest).length ? ` ${JSON.stringify(rest)}` : "";
    const tag = level === "error" ? "\x1b[31mERR\x1b[0m" : level === "warn" ? "\x1b[33mWRN\x1b[0m" : "\x1b[36mINF\x1b[0m";
    process.stdout.write(`  ${tag} ${message}${meta}\n`);
    return;
  }

  const line = JSON.stringify(entry) + "\n";
  if (entry.level === "error") {
    process.stderr.write(line);
  } else {
    process.stdout.write(line);
  }
}

function log(level: LogLevel, message: string, meta?: Record<string, unknown>) {
  write({ timestamp: new Date().toISOString(), level, message, ...meta });
}

export const logger = {
  info: (msg: string, meta?: Record<string, unknown>) => log("info", msg, meta),
  warn: (msg: string, meta?: Record<string, unknown>) => log("warn", msg, meta),
  error: (msg: string, meta?: Record<string, unknown>) => log("error", msg, meta),
};

export function audit(
  action: string,
  userId: string,
  meta?: Record<string, unknown>,
) {
  logger.info("audit", { action, userId, ...meta });
}

export function requestLogger(): RequestHandler {
  return (req, res, next) => {
    const start = Date.now();
    res.on("finish", () => {
      log("info", "request", {
        method: req.method,
        url: req.originalUrl,
        status: res.statusCode,
        duration_ms: Date.now() - start,
        ip: req.ip,
      });
    });
    next();
  };
}
