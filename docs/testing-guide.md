# Testing Guide

Run locally:

```bash
flutter test
(cd packages/validation && dart test)
(cd packages/design_system && flutter test)
```

Use Firebase Emulator for backend-dependent flows:

```bash
firebase emulators:start
```
