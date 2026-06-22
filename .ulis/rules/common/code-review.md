# Code Review

**Trigger:** after writing/modifying code, before commits to shared branches, on security-sensitive or architectural changes. CI green + conflicts resolved before requesting review.

**Severity → action:**

| Level | Action |
| --- | --- |
| CRITICAL (security / data loss) | **BLOCK** — fix before merge |
| HIGH (bug / quality) | **WARN** — fix before merge |
| MEDIUM (maintainability) | consider |
| LOW (style) | optional |

**Security review (use security-reviewer) when touching:** auth/authz, user input, DB queries, filesystem, external APIs, crypto, payments.

**Reviewers:** code-reviewer (general), security-reviewer (OWASP), language-specific (typescript/python/go/rust)-reviewer.

Quality/security/perf checks live in [coding-style.md](coding-style.md), [security.md](security.md), [testing.md](testing.md).
