# Security Review Workflow

Complete guide for when and how to trigger security reviews in the development process.

## When Security Review is REQUIRED

Security reviews are **mandatory** for changes involving:

### 1. Authentication & Authorization ✅
- Login/logout functionality
- Password reset/change
- Session management
- OAuth/SSO integration
- API key management
- Multi-factor authentication
- Permission/role systems
- Access control lists (ACLs)

### 2. Payment Processing ✅
- Payment gateway integration
- Credit card handling
- Subscription management
- Refund processing
- Billing calculations
- Invoice generation
- Payment webhooks

### 3. Personal Data (PII) ✅
- User profile data
- Email addresses
- Phone numbers
- Physical addresses
- Date of birth
- Government IDs
- Health information
- Financial data

### 4. File Uploads ✅
- Document uploads
- Image uploads
- Video uploads
- File storage integration
- Profile pictures/avatars
- User-generated content

### 5. Cryptographic Operations ✅
- Encryption/decryption
- Hashing passwords
- Signing tokens (JWT, etc.)
- API signature verification
- Certificate management
- Key generation

### 6. Webhooks & External APIs ✅
- Webhook receivers
- Third-party API integrations
- Callback URLs
- External service authentication
- API rate limiting

### 7. Database Operations ✅
- Direct SQL queries
- User input in queries
- Database migrations affecting sensitive data
- Bulk data operations
- Data exports

### 8. Admin/Privileged Functions ✅
- Admin panels
- User impersonation
- Bulk operations
- System configuration changes
- Feature flags affecting security

---

## Security Review Process

### Step 1: Identify Need for Security Review

**During Planning:**
```bash
# Planner should flag security-sensitive changes
@planner Create spec for [feature involving auth/payments/etc.]

# Planner output should include:
# "⚠️ Security Review Required: This feature involves [authentication/payments/etc.]"
```

**Automatic Triggers:**
- Changes to files in `auth/` directory
- Changes to files in `payment/` directory
- Changes to files in `admin/` directory
- Files with "password", "secret", "token" in names
- Database migrations on sensitive tables

### Step 2: Request Security Review

**In PR Description:**
```markdown
## Security Review

🔒 **Security review required**

**Why**: This PR involves [authentication/payment/file upload/etc.]

**Security-sensitive changes**:
- File: `src/auth/login.ts` - Updated login flow
- File: `src/auth/session.ts` - Session token generation

**Specific concerns**:
- [ ] JWT signing algorithm secure?
- [ ] Session timeout appropriate?
- [ ] Rate limiting in place?

**Testing**:
- [ ] Attempted SQL injection
- [ ] Attempted XSS attacks
- [ ] Tested authentication bypass scenarios

@security-team please review
```

### Step 3: Invoke Security Agent

```bash
# Use security agent for automated review
@security Review the authentication implementation in this PR

# Security agent will check:
# - OWASP Top 10 vulnerabilities
# - Common security pitfalls
# - Input validation
# - Output sanitization
# - Authentication/authorization patterns
```

### Step 4: Human Security Review

**Required Reviewers:**
- Security team member (required for P0/P1 items)
- Senior engineer with security knowledge
- Tech lead (always)

**Review Checklist** (see below)

### Step 5: Address Findings

**Security findings should be categorized:**

**CRITICAL** - Must fix before merge
- Example: SQL injection vulnerability
- Action: Block PR, implement fix immediately

**HIGH** - Must fix before deployment
- Example: Missing rate limiting
- Action: Create fix in this PR or immediate follow-up

**MEDIUM** - Should fix soon
- Example: Weak password requirements
- Action: Create ticket, fix within sprint

**LOW** - Nice to fix
- Example: Verbose error messages
- Action: Create ticket, prioritize in backlog

### Step 6: Document Security Decisions

```markdown
## Security Review Outcome

**Reviewer**: @security-person
**Date**: 2024-02-13
**Verdict**: APPROVED / CHANGES REQUIRED / BLOCKED

**Findings**:
1. **CRITICAL**: SQL injection in user search
   - Fixed in commit abc123
2. **HIGH**: Missing rate limiting on login
   - Added in commit def456
3. **MEDIUM**: Password requirements weak
   - Ticket created: SEC-789

**Approved for deployment**: YES
**Follow-up required**: Ticket SEC-789
```

---

## Security Review Checklist

### Authentication Review

