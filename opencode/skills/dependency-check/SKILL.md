---
name: dependency-check
description: Scans dependencies for known security vulnerabilities and license issues
version: 1.0.0
category: security
tools:
  - npm audit
  - pip-audit
  - snyk
  - dependabot
permissions:
  - read
  - bash
---

# Dependency Check Skill

Automated vulnerability scanning for project dependencies across multiple package managers.

## Purpose

Identify and report:
- Known security vulnerabilities (CVEs)
- Outdated dependencies
- License compliance issues
- Dependency conflicts
- Supply chain risks

## Supported Package Managers

### JavaScript/TypeScript
- **npm audit**: Built-in npm security scanner
- **yarn audit**: Yarn security scanner
- **Snyk**: Commercial vulnerability scanner (free tier available)

### Python
- **pip-audit**: Python dependency vulnerability scanner
- **safety**: Python dependency checker

### Other Languages
- **Go**: `go list -m all` + vulnerability databases
- **Ruby**: `bundle audit`
- **Java/Maven**: `mvn dependency:tree` + OWASP Dependency-Check

## Usage

### Invoke from Agent

```
@security Use dependency-check skill to scan for vulnerabilities
```

### Command Line

```bash
# JavaScript/Node.js
npm audit
npm audit --json > audit-report.json

# Python
pip-audit
pip-audit --format json > audit-report.json

# Snyk (multi-language)
snyk test
snyk test --json > snyk-report.json
```

## Vulnerability Severity Levels

| Severity | Description | Action Required |
|----------|-------------|-----------------|
| **CRITICAL** | Actively exploited, CVSS 9.0+ | Fix immediately (hours) |
| **HIGH** | Exploitable, CVSS 7.0-8.9 | Fix within 7 days |
| **MODERATE** | Limited impact, CVSS 4.0-6.9 | Fix within 30 days |
| **LOW** | Minimal impact, CVSS 0.1-3.9 | Fix when convenient |

## Configuration

### npm audit

**package.json** (audit levels):
```json
{
  "scripts": {
    "audit": "npm audit",
    "audit:fix": "npm audit fix",
    "audit:production": "npm audit --production",
    "audit:critical": "npm audit --audit-level=critical"
  }
}
```

**Audit levels:**
- `low`: Report all vulnerabilities
- `moderate`: Report moderate and above
- `high`: Report high and critical only
- `critical`: Report critical only

### pip-audit

**pyproject.toml**:
```toml
[tool.pip-audit]
require-hashes = true
ignore-vulns = [
  # Temporary ignores with ticket references
  "GHSA-xxxx-yyyy-zzzz"  # See issue #123
]
```

### Snyk

**.snyk** (policy file):
```yaml
# Snyk (https://snyk.io) policy file
version: v1.22.1

ignore:
  # Temporary ignores with expiration
  'SNYK-JS-AXIOS-1234567':
    - '* > axios':
        reason: 'No fix available, mitigated by WAF'
        expires: '2024-03-01T00:00:00.000Z'

patch: {}
```

## Implementation

### Scan npm Dependencies

```typescript
async function scanNpmDependencies() {
  const result = await runCommand('npm audit --json');
  const auditData = JSON.parse(result.stdout);

  const vulnerabilities = {
    critical: [],
    high: [],
    moderate: [],
    low: []
  };

  for (const [name, details] of Object.entries(auditData.vulnerabilities)) {
    const vuln = {
      package: name,
      severity: details.severity,
      title: details.via[0].title,
      cve: details.via[0].cve || 'N/A',
      fixAvailable: details.fixAvailable
    };

    vulnerabilities[details.severity].push(vuln);
  }

  return {
    totalVulnerabilities: auditData.metadata.vulnerabilities.total,
    vulnerabilities,
    dependencies: auditData.metadata.dependencies,
    auditReportVersion: auditData.auditReportVersion
  };
}
```

### Scan Python Dependencies

```python
async def scan_python_dependencies():
    result = await run_command('pip-audit --format json')
    audit_data = json.loads(result.stdout)

    vulnerabilities = {
        'critical': [],
        'high': [],
        'moderate': [],
        'low': []
    }

    for vuln in audit_data['dependencies']:
        severity = map_cvss_to_severity(vuln.get('cvss_score', 0))

        vuln_info = {
            'package': vuln['name'],
            'version': vuln['version'],
            'severity': severity,
            'cve': vuln['vulns'][0]['id'] if vuln.get('vulns') else 'N/A',
            'fix_versions': vuln.get('fix_versions', [])
        }

        vulnerabilities[severity].append(vuln_info)

    return {
        'total_vulnerabilities': len(audit_data['dependencies']),
        'vulnerabilities': vulnerabilities,
        'scan_date': audit_data.get('scan_date')
    }
```

