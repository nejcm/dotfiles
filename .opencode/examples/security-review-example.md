# Security Review Example: OAuth2 Authentication Implementation

**Scenario:** Add OAuth2 authentication to a REST API with comprehensive security review

**Complexity:** High
**Duration:** ~4 hours
**Agents Used:** @planner, @security, @builder, @tester, @reviewer
**Skills Used:** `api-validator`, `code-quality`, `run-tests`

---

## Scenario

### Initial Request

**User:** "We need to add OAuth2 authentication to our REST API. Currently, we just use API keys which isn't secure enough. We want to support Google and GitHub OAuth providers."

### Context

**Current State:**
- REST API with 15 endpoints
- Simple API key authentication (`X-API-Key` header)
- No user management
- No token refresh mechanism

**Requirements:**
- OAuth2 authorization code flow
- Support Google and GitHub providers
- JWT-based access tokens
- Refresh token rotation
- Secure token storage
- PKCE (Proof Key for Code Exchange) support

### Success Criteria

- ✅ OAuth2 flow implemented correctly
- ✅ All security best practices followed (OWASP)
- ✅ No hardcoded secrets
- ✅ Proper error handling
- ✅ Comprehensive tests (unit + integration)
- ✅ Security review passes
- ✅ Documentation complete

---

## Agent Transcript

### Phase 1: Planning (@ planner)

**User:** @planner Design OAuth2 authentication system for our API

**@planner:**
> Analyzing requirements for OAuth2 implementation...
>
> **Scope Analysis:**
> - OAuth2 authorization code flow with PKCE
> - Multi-provider support (Google, GitHub)
> - JWT token management
> - Secure credential storage
>
> **Reading current authentication:**
> - `src/middleware/auth.ts` - Current API key auth
> - `src/routes/auth.ts` - Auth endpoints
> - `package.json` - No OAuth libraries yet
>
> **Creating specification...**

**Output:** `specs/oauth2-implementation.md`

```markdown
# OAuth2 Authentication Implementation Spec

## Overview
Implement OAuth2 2.0 authorization code flow with PKCE for secure authentication.

## Architecture

### Components
1. **OAuth Controller** (`src/auth/oauth.controller.ts`)
   - `/auth/oauth/authorize` - Initiate OAuth flow
   - `/auth/oauth/callback` - Handle provider callback
   - `/auth/oauth/refresh` - Refresh access token
   - `/auth/oauth/revoke` - Revoke tokens

2. **OAuth Service** (`src/auth/oauth.service.ts`)
   - Provider integration (Google, GitHub)
   - Token generation (JWT)
   - Token validation
   - PKCE verification

3. **Token Store** (`src/auth/token.store.ts`)
   - Refresh token storage (Redis)
   - Token rotation
   - Expiration management

### Security Measures
1. **PKCE** - Prevent authorization code interception
2. **State Parameter** - CSRF protection
3. **Secure Cookies** - HttpOnly, Secure, SameSite
4. **Token Encryption** - Encrypt refresh tokens at rest
5. **Rate Limiting** - Prevent token enumeration
6. **Audit Logging** - Log all auth events

## Data Models

### User
```typescript
interface User {
  id: string;
  email: string;
  provider: 'google' | 'github';
  providerId: string;
  createdAt: Date;
  lastLoginAt: Date;
}
```

### OAuthToken
```typescript
interface OAuthToken {
  accessToken: string;  // JWT, 15 min expiry
  refreshToken: string; // Encrypted, 30 day expiry
  expiresAt: Date;
  tokenType: 'Bearer';
}
```

## Implementation Steps
1. Install dependencies (passport, jsonwebtoken, etc.)
2. Implement OAuth providers
3. Create token generation/validation
4. Implement PKCE flow
5. Add refresh token rotation
6. Security review
7. Testing
8. Documentation

## Security Requirements
- ❌ No secrets in code or env files (use secret manager)
- ✅ All tokens encrypted at rest
- ✅ Rate limiting on auth endpoints
- ✅ Audit logging enabled
- ✅ HTTPS only (no HTTP)
- ✅ CSP headers configured
```

**@planner:**
> Specification created. Ready for security review.
>
> **Estimated Complexity:** HIGH
> **Suggested Review:** @security should review spec before implementation

---

### Phase 2: Security Review - Specification (@ security)

**User:** @security Review the OAuth2 specification for security concerns

**@security:**
> Reading specification: `specs/oauth2-implementation.md`
>
> **Security Analysis in Progress...**
>
> Checking against OWASP OAuth 2.0 Security Best Current Practices...

**Output:** `reports/security-spec-review.md`

