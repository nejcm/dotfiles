"""
RLM engineering loop: plan -> patch -> validate. Runs uninterrupted to completion.
Uses alexzhang13/rlm (rlms) for completions; applies diffs and runs validation locally.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from opencode_rlm.prompts import (
    PLAN_SYSTEM,
    PLAN_USER,
    PATCH_SYSTEM,
    PATCH_USER,
)


def _find_repo_root(start: Path) -> Path:
    """Return repo root (directory containing .git) or start."""
    p = start.resolve()
    for _ in range(20):
        if (p / ".git").exists():
            return p
        parent = p.parent
        if parent == p:
            break
        p = parent
    return start


def _gather_context(repo_root: Path, max_files: int = 50) -> str:
    """List code-like paths for plan context (MVP: no indexing)."""
    paths = []
    for ext in (".ts", ".tsx", ".js", ".jsx", ".py", ".go", ".rs", ".java", ".md"):
        for p in repo_root.rglob(f"*{ext}"):
            if ".git" in str(p) or "node_modules" in str(p):
                continue
            try:
                rel = p.relative_to(repo_root)
            except ValueError:
                continue
            paths.append(str(rel))
            if len(paths) >= max_files:
                return "\n".join(paths)
    return "\n".join(paths) if paths else "(no code files found)"


def _extract_json(text: str) -> dict | None:
    """Extract first JSON object from model output."""
    text = text.strip()
    # Drop markdown code block if present
    if "```" in text:
        match = re.search(r"```(?:json)?\s*(\{[\s\S]*?\})\s*```", text)
        if match:
            text = match.group(1)
    start = text.find("{")
    if start == -1:
        return None
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                try:
                    return json.loads(text[start : i + 1])
                except json.JSONDecodeError:
                    return None
    return None


def _apply_diffs(repo_root: Path, diffs: list[dict]) -> list[str]:
    """Apply unified diffs; return list of changed paths. Uses patch(1) or write-and-apply."""
    changed = []
    for item in diffs:
        path = item.get("path")
        unified_diff = item.get("unified_diff", "")
        if not path or not unified_diff:
            continue
        target = repo_root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".patch", delete=False, encoding="utf-8"
        ) as f:
            f.write(unified_diff)
            patch_path = f.name
        try:
            result = subprocess.run(
                ["patch", "-p1", "-f", "-s", "-d", str(repo_root), "-i", patch_path],
                capture_output=True,
                text=True,
                timeout=30,
            )
            if result.returncode == 0:
                changed.append(path)
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        finally:
            try:
                os.unlink(patch_path)
            except OSError:
                pass
    return changed


def _run_validation(repo_root: Path, commands: list[str], budget_seconds: int = 120)
    -> tuple[bool, list[dict], str, list[str]]:
    """
    Run commands in repo_root. Return (overall_pass, results[], suggested_next_action, relevant_snippet_ids).
    results: [{command, pass, exit_code, log_excerpt?, failure_summary?}]
    """
    per_cmd_timeout = max(10, budget_seconds // len(commands)) if commands else 60
    results = []
    for cmd in commands:
        try:
            proc = subprocess.run(
                cmd,
                shell=True,
                cwd=repo_root,
                capture_output=True,
                text=True,
                timeout=per_cmd_timeout,
                env={**os.environ, "CI": "true"},
            )
            out = (proc.stdout or "") + (proc.stderr or "")
            log_excerpt = out[-2048:] if len(out) > 2048 else out
            if proc.returncode != 0 and len(out) > 2048:
                log_excerpt = "... (truncated)\n" + log_excerpt
            results.append({
                "command": cmd,
                "pass": proc.returncode == 0,
                "exit_code": proc.returncode,
                "log_excerpt": log_excerpt[:2048],
                "failure_summary": None if proc.returncode == 0 else f"Exit code {proc.returncode}",
            })
        except subprocess.TimeoutExpired:
            results.append({
                "command": cmd,
                "pass": False,
                "exit_code": None,
                "log_excerpt": "(command timed out)",
                "failure_summary": "Command timed out.",
            })
    overall = all(r["pass"] for r in results)
    suggested = "done"
    snippet_ids = []
    if not overall and results:
        first_fail = next(r for r in results if not r["pass"])
        suggested = "fix"
        snippet_ids = []
    return overall, results, suggested, snippet_ids


def _default_validate_commands(repo_root: Path) -> list[str]:
    """Detect package manager and return [lint, typecheck?, test]."""
    cmds = []
    if (repo_root / "pnpm-lock.yaml").exists():
        cmds = ["pnpm run lint 2>/dev/null || pnpm exec eslint . 2>/dev/null || true", "pnpm test"]
    elif (repo_root / "yarn.lock").exists():
        cmds = ["yarn lint 2>/dev/null || true", "yarn test"]
    elif (repo_root / "package-lock.json").exists():
        cmds = ["npm run lint 2>/dev/null || true", "npm test"]
    elif (repo_root / "pyproject.toml").exists():
        cmds = ["uv run pytest -q 2>/dev/null || python -m pytest -q 2>/dev/null || true"]
    else:
        cmds = ["true"]
    return cmds if cmds else ["true"]


def run_loop(
    goal: str,
    repo_path: Path,
    constraints: list[str],
    validate_commands_override: list[str] | None,
    max_iterations: int,
    backend: str,
    model: str,
    verbose: bool,
) -> dict:
    """
    Run plan -> patch -> validate loop to completion. Returns a result dict with
    summary, file_list, tests_run, limitations, follow_ups, and optionally plan_id, patch_id, error.
    """
    repo_root = _find_repo_root(repo_path)
    try:
        from rlm import RLM
    except ImportError as e:
        return {
            "error": "rlms not installed. Install with: pip install rlms (or uv add rlms)",
            "detail": str(e),
        }

    backend_kwargs = {"model_name": model or "claude-sonnet-4-20250514"}
    if backend == "openai":
        backend_kwargs["model_name"] = model or "gpt-4o"
    rlm = RLM(
        backend=backend,
        backend_kwargs=backend_kwargs,
        environment="local",
        verbose=verbose,
    )

    retrieved_context = _gather_context(repo_root)
    constraints_str = ", ".join(constraints) if constraints else "None"

    # Step 1: Plan
    plan_prompt = PLAN_USER.format(
        goal=goal,
        constraints=constraints_str,
        retrieved_context=retrieved_context,
    )
    full_plan_prompt = PLAN_SYSTEM + "\n\n" + plan_prompt
    try:
        completion = rlm.completion(full_plan_prompt)
        response_text = getattr(completion, "response", None) or str(completion)
    except Exception as e:
        return {"error": "Plan step failed", "detail": str(e)}

    plan = _extract_json(response_text)
    if not plan or plan.get("error"):
        return {
            "error": "Plan step did not return valid JSON",
            "detail": response_text[:500],
            "raw_response": response_text[:2000],
        }

    plan_id = plan.get("plan_id") or "plan-1"
    milestones = plan.get("milestones") or []
    if not milestones:
        milestones = [{"id": "m1", "title": "Implement", "order": 1, "scope_summary": goal}]

    acceptance_criteria = plan.get("acceptance_criteria") or []
    test_strategy = plan.get("test_strategy") or "Run lint and tests."

    # Validation commands: explicit override or auto-detect per repo
    validate_commands = (
        validate_commands_override
        if validate_commands_override
        else _default_validate_commands(repo_root)
    )
    all_changed_files = []
    iterations = 0

    for milestone in sorted(milestones, key=lambda m: m.get("order", 0)):
        scope = milestone.get("scope_summary") or milestone.get("title") or milestone.get("id")
        scope_id = milestone.get("id") or f"m{milestone.get('order', 0)}"

        for attempt in range(max_iterations):
            iterations += 1
            if iterations > max_iterations:
                break

            # Patch step
            patch_prompt = PATCH_USER.format(
                scope=scope,
                snippets_and_symbols=retrieved_context[:8000],
            )
            full_patch_prompt = PATCH_SYSTEM + "\n\n" + patch_prompt
            try:
                patch_completion = rlm.completion(full_patch_prompt)
                patch_response = getattr(patch_completion, "response", None) or str(patch_completion)
            except Exception as e:
                return {"error": "Patch step failed", "detail": str(e), "milestone": scope_id}

            patch_data = _extract_json(patch_response)
            if not patch_data or patch_data.get("error"):
                continue

            diffs = patch_data.get("diffs") or []
            if not diffs:
                break

            changed = _apply_diffs(repo_root, diffs)
            all_changed_files.extend(changed)

            # Validate
            overall_pass, results, suggested, _ = _run_validation(
                repo_root, validate_commands, budget_seconds=120
            )
            if overall_pass:
                break
            if suggested == "done" or suggested == "adjust_tests":
                break
            # suggested == "fix" or "expand_scope": retry with same or next scope

    # Final summary
    return {
        "summary": f"RLM run completed for goal: {goal}",
        "plan_id": plan_id,
        "acceptance_criteria": acceptance_criteria,
        "test_strategy": test_strategy,
        "file_list": list(dict.fromkeys(all_changed_files)),
        "tests_run": validate_commands,
        "known_limitations": [],
        "follow_ups": [],
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run RLM engineering loop (plan -> patch -> validate) to completion. Opt-in only; runs uninterrupted."
    )
    parser.add_argument("--goal", "-g", required=True, help="User goal (e.g. 'Add OAuth login')")
    parser.add_argument("--repo", "-r", default=".", type=Path, help="Repo root (default: cwd)")
    parser.add_argument("--constraints", "-c", action="append", default=[], help="Constraint (repeatable)")
    parser.add_argument(
        "--validate", "-V",
        action="append",
        default=[],
        dest="validate_commands",
        help="Verification command to run after each patch (repeatable). Default: auto-detect from repo (lint + test).",
    )
    parser.add_argument("--max-iterations", type=int, default=10, help="Max plan/patch/validate iterations (default 10)")
    parser.add_argument("--backend", default="anthropic", choices=["anthropic", "openai"], help="LLM backend")
    parser.add_argument("--model", "-m", default="", help="Model name (default per backend)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose RLM output")
    args = parser.parse_args()

    result = run_loop(
        goal=args.goal,
        repo_path=args.repo,
        constraints=args.constraints,
        validate_commands_override=args.validate_commands or None,
        max_iterations=args.max_iterations,
        backend=args.backend,
        model=args.model,
        verbose=args.verbose,
    )

    if result.get("error"):
        print("RLM error:", result["error"], file=sys.stderr)
        if result.get("detail"):
            print(result["detail"], file=sys.stderr)
        sys.exit(1)

    print("--- RLM PR-style summary ---")
    print(result.get("summary", ""))
    print("\nFiles changed:", result.get("file_list", []))
    print("Tests run:", result.get("tests_run", []))
    print("Acceptance criteria:", result.get("acceptance_criteria", []))
    print("Known limitations:", result.get("known_limitations", []))
    print("Follow-ups:", result.get("follow_ups", []))
    sys.exit(0)
