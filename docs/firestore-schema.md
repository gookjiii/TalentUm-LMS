# Firestore Schema

Collections:

- `users`: auth profile, role, class membership.
- `classes`: teacher, students, parents.
- `messages`: realtime class chat.
- `assignments`: teacher-created work.
- `submissions`: student submissions.
- `grades`: teacher grades.
- `notifications`: per-user alerts.

Indexes:

- `messages`: `classId + createdAt`.
- `assignments`: `dueDate`.
- `notifications`: `userId + read + createdAt`.
