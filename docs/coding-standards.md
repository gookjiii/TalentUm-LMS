# Coding Standards

- Feature-first Flutter architecture.
- Riverpod providers only; no Firebase calls in widgets.
- `AsyncValue<T>` for async UI state.
- DTOs map external data; entities are immutable and business-safe.
- No hardcoded colors; use theme/design-system tokens.
- No swallowed errors; log `error + stackTrace`.
