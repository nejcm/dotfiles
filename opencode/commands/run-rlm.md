---
description: Run the RLM engineering assistant (plan -> patch -> validate) for the given goal; runs to completion without interruption. Use only when explicitly requested.
subtask: true
model: anthropic/claude-sonnet-4-6
---

# Run RLM (opt-in only)

This command runs the **RLM engineering loop** for the user's goal. RLM is **only** used when this command (or the RLM agent) is explicitly invoked; default OpenCode workflows do not use RLM.

**Behavior:** The task runs **uninterrupted to completion**: plan → patch → validate → iterate until done or max iterations. No intermediate approval or handoff.

## What to do

1. **Interpret the goal** from the input (e.g. `$ARGUMENTS` or the user message). If no goal is provided, ask the user for one.

2. **Run the RLM runner** from the repository root (the repo containing the code to change):
   - If using uv (recommended):
     ```bash
     uv run --project opencode/rlm python -m opencode_rlm --goal "USER_GOAL_HERE"
     ```
   - If the project is installed:
     ```bash
     opencode-rlm --goal "USER_GOAL_HERE"
     ```
   - Pass optional constraints with repeated `--constraints "constraint"` if the user specified any.
   - Use `--repo .` when already in the target repo, or `--repo /path/to/repo` when needed.

3. **Report the result**: The runner prints a PR-style summary (file list, tests run, acceptance criteria, limitations, follow-ups). Relay that summary to the user. If the runner exits with an error, report the error and any detail.

## Notes

- Ensure `ANTHROPIC_API_KEY` (or `OPENAI_API_KEY` if using `--backend openai`) is set in the environment.
- The runner applies patches and runs lint/test in the repo; do not interrupt it mid-run.
- Full spec: `opencode/specs/rlm-mcp/`.