```markdown
# Security Review: OAuth2 Specification

**Reviewer:** @security
**Date:** 2026-02-16
**Status:** ⚠️ CONDITIONAL APPROVAL

## Findings

### ✅ SECURE Practices Identified

1. **PKCE Implementation**
   - Severity: N/A (Good practice)
   - Prevents authorization code interception attacks
   - Required for public clients

2. **State Parameter**
   - Severity: N/A (Good practice)
   - CSRF protection on callback
   - Must be cryptographically random

3. **Token Encryption at Rest**
   - Severity: N/A (Good practice)
   - Refresh tokens encrypted in Redis
   - Use AES-256-GCM

4. **Short-lived Access Tokens**
   - Severity: N/A (Good practice)
   - 15-minute expiry reduces attack window

### ⚠️ WARNINGS (Should Fix)

1. **Missing Token Binding**
   - Severity: MEDIUM
   - Location: Spec section 3.2
   - Issue: No mention of binding tokens to clients
   - Recommendation: Implement DPoP or certificate-bound tokens
   - Impact: Reduces token theft effectiveness

2. **Insufficient Rate Limiting Details**
   - Severity: MEDIUM
   - Location: Security Measures section
   - Issue: Rate limits not specified
   - Recommendation:
     - `/auth/oauth/authorize`: 10 requests/hour per IP
     - `/auth/oauth/callback`: 20 requests/hour per IP
     - `/auth/oauth/refresh`: 100 requests/hour per user
   - Impact: Prevents brute force and token enumeration

3. **No Mention of OAuth Scope Management**
   - Severity: LOW
   - Issue: Scopes not defined
   - Recommendation: Define minimal scopes (profile, email)
   - Impact: Principle of least privilege

### 🚨 CRITICAL Issues (Must Fix)

1. **Secret Management Not Specified**
   - Severity: CRITICAL
   - Location: Throughout spec
   - Issue: Says "use secret manager" but doesn't specify which
   - Recommendation:
     - Use HashiCorp Vault, AWS Secrets Manager, or similar
     - Never use .env files for production secrets
     - Implement secret rotation (90 days)
   - Impact: Hardcoded secrets = HIGH risk of compromise

2. **Missing Redirect URI Validation**
   - Severity: CRITICAL
   - Location: OAuth Controller section
   - Issue: No mention of redirect_uri validation
   - Recommendation:
     - Whitelist exact redirect URIs (no wildcards)
     - Validate on BOTH authorize and callback
     - Reject localhost in production
   - Impact: Open redirect vulnerability (CWE-601)

3. **No Token Revocation Strategy**
   - Severity: HIGH
   - Location: Token Store section
   - Issue: `/oauth/revoke` endpoint but no revocation logic
   - Recommendation:
     - Implement token blacklist (Redis)
     - Revoke all user tokens on password change
     - Provide admin revocation capability
   - Impact: Compromised tokens cannot be invalidated

## Required Spec Changes

**BEFORE implementation can proceed:**

1. Add redirect URI validation section
2. Specify secret management solution
3. Define OAuth scopes
4. Add token revocation details
5. Specify exact rate limits

## Additional Recommendations

1. **Token Storage**
   - Use separate Redis instance for auth
   - Enable Redis AUTH
   - Use TLS for Redis connections

2. **Logging**
   - Log failed auth attempts
   - Log token refresh (but NOT the token itself)
   - Alert on suspicious patterns (10 failed attempts/minute)

3. **Compliance**
   - Consider GDPR implications (user data from providers)
   - Implement data retention policy
   - Provide user data export/deletion

## Approval Status

**⚠️ CONDITIONAL APPROVAL**

The specification demonstrates good security awareness but has **2 CRITICAL issues** that MUST be addressed before implementation:

1. Redirect URI validation
2. Secret management specification

Once these are fixed, implementation may proceed with @security oversight.

## Next Steps

1. @planner: Address CRITICAL and HIGH findings
2. @security: Re-review updated spec
3. @builder: Begin implementation ONLY after approval
```

**@security:**
> Security review complete.
>
> **Status:** CONDITIONAL APPROVAL
> **Critical Issues:** 2
> **Must Fix:** Redirect URI validation, Secret management

---

### Phase 3: Spec Revision (@ planner)

**User:** @planner Update the spec based on security review findings

**@planner:**
> Reading security review: `reports/security-spec-review.md`
>
> Updating specification with required changes...

**Updated Section in `specs/oauth2-implementation.md`:**

```markdown
## Redirect URI Validation (ADDED)

### Whitelist Strategy
```typescript
const ALLOWED_REDIRECT_URIS = {
  development: [
    'http://localhost:3000/auth/callback',
    'http://localhost:8080/auth/callback'
  ],
  production: [
    'https://app.example.com/auth/callback',
    'https://example.com/auth/callback'
  ]
};

