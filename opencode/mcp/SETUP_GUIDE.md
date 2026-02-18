# MCP Server Setup Guide

Complete step-by-step guide for configuring all MCP servers for your OpenCode agent architecture.

## ⚡ Quick Start (Recommended)

**Use the automated setup script for secure credential management:**

```bash
bash ~/.config/opencode/scripts/setup-mcp-credentials.sh
```

This script will:
- ✅ Guide you through token creation
- ✅ Validate token format and connectivity
- ✅ Store credentials in environment variables (NOT in opencode.json)
- ✅ Set secure file permissions (600)
- ✅ Add to your shell RC file automatically

**Then validate:**

```bash
bash ~/.config/opencode/scripts/validate-mcp.sh
```

---

## 🔐 CRITICAL SECURITY WARNING

**⚠️ DO NOT store tokens directly in opencode.json ⚠️**

**Why?**
- ❌ opencode.json may be committed to git (exposing secrets)
- ❌ Plaintext tokens are vulnerable if filesystem is compromised
- ❌ Difficult to rotate tokens across multiple machines
- ❌ No access control (any process can read the file)

**✅ RECOMMENDED APPROACH:** Use environment variables via `setup-mcp-credentials.sh`

**Consequences of Token Exposure:**
- 🚨 Attacker gains full access to your GitHub repositories
- 🚨 Attacker can read/modify/delete code, issues, PRs
- 🚨 Attacker can access private repositories and organization data
- 🚨 Attacker can access your Linear workspace and sensitive project data

**If you suspect a token is compromised:**
1. **Immediately revoke** at GitHub/Linear settings
2. Generate new token with minimal scopes
3. Audit recent activity for unauthorized actions
4. Report incident to your security team

---

## Quick Validation

Before starting, validate your current setup:

```bash
bash ~/.config/opencode/scripts/validate-mcp.sh
```

This will show which MCP servers are configured and which need authentication.

---

## GitHub MCP Setup

### Step 1: Create Personal Access Token

1. Visit: https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Give it a descriptive name: `OpenCode MCP Server`
4. Set expiration: **90 days** (or longer)
5. Select scopes:
   - ✅ **repo** - Full control of private repositories
   - ✅ **read:org** - Read org and team membership
   - ✅ **read:user** - Read user profile data
