# Performance & Model Use

- **Model choice:** Haiku for cheap high-frequency/worker agents; Sonnet for main dev & orchestration; Opus for deep architecture/reasoning. (Use current model IDs — verify via the claude-api skill.)
- **Context budget:** avoid the last ~20% for large refactors / multi-file features / complex debugging.
- **Extended thinking + Plan Mode** for deep-reasoning tasks; multiple critique rounds for thorough analysis.
- **Build fails:** use build-error-resolver — fix incrementally, verify after each step.
