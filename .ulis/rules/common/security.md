# Security

**Before any commit:** no hardcoded secrets; inputs validated; parameterized queries (no SQLi); sanitized HTML (no XSS); CSRF protection; auth/authz verified; rate limiting; errors don't leak sensitive data.

**Secrets:** never in source — env vars / secret manager. Validate presence at startup. Rotate anything exposed.

**On finding an issue:** STOP → security-reviewer agent → fix CRITICAL first → rotate exposed secrets → sweep codebase for the same pattern.
