# RLM MCP agent rules

**Apply these rules only when using the RLM command or the RLM agent; they are not applied to standard agents.** Use these rules when the RLM MCP server is configured or when invoking the RLM runner. Full policy: [specs/rlm-mcp/opencode-integration.md](../specs/rlm-mcp/opencode-integration.md).

- Prefer **rlm_plan** then **rlm_patch**; do not implement without a plan when using RLM.
- Never ask for whole files; use **rlm_get_symbol** or **rlm_get_snippet** only.
- After any code change, call **rlm_validate**.
- On validation failure, use **suggested_next_action** and **relevant_snippet_ids**; fetch only those snippets and iterate; do not dump full files.
- Produce a final **PR-style summary** (summary, file list, tests run, limitations, follow-ups) when the task is complete.
- Do not request patches that modify lockfiles unless the task explicitly requires dependency changes.
- For migrations, require an explicit migration file and rollback note before applying.
