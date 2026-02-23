# opencode-rlm

Opt-in RLM (Recursive Language Model) engineering loop for OpenCode, using the [alexzhang13/rlm](https://github.com/alexzhang13/rlm) library. **Runs only when explicitly invoked** (e.g. via the RLM command or RLM agent) and **runs uninterrupted to completion**.

## Install

From the `opencode/rlm` directory:

```bash
uv pip install -e .
# or
pip install -e .
```

Requires Python 3.11+. Depends on `rlms` (PyPI). Set `ANTHROPIC_API_KEY` (default backend) or `OPENAI_API_KEY` for the chosen backend.

## How to run

### Prerequisites

- Python 3.11+
- API key in the environment: `export ANTHROPIC_API_KEY=your_key` (or `OPENAI_API_KEY` if using `--backend openai`)
- Run from the **repository you want to change** (or pass `--repo /path/to/repo`)

### Option 1: Run with uv (no install)

From the **root of the repo you want to modify** (and with `opencode` as a sibling or parent):

```bash
cd /path/to/your-project
uv run --project /path/to/opencode/rlm python -m opencode_rlm --goal "Add OAuth login with Google"
```

If `opencode/rlm` lives inside your repo (e.g. `your-project/opencode/rlm`):

```bash
cd /path/to/your-project
uv run --project opencode/rlm python -m opencode_rlm --goal "Add OAuth login with Google"
```

### Option 2: Run after installing the package

From the `opencode/rlm` directory, install in editable mode:

```bash
cd opencode/rlm
uv pip install -e .
# or: pip install -e .
```

Then from **any directory** (default is current directory as repo):

```bash
cd /path/to/your-project
opencode-rlm --goal "Add OAuth login with Google"
```

To run against another repo without changing directory:

```bash
opencode-rlm --goal "Add OAuth login" --repo /path/to/other-repo
```

### Option 3: Run from OpenCode

- **Command:** Use the **Run RLM** command with your goal as the argument (e.g. “Add OAuth login”). The agent will execute the runner and report the PR-style summary.
- **Agent:** Invoke the RLM agent (e.g. `@rlm`) and give it a goal; it runs the same runner to completion and returns the summary.

### CLI options

| Option | Description |
|--------|-------------|
| `--goal`, `-g` | **Required.** User goal (e.g. "Add OAuth login"). |
| `--repo`, `-r` | Repo root (default: current directory). |
| `--constraints`, `-c` | Constraint; repeat for multiple. |
| `--validate`, `-V` | Verification command to run after each patch; repeat for multiple (default: auto-detect). |
| `--max-iterations` | Max plan/patch/validate iterations (default: 10). |
| `--backend` | `anthropic` (default) or `openai`. |
| `--model`, `-m` | Model name (default per backend). |
| `--verbose`, `-v` | Verbose RLM output. |

## How to provide instructions

**Goal (required)**  
Pass the task you want the RLM to accomplish as `--goal`. Be specific enough for the planner to break it into milestones and acceptance criteria.

```bash
opencode-rlm --goal "Add OAuth login with Google"
opencode-rlm --goal "Implement GET /api/users with pagination and filtering"
```

**Constraints (optional)**  
Use `--constraints` to narrow the solution space. Constraints are injected into the plan step so the model respects them when generating milestones and patches. Repeat for multiple constraints.

```bash
opencode-rlm --goal "Add user preferences API" \
  --constraints "Do not change the database schema" \
  --constraints "Reuse existing auth middleware" \
  --constraints "Must pass pnpm typecheck and pnpm test"
```

Examples of useful constraints:
- Technical: "TypeScript only", "No new dependencies", "Backward compatible"
- Process: "Must pass pnpm lint and pnpm test", "Include unit tests for new code"
- Scope: "Only under src/auth", "Do not modify lockfiles"

The planner turns the goal and constraints into acceptance criteria and a test strategy; the patch step is instructed not to modify lockfiles unless the task explicitly requires it.

## Verification and test (per loop)

After **each** patch segment, the runner runs verification commands. Only when all commands succeed does it move to the next milestone (or finish). Failed runs are retried (patch/validate again) up to `--max-iterations`.

**Default (auto-detect)**  
If you do not pass `--validate`, the runner detects commands from the repo:

| Repo signal | Commands run |
|-------------|--------------|
| `pnpm-lock.yaml` | `pnpm run lint` (or eslint), then `pnpm test` |
| `yarn.lock` | `yarn lint`, then `yarn test` |
| `package-lock.json` | `npm run lint`, then `npm test` |
| `pyproject.toml` | `uv run pytest -q` or `python -m pytest -q` |
| None | `true` (no-op) |

**Custom verification**  
Override with one or more `--validate` (or `-V`) arguments. Order is preserved; each command runs in the repo root with the current patch applied. Typical order: lint, then typecheck, then test.

```bash
opencode-rlm --goal "Add settings page" \
  --validate "pnpm run lint" \
  --validate "pnpm run typecheck" \
  --validate "pnpm test"
```

- Commands run in sequence; failure of one stops the run for that iteration (and may trigger a retry).
- Output is capped (last 2048 chars per command) to keep context small.
- Budget: total time for all validation commands in one run is limited (default 120s); you can add a future `--validate-budget` if needed.

To reproduce CI locally, pass the same commands your CI runs, e.g. `--validate "pnpm ci"` or multiple `--validate` entries matching your pipeline.

## Guardrails

The runner and prompts enforce the following so the loop stays safe and context stays small:

- **Small diffs:** Patches are limited to 1–3 files per segment; no whole-file dumps.
- **No lockfile edits:** The patch prompt instructs the model not to change lockfiles unless the task explicitly requires dependency changes.
- **Migrations:** If the plan includes schema/migrations, the policy is to require an explicit migration file and rollback note (documented in [config/rlm-mcp-rules.md](../config/rlm-mcp-rules.md)).
- **Validation every step:** After each patch, the runner runs your verification commands; it does not mark the task done until they pass (or max iterations are used).
- **Response caps:** Evidence list and snippet sizes are capped in the spec; the runner does not stream huge content into the model.
- **Iteration cap:** `--max-iterations` (default 10) prevents unbounded retry loops.

These match the OpenCode RLM rules applied when using the RLM command or agent; see [opencode/config/rlm-mcp-rules.md](../config/rlm-mcp-rules.md) and [opencode/specs/rlm-mcp/opencode-integration.md](../specs/rlm-mcp/opencode-integration.md).

## Behavior

1. **Plan**: Builds a structured plan (milestones, acceptance criteria) from the goal using the RLM.
2. **Patch**: For each milestone, generates small diffs (1–3 files) and applies them to the repo.
3. **Validate**: Runs lint/test commands (auto-detected from lockfile). On failure, retries within `--max-iterations`.
4. **Output**: Prints a PR-style summary (file list, tests run, acceptance criteria, limitations, follow-ups).

No intermediate approval; the loop runs to completion or until max iterations.

## Spec alignment

See [opencode/specs/rlm-mcp/](../specs/rlm-mcp/) for tool schemas, prompts, patch format, and validation contract. This runner implements the same loop and constraints (small diffs, validation after each patch, no whole-file dumps).
