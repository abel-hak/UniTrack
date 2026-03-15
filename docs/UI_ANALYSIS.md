# UniTrack UI – Codebase Analysis & Recommendations

## 1. Current UI Structure

### Theme & design system (`main.dart`)
- **Colors**: Single light theme with `primary` (#0045AB), `surface`, `mutedForeground`, `border`, course colors (yellow, teal, terracotta, slate), shadows.
- **Typography**: Space Grotesk for display/titles, Inter for body (Google Fonts).
- **Extensions**: `UniTrackColors` used via `UniTrackColors.of(context)` in UI.
- **Material 3**: Enabled; FAB and basic components use theme.

### Pages
| Page | Role | Notes |
|------|------|------|
| **LoginPage** | Auth | Centered form, `_Field` for email/password, error text, “Create account” link, API URL at bottom. |
| **RegisterPage** | Auth | AppBar with back, batch dropdown, same `_Field`-style inputs, validation errors. |
| **HomePage** | Main | Header (title, date, courses count, GPA pill, menu), Timeline/Grades tabs, course filter chips, timeline list, FAB. |
| **ProfilePage** | Settings | AppBar, avatar + name + email + role pill, “Change Password” section, Sign Out, version text. |
| **AnnouncementsExamsPage** | Content | Tabs (Announcements / Exams), list cards, FAB, AI TL;DR on announcements, delete on cards. |

### Shared patterns
- **Max width**: `ConstrainedBox(maxWidth: 420)` on main content for larger screens.
- **Cards**: Rounded (14–16px), border, light shadow; timeline cards have colored left bar + leading icon.
- **Buttons**: Primary = filled blue, rounded (14px); secondary = outlined; danger = red.
- **Inputs**: Filled surface, rounded OutlineInputBorder, focus = primary border.
- **Empty states**: Icon + short message + sometimes “Tap + to add” / “Retry”.
- **Loading**: Small `CircularProgressIndicator` (strokeWidth: 2) in center or inline.

---

## 2. What’s Already Good

- **Consistent theme**: One place for colors and fonts; course colors and shadows are centralized.
- **Responsive width**: 420px constraint avoids over‑stretched layout on tablets/desktop.
- **Clear hierarchy**: Title/subtitle and card structure are readable.
- **Recent polish**: GPA pill (gradient, icon), menu (icon boxes, list tiles), timeline cards (type-colored icons, left bar, shadow) already improved.
- **Accessible touch targets**: Buttons and list items are reasonably sized.

---

## 3. Gaps & Inconsistencies

| Area | Issue |
|------|--------|
| **Auth screens** | Very plain: no illustration, no branding strip, API URL visible in production. |
| **Profile** | Feels like a form-only screen; avatar/role could be more visually distinct. |
| **Announcements & Exams** | Cards are functional but visually lighter than home timeline cards; no type badge (e.g. “Announcement” / “Exam”). |
| **Empty states** | Inconsistent: some use icon + text, others only text; no shared component. |
| **Loading** | Same spinner everywhere; no skeleton or card-placeholder loading. |
| **Bottom sheets** | Add Course / Add Assignment / Add Exam / Assignment detail: same white rounded container; no illustration or step indicator. |
| **Dialogs** | AlertDialog for AI summary and today plan; simple, could feel more “premium”. |
| **Errors** | Red text only; no inline recovery (e.g. “Retry” next to the error) on some screens. |
| **No dark theme** | Single theme only. |

---

## 4. What We Can Do – Prioritized

### High impact, low effort
1. **Unify empty states** – One reusable widget (icon + title + subtitle + optional action button) and use it for “No announcements”, “No exams”, “No graded items”, “No upcoming items”.
2. **Add type labels on cards** – Small chip or caption (“Announcement”, “Assignment”, “Exam”) on timeline and on Announcements/Exams cards so type is obvious at a glance.
3. **Auth screen refresh** – Add a thin branded bar or gradient at top for Login/Register; optional small logo or wordmark; hide or gate “API: …” behind debug mode.
4. **Profile polish** – Slight gradient or tint behind avatar section; make role pill and “Change Password” section visually distinct (e.g. card or divider).

### High impact, medium effort
5. **Announcement & Exam cards** – Align with home timeline: colored left bar + icon by type (announcement vs exam), same border radius and shadow style.
6. **Bottom sheets** – Shared style (e.g. drag handle, consistent title row, primary button style) and optional header illustration or icon for “Add assignment” / “Add course” / “New exam”.
7. **Loading states** – Skeleton placeholders for timeline and for course list (e.g. shimmer cards) instead of only spinner.
8. **Error states** – Consistent “message + Retry” pattern on list screens; optional illustration for “Something went wrong”.

### Medium impact, low effort
9. **Dialogs** – Rounded corners, optional icon in title, consistent padding and action button style for AI summary and today plan.
10. **Input focus** – Slight elevation or stronger focus ring on focused fields (theme or decoration) so focus is clearer.
11. **Version / footer** – Move “UniTrack v1.0.0” into a small footer component used on Profile (and optionally elsewhere).

### Larger initiatives
12. **Dark theme** – Second `ThemeData.dark()` + dark `UniTrackColors`, switch via provider or system.
13. **Onboarding** – First-run screen(s): short value prop, maybe one-time course/assignment prompt.
14. **Micro‑animations** – Staggered list appearance, card tap feedback, or FAB expand/collapse for multiple actions.

---

## 5. Suggested Next Steps

- **Quick wins**: (1) Empty-state component, (2) type labels on cards, (3) auth screen branding strip and hide API URL in release.
- **Then**: (5) Align Announcements/Exams cards with timeline style, (6) bottom sheet style, (7) skeleton loading.
- **Later**: Dark theme, onboarding, animations.

If you tell me which item(s) you want first (e.g. “empty states and type labels” or “auth and profile polish”), I can implement them in the codebase next.
