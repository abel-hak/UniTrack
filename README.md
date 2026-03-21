# UniTrack

A full-stack academic tracker for university students — built with **TypeScript / Express** on the backend and **Flutter** on the frontend.

Students can manage courses, track assignments and grades, view announcements and exams, and stay organized through a unified timeline and interactive calendar. AI features (powered by Groq) provide announcement summaries and personalized daily study plans.

---

## Repository structure

```
UniTrack/
├── backend/                     # Express API + Prisma ORM + SQLite
│   ├── src/
│   │   ├── server.ts            # All API routes
│   │   ├── seed.ts              # Sample data seeder
│   │   └── lib/
│   │       ├── ai.ts            # Groq AI integration
│   │       ├── auth.ts          # JWT auth helpers
│   │       ├── http.ts          # Error response helpers
│   │       └── validation.ts    # Zod request schemas
│   ├── prisma/
│   │   └── schema.prisma        # Database schema
│   ├── .env.example
│   └── package.json
│
├── unitrack_flutter/            # Flutter app (Android, iOS, Web, Desktop)
│   └── lib/
│       ├── main.dart            # App entry, light + dark themes
│       ├── core/
│       │   ├── providers.dart   # Riverpod providers
│       │   ├── config.dart      # API URL config per platform
│       │   └── api/             # Dio HTTP client
│       ├── features/
│       │   ├── courses/         # Course models + repository
│       │   ├── assignments/     # Assignment repository
│       │   ├── announcements_exams/  # Announcements + exams repo
│       │   └── timeline/        # Timeline models + repository
│       └── ui/
│           ├── home_page.dart           # Main screen (timeline, calendar, grades)
│           ├── calendar_tab.dart        # Interactive monthly calendar
│           ├── course_detail_page.dart  # Per-course detail view
│           ├── announcements_exams_page.dart
│           ├── login_page.dart
│           ├── register_page.dart
│           ├── profile_page.dart
│           ├── onboarding_page.dart
│           └── widgets/         # Shared components
│
└── docs/
    └── UI_ANALYSIS.md           # UI audit and improvement tracker
```

---

## Tech stack

| Layer | Technologies |
|-------|-------------|
| **Backend** | Node.js 20+, TypeScript, Express, Prisma, SQLite, Zod, JWT |
| **Frontend** | Flutter 3.8+, Dart, Riverpod, Dio, Flutter Secure Storage, Google Fonts |
| **AI** | Groq API (Llama 3) — announcement summaries + daily study plans |

---

## Getting started

### Prerequisites

- **Node.js 20+** and **npm**
- **Flutter SDK 3.8+**
- An emulator (Android Studio / Xcode) or a browser (Chrome / Edge)

### 1. Backend

```bash
cd backend
```

Create your `.env` file:

```bash
# macOS / Linux
cp .env.example .env

# Windows PowerShell
Copy-Item .env.example .env
```

Edit `.env` as needed:

| Variable | Required | Default | Notes |
|----------|----------|---------|-------|
| `JWT_SECRET` | Yes | `dev-secret-change-me` | Use a long random string in production |
| `DATABASE_URL` | No | `file:./dev.db` | SQLite by default |
| `PORT` | No | `3001` | API port |
| `GROQ_API_KEY` | No | — | Enables AI features |

Install, migrate, seed, and run:

```bash
npm install
npm run prisma:generate
npm run prisma:migrate
npm run seed
npm run dev
```

Verify: `curl http://localhost:3001/health` → `{ "ok": true }`

### 2. Flutter app

In a **separate terminal** (keep the backend running):

```bash
cd unitrack_flutter
flutter pub get
flutter run
```

The app auto-detects the API URL:

| Platform | Base URL |
|----------|----------|
| Android emulator | `http://10.0.2.2:3001` |
| iOS simulator / Desktop / Web | `http://localhost:3001` |

---

## Seeded accounts

After `npm run seed`:

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@unitrack.dev` | `admin123` |
| Publisher | `publisher@unitrack.dev` | `publisher123` |
| Student | `student@unitrack.dev` | `student123` |

- **Admin / Publisher** — can create announcements and exams
- **Student** — can create courses and assignments, view everything

---

## Features

### Core functionality

| Feature | Details |
|---------|---------|
| **Courses** | Full CRUD — create, edit (title, credits, color), delete with cascading cleanup |
| **Assignments** | Full CRUD — edit title, type, weight, due date, status, and grade |
| **Exams** | Full CRUD — edit kind, date/time, location, and notes |
| **Announcements** | Batch-wide posts from admins/publishers, create and delete |
| **Timeline** | Unified chronological feed of all items, filterable by course |
| **Calendar** | Swipeable monthly view with color-coded event dots, collapsible grid, and "Today" shortcut |
| **Course detail** | Per-course page with upcoming/graded assignments, exams, and stats |
| **GPA** | Automatic GPA calculated from graded assignments |

### UI / UX

- **Light + dark theme** — toggle from the home screen header; dark theme uses a Tailwind Slate palette
- **Onboarding** — first-run welcome screen
- **Tappable calendar events** — tap any event to view details or edit inline
- **Tap-to-add from calendar** — select a date, tap `+` to create an assignment with the due date pre-filled
- **Skeleton loading** — shimmer placeholders while data loads
- **Micro-animations** — staggered fade-in on lists, ripple feedback on cards
- **Consistent patterns** — shared empty states, error + retry, bottom sheet drag handles

### AI-powered (requires `GROQ_API_KEY`)

- **Announcement TL;DR** — summarizes long announcements into bullet points + key dates
- **Daily study plan** — "What should I work on today?" — prioritized plan from upcoming deadlines

---

## Useful commands

### Backend (`backend/`)

| Command | Description |
|---------|-------------|
| `npm run dev` | Start API in watch mode |
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

## API reference

Base URL: `http://localhost:3001`

All endpoints except `/health`, `/batches`, `/auth/register`, and `/auth/login` require `Authorization: Bearer <token>`.

### Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/register` | Create account |
| `POST` | `/auth/login` | Sign in → JWT |
| `GET` | `/auth/me` | Current user info |
| `PATCH` | `/auth/password` | Change password |

### Courses

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/courses` | List courses |
| `POST` | `/courses` | Create course |
| `PATCH` | `/courses/:id` | Update course |
| `DELETE` | `/courses/:id` | Delete course (cascades to assignments + exams) |

### Assignments

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/assignments` | List assignments |
| `POST` | `/assignments` | Create assignment |
| `PATCH` | `/assignments/:id` | Update (title, type, status, grade, weight, due date) |
| `DELETE` | `/assignments/:id` | Delete assignment |

### Announcements

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/batches/:batchId/announcements` | List announcements |
| `POST` | `/batches/:batchId/announcements` | Create announcement |
| `DELETE` | `/batches/:batchId/announcements/:id` | Delete announcement |

### Exams

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/batches/:batchId/exams` | List exams |
| `POST` | `/batches/:batchId/exams` | Create exam |
| `PATCH` | `/batches/:batchId/exams/:id` | Update (kind, date, location, notes) |
| `DELETE` | `/batches/:batchId/exams/:id` | Delete exam |

### Other

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/timeline` | Unified timeline (assignments + announcements + exams) |
| `GET` | `/batches` | List batches |
| `POST` | `/batches/:batchId/announcements/:id/summary` | AI summary of announcement |
| `POST` | `/ai/today-plan` | AI daily study plan |

---

## Database

- Default: **SQLite** (`file:./dev.db`) — zero config, works out of the box
- Postgres: update `DATABASE_URL` in `.env` and re-run `npm run prisma:migrate`
