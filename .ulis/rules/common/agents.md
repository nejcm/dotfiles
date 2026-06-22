# Agent Orchestration

Agents in `~/.claude/agents/`: planner, architect, tdd-guide, code-reviewer, security-reviewer, build-error-resolver, e2e-runner, refactor-cleaner, doc-updater, rust-reviewer.

- **Auto-use (no prompt needed):** planner for complex features; code-reviewer after writing code; tdd-guide for bug fix / new feature; architect for architectural decisions.
- **Run independent agents in parallel**, never sequentially.
- **Complex problems:** split-role sub-agents (factual reviewer, senior engineer, security expert, consistency, redundancy).
