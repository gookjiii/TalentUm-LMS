# Agent guide

## Canonical layout

- Flutter app source: `lib/`; shared local packages: `packages/`.
- Platform targets: `android/`, `ios/`, `macos/`, `web/`, `windows/`, `linux/`.
- Firebase config/rules: `firebase.json`, `firestore.rules`, `database.rules.json`, `storage.rules`.
- Google Drive large-file backend: `vercel_backend/`.
- Do not recreate or search archived copies outside this directory as app source.

## Active runtime assumptions

- Firebase Auth/Firestore/Realtime Database/Storage and Firebase Hosting are active.
- Cloudinary handles chat/profile media.
- Library, homework, assignment, and document uploads use Google Drive via Vercel as primary storage (default threshold 0 MB) with Firebase Storage as an error fallback.
- Google Drive upload metadata is stored in Firestore; PostgreSQL is not required for the active flow.

## Generated files

`.dart_tool/`, `build/`, `.firebase/`, `packages/*/build/`, `vercel_backend/node_modules/`, `.tessl/`, and `test/goldens/failures/` are generated. Ignore or regenerate them; do not spend analysis time indexing them.

## Verification

Run `flutter analyze` and targeted `flutter test` before changes. For a web release, use `./deploy_web.sh` with Cloudinary variables and a valid `GOOGLE_DRIVE_PROXY_URL` (defaulting to Vercel backend with 0 MB threshold for Google Drive).
