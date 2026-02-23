---
description: Cancel the active Ralph Wiggum loop
subtask: true
---

This command stops any active Ralph Wiggum loop managed by the `ralph-wiggum` plugin.

Follow these steps:

1. **Call the `cancel-ralph` tool** (no arguments).
2. Inspect the tool output and relay the result to the user:
   - If it reports that no loop was active, say that there was no Ralph loop to cancel.
   - If it reports successful cancellation, include the last iteration number and max-iterations value in your summary.
3. Do **not** manually edit or delete `.opencode/ralph-loop.md`; always go through the tool.

