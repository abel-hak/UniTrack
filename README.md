# UniTrack

UniTrack is a student-focused academic tracker with:
- a TypeScript/Express backend API (`backend`)
- a Flutter mobile app (`unitrack_flutter`)

It helps students manage courses, assignments, announcements, exams, and a unified timeline.

## Repository Structure

- `backend`: Express API, Prisma schema/migrations, seed script
- `unitrack_flutter`: Flutter app (Riverpod + Dio + secure token storage)

## Tech Stack

- Backend: Node.js, TypeScript, Express, Prisma, SQLite (default), JWT auth
- Mobile: Flutter, Riverpod, Dio, Flutter Secure Storage

## Prerequisites

- Node.js 20+ and npm
- Flutter SDK 3.8+
- Android Studio or Xcode (for device/simulator runs)

## Quick Start

### 1) Start the Backend

```bash
cd backend
cp .env.example .env
npm install
npm run prisma:generate
npm run prisma:migrate
npm run seed
npm run dev
```

API runs at `http://localhost:3001`.

### 2) Start the Flutter App

In a second terminal:

```bash
cd unitrack_flutter
flutter pub get
flutter run
```

The app uses:
- `http://10.0.2.2:3001` on Android emulator
- `http://localhost:3001` on iOS simulator/desktop/web

This behavior is configured in `unitrack_flutter/lib/core/config.dart`.

## Environment Variables (Backend)

Defined in `backend/.env.example`:

- `DATABASE_URL` (default: `file:./dev.db`)
- `PORT` (default: `3001`)
- `JWT_SECRET` (must be at least 16 chars)
- `JWT_EXPIRES_IN` (default: `7d`)

## Seeded Development Accounts

After `npm run seed`:

- Admin: `admin@unitrack.dev` / `admin123`
- Publisher: `publisher@unitrack.dev` / `publisher123`
- Student: `student@unitrack.dev` / `student123`

## Useful Commands

From `backend`:

- `npm run dev` - run API in watch mode
- `npm run build` - compile to `dist`
- `npm run start` - run compiled API
- `npm run prisma:migrate` - apply development migrations
- `npm run seed` - seed sample data
- `npm run db:up` / `npm run db:down` - start/stop optional Postgres container

From `unitrack_flutter`:

- `flutter pub get` - install dependencies
- `flutter run` - run app
- `flutter test` - run tests

## API Overview

Base URL: `http://localhost:3001`

- Health: `GET /health`
- Auth: `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `PATCH /auth/password`
- Batches: `GET /batches`
- Courses: `GET /courses`, `POST /courses`, `PATCH /courses/:id`
- Assignments: `GET /assignments`, `POST /assignments`, `PATCH /assignments/:id`, `DELETE /assignments/:id`
- Announcements: `GET/POST/DELETE /batches/:batchId/announcements...`
- Exams: `GET/POST/DELETE /batches/:batchId/exams...`
- Timeline: `GET /timeline`

Most endpoints require `Authorization: Bearer <token>`.

## Notes

- Current Prisma datasource is SQLite by default.
- A Postgres Docker setup is available in `backend/docker-compose.yml` if you want to switch databases.
