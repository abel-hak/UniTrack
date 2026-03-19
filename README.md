# UniTrack

A student-focused academic tracker built with a **TypeScript / Express** backend and a **Flutter** mobile app.

UniTrack helps students manage **courses, assignments, announcements, exams**, and view everything on a **unified timeline**. It also includes **AI-powered features** like announcement summaries and daily study plans.

---

## Repository structure

```
UniTrack/
├── backend/                 # Express API + Prisma ORM + SQLite
│   ├── src/
│   │   ├── server.ts        # All API routes
│   │   └── lib/
│   │       └── ai.ts        # Groq AI integration
│   ├── prisma/
│   │   ├── schema.prisma    # Database schema
│   │   ├── migrations/      # Migration history
│   │   └── seed.ts          # Sample data seeder
│   ├── .env.example
│   └── package.json
│
├── unitrack_flutter/        # Flutter mobile app
│   └── lib/
│       ├── main.dart        # App entry, themes
│       ├── core/            # Providers, config, API client
│       ├── features/        # Repositories & data models
│       └── ui/              # Screens & widgets
│
└── docs/
    └── UI_ANALYSIS.md       # UI improvement tracker
```

## Tech stack

| Layer | Technologies |
|-------|-------------|
| **Backend** | Node.js, TypeScript, Express, Prisma, SQLite (default), JWT auth |
| **Mobile** | Flutter 3.8+, Riverpod, Dio, Flutter Secure Storage, Google Fonts |
| **AI** | Groq API (Llama 3) for summaries and daily plans |

---

## 1. Prerequisites

- **Node.js 20+** and **npm**
- **Flutter SDK 3.8+**
- **Android Studio** (Android emulator) or **Xcode** (iOS simulator, macOS only)

---

## 2. Backend setup

All commands below run from inside the `backend/` folder.

### 2.1 Create `.env`

```bash
cd backend
```

**Windows PowerShell:**

```powershell
Copy-Item .env.example .env
```

**macOS / Linux:**

```bash
cp .env.example .env
```

Open `.env` and set:

| Variable | Required | Default | Notes |
|----------|----------|---------|-------|
| `JWT_SECRET` | Yes | `dev-secret-change-me` | Change to a long random string (16+ chars) |
| `DATABASE_URL` | No | `file:./dev.db` | SQLite file path |
| `PORT` | No | `3001` | API port |
| `JWT_EXPIRES_IN` | No | `7d` | Token expiry |
| `GROQ_API_KEY` | No | — | Enables AI features (summaries + daily plan) |

### 2.2 Install and prepare the database

```bash
npm install
npm run prisma:generate
npm run prisma:migrate
npm run seed
```

This installs dependencies, generates the Prisma client, applies migrations, and seeds sample data (batches, users, courses, announcements).

### 2.3 Start the API

```bash
npm run dev
```

The API listens on **`http://localhost:3001`**. Verify with:

```bash
curl http://localhost:3001/health
# → { "ok": true }
```

---

## 3. Flutter app setup

Open a **new terminal** (keep the backend running):

```bash
cd unitrack_flutter
flutter pub get
flutter run
```

The app auto-detects the API URL by platform:

| Platform | Base URL |
|----------|----------|
| Android emulator | `http://10.0.2.2:3001` |
| iOS simulator / desktop / web | `http://localhost:3001` |

This is configured in `lib/core/config.dart`.

---

## 4. Seeded accounts

After running `npm run seed`, these accounts are available:

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@unitrack.dev` | `admin123` |
| Publisher | `publisher@unitrack.dev` | `publisher123` |
| Student | `student@unitrack.dev` | `student123` |

**Role permissions:**

- **Admin / Publisher**: Can create announcements and exams
- **Student**: Can create assignments, view announcements and exams

---

## 5. Features

### Core

- **Courses** — Full CRUD: create, edit (title, credits, color), and delete courses with cascading cleanup
- **Assignments** — Full CRUD: create, edit all fields (title, type, weight, due date, status, grade), and delete
- **Announcements** — Batch-wide announcements from admins/publishers with create and delete
- **Exams** — Full CRUD: create, edit (kind, date/time, location, notes), and delete
- **Timeline** — Unified chronological view of all items across courses, filterable by course
- **Calendar** — Interactive monthly calendar with swipeable navigation, color-coded event dots, collapsible grid, and a "Today" shortcut
- **Course detail** — Dedicated page per course showing assignments (upcoming + graded), exams, and grade breakdown
- **GPA calculation** — Automatic GPA from graded assignments

### UI / UX

- Light and **dark theme** with toggle (Tailwind Slate dark palette)
- **First-run onboarding** screen
- **Tappable calendar events** — tap any event to view details or edit inline
- **Tap-to-add from calendar** — select a date and add an assignment with the due date pre-filled
- Skeleton loading shimmer effects
- Staggered fade-in animations
- Consistent empty states and error handling with retry
- Bottom sheet forms with drag handles

### AI-powered (requires `GROQ_API_KEY`)

- **Announcement TL;DR** — Summarizes long announcements into bullet points + key dates
- **Daily study plan** — "What should I work on today?" generates a prioritized plan from upcoming deadlines

---

## 6. Useful commands

### Backend (`backend/`)

| Command | Description |
|---------|-------------|
| `npm run dev` | Run API in watch mode |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm run start` | Run compiled API |
| `npm run prisma:migrate` | Apply database migrations |
| `npm run prisma:generate` | Regenerate Prisma client |
| `npm run seed` | Seed sample data |

### Flutter (`unitrack_flutter/`)

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run the app |
| `flutter analyze` | Static analysis |
| `flutter test` | Run tests |

---

## 7. API endpoints

Base URL: **`http://localhost:3001`**

All endpoints except health, batches, register, and login require `Authorization: Bearer <token>`.

### Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/register` | Create a new account |
| `POST` | `/auth/login` | Sign in, returns JWT |
| `GET` | `/auth/me` | Current user info |
| `PATCH` | `/auth/password` | Change password |

### Data

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/batches` | List all batches |
| `GET` | `/courses` | List user's courses |
| `POST` | `/courses` | Create a course |
| `PATCH` | `/courses/:id` | Update a course |
| `DELETE` | `/courses/:id` | Delete a course (cascades to assignments + exams) |
| `GET` | `/assignments` | List user's assignments |
| `POST` | `/assignments` | Create an assignment |
| `PATCH` | `/assignments/:id` | Update any field (title, type, status, grade, weight, due date) |
| `DELETE` | `/assignments/:id` | Delete an assignment |
| `GET` | `/batches/:batchId/announcements` | List announcements |
| `POST` | `/batches/:batchId/announcements` | Create an announcement |
| `DELETE` | `/batches/:batchId/announcements/:id` | Delete an announcement |
| `GET` | `/batches/:batchId/exams` | List exams |
| `POST` | `/batches/:batchId/exams` | Create an exam |
| `PATCH` | `/batches/:batchId/exams/:id` | Update an exam (kind, date, location, notes) |
| `DELETE` | `/batches/:batchId/exams/:id` | Delete an exam |
| `GET` | `/timeline` | Unified timeline |

### AI

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/batches/:batchId/announcements/:id/summary` | AI summary of announcement |
| `POST` | `/ai/today-plan` | AI-generated daily study plan |

---

## 8. Database notes

- Default database is **SQLite** (`file:./dev.db`).
- A **Postgres Docker** setup is available in `backend/docker-compose.yml` — update `DATABASE_URL` and re-run migrations to switch.