function validateRedirectUri(uri: string, env: string): boolean {
  const allowed = ALLOWED_REDIRECT_URIS[env];
  return allowed.includes(uri);  // Exact match, no wildcards
}
```

### Validation Points
1. **On /authorize**: Reject invalid redirect_uri immediately
2. **On /callback**: Re-validate against whitelist
3. **No localhost in production**: Hard fail if detected

## Secret Management (ADDED)

### Solution: AWS Secrets Manager

**Secrets to Store:**
- `OAUTH_GOOGLE_CLIENT_ID`
- `OAUTH_GOOGLE_CLIENT_SECRET`
- `OAUTH_GITHUB_CLIENT_ID`
- `OAUTH_GITHUB_CLIENT_SECRET`
- `JWT_PRIVATE_KEY` (RSA 2048-bit)
- `JWT_PUBLIC_KEY`
- `TOKEN_ENCRYPTION_KEY` (AES-256)

**Rotation Schedule:**
- OAuth client secrets: 90 days
- JWT keys: 180 days
- Encryption keys: 365 days

**Access:**
- Application uses IAM role (no credentials in code)
- Secrets fetched on startup and cached (15 min TTL)
- Rotation triggers application reload

## OAuth Scopes (ADDED)

```typescript
const OAUTH_SCOPES = {
  google: ['openid', 'profile', 'email'],
  github: ['read:user', 'user:email']
};
```

**Minimal Scopes:** Only request profile and email
**Scope Validation:** Verify received scopes match requested

## Rate Limiting (DETAILED)

```typescript
const RATE_LIMITS = {
  '/auth/oauth/authorize': { max: 10, window: '1h', by: 'ip' },
  '/auth/oauth/callback': { max: 20, window: '1h', by: 'ip' },
  '/auth/oauth/refresh': { max: 100, window: '1h', by: 'user' },
  '/auth/oauth/revoke': { max: 50, window: '1h', by: 'user' }
};
```

## Token Revocation (DETAILED)

### Revocation Strategy
1. **Blacklist in Redis** (TTL = token expiry)
2. **All Endpoints Check Blacklist** before accepting token
3. **Revocation Triggers:**
   - User-initiated logout
   - Password change
   - Admin action
   - Suspicious activity detected

### Implementation
```typescript
class TokenBlacklist {
  async revoke(token: string, expiresAt: Date): Promise<void> {
    const ttl = Math.floor((expiresAt.getTime() - Date.now()) / 1000);
    await redis.setex(`blacklist:${token}`, ttl, '1');
  }

  async isRevoked(token: string): Promise<boolean> {
    return await redis.exists(`blacklist:${token}`) === 1;
  }
}
```
```

**@planner:**
> Specification updated with all CRITICAL and HIGH severity findings addressed.
>
> **Changes Made:**
> - ✅ Redirect URI validation (whitelist, exact match)
> - ✅ Secret management (AWS Secrets Manager, rotation)
> - ✅ OAuth scopes defined (minimal permissions)
> - ✅ Rate limits specified (all endpoints)
> - ✅ Token revocation detailed (blacklist + TTL)
>
> Ready for security re-review.

---

### Phase 4: Security Re-Review (@ security)

**User:** @security Re-review updated specification

**@security:**
> Re-reviewing updated spec...
>
> **Checking CRITICAL fixes:**
> - ✅ Redirect URI validation: FIXED (exact match, whitelist)
> - ✅ Secret management: FIXED (AWS Secrets Manager + rotation)
>
> **Checking HIGH/MEDIUM fixes:**
> - ✅ Rate limiting: FIXED (specific limits per endpoint)
> - ✅ Token revocation: FIXED (blacklist with TTL)
> - ✅ OAuth scopes: FIXED (minimal scopes defined)

**Output:** `reports/security-spec-re-review.md`

```markdown
# Security Re-Review: OAuth2 Specification

**Status:** ✅ **APPROVED FOR IMPLEMENTATION**

All CRITICAL and HIGH severity findings have been addressed:

1. ✅ Redirect URI validation implemented with whitelist
2. ✅ Secret management specified (AWS Secrets Manager)
3. ✅ Token revocation strategy defined
4. ✅ Rate limits specified for all endpoints
5. ✅ OAuth scopes minimized

## Recommendations for Implementation Phase

1. **Code Review Focus Areas:**
   - Verify redirect_uri validation on BOTH authorize and callback
   - Ensure secrets never logged or exposed in errors
   - Check rate limiting middleware configuration

2. **Testing Requirements:**
   - Test redirect URI bypass attempts
   - Test token revocation immediately invalidates tokens
   - Test rate limiting triggers correctly

3. **Security Review Checkpoints:**
   - After OAuth flow implementation → @security review code
   - After token management → @security review
   - Before deployment → Full security audit

Implementation may proceed. @security will review code at checkpoints.
```

**@security:**
> ✅ **SPECIFICATION APPROVED**
>
> Implementation may proceed with @security checkpoints.

---

### Phase 5: Implementation (@ builder)

**User:** @builder Implement OAuth2 authentication per approved spec

**@builder:**
> Reading specification: `specs/oauth2-implementation.md`
> Reading security reviews: `reports/security-spec-*.md`
>
> **Implementation Plan:**
> 1. Install dependencies
> 2. Implement redirect URI validation
> 3. Set up secret management
> 4. Implement OAuth providers (Google, GitHub)
> 5. Implement token generation/validation
> 6. Implement PKCE flow
> 7. Implement refresh token rotation
> 8. Add rate limiting
> 9. Add audit logging
>
> **Starting implementation...**

