# Teacher Schedule & Today Revamp — Design

Date: 2026-05-22  
Status: Approved (sections A,B,C agreed by user)

## 1. Goals

- Remove hard‑coded mock data from the teacher **Today** tab.
- Show only **today's** classes, sorted by start time, with a "Next class in X min" indicator.
- Add a dedicated **Schedule** screen for teachers using a Google‑Calendar‑style **week view** (7 columns × hourly grid, tap to create event).
- Persist schedule as **hybrid**: recurring weekly templates + per‑date overrides (move/cancel).

## 2. Data model (Firestore)

### `schedules/{scheduleId}`

| Field | Type | Notes |
|---|---|---|
| `teacherId` | string | Owner UID. |
| `classId` | string | Reference to `classes/{id}`. |
| `dayOfWeek` | int (1‑7) | ISO weekday for recurring templates. `null` for one‑off. |
| `startMinute` | int | Minutes since 00:00. |
| `endMinute` | int | Minutes since 00:00; must be > `startMinute`. |
| `room` | string? | Optional location/note. |
| `color` | string? | Optional hex; defaults from class. |
| `effectiveFrom` | timestamp? | Recurring item starts from this date. |
| `effectiveTo` | timestamp? | Optional end date. |
| `createdAt`, `updatedAt` | timestamp | Server timestamps. |

### `schedule_overrides/{overrideId}`

| Field | Type | Notes |
|---|---|---|
| `scheduleId` | string | Reference to recurring `schedules` doc. |
| `date` | string (YYYY‑MM‑DD) | The specific date this override applies to. |
| `cancelled` | bool | If true, hide that occurrence. |
| `newStartMinute` | int? | Optional reschedule. |
| `newEndMinute` | int? | Optional reschedule. |
| `note` | string? | Reason/announcement. |
| `createdAt` | timestamp | |

Rationale: keep recurring rows compact; only store overrides when something changes for a specific day. Queries for "today" merge both sources.

### Firestore rules (delta)

- `schedules` read: any class member; write: only teacher who owns it.
- `schedule_overrides`: same as parent schedule.

## 3. Callable functions (`functions/index.js`)

Add four new `onCall` functions, mirroring existing style (auth + validation + batch):

- `createSchedule({ classId, dayOfWeek, startMinute, endMinute, room?, color?, effectiveFrom?, effectiveTo? })` → `{ id }`
- `updateSchedule({ scheduleId, ...patch })` → `{ ok }`
- `deleteSchedule({ scheduleId })` → `{ ok }`
- `upsertScheduleOverride({ scheduleId, date, cancelled?, newStartMinute?, newEndMinute?, note? })` → `{ ok, id }`

All validate teacher ownership of `scheduleId.classId`.

## 4. Flutter — repository

Add to `SchoolRepository`:

```dart
Stream<List<ScheduleEntry>> teacherSchedulesStream(String teacherId);
Stream<List<ScheduleEntry>> classSchedulesStream(String classId);
Stream<List<ScheduleOverride>> scheduleOverridesStream(String scheduleId);
Future<String> createSchedule(ScheduleEntryDraft draft);
Future<void> updateSchedule(String id, Map<String, dynamic> patch);
Future<void> deleteSchedule(String id);
Future<void> upsertScheduleOverride(String scheduleId, ScheduleOverrideDraft draft);
List<ResolvedScheduleItem> resolveDay(DateTime date, List<ScheduleEntry>, List<ScheduleOverride>);
```

`ResolvedScheduleItem` = the merged "what runs on this date" record (start/end/class/room/cancelled/note).

Models live in `lib/src/models/schedule.dart`.

## 5. Flutter — Today screen (`teacher_workspace_screen.dart`)

Replace `_TeacherHome` body:

- **Greeting**: `Good morning|afternoon|evening, {firstName} 👋` based on `DateTime.now().hour`.
- **Date strip**: `EEEE, MMMM d` (kept).
- **"Today's classes" section**:
  - `StreamBuilder` over `teacherSchedulesStream`.
  - Filter to entries effective on today's `dayOfWeek` (or one‑off matching today), apply overrides, sort by `startMinute`.
  - Empty state: "Bạn không có lịch dạy hôm nay 🎉" + CTA `[Open schedule]`.
  - Each item card shows:
    - Class color stripe + name
    - `HH:mm – HH:mm` start/end
    - Room (if any)
    - Right side: status chip — `Live`, `In X min`, `Done` (computed from now).
- **CTA** "Open weekly schedule" → push `TeacherScheduleScreen`.
- Quick actions row kept but generated from a list (no per‑tile hard‑coding).

Remove the hard‑coded red/orange live banner.

## 6. Flutter — Schedule screen (new)

File: `lib/src/screens/teacher_schedule_screen.dart`.

- AppBar: title "Schedule", week navigation (`<` `>`), `Today` button, overflow → switch to month view (future).
- Body: **Google‑style week grid**
  - Header row: 7 day labels with date numbers; today highlighted (Material 3 primary container).
  - Left gutter: hour labels 06:00–22:00 (configurable).
  - Body: `Stack` over a `GridView` of 7×N hour cells; events rendered as colored cards positioned absolutely by `(dayIndex, startMinute, durationMinute)`.
  - Tap on empty cell → bottom sheet `ScheduleEditorSheet` prefilled with that day/time.
  - Tap on event → same sheet for edit/delete/override.
  - Drag (long‑press + drag) → reposition event; on release, update doc. Vertical drag = change time; horizontal drag = change day. (V1: drag is nice‑to‑have, ship without if tight.)
- FAB: `+ Add class time` → opens `ScheduleEditorSheet` blank.
- `ScheduleEditorSheet` fields:
  - Class picker (dropdown from teacher's classes)
  - Recurring vs one‑off toggle
  - Day of week (if recurring) or date (if one‑off)
  - Start/end time pickers (`TimeOfDay`)
  - Room (text)
  - Color (auto from class, optional override)
  - Effective from/to (optional, recurring only)
  - Save / Delete

Routing: pushed via `MaterialPageRoute` from Today's CTA and from sidebar (new "Schedule" tab if room).

## 7. Visual style

- Material 3, light surface.
- Use `SchoolColors` palette.
- Cards: 16dp radius, soft shadow (`alpha: 0.06`).
- Time chips: filled tonal, primary container for "Live", secondary for "In X min", outline for "Done".
- Typography: existing `SchoolColors.text`.

## 8. Testing

- Widget test: Today empty state + non‑empty rendering with mocked stream.
- Unit test: `resolveDay` merging recurring + overrides + cancellations.
- Manual: create recurring Tue 10:00–11:00, override next Tue with newStart 10:30, verify Today reflects it on that Tue.

## 9. Out of scope (v1)

- Drag‑to‑resize on the week grid (can be added later).
- Sharing schedule with students/parents (will surface later via existing class views).
- Conflicts detection across teachers (single‑teacher only for now).

## 10. Open questions

- None blocking. Drag UX deferred. Time range default 06:00–22:00; can be made user setting later.