## Output Format

### Success Output (No Vulnerabilities)

```
✅ Dependency Check: PASSED

Scanned: 342 dependencies
Found: 0 vulnerabilities

All dependencies are secure! 🎉

Last updated: 2024-02-14 10:30:45
```

### Failure Output (Vulnerabilities Found)

```
❌ Dependency Check: FAILED

Scanned: 342 dependencies
Found: 15 vulnerabilities

Breakdown by Severity:
  🚨 CRITICAL: 2
  ⚠️  HIGH: 5
  ⚡ MODERATE: 6
  ℹ️  LOW: 2

Critical Vulnerabilities:
  1. axios@0.21.1
     CVE-2021-3749 - Server-Side Request Forgery
     Fix: Update to axios@0.21.2 or later

  2. express@4.17.1
     CVE-2022-24999 - Open Redirect Vulnerability
     Fix: Update to express@4.18.2 or later

High Vulnerabilities:
  3. lodash@4.17.20
     CVE-2021-23337 - Command Injection
     Fix: Update to lodash@4.17.21 or later

  4. jsonwebtoken@8.5.1
     CVE-2022-23529 - Improper Signature Verification
     Fix: Update to jsonwebtoken@9.0.0 or later

  [... 3 more high severity issues]

Moderate Vulnerabilities: (6 total)
Low Vulnerabilities: (2 total)

Recommended Actions:
  1. Run: npm audit fix
  2. Manually update critical/high severity packages
  3. Test thoroughly after updates
  4. Re-run dependency-check to verify

Next Steps:
  @builder Fix critical vulnerabilities immediately
  @tester Run full test suite after updates
  @security Review changes before deployment
```

## Auto-Fix Support

### npm audit fix

```bash
# Fix all auto-fixable issues
npm audit fix

# Fix only production dependencies
npm audit fix --production

# Force fix (may introduce breaking changes)
npm audit fix --force
```

### Manual Updates

```bash
# Update specific package
npm install axios@latest

# Update all packages (use with caution)
npm update
```

### Python Auto-Fix

```bash
# Upgrade vulnerable packages
pip install --upgrade package-name

# Upgrade all packages in requirements.txt
pip install --upgrade -r requirements.txt
```

## Integration with Agents

### Security Agent

```markdown
Before approving security review:
1. Run dependency-check skill
2. If critical/high vulnerabilities found, block approval
3. Require fixes before proceeding
4. Re-run after fixes applied
```

### Builder Agent

```markdown
Before implementing new feature:
1. Check if new dependencies required
2. Run dependency-check on new dependencies
3. If vulnerabilities found, choose alternative package
4. Document decision in spec
```

### CI/CD Integration

**GitHub Actions:**
```yaml
name: Dependency Check

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3

      - name: Install dependencies
        run: npm ci

      - name: Run npm audit
        run: npm audit --audit-level=moderate

      - name: Fail on high/critical
        run: npm audit --audit-level=high
```

## Snyk Integration

### Setup

```bash
# Install Snyk CLI
npm install -g snyk

# Authenticate
snyk auth

# Test project
snyk test

# Monitor project (ongoing scans)
snyk monitor
```

### Advanced Features

```bash
# Test and output JSON
snyk test --json

# Test specific severity
snyk test --severity-threshold=high

# Test Docker images
snyk container test node:18-alpine

# Test infrastructure as code
snyk iac test terraform/
```

### Snyk in CI/CD

```yaml
- name: Run Snyk
  run: |
    npm install -g snyk
    snyk test --severity-threshold=high
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

## License Checking

### Check npm Licenses

```bash
# Install license-checker
npm install -g license-checker

# Check licenses
license-checker --summary

# Check for specific licenses
license-checker --onlyAllow 'MIT;Apache-2.0;BSD-3-Clause'

# Fail on GPL licenses
license-checker --failOn 'GPL'
```

### Output Example

```
├─ MIT: 245 packages
├─ Apache-2.0: 43 packages
├─ BSD-3-Clause: 18 packages
├─ ISC: 12 packages
└─ GPL-3.0: 1 package ⚠️

WARNING: GPL-3.0 license found in package 'some-package'
This may have legal implications for proprietary software.
```

## Supply Chain Security

### Verify Package Integrity

```bash
# npm: Verify package signatures
npm install --ignore-scripts

# Check package integrity
npm audit signatures

