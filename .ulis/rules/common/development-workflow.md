# Development Workflow

> Extends [git-workflow.md](./git-workflow.md) with what happens before git.

**0. Research & Reuse (mandatory before new code):**
- `gh search repos` / `gh search code` first — find existing implementations/patterns.
- Context7 or vendor docs second — confirm API behavior & versions.
- Exa only if the above fall short.
- Check npm/PyPI/crates before hand-rolling utilities. Prefer forking/porting something that solves 80%+ over net-new code.

**1. Plan** (planner agent): PRD/architecture/task_list, risks, phases.
**2. TDD** (tdd-guide): RED → GREEN → refactor, 80%+ coverage.
**3. Review** (code-reviewer) immediately after writing: fix CRITICAL/HIGH.
**4. Commit & push:** conventional commits — see [git-workflow.md](./git-workflow.md).
**5. Pre-review:** CI green, conflicts resolved, branch up to date.