6. Click **"Generate token"**
7. **Copy the token immediately** (you won't see it again!)

### Step 2: Add Token to Configuration

1. Open: `~/.config/opencode/opencode.json`
2. Find the `github` section under `mcp`:
   ```json
   "github": {
     "type": "local",
     "enabled": true,
     "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
     "environment": {
       "GITHUB_PERSONAL_ACCESS_TOKEN": ""  ← ADD YOUR TOKEN HERE
     }
   }
   ```
3. Replace the empty string with your token:
   ```json
   "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
   ```
4. Save the file

### Step 3: Verify

```bash
# Run validation
bash ~/.config/opencode/scripts/validate-mcp.sh

# Should show: ✅ GitHub token configured
```

### What GitHub MCP Enables

With GitHub MCP configured, agents can:
- 📂 Browse repositories
- 📝 Read and create issues
- 🔀 Create and comment on pull requests
- ✅ Check CI/CD status
- 🏷️ Manage labels and milestones
- 📊 Access repository metadata

**Example Usage:**
```
@planner Research existing issues for similar features
@builder Create PR for this implementation
@tester Check CI status for this branch
```

---

## Linear MCP Setup

### Step 1: Create API Key

1. Visit: https://linear.app/settings/api
2. Click **"Create new API key"**
3. Give it a name: `OpenCode MCP Server`
4. Click **"Create"**
5. **Copy the API key** (starts with `lin_api_`)

### Step 2: Add API Key to Configuration

1. Open: `~/.config/opencode/opencode.json`
2. Find the `linear` section under `mcp`:
   ```json
   "linear": {
     "type": "local",
     "enabled": true,
     "command": ["npx", "-y", "@linear/mcp"],
     "environment": {
       "LINEAR_API_KEY": ""  ← ADD YOUR API KEY HERE
     }
   }
   ```
3. Replace the empty string with your API key:
   ```json
   "LINEAR_API_KEY": "lin_api_your_key_here"
   ```
4. Save the file

### Step 3: Verify

```bash
# Run validation
bash ~/.config/opencode/scripts/validate-mcp.sh

# Should show: ✅ Linear API key configured
```

### What Linear MCP Enables

With Linear MCP configured, agents can:
- 📋 List and search issues
- ✏️ Create new issues
- 🔄 Update issue status
- 🏷️ Manage labels and priorities
- 🔗 Link issues to commits/PRs
- 📈 Track project progress

**Example Usage:**
```
@planner Pull requirements from Linear issue #123
@builder Link this commit to Linear issue
@reviewer Update Linear issue status to "In Review"
```

---

## Context7 MCP Setup

### No Configuration Needed! ✅

Context7 MCP works out of the box with no authentication required.

### What Context7 MCP Enables

Agents can access up-to-date documentation for:
- 🔍 Search across 1000s of libraries
- 📚 Get working code examples
- 📖 Access API references
- 💡 Find best practices
- 🚀 Get migration guides
- 🔧 Troubleshooting help

**Example Usage:**
```
@planner How should we implement authentication with NextAuth.js?
@builder Show me React hooks examples for data fetching
@debug Find troubleshooting guide for this error
```

---

## Security Best Practices

### 🔒 Protecting Your Tokens

**DO:**
- ✅ Keep tokens in `opencode.json` (not committed to git)
- ✅ Use tokens with minimal required scopes
- ✅ Rotate tokens every 90 days
- ✅ Revoke tokens immediately if compromised
- ✅ Use different tokens for dev/staging/prod

**DON'T:**
- ❌ Commit tokens to version control
- ❌ Share tokens in Slack/email
- ❌ Give tokens excessive permissions
- ❌ Use the same token across multiple tools
- ❌ Store tokens in plaintext files

### Environment Variables (STRONGLY RECOMMENDED)

**🔒 This is the RECOMMENDED approach for production use.**

#### Automated Setup (Easiest)

```bash
bash ~/.config/opencode/scripts/setup-mcp-credentials.sh
```

This script handles everything automatically:
- Creates `~/.opencode_mcp_env` with secure permissions (600)
- Validates token format and connectivity
- Optionally adds source command to ~/.bashrc
- Never stores tokens in opencode.json

#### Manual Setup

If you prefer manual configuration:

**1. Create credentials file:**
```bash
# Create with secure permissions
touch ~/.opencode_mcp_env
chmod 600 ~/.opencode_mcp_env

# Add credentials
cat >> ~/.opencode_mcp_env <<EOF
export GITHUB_PAT="ghp_your_token_here"
export LINEAR_API_KEY="lin_api_your_key_here"
EOF
```

**2. Update opencode.json to reference env vars:**
```json
"github": {
  "environment": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PAT}"
  }
},
"linear": {
  "environment": {
    "LINEAR_API_KEY": "${LINEAR_API_KEY}"
  }
}
```

**3. Load credentials:**
```bash
# Add to ~/.bashrc or ~/.zshrc
source ~/.opencode_mcp_env

# Reload current shell
source ~/.bashrc
```

**4. Verify:**
```bash
echo $GITHUB_PAT  # Should show your token
bash ~/.config/opencode/scripts/validate-mcp.sh
```

#### Security Benefits

✅ **Credentials never in opencode.json** - Safe to commit config
✅ **File permissions 600** - Only you can read credentials
✅ **Easy rotation** - Update one file, affects all tools
✅ **Separation of concerns** - Config separate from secrets
✅ **Audit trail** - Know when credentials file was modified

---

## Troubleshooting

### GitHub MCP Not Working

**Problem**: "Authentication failed" or "401 Unauthorized"

**Solutions**:
1. Verify token is correct (starts with `ghp_`)
2. Check token hasn't expired
3. Ensure token has required scopes:
   ```
   repo, read:org, read:user
   ```
4. Test token manually:
   ```bash
   curl -H "Authorization: token ghp_your_token" \
        https://api.github.com/user
   ```

**Problem**: "Cannot find package @modelcontextprotocol/server-github"

**Solutions**:
1. Check internet connection
2. Try manually: `npx -y @modelcontextprotocol/server-github`
3. Clear npm cache: `npm cache clean --force`

### Linear MCP Not Working

**Problem**: "Invalid API key"

**Solutions**:
1. Verify API key is correct (starts with `lin_api_`)
2. Regenerate API key in Linear settings
3. Ensure no extra spaces in opencode.json
4. Test API key manually:
   ```bash
   curl -H "Authorization: lin_api_your_key" \
        https://api.linear.app/graphql \
        -d '{"query":"{ viewer { name } }"}'
   ```

### Context7 MCP Not Working

**Problem**: "Server failed to start"

**Solutions**:
1. Check Node.js is installed: `node --version`
2. Check internet connection (npx downloads packages)
3. Try manually: `npx -y @upstash/context7-mcp`
4. Clear npm cache: `npm cache clean --force`

### General MCP Issues

**Problem**: MCP server not responding

**Solutions**:
1. Restart OpenCode
2. Check logs for error messages
3. Verify Node.js version >= 16
4. Test npx availability: `npx --version`

---

## Validation Checklist

After setup, verify everything works:

- [ ] Run `bash ~/.config/opencode/scripts/validate-mcp.sh`
- [ ] All 3 MCP servers show as configured
- [ ] GitHub token shows ✅
- [ ] Linear API key shows ✅
- [ ] Context7 shows ✅
- [ ] No error messages in validation output

---

## Next Steps

Once MCP servers are configured:

1. **Test GitHub integration:**
   ```
   opencode "List my recent GitHub repositories"
   ```

2. **Test Linear integration:**
   ```
   opencode "Show my Linear issues"
   ```

3. **Test Context7 integration:**
   ```
   opencode "How do I use React hooks?"
   ```

4. **Use in workflows:**
   - Planner can research existing issues
   - Builder can create PRs automatically
   - Agents can access up-to-date documentation

---

## Support

- Validation script: `~/.config/opencode/scripts/validate-mcp.sh`
- Full MCP docs: `~/.config/opencode/mcp/README.md`
- OpenCode docs: https://opencode.ai/docs
- GitHub: https://github.com/opencode-ai/opencode

**Remember**: Never commit your tokens to version control!