**Files Created:**

**1. `src/auth/oauth.controller.ts`** (Primary OAuth endpoints)

```typescript
import { Router } from 'express';
import { OAuthService } from './oauth.service';
import { validateRedirectUri } from './redirect-validator';
import { rateLimiter } from '../middleware/rate-limit';
import { auditLog } from '../middleware/audit';

const router = Router();
const oauthService = new OAuthService();

// Rate limiting per spec
const authorizeLimiter = rateLimiter({ max: 10, window: '1h', by: 'ip' });
const callbackLimiter = rateLimiter({ max: 20, window: '1h', by: 'ip' });
const refreshLimiter = rateLimiter({ max: 100, window: '1h', by: 'user' });

/**
 * Initiate OAuth2 authorization flow with PKCE
 */
router.get('/auth/oauth/authorize',
  authorizeLimiter,
  auditLog('oauth_authorize_start'),
  async (req, res) => {
    const { provider, redirect_uri } = req.query;

    // SECURITY: Validate redirect URI (exact match, whitelist)
    if (!validateRedirectUri(redirect_uri as string)) {
      return res.status(400).json({
        error: 'INVALID_REDIRECT_URI',
        message: 'Redirect URI not whitelisted'
      });
    }

    // Generate PKCE challenge
    const { codeVerifier, codeChallenge } = oauthService.generatePKCE();

    // Generate state for CSRF protection
    const state = oauthService.generateState();

    // Store PKCE and state in session (HttpOnly cookie)
    req.session.codeVerifier = codeVerifier;
    req.session.state = state;
    req.session.redirect_uri = redirect_uri;

    // Get authorization URL from provider
    const authUrl = await oauthService.getAuthorizationUrl(
      provider as 'google' | 'github',
      codeChallenge,
      state,
      redirect_uri as string
    );

    res.redirect(authUrl);
  }
);

/**
 * Handle OAuth2 callback from provider
 */
router.get('/auth/oauth/callback',
  callbackLimiter,
  auditLog('oauth_callback_received'),
  async (req, res) => {
    const { code, state } = req.query;

    // SECURITY: Validate state (CSRF protection)
    if (state !== req.session.state) {
      return res.status(400).json({
        error: 'INVALID_STATE',
        message: 'State parameter mismatch (possible CSRF attack)'
      });
    }

    // SECURITY: Re-validate redirect URI from session
    const redirect_uri = req.session.redirect_uri;
    if (!validateRedirectUri(redirect_uri)) {
      return res.status(400).json({
        error: 'INVALID_REDIRECT_URI',
        message: 'Stored redirect URI is not whitelisted'
      });
    }

    try {
      // Exchange code for tokens (with PKCE verification)
      const tokens = await oauthService.exchangeCodeForTokens(
        code as string,
        req.session.codeVerifier,
        redirect_uri
      );

      // Set secure cookies (HttpOnly, Secure, SameSite)
      res.cookie('access_token', tokens.accessToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 15 * 60 * 1000  // 15 minutes
      });

      res.cookie('refresh_token', tokens.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 30 * 24 * 60 * 60 * 1000  // 30 days
      });

      // Clear PKCE from session
      delete req.session.codeVerifier;
      delete req.session.state;
      delete req.session.redirect_uri;

      res.redirect(redirect_uri);
    } catch (error) {
      auditLog('oauth_callback_failed')(req, res, () => {});
      res.status(500).json({
        error: 'OAUTH_EXCHANGE_FAILED',
        message: 'Failed to exchange authorization code'
      });
    }
  }
);

/**
 * Refresh access token using refresh token
 */
router.post('/auth/oauth/refresh',
  refreshLimiter,
  auditLog('oauth_token_refresh'),
  async (req, res) => {
    const refreshToken = req.cookies.refresh_token;

    if (!refreshToken) {
      return res.status(401).json({
        error: 'NO_REFRESH_TOKEN',
        message: 'Refresh token not provided'
      });
    }

    try {
      // SECURITY: Check if token is blacklisted
      if (await oauthService.isTokenRevoked(refreshToken)) {
        return res.status(401).json({
          error: 'TOKEN_REVOKED',
          message: 'Refresh token has been revoked'
        });
      }

      // Generate new tokens (refresh token rotation)
      const tokens = await oauthService.refreshAccessToken(refreshToken);

      // Set new secure cookies
      res.cookie('access_token', tokens.accessToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 15 * 60 * 1000
      });

      res.cookie('refresh_token', tokens.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 30 * 24 * 60 * 60 * 1000
      });

      res.json({ success: true });
    } catch (error) {
      res.status(401).json({
        error: 'REFRESH_FAILED',
        message: 'Failed to refresh access token'
      });
    }
  }
);

/**
 * Revoke all tokens for user (logout)
 */
router.post('/auth/oauth/revoke',
  auditLog('oauth_token_revoke'),
  async (req, res) => {
    const accessToken = req.cookies.access_token;
    const refreshToken = req.cookies.refresh_token;

    // Revoke both tokens
    if (accessToken) {
      await oauthService.revokeToken(accessToken);
    }
    if (refreshToken) {
      await oauthService.revokeToken(refreshToken);
    }

    // Clear cookies
    res.clearCookie('access_token');
    res.clearCookie('refresh_token');

    res.json({ success: true });
  }
);

export default router;
```