# Python: Verify hashes
pip install --require-hashes -r requirements.txt
```

### Detect Malicious Packages

**Red Flags:**
- Recently created packages with high download counts
- Typosquatting (lodash vs. lodah)
- Suspicious maintainer changes
- Obfuscated code
- Network requests to unknown domains

**Tools:**
- **Socket.dev**: Detects malicious packages
- **npm audit signatures**: Verifies package authenticity

## Remediation Workflow

### 1. Identify Vulnerabilities

```bash
npm audit
```

### 2. Prioritize by Severity

```
Priority 1: CRITICAL - Fix immediately
Priority 2: HIGH - Fix within 7 days
Priority 3: MODERATE - Fix within 30 days
Priority 4: LOW - Fix when convenient
```

### 3. Attempt Auto-Fix

```bash
npm audit fix
```

### 4. Manual Fix if Needed

```bash
npm install package-name@latest
```

### 5. Test Changes

```bash
npm test
npm run build
```

### 6. Verify Fix

```bash
npm audit
# Should show reduced vulnerability count
```

### 7. Deploy

```bash
git add package.json package-lock.json
git commit -m "fix(deps): resolve critical security vulnerabilities"
git push
```

## Continuous Monitoring

### Dependabot (GitHub)

**.github/dependabot.yml**:
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"
```

### Snyk Monitor

```bash
# Monitor project for vulnerabilities
snyk monitor

# Receive alerts via email/Slack
```

### Renovate

**renovate.json**:
```json
{
  "extends": ["config:base"],
  "vulnerabilityAlerts": {
    "enabled": true
  },
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "enabled": false
    }
  ]
}
```

## Reporting

### Generate Report

```typescript
async function generateDependencyReport() {
  const npmAudit = await scanNpmDependencies();
  const report = {
    date: new Date().toISOString(),
    summary: {
      total_dependencies: npmAudit.dependencies,
      total_vulnerabilities: npmAudit.totalVulnerabilities,
      critical: npmAudit.vulnerabilities.critical.length,
      high: npmAudit.vulnerabilities.high.length,
      moderate: npmAudit.vulnerabilities.moderate.length,
      low: npmAudit.vulnerabilities.low.length
    },
    details: npmAudit.vulnerabilities,
    recommendations: generateRecommendations(npmAudit)
  };

  await writeFile('dependency-report.json', JSON.stringify(report, null, 2));
  await generateMarkdownReport(report);
}
```

### Report Template

```markdown
# Dependency Security Report

**Date:** 2024-02-14
**Project:** my-app
**Total Dependencies:** 342

## Summary

| Severity | Count |
|----------|-------|
| Critical | 2     |
| High     | 5     |
| Moderate | 6     |
| Low      | 2     |

## Critical Vulnerabilities

### 1. axios@0.21.1 - Server-Side Request Forgery (CVE-2021-3749)

**CVSS Score:** 9.8 (Critical)
**Introduced:** 2021-09-12
**Fix Available:** Yes (axios@0.21.2+)

**Description:**
Axios versions prior to 0.21.2 are vulnerable to Server-Side Request Forgery...

**Remediation:**
```bash
npm install axios@latest
```

[... more details ...]
```

## Troubleshooting

### npm audit: "No Fix Available"

**Problem:** Vulnerability found but no fix exists

**Solutions:**
1. Check if transitive dependency (indirect)
2. Update parent package that depends on it
3. Use `npm ls package-name` to see dependency tree
4. Consider alternative package
5. Add to `.snyk` ignore with ticket reference

### pip-audit: "Package not found"

**Problem:** Package not in vulnerability database

**Solution:** This is expected for internal/private packages
```bash
pip-audit --ignore-package internal-package
```

### False Positives

**Problem:** Vulnerability doesn't apply to usage

**Solution:** Document and ignore with justification
```yaml
# .snyk
ignore:
  'SNYK-JS-AXIOS-1234567':
    - 'axios':
        reason: 'We only use axios for outbound requests, not user input'
        expires: '2024-12-31T00:00:00.000Z'
```

## Best Practices

### DO
✅ Run dependency check weekly
✅ Fix critical/high vulnerabilities immediately
✅ Use automated tools (Dependabot, Renovate)
✅ Keep dependencies up to date
✅ Review new dependencies before adding
✅ Document ignored vulnerabilities with reasons

### DON'T
❌ Ignore vulnerability warnings
❌ Use `--force` without understanding impact
❌ Skip dependency checks in CI/CD
❌ Use outdated packages
❌ Blindly trust package popularity

## Related Skills

- **code-quality**: Linting and formatting
- **run-tests**: Test execution after dependency updates

## Version History

- **1.0.0** (2024-02-14): Initial implementation
  - npm audit support
  - pip-audit support
  - Snyk integration
  - License checking
  - Reporting capabilities

---

*For more information, see [skills README](../README.md) or [main documentation](../../README.md)*
