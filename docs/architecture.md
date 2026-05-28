# Architecture Overview

The repo follows a feature‑first, clean‑architecture monorepo layout.

```
packages/
├─ core            ← common logic
├─ design_system   ← UI tokens & widgets
├─ validation      ← validators
├─ shared_models   ← immutable entities
├─ firebase_api    ← Firestore / Firebase services
school_world/      ← Flutter application (single‑package)
```

See the plan for details.