**2. `src/auth/redirect-validator.ts`** (Redirect URI validation)

```typescript
/**
 * Redirect URI Validation
 * SECURITY: Whitelist-based, exact match, no wildcards
 */

const ALLOWED_REDIRECT_URIS: Record<string, string[]> = {
  development: [
    'http://localhost:3000/auth/callback',
    'http://localhost:8080/auth/callback'
  ],
  production: [
    'https://app.example.com/auth/callback',
    'https://example.com/auth/callback'
  ]
};

export function validateRedirectUri(uri: string): boolean {
  const env = process.env.NODE_ENV || 'development';
  const allowed = ALLOWED_REDIRECT_URIS[env];

  // SECURITY: Exact match only, no wildcards, no pattern matching
  const isAllowed = allowed.includes(uri);

  // SECURITY: Hard fail on localhost in production
  if (env === 'production' && uri.startsWith('http://localhost')) {
    throw new Error('Localhost redirect URI not allowed in production');
  }

  return isAllowed;
}
```

**3. `src/auth/secrets.ts`** (AWS Secrets Manager integration)

```typescript
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const client = new SecretsManagerClient({ region: 'us-east-1' });

interface OAuthSecrets {
  OAUTH_GOOGLE_CLIENT_ID: string;
  OAUTH_GOOGLE_CLIENT_SECRET: string;
  OAUTH_GITHUB_CLIENT_ID: string;
  OAUTH_GITHUB_CLIENT_SECRET: string;
  JWT_PRIVATE_KEY: string;
  JWT_PUBLIC_KEY: string;
  TOKEN_ENCRYPTION_KEY: string;
}

let cachedSecrets: OAuthSecrets | null = null;
let cacheExpiry: number = 0;

/**
 * Fetch secrets from AWS Secrets Manager
 * SECURITY: Cached for 15 minutes to reduce API calls
 */
export async function getSecrets(): Promise<OAuthSecrets> {
  // Return cached if still valid
  if (cachedSecrets && Date.now() < cacheExpiry) {
    return cachedSecrets;
  }

  const command = new GetSecretValueCommand({
    SecretId: 'opencode/oauth2'
  });

  const response = await client.send(command);
  const secrets = JSON.parse(response.SecretString!) as OAuthSecrets;

  // SECURITY: Validate all required secrets present
  const required = [
    'OAUTH_GOOGLE_CLIENT_ID',
    'OAUTH_GOOGLE_CLIENT_SECRET',
    'OAUTH_GITHUB_CLIENT_ID',
    'OAUTH_GITHUB_CLIENT_SECRET',
    'JWT_PRIVATE_KEY',
    'JWT_PUBLIC_KEY',
    'TOKEN_ENCRYPTION_KEY'
  ];

  for (const key of required) {
    if (!secrets[key as keyof OAuthSecrets]) {
      throw new Error(`Missing required secret: ${key}`);
    }
  }

  // Cache for 15 minutes
  cachedSecrets = secrets;
  cacheExpiry = Date.now() + (15 * 60 * 1000);

  return secrets;
}

// SECURITY: Never log secrets
process.on('uncaughtException', (err) => {
  const secretKeys = ['CLIENT_SECRET', 'PRIVATE_KEY', 'ENCRYPTION_KEY'];
  const errorMessage = err.message;
  for (const key of secretKeys) {
    if (errorMessage.includes(key)) {
      console.error('REDACTED: Error contains sensitive information');
      process.exit(1);
    }
  }
  throw err;
});
```

**@builder:**
> Implementation complete.
>
> **Files Created:** 8
> **Lines of Code:** 1,245
> **Security Measures Implemented:**
> - ✅ Redirect URI validation (whitelist, exact match)
> - ✅ PKCE flow
> - ✅ State parameter (CSRF protection)
> - ✅ Secure cookies (HttpOnly, Secure, SameSite)
> - ✅ AWS Secrets Manager integration
> - ✅ Token blacklist (revocation)
> - ✅ Rate limiting
> - ✅ Audit logging
>
> Ready for @security code review.

---

### Phase 6: Security Code Review (@ security)

**User:** @security Review OAuth2 implementation code

**@security:**
> Reading implementation files...
>
> **Reviewing:**
> - `src/auth/oauth.controller.ts`
> - `src/auth/redirect-validator.ts`
> - `src/auth/secrets.ts`
> - `src/auth/oauth.service.ts`
> - `src/auth/token.store.ts`
>
> **Security Analysis...**

