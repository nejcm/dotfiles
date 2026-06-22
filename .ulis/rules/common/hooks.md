# Hooks & TodoWrite

- **Hook types:** PreToolUse (validate), PostToolUse (auto-format/check), Stop (final verify).
- **Auto-accept:** only for trusted, well-defined plans. Never `--dangerously-skip-permissions`; allowlist via `~/.claude.json` instead.
- **TodoWrite:** use for multi-step tasks — surfaces wrong order, missing/extra steps, bad granularity, misread requirements.
