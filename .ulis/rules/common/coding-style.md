# Coding Style

- **Immutability (CRITICAL):** never mutate in place — return new copies.
- **KISS / DRY / YAGNI:** simplest thing that works; extract *real* (not speculative) repetition; don't build ahead of need.
- **Files:** many small > few large. 200–400 lines typical, 800 hard max. Organize by feature/domain, not by type.
- **Functions:** <50 lines, single responsibility. Early returns over nesting (>4 levels is a smell).
- **Errors:** handle explicitly at every level, never silently swallow. Friendly messages in UI, detailed context in server logs.
- **Validate at boundaries:** all external input (user, API responses, files) via schema; fail fast.
- **No magic numbers / hardcoded values** — use named constants or config.

## Naming

- `camelCase` vars/functions; booleans prefixed `is/has/should/can`.
- `PascalCase` types/interfaces/components; `UPPER_SNAKE_CASE` constants; hooks `useX`.