**Output:** `reports/security-code-review.md`

```markdown
# Security Code Review: OAuth2 Implementation

**Status:** ✅ **APPROVED WITH MINOR RECOMMENDATIONS**

## Code Review Findings

### ✅ EXCELLENT Security Practices

1. **Redirect URI Validation** (`redirect-validator.ts`)
   - ✅ Exact match only (no wildcards)
   - ✅ Whitelist-based
   - ✅ Hard fail on localhost in production
   - ✅ No pattern matching vulnerabilities
   - **VERDICT:** SECURE

2. **PKCE Implementation** (`oauth.controller.ts:25-29`)
   - ✅ Code verifier properly generated (cryptographically random)
   - ✅ Challenge calculated correctly (SHA-256)
   - ✅ Stored in session (not exposed to client)
   - **VERDICT:** SECURE

3. **State Parameter** (`oauth.controller.ts:32`)
   - ✅ Cryptographically random generation
   - ✅ Verified on callback
   - ✅ Stored server-side only
   - **VERDICT:** SECURE (CSRF protected)

4. **Secure Cookies** (`oauth.controller.ts:92-102`)
   - ✅ HttpOnly (prevents XSS)
   - ✅ Secure flag (HTTPS only)
   - ✅ SameSite=strict (CSRF protection)
   - ✅ Appropriate expiry times
   - **VERDICT:** SECURE

5. **Secret Management** (`secrets.ts`)
   - ✅ AWS Secrets Manager (no hardcoded secrets)
   - ✅ Caching with expiry (15 min)
   - ✅ Validation of all required secrets
   - ✅ No logging of secrets
   - **VERDICT:** SECURE

6. **Token Revocation** (`oauth.controller.ts:165-183`)
   - ✅ Blacklist implementation
   - ✅ TTL-based expiry
   - ✅ Revokes both access and refresh tokens
   - **VERDICT:** SECURE

### ⚠️ MINOR Recommendations (Not Blocking)

1. **Rate Limit Headers**
   - Add `X-RateLimit-Remaining` headers
   - Helps clients implement backoff
   - Severity: LOW

2. **Token Binding**
   - Consider DPoP (OAuth 2.0 Demonstrating Proof-of-Possession)
   - Binds tokens to client TLS certificate
   - Severity: LOW (nice-to-have)

3. **Audit Log Enrichment**
   - Include user agent and IP in audit logs
   - Helps detect suspicious patterns
   - Severity: LOW

### 🔍 Manual Testing Required

Before production deployment, manually verify:

1. **Redirect URI Bypass Attempts**
   - Try subdomain: `https://evil.example.com/auth/callback`
   - Try path traversal: `https://example.com/auth/callback/../admin`
   - Try protocol upgrade: `http://example.com` → `https://example.com`

2. **Token Replay**
   - Verify revoked token immediately fails
   - Verify old refresh token fails after rotation

3. **CSRF Protection**
   - Verify state mismatch fails
   - Verify missing state fails

## Security Score: 9.5/10

**Exceptional implementation** following all OWASP OAuth 2.0 best practices.

## Approval

✅ **APPROVED FOR TESTING**

Minor recommendations can be addressed post-deployment if desired.

Proceed to @tester for comprehensive testing.
```

**@security:**
> ✅ **CODE APPROVED**
>
> Security Score: 9.5/10
> Excellent implementation of OAuth2 with all critical security measures in place.

---

### Phase 7: Testing (@ tester)

**User:** @tester Test OAuth2 implementation comprehensively

**@tester:**
> Running test suite...
>
> **Test Categories:**
> - Unit tests (OAuth service, validators)
> - Integration tests (full OAuth flow)
> - Security tests (bypass attempts)
>
> **Executing...**

**Output:** `reports/test-results.md`

```markdown
# OAuth2 Implementation Test Results

## Test Summary

**Total Tests:** 47
**Passed:** 47 ✅
**Failed:** 0
**Coverage:** 94.2%

## Test Breakdown

### Unit Tests (18/18 passed)

**Redirect URI Validation:**
- ✅ Accepts whitelisted URIs
- ✅ Rejects non-whitelisted URIs
- ✅ Rejects localhost in production
- ✅ Rejects wildcard attempts
- ✅ Rejects subdomain variations

**PKCE Generation:**
- ✅ Generates cryptographically random verifier
- ✅ Calculates SHA-256 challenge correctly
- ✅ Verifier is 128 characters (base64url)

**Token Generation:**
- ✅ JWT contains correct claims
- ✅ JWT signed with RSA key
- ✅ JWT expiry set correctly (15 min)
- ✅ Refresh token encrypted

**Token Revocation:**
- ✅ Revoked token added to blacklist
- ✅ TTL set to token expiry
- ✅ Blacklist check works

### Integration Tests (20/20 passed)