- [ ] **Passwords**
  - [ ] Hashed with bcrypt/argon2 (NOT MD5/SHA1)
  - [ ] Minimum 12 character length enforced
  - [ ] Complexity requirements (uppercase, lowercase, number, special)
  - [ ] Passwords never logged or stored in plaintext
  - [ ] Password reset tokens expire within 1 hour
  - [ ] Password reset tokens single-use

- [ ] **Sessions**
  - [ ] Session tokens cryptographically random
  - [ ] Session expiration implemented (< 24 hours for sensitive apps)
  - [ ] Sessions invalidated on logout
  - [ ] Secure, HttpOnly, SameSite cookies
  - [ ] Session fixation prevented
  - [ ] No session data in URL parameters

- [ ] **Authentication Flow**
  - [ ] Account lockout after failed attempts (5-10 attempts)
  - [ ] Rate limiting on login endpoint (e.g., 5 attempts/minute)
  - [ ] MFA supported (TOTP preferred over SMS)
  - [ ] No timing attacks on username/password check
  - [ ] "Forgot password" doesn't reveal if email exists

---

### Authorization Review

- [ ] **Access Control**
  - [ ] Authorization checked on EVERY endpoint
  - [ ] No client-side only access control
  - [ ] Default deny (not default allow)
  - [ ] Principle of least privilege
  - [ ] Horizontal privilege escalation prevented (user can't access other users' data)
  - [ ] Vertical privilege escalation prevented (user can't access admin functions)

- [ ] **Resource Access**
  - [ ] Object-level authorization (can user access THIS resource?)
  - [ ] Predictable IDs don't bypass authorization
  - [ ] No direct object references without auth check
  - [ ] API returns only authorized data

**Example Test:**
```bash
# Try to access another user's data
curl -H "Authorization: Bearer user1_token" \
     https://api.yourapp.com/users/user2/profile

# Should return 403 Forbidden, not 200 OK
```

---

### Input Validation Review

- [ ] **All Inputs Validated**
  - [ ] Server-side validation (never trust client)
  - [ ] Type checking enforced
  - [ ] Length limits enforced
  - [ ] Format validation (email, phone, etc.)
  - [ ] Whitelist validation where possible

- [ ] **SQL Injection Prevention**
  - [ ] Parameterized queries ALWAYS used
  - [ ] No string concatenation in SQL
  - [ ] ORM used correctly (no raw queries with user input)

- [ ] **XSS Prevention**
  - [ ] User input HTML-escaped on output
  - [ ] Content-Security-Policy header set
  - [ ] No `innerHTML` with user data
  - [ ] Sanitization library used (DOMPurify)

- [ ] **Command Injection Prevention**
  - [ ] No shell commands with user input
  - [ ] If necessary, input strictly validated
  - [ ] Use language APIs instead of shell

---

### File Upload Security

- [ ] **File Validation**
  - [ ] File type validated (MIME type AND extension)
  - [ ] File size limits enforced
  - [ ] Filename sanitized (remove path traversal)
  - [ ] Files scanned for malware (if critical)
  - [ ] Files stored outside web root
  - [ ] No code execution on uploaded files

- [ ] **File Serving**
  - [ ] Correct Content-Type header
  - [ ] Content-Disposition: attachment for downloads
  - [ ] No directory listing
  - [ ] Signed URLs with expiration for sensitive files

**Example Vulnerable Code:**
```typescript
// ❌ VULNERABLE
app.post('/upload', (req, res) => {
  const filename = req.files.avatar.name;
  req.files.avatar.mv(`./uploads/${filename}`); // Path traversal!
});

// ✅ SECURE
app.post('/upload', (req, res) => {
  const allowedTypes = ['image/jpeg', 'image/png'];
  const file = req.files.avatar;

  if (!allowedTypes.includes(file.mimetype)) {
    return res.status(400).json({ error: 'Invalid file type' });
  }

  if (file.size > 5 * 1024 * 1024) {
    return res.status(400).json({ error: 'File too large' });
  }

  const safeFilename = crypto.randomUUID() + path.extname(file.name);
  file.mv(`./uploads/${safeFilename}`);
});
```

---

### API Security Review

- [ ] **Authentication**
  - [ ] API requires authentication (Bearer token, API key)
  - [ ] Tokens transmitted over HTTPS only
  - [ ] Tokens have appropriate expiration
  - [ ] Refresh tokens implemented for long-lived sessions

- [ ] **Rate Limiting**
  - [ ] Rate limiting per user/IP
  - [ ] Stricter limits on sensitive endpoints (auth, password reset)
  - [ ] 429 status code returned when limited

- [ ] **CORS**
  - [ ] CORS configured (not `*` in production)
  - [ ] Credentials allowed only for specific origins
  - [ ] Preflight requests handled correctly

- [ ] **Security Headers**
  - [ ] Strict-Transport-Security (HSTS)
  - [ ] X-Content-Type-Options: nosniff
  - [ ] X-Frame-Options: DENY or SAMEORIGIN
  - [ ] Content-Security-Policy
  - [ ] X-XSS-Protection: 1; mode=block

---

### Payment Processing Security

- [ ] **PCI Compliance**
  - [ ] NO credit card data stored (use Stripe/PayPal/etc.)
  - [ ] CVV NEVER stored
  - [ ] If storing card tokens, PCI-DSS compliant
  - [ ] HTTPS enforced on all payment pages
  - [ ] Payment gateway SDK up to date

- [ ] **Webhook Security**
  - [ ] Webhook signatures validated
  - [ ] Replay attacks prevented
  - [ ] Idempotency keys used
  - [ ] Sensitive operations require confirmation

**Example Webhook Validation:**
```typescript
// ✅ SECURE - Verify webhook signature
app.post('/webhooks/stripe', (req, res) => {
  const signature = req.headers['stripe-signature'];
  const secret = process.env.STRIPE_WEBHOOK_SECRET;

  try {
    const event = stripe.webhooks.constructEvent(
      req.body,
      signature,
      secret
    );
    // Process event...
  } catch (err) {
    return res.status(400).json({ error: 'Invalid signature' });
  }
});
```

---

### Data Privacy (GDPR/CCPA)

- [ ] **User Consent**
  - [ ] Explicit consent for data collection
  - [ ] Privacy policy accessible
  - [ ] Cookie consent banner (if applicable)
  - [ ] Opt-out mechanisms available

- [ ] **Data Minimization**
  - [ ] Collect only necessary data
  - [ ] Clear data retention policy
  - [ ] Automatic data deletion after retention period

- [ ] **User Rights**
  - [ ] Users can request their data (data export)
  - [ ] Users can delete their data (right to be forgotten)
  - [ ] Users can update their data
  - [ ] Deletion is permanent (not soft delete for PII)

---

### Secrets Management

- [ ] **No Hardcoded Secrets**
  - [ ] No API keys in code
  - [ ] No passwords in code
  - [ ] No private keys in repository
  - [ ] Secrets in environment variables or secret manager

- [ ] **Secret Storage**
  - [ ] Secrets encrypted at rest
  - [ ] Access to secrets logged
  - [ ] Secrets rotated regularly
  - [ ] Different secrets per environment

- [ ] **Logging**
  - [ ] Secrets redacted from logs
  - [ ] No PII in logs
  - [ ] Error messages don't expose secrets
  - [ ] Stack traces sanitized

---

## Security Testing

### Manual Testing

**Authentication Tests:**
```bash
# 1. Test invalid credentials
curl -X POST https://api.yourapp.com/login \
  -d '{"email":"test@example.com","password":"wrong"}'
# Should return 401, not reveal if email exists

# 2. Test account lockout
# Try 10 failed logins
# Should lock account temporarily

# 3. Test session expiration
# Wait for session timeout
# API calls should return 401
```

**Authorization Tests:**
```bash
# 1. Try to access another user's resource
curl -H "Authorization: Bearer user1_token" \
     https://api.yourapp.com/users/user2/profile
# Should return 403

# 2. Try to access admin endpoint as regular user
curl -H "Authorization: Bearer user_token" \
     https://api.yourapp.com/admin/users
# Should return 403
```

**Input Validation Tests:**
```bash
# 1. SQL injection attempt
curl -X POST https://api.yourapp.com/search \
  -d '{"query":"'; DROP TABLE users;--"}'
# Should NOT execute SQL, return error or empty result

# 2. XSS attempt
curl -X POST https://api.yourapp.com/comments \
  -d '{"text":"<script>alert(1)</script>"}'
# Should escape HTML on output

# 3. Path traversal
curl https://api.yourapp.com/files/../../../etc/passwd
# Should return 400 or 404, not the file
```

### Automated Security Scanning

```bash
# Run security scan
npm audit
# or
snyk test

# Run OWASP dependency check
dependency-check --scan .

# Run static analysis
eslint --ext .js,.ts --plugin security .
```

---

## Security Review Templates

### PR Security Review Comment

```markdown
## Security Review - APPROVED ✅

**Reviewed by**: @security-person
**Date**: 2024-02-13

### Summary
This PR implements user profile editing with appropriate security controls.

### Findings
✅ Input validation present and correct
✅ Output sanitization implemented
✅ Authorization checks on all endpoints
✅ No SQL injection vulnerabilities
✅ XSS prevention in place
✅ Rate limiting configured

### Recommendations (non-blocking)
- Consider adding audit logging for profile changes
- Password strength meter could be more visual

**Approved for deployment**
```

### Security Review - Changes Required

```markdown
## Security Review - CHANGES REQUIRED ⚠️

**Reviewed by**: @security-person
**Date**: 2024-02-13

### Critical Issues (MUST FIX before merge)
1. **SQL Injection** in user search endpoint
   - File: `src/user.controller.ts:45`
   - Issue: Direct string interpolation in query
   - Fix: Use parameterized queries

### High Priority Issues (Fix before deployment)
2. **Missing Rate Limiting** on password reset
   - File: `src/auth.controller.ts:123`
   - Issue: No rate limit, allows brute force
   - Fix: Add rate limiting (5 requests/hour/IP)

### Recommendations
3. Consider implementing MFA
4. Add security logging for auth events

**Status**: BLOCKED until critical issues resolved
```

---

## Security Escalation

### When to Escalate

Escalate immediately to security team for:
- **Active security incident** (breach, attack)
- **Critical vulnerability** discovered in production
- **Compliance issues** (GDPR, PCI-DSS)
- **Third-party vulnerability** affecting your system

### Escalation Process

```markdown
🚨 SECURITY ESCALATION

**Severity**: CRITICAL / HIGH / MEDIUM
**Type**: Vulnerability / Incident / Compliance
**Description**: [Brief description]

**Impact**:
- Users affected: [number]
- Data exposed: [type of data]
- Attack vector: [how it can be exploited]

**Immediate actions taken**:
- [ ] Disabled affected feature
- [ ] Blocked malicious IPs
- [ ] Rotated compromised credentials

**Security team**: @security-team
**Incident channel**: #security-incident-[date]
```

---

## Common Security Mistakes

### ❌ NEVER Do This

1. **Store passwords in plaintext**
   ```typescript
   // ❌ NEVER
   user.password = req.body.password;
   ```

2. **SQL injection**
   ```typescript
   // ❌ NEVER
   db.query(`SELECT * FROM users WHERE email = '${email}'`);
   ```

3. **Client-side only validation**
   ```typescript
   // ❌ NEVER rely on this alone
   <input type="email" required />
   ```

4. **Hardcoded secrets**
   ```typescript
   // ❌ NEVER
   const API_KEY = "sk-1234567890abcdef";
   ```

5. **Insecure cookies**
   ```typescript
   // ❌ NEVER
   res.cookie('session', token);
   ```

### ✅ ALWAYS Do This

1. **Hash passwords**
   ```typescript
   // ✅ ALWAYS
   const hash = await bcrypt.hash(password, 10);
   ```

2. **Parameterized queries**
   ```typescript
   // ✅ ALWAYS
   db.query('SELECT * FROM users WHERE email = ?', [email]);
   ```

3. **Server-side validation**
   ```typescript
   // ✅ ALWAYS
   if (!validator.isEmail(email)) {
     return res.status(400).json({ error: 'Invalid email' });
   }
   ```

4. **Environment variables**
   ```typescript
   // ✅ ALWAYS
   const API_KEY = process.env.API_KEY;
   ```

5. **Secure cookies**
   ```typescript
   // ✅ ALWAYS
   res.cookie('session', token, {
     httpOnly: true,
     secure: true,
     sameSite: 'strict',
     maxAge: 3600000
   });
   ```

---

## Resources

### Internal
- Security team: @security-team
- Security runbooks: [location]
- Incident response: `workflows/incident_response.md`
- Security agent: `@security`

### External
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheets: https://cheatsheetseries.owasp.org/
- Security Headers: https://securityheaders.com/
- Have I Been Pwned API: https://haveibeenpwned.com/API/v3

### Tools
- npm audit / yarn audit
- Snyk: https://snyk.io/
- OWASP Dependency Check
- ESLint security plugin
- Bandit (Python)
- Brakeman (Ruby)

---

## Security Review SLA

| Change Type | Review SLA | Reviewer |
|-------------|-----------|----------|
| Critical (auth, payments) | 4 hours | Security team required |
| High (PII, file uploads) | 1 business day | Security-trained engineer |
| Medium (general) | 2 business days | Senior engineer |

---

**Remember**: Security is everyone's responsibility. When in doubt, request a security review. It's better to be safe than sorry!
