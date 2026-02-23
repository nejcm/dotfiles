---
description: Start a Ralph Wiggum loop in the current session
subtask: true
---

You are implementing the Ralph Wiggum iterative loop technique in OpenCode.

`$ARGUMENTS` contains the raw user input for this command.

Follow these rules:

1. **Do not implement the loop yourself in this command.** The loop mechanics are handled entirely by the `ralph-wiggum` plugin.
2. **Start the loop via the `ralph-loop` tool** exposed by the plugin:
   - Call the `ralph-loop` tool once.
   - Pass a single `input` string equal to the exact `$ARGUMENTS` text from this command.
   - Do not attempt to parse flags yourself; the tool will parse:
     - Task prompt (free text)
     - Optional `--max-iterations N`
     - Optional `--completion-promise TEXT`
3. **After the tool returns**, briefly summarize to the user:
   - The detected prompt
   - Whether a completion promise was configured
   - The max-iterations setting (or that it is unlimited)
4. **Then begin working on the task normally.**
   - Treat the current response as **iteration 1** of the Ralph loop.
   - Do not try to manually re-trigger future iterations; the plugin will do that by listening to `session.idle` events.

If the `ralph-loop` tool fails (for example, due to invalid flags), report the error clearly and ask the user to rerun the command with a corrected argument string.