**Full OAuth Flow:**
- ✅ /authorize returns provider URL
- ✅ /callback exchanges code for tokens
- ✅ Tokens stored in secure cookies
- ✅ /refresh rotates tokens correctly
- ✅ /revoke clears all tokens

**Error Handling:**
- ✅ Invalid redirect_uri returns 400
- ✅ State mismatch returns 400
- ✅ Missing code returns 400
- ✅ Revoked token returns 401
- ✅ Rate limit triggers 429

**Security:**
- ✅ HttpOnly cookies set
- ✅ Secure flag set in production
- ✅ SameSite=strict set
- ✅ PKCE verified on callback

### Security Tests (9/9 passed)

**Attack Scenarios:**
- ✅ Redirect URI bypass (subdomain) - BLOCKED
- ✅ Redirect URI bypass (path traversal) - BLOCKED
- ✅ CSRF attack (state mismatch) - BLOCKED
- ✅ Token replay after revocation - BLOCKED
- ✅ Rate limit enumeration - BLOCKED
- ✅ Expired token usage - BLOCKED
- ✅ Missing PKCE verifier - BLOCKED
- ✅ Wrong PKCE verifier - BLOCKED
- ✅ Authorization code reuse - BLOCKED

## Coverage Report

```
File                          | Stmts | Branch | Funcs | Lines | Uncovered
------------------------------|-------|--------|-------|-------|----------
auth/oauth.controller.ts      |  98.2 |   95.5 |  100  |  98.2 | 156-158
auth/oauth.service.ts         |  96.4 |   92.3 |  100  |  96.4 | 89-91,234
auth/redirect-validator.ts    | 100   |  100   |  100  | 100   |
auth/secrets.ts               |  87.5 |   80.0 |  100  |  87.5 | 45-47,78-80
auth/token.store.ts           |  95.8 |   90.9 |  100  |  95.8 | 123-125
------------------------------|-------|--------|-------|-------|----------
TOTAL                         |  94.2 |   91.4 |  100  |  94.2 |
```

## Performance

**Response Times:**
- /authorize: 45ms (median)
- /callback: 123ms (median)
- /refresh: 78ms (median)
- /revoke: 34ms (median)

All within acceptable limits (<200ms).

## Recommendations

1. **Increase coverage to 95%+** - Add tests for error scenarios in secrets.ts
2. **Add load testing** - Test rate limiting under high load
3. **Add monitoring** - Track OAuth success/failure rates

## Verdict

✅ **ALL TESTS PASSED**

Implementation is production-ready from a testing perspective.
```

**@tester:**
> ✅ **ALL TESTS PASSED (47/47)**
>
> Coverage: 94.2%
> Security tests: 100% passed
> Ready for final review.

---

### Phase 8: Final Review (@ reviewer)

**User:** @reviewer Final review before deployment

**@reviewer:**
> **Comprehensive Review:**
>
> - Reading specification ✅
> - Reading security reviews ✅
> - Reading implementation ✅
> - Reading test results ✅
>
> **Checking compliance with spec...**

**Output:** `reports/final-review.md`

```markdown
# Final Review: OAuth2 Implementation

**Reviewer:** @reviewer
**Date:** 2026-02-16
**Status:** ✅ **APPROVED FOR PRODUCTION**

## Specification Compliance

| Requirement | Status | Evidence |
|-------------|--------|----------|
| OAuth2 authorization code flow | ✅ | oauth.controller.ts:25-65 |
| PKCE support | ✅ | oauth.service.ts:45-78 |
| Multi-provider (Google, GitHub) | ✅ | oauth.service.ts:123-234 |
| JWT access tokens (15 min) | ✅ | token.service.ts:34-56 |
| Refresh token rotation | ✅ | oauth.controller.ts:145-163 |
| Secure token storage | ✅ | token.store.ts:12-45 |
| Redirect URI validation | ✅ | redirect-validator.ts:15-30 |
| State parameter (CSRF) | ✅ | oauth.controller.ts:32,72 |
| Secret management (AWS) | ✅ | secrets.ts:12-67 |
| Token revocation | ✅ | oauth.controller.ts:165-183 |
| Rate limiting | ✅ | oauth.controller.ts:10-13 |
| Audit logging | ✅ | oauth.controller.ts:16,46,115 |

**Compliance:** 12/12 (100%)

## Code Quality

- **Readability:** Excellent (clear function names, good comments)
- **Structure:** Well-organized (separation of concerns)
- **Error Handling:** Comprehensive (all errors caught and logged)
- **Documentation:** Good (inline comments, TSDoc)

## Security Review

- **@security approval:** ✅ (9.5/10 score)
- **Critical issues:** 0
- **High issues:** 0
- **Medium issues:** 0
- **Minor recommendations:** 3 (not blocking)

## Testing

- **Test coverage:** 94.2% (exceeds 90% requirement)
- **All tests passing:** ✅ (47/47)
- **Security tests:** ✅ (9/9 attack scenarios blocked)

## Performance

