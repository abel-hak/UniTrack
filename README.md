## UniTrack

UniTrack is a student-focused academic tracker with:
- a **TypeScript / Express backend API** (`backend`)
- a **Flutter mobile app** (`unitrack_flutter`)

It helps students manage **courses, assignments, announcements, exams, and a unified timeline**.

### Repository structure

- **`backend`**: Express API, Prisma schema/migrations, seed script
- **`unitrack_flutter`**: Flutter app (Riverpod + Dio + secure token storage)

### Tech stack

- **Backend**: Node.js, TypeScript, Express, Prisma, SQLite (default), JWT auth
- **Mobile**: Flutter, Riverpod, Dio, Flutter Secure Storage

---

## 1. Prerequisites

You should have these installed:

- **Node.js 20+** and **npm**
- **Flutter SDK 3.8+**
- For running the app on a device/emulator:
  - **Android Studio** (Android emulator), or
  - **Xcode** (iOS simulator, on macOS)

---

## 2. Backend setup (Node + Prisma)

All commands below are intended to be run **from the project root folder** (`UniTrack`).

### 2.1 Create `.env`

In a terminal:

```bash
cd backend
```

On **Windows PowerShell**, copy the example env file with:

```powershell
Copy-Item .env.example .env
```

On **macOS / Linux**, use:

```bash
cp .env.example .env
```

Open `.env` and, at minimum, change:

- **`JWT_SECRET`** to a long random string (at least 16 characters).

### 2.2 Install dependencies and prepare the database

Still inside the `backend` folder:

```bash
npm install
npm run prisma:generate
npm run prisma:migrate
npm run seed
```

This will:
- install npm packages
- generate the Prisma client
- apply database migrations
- create sample data (batches, users, courses, announcement)

By default, the database is a **SQLite file** defined by `DATABASE_URL` in `.env` (`file:./dev.db`).

### 2.3 Run the backend

Start the API server:

```bash
npm run dev
```

The API listens on **`http://localhost:3001`** (configurable via `PORT` in `.env`).

You can quickly verify it with:

```bash
curl http://localhost:3001/health
```

You should get `{ "ok": true }`.

---

## 3. Flutter app setup

Open a **new terminal** (keep the backend running) and from the project root:

```bash
cd unitrack_flutter
flutter pub get
```

### 3.1 Run the app

With an emulator/simulator or device attached:

```bash
flutter run
```

The app chooses the API base URL based on the platform:

- **Android emulator**: `http://10.0.2.2:3001`
- **iOS simulator / desktop / web**: `http://localhost:3001`

This logic lives in `unitrack_flutter/lib/core/config.dart` and providers in `unitrack_flutter/lib/core/providers.dart`.

---

## 4. Backend configuration

Environment variables are defined in `backend/.env.example`:

- **`DATABASE_URL`** – default `file:./dev.db` (SQLite file)
- **`PORT`** – default `3001`
- **`JWT_SECRET`** – must be at least 16 characters (required for signing tokens)
- **`JWT_EXPIRES_IN`** – default `7d`
 - **`GROQ_API_KEY`** – optional; set this to enable AI-powered announcement summaries (see section 8)

You **must** set a strong `JWT_SECRET` before using the app in any non-local environment.

---

## 5. Seeded development accounts

After running `npm run seed` in `backend`, these accounts are available:

- **Admin**: `admin@unitrack.dev` / `admin123`
- **Publisher**: `publisher@unitrack.dev` / `publisher123`
- **Student**: `student@unitrack.dev` / `student123`

You can log in with these users from the Flutter app to explore different roles.

---

## 6. Useful commands

### 6.1 Backend (`backend` folder)

- **`npm run dev`** – run API in watch mode (recommended during development)
- **`npm run build`** – compile TypeScript to `dist`
- **`npm run start`** – run compiled API from `dist`
- **`npm run prisma:migrate`** – apply development migrations
- **`npm run seed`** – seed sample data
- **`npm run db:up` / `npm run db:down`** – start/stop optional Postgres container (see `docker-compose.yml`)

### 6.2 Flutter (`unitrack_flutter` folder)

- **`flutter pub get`** – install dependencies
- **`flutter run`** – run the app
- **`flutter test`** – run tests

---

## 7. API overview

Base URL (backend): **`http://localhost:3001`**

High-level endpoints:

- **Health**
  - `GET /health`
- **Auth**
  - `POST /auth/register`
  - `POST /auth/login`
  - `GET /auth/me`
  - `PATCH /auth/password`
- **Batches**
  - `GET /batches`
- **Courses**
  - `GET /courses`
  - `POST /courses`
  - `PATCH /courses/:id`
- **Assignments**
  - `GET /assignments`
  - `POST /assignments`
  - `PATCH /assignments/:id`
  - `DELETE /assignments/:id`
- **Announcements**
  - `GET /batches/:batchId/announcements`
  - `POST /batches/:batchId/announcements`
  - `DELETE /batches/:batchId/announcements/:id`
- **Exams**
  - `GET /batches/:batchId/exams`
  - `POST /batches/:batchId/exams`
  - `DELETE /batches/:batchId/exams/:id`
- **Timeline**
  - `GET /timeline`

Most endpoints (everything except `/health`, `/batches`, `POST /auth/register`, `POST /auth/login`) require:

- header **`Authorization: Bearer <token>`**, where `<token>` is the JWT obtained from `POST /auth/login`.

---

## 8. AI-powered features

### 8.1 Announcement summaries ("AI TL;DR")

If `GROQ_API_KEY` is set in `backend/.env`, the backend calls the Groq API and exposes:

- `POST /batches/:batchId/announcements/:id/summary`

The Flutter app surfaces this as an **“AI TL;DR”** button on each announcement card. It returns:

- a short summary of the announcement
- key bullet points
- a list of important dates mentioned (if any)

If `GROQ_API_KEY` is not configured or the AI call fails, the app simply shows a friendly error instead.

---

## 9. Database notes

- The current **Prisma datasource is SQLite** by default, using `DATABASE_URL` from `.env`.
- A **Postgres Docker setup** is available in `backend/docker-compose.yml` if you want to switch databases (you’ll need to update `DATABASE_URL` accordingly and re-run migrations).

