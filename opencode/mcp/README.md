# MCP Server Configuration Guide

This guide helps you configure Model Context Protocol (MCP) servers for your OpenCode agent system.

## What are MCP Servers?

MCP servers provide agents with access to external tools and services like:
- **GitHub**: Repository operations, issues, PRs
- **Linear**: Issue tracking, project management
- **Context7**: Up-to-date documentation access

## Configured Servers

### 1. GitHub MCP

**Purpose**: Access GitHub repositories, issues, pull requests, and workflows.

**Setup**:

1. Create a Personal Access Token:
   - Visit: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scopes:
     - `repo` (Full control of private repositories)
     - `read:org` (Read org and team membership)
     - `read:user` (Read user profile data)
   - Generate and copy the token

2. Add token to `opencode.json`:
   ```json
   "mcp": {
     "github": {
       "type": "local",
       "enabled": true,
       "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
       "environment": {
         "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
       }
     }
   }
   ```

**Capabilities**:
- Search repositories
- Read issues and PRs
- Create/update issues
- Comment on PRs
- Check CI status
- List branches and commits

**Usage in Agents**:
- Planner: Research existing issues
- Builder: Create PRs
- Reviewer: Comment on PRs
- Tester: Check CI results

---

### 2. Linear MCP

**Purpose**: Access Linear for issue tracking and project management.

**Setup**:

1. Get API Key:
   - Visit: https://linear.app/settings/api
   - Click "Create new API key"
   - Give it a name (e.g., "OpenCode MCP")
   - Copy the key

2. Add key to `opencode.json`:
   ```json
   "mcp": {
     "linear": {
       "type": "local",
       "enabled": true,
       "command": ["npx", "-y", "@linear/mcp"],
       "environment": {
         "LINEAR_API_KEY": "lin_api_your_key_here"
       }
     }
   }
   ```

**Capabilities**:
- List issues
- Create issues
- Update issue status
- Link issues to commits
- Track project progress

**Usage in Agents**:
- Planner: Pull requirements from Linear
- Builder: Link commits to issues
- Reviewer: Update issue status

---

### 3. Context7 MCP

**Purpose**: Access up-to-date documentation for libraries and frameworks.

**Setup**:

No configuration needed! Context7 works out of the box.

```json
"mcp": {
  "context7": {
    "type": "local",
    "enabled": true,
    "command": ["npx", "-y", "@upstash/context7-mcp"],
    "environment": {}
  }
}
```

**Capabilities**:
- Search documentation across thousands of libraries
- Get working code examples
- Access API references
- Find best practices
- Get migration guides

**Usage in Agents**:
- Planner: Research API patterns
- Builder: Get code examples
- Reviewer: Check against best practices
- Debug: Find troubleshooting guides

---

## Testing MCP Servers

### Test GitHub MCP

```bash
# List your repositories
opencode "List my GitHub repositories"

# Check recent issues
opencode "Show recent issues in my repositories"
```

### Test Linear MCP

```bash
# List Linear issues
opencode "Show my Linear issues"

# Create a test issue
opencode "Create a Linear issue for testing MCP integration"
```

### Test Context7 MCP

```bash
# Search documentation
opencode "How do I use React hooks?"

# Get code examples
opencode "Show me examples of using async/await in TypeScript"
```

---

## Troubleshooting

### GitHub MCP not working

**Problem**: "Authentication failed" or "Token invalid"

**Solution**:
1. Check token has correct scopes (repo, read:org, read:user)
2. Ensure token is not expired
3. Verify token is correctly copied to `opencode.json`
4. Check token starts with `ghp_`

### Linear MCP not working

**Problem**: "API key invalid"

**Solution**:
1. Regenerate API key in Linear settings
2. Ensure key is correctly copied
3. Check key starts with `lin_api_`

### Context7 MCP not working

**Problem**: Server fails to start

**Solution**:
1. Ensure Node.js is installed (`node --version`)
2. Check internet connection
3. Try: `npx -y @upstash/context7-mcp` manually
4. Clear npm cache: `npm cache clean --force`

### General MCP Issues

**Problem**: MCP server not starting

**Solution**:
1. Check Node.js is installed
2. Ensure `npx` is available
3. Check internet connection (npx downloads packages)
4. Look for errors in OpenCode logs

---

## Security Best Practices

### 🔒 Token Security

**DO**:
- ✅ Use environment variables for tokens
- ✅ Limit token scopes to minimum needed
- ✅ Rotate tokens periodically
- ✅ Use different tokens for dev/prod
- ✅ Revoke tokens when not needed

**DON'T**:
- ❌ Commit tokens to git
- ❌ Share tokens in chat/email
- ❌ Give tokens excessive scopes
- ❌ Use same token everywhere
- ❌ Store tokens in plaintext

### Environment Variables (Recommended)

Instead of hardcoding tokens:

```json
"environment": {
  "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}",
  "LINEAR_API_KEY": "${LINEAR_API_KEY}"
}
```

Set in your shell:
```bash
export GITHUB_TOKEN="ghp_your_token"
export LINEAR_API_KEY="lin_api_your_key"
```

---

## Adding Custom MCP Servers

You can add additional MCP servers to your configuration:

### Example: Slack MCP

```json
"mcp": {
  "slack": {
    "type": "local",
    "enabled": true,
    "command": ["npx", "-y", "@slack/mcp"],
    "environment": {
      "SLACK_BOT_TOKEN": "xoxb-your-token"
    }
  }
}
```

### Finding MCP Servers

- Official MCP servers: https://github.com/modelcontextprotocol/servers
- Community servers: https://github.com/topics/mcp-server
- LobeHub registry: https://lobehub.com/mcp

---

## MCP Server Permissions

Control which agents can use MCP servers in `opencode.json`:

```json
"permission": {
  "mcp": {
    "github": "allow",      // All agents can use
    "linear": "ask",        // Prompt before use
    "custom-internal": "deny"  // Block access
  }
}
```

---

## Performance Tips

### 1. Disable Unused Servers

```json
"mcp": {
  "github": {
    "enabled": false  // Disable if not using
  }
}
```

### 2. Cache Results

Some MCP servers cache responses automatically. Clear cache if data seems stale.

### 3. Rate Limiting

Be aware of API rate limits:
- **GitHub**: 5,000 requests/hour (authenticated)
- **Linear**: 2,000 requests/hour
- **Context7**: No official limits (be reasonable)

---

## Advanced Configuration

### Remote MCP Servers

For production environments, run MCP servers remotely:

```json
"mcp": {
  "github-remote": {
    "type": "remote",
    "url": "https://your-mcp-server.com",
    "headers": {
      "Authorization": "Bearer your_token"
    }
  }
}
```

### Custom Commands

Run MCP servers with custom configurations:

```json
"mcp": {
  "custom": {
    "type": "local",
    "command": ["node", "/path/to/custom-mcp-server.js"],
    "environment": {
      "CUSTOM_CONFIG": "/path/to/config.json"
    }
  }
}
```

---

## Next Steps

1. ✅ Configure GitHub MCP with your token
2. ✅ Configure Linear MCP if you use Linear
3. ✅ Test each MCP server
4. ✅ Start using MCP servers in your workflows

For more information:
- [MCP Documentation](https://modelcontextprotocol.io/)
- [OpenCode MCP Guide](https://opencode.ai/docs/mcp-servers)
- [Available MCP Servers](https://github.com/modelcontextprotocol/servers)