- **Response times:** All <200ms ✅
- **Rate limiting:** Configured and tested ✅
- **Resource usage:** Acceptable ✅

## Documentation

- **Specification:** Complete ✅
- **Code comments:** Comprehensive ✅
- **API documentation:** Generated from OpenAPI spec ✅
- **Security docs:** Detailed ✅

## Pre-Deployment Checklist

- [x] All tests passing
- [x] Security review approved
- [x] Code follows project standards
- [x] Documentation complete
- [x] Secrets configured in AWS
- [x] Rate limiting tested
- [x] Error handling comprehensive
- [x] Logging implemented
- [x] Performance acceptable

## Approval

✅ **APPROVED FOR PRODUCTION DEPLOYMENT**

This implementation demonstrates:
- Exceptional security practices
- Comprehensive testing
- Full specification compliance
- Production-ready code quality

**Recommended Next Steps:**
1. Deploy to staging environment
2. Perform manual UAT
3. Monitor for 24 hours
4. Deploy to production with canary rollout

**Congratulations to the team!**
```

**@reviewer:**
> ✅ **FINAL REVIEW PASSED**
>
> Implementation ready for production.
> Excellent work following security best practices.

---

## Artifacts Generated

### Specifications
1. **specs/oauth2-implementation.md** (Initial spec, 245 lines)
2. **specs/oauth2-implementation.md** (Updated with security fixes, 312 lines)

### Security Reviews
1. **reports/security-spec-review.md** (Initial review, 2 CRITICAL issues)
2. **reports/security-spec-re-review.md** (Re-review, APPROVED)
3. **reports/security-code-review.md** (Code review, 9.5/10 score)

### Implementation Code
1. **src/auth/oauth.controller.ts** (OAuth endpoints, 185 lines)
2. **src/auth/oauth.service.ts** (OAuth logic, 234 lines)
3. **src/auth/redirect-validator.ts** (Validation, 30 lines)
4. **src/auth/secrets.ts** (AWS integration, 78 lines)
5. **src/auth/token.store.ts** (Token storage, 145 lines)
6. **src/middleware/rate-limit.ts** (Rate limiting, 45 lines)
7. **src/middleware/audit.ts** (Audit logging, 56 lines)
8. **tests/auth/oauth.test.ts** (47 tests, 312 lines)

### Reports
1. **reports/test-results.md** (47/47 tests passed, 94.2% coverage)
2. **reports/final-review.md** (Approved for production)

**Total Lines of Code:** ~1,680 lines
**Total Documentation:** ~1,200 lines

---

## Lessons Learned

### What Went Well ✅

1. **Security-First Approach**
   - @security reviewed spec BEFORE implementation
   - Caught CRITICAL issues early (redirect URI, secrets)
   - Prevented costly refactoring later

2. **Clear Specification**
   - Detailed spec prevented ambiguity
   - Security requirements explicit
   - Implementation straightforward

3. **Comprehensive Testing**
   - 47 tests including security scenarios
   - 94.2% coverage
   - Attack scenarios verified

4. **Iterative Review**
   - Spec → Security Review → Update → Re-review → Implement
   - Ensured security from design phase

### What Could Be Improved 🔧

1. **Initial Spec Completeness**
   - Redirect URI validation missing initially
   - Secret management vague
   - Could have been caught with security checklist

2. **Testing Earlier**
   - Security tests written after implementation
   - Could write security test cases from spec

3. **Performance Testing**
   - No load testing performed
   - Should verify rate limiting under real load

### Key Takeaways 💡

1. **Always Involve @security Early**
   - Security review of spec prevents issues
   - Cheaper to fix design than code

2. **Explicit > Implicit**
   - Spec should be detailed and specific
   - "Use secret manager" → "Use AWS Secrets Manager with 90-day rotation"

3. **Test Security Scenarios**
   - Don't just test happy path
   - Test every attack scenario (redirect bypass, CSRF, etc.)

4. **Documentation Matters**
   - Inline comments explain WHY, not just WHAT
   - Future developers will thank you

5. **Checklists Work**
   - OWASP OAuth 2.0 checklist caught everything
   - Security checklists prevent oversights

---

## Success Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Security Review Score | >8/10 | 9.5/10 | ✅ |
| Test Coverage | >90% | 94.2% | ✅ |
| Response Time | <200ms | <150ms | ✅ |
| Critical Issues | 0 | 0 | ✅ |
| Spec Compliance | 100% | 100% | ✅ |
| Tests Passing | 100% | 100% | ✅ |

**All success criteria met!**

---

**This example demonstrates:**
- Multi-agent collaboration (planner → security → builder → tester → reviewer)
- Iterative security reviews (spec review → code review)
- Comprehensive testing (unit + integration + security)
- Real-world security considerations (OWASP best practices)
- Professional workflow (spec → implement → test → review → deploy)

**Estimated Time:** ~4 hours with OpenCode agents vs ~3-5 days manual implementation

---

*Example last updated: 2026-02-16*
