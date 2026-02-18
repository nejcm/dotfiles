# OpenCode Agent Architecture - Troubleshooting Guide

**Common issues and solutions for the OpenCode agent system.**

---

## Table of Contents

1. [Agent Issues](#agent-issues)
2. [MCP Server Issues](#mcp-server-issues)
3. [Permission and Guardrail Issues](#permission-and-guardrail-issues)
4. [Workflow Issues](#workflow-issues)
5. [Skill Issues](#skill-issues)
6. [Performance Issues](#performance-issues)
7. [Cost and Budget Issues](#cost-and-budget-issues)
8. [Configuration Issues](#configuration-issues)

---

## Agent Issues

### Agent Not Responding

**Symptoms:**
- Agent command hangs indefinitely
- No response after `@agent-name` command
- Timeout errors

**Possible Causes & Solutions:**

1. **Model API unavailable**
   ```bash
   # Check internet connectivity
   ping anthropic.com

   # Verify API key is set (if required)
   echo $ANTHROPIC_API_KEY
   ```
   **Solution:** Wait for API to recover or check API status page

2. **Agent not defined in config**
   ```bash
   # Verify agent exists in opencode.json
   cat ~/.config/opencode/opencode.json | grep -A 10 '"agent-name"'
   ```
   **Solution:** Add agent configuration or use correct agent name

3. **Rate limit exceeded**
   ```bash
   # Check rate limit settings
   cat ~/.config/opencode/opencode.json | grep -A 10 "rate_limits"
   ```
   **Solution:** Wait for rate limit window to reset (1 hour) or adjust limits

4. **Context token limit exceeded**
   **Solution:** Reduce context size or increase `max_context_tokens` in guardrails

---

### Agent Returns Error: "Spec Required"

**Symptoms:**
```
Error: Builder agent requires a specification file.
Guardrail 'require_spec_for_builder' is enabled.
```

**Cause:** Builder agent has `require_spec_for_builder: true` in guardrails

**Solution:**
1. Use planner agent first to create spec:
   ```
   @planner Create a spec for [your feature]
   ```
2. Then use builder with spec reference:
   ```
   @builder Implement specs/[generated-spec].md
   ```

**Alternative:** Disable guardrail (not recommended):
```json
{
  "guardrails": {
    "require_spec_for_builder": false
  }
}
```

---

### Agent Makes Unauthorized Changes

**Symptoms:**
- Agent modifies files outside intended scope
- Agent executes bash commands without permission
- Agent writes to production database

**Solution:**

1. **Review agent permissions** in `opencode.json`:
   ```json
   {
     "agent": {
       "builder": {
         "tools": {
           "write": true,   // Can create/overwrite files
           "edit": true,    // Can modify files
           "bash": true,    // Can execute commands
           "read": true     // Can read files
         }
       }
     }
   }
   ```

2. **Restrict permissions** for specific agents:
   ```json
   {
     "agent": {
       "reviewer": {
         "tools": {
           "write": false,  // Read-only
           "edit": false,
           "bash": false,
           "read": true
         }
       }
     }
   }
   ```

3. **Enable deployment protection**:
   ```json
   {
     "deployment": {
       "production_require_approval": true,
       "production_require_security_review": true
     }
   }
   ```

4. **Review audit logs**:
   ```bash
   tail -f ~/.config/opencode/logs/audit.log
   ```

---

### Agent Output is Low Quality

**Symptoms:**
- Incorrect implementations
- Missing edge cases
- Poor code quality

**Solutions:**

1. **Use appropriate agent** for the task:
   - Planner → Specifications and design
   - Builder → Implementation
   - Reviewer → Code review
   - Security → Security analysis

2. **Adjust temperature** for more deterministic output:
   ```json
   {
     "agent": {
       "builder": {
         "temperature": 0.1  // Lower = more deterministic
       }
     }
   }
   ```

3. **Use higher-capability model**:
   ```json
   {
     "agent": {
       "builder": {
         "model": "anthropic/claude-opus-4-20250514"  // More capable
       }
     }
   }
   ```

4. **Provide more context** in spec:
   - Add detailed constraints
   - Include examples
   - Specify edge cases
   - Reference existing patterns

---

## MCP Server Issues

### MCP Server Not Found

**Symptoms:**
```
Error: MCP server 'github' not found or not responding
```

**Solution:**

1. **Verify MCP is configured** in `opencode.json`:
   ```bash
   cat ~/.config/opencode/opencode.json | grep -A 10 '"github"'
   ```

2. **Check MCP is enabled**:
   ```json
   {
     "mcp": {
       "github": {
         "enabled": true  // Must be true
       }
     }
   }
   ```

3. **Run validation script**:
   ```bash
   bash ~/.config/opencode/scripts/validate-mcp.sh
   ```

4. **Install dependencies**:
   ```bash
   npm install -g @modelcontextprotocol/server-github
   ```

---

### GitHub MCP: Authentication Failed

**Symptoms:**
```
Error: GitHub MCP authentication failed
Status: 401 Unauthorized
```

**Solution:**

1. **Check token is set** in `opencode.json`:
   ```json
   {
     "mcp": {
       "github": {
         "environment": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxx"  // Must be set
         }
       }
     }
   }
   ```

2. **Verify token has correct scopes**:
   - Go to: https://github.com/settings/tokens
   - Required scopes: `repo`, `read:org`, `workflow`

3. **Test token manually**:
   ```bash
   curl -H "Authorization: token ghp_xxxxx" https://api.github.com/user
   ```

4. **Regenerate token** if expired or invalid

**See:** `~/.config/opencode/mcp/SETUP_GUIDE.md` for detailed setup

---

### Linear MCP: API Key Missing

**Symptoms:**
```
Error: Linear MCP requires LINEAR_API_KEY environment variable
```

**Solution:**

1. **Add API key** to `opencode.json`:
   ```json
   {
     "mcp": {
       "linear": {
         "environment": {
           "LINEAR_API_KEY": "lin_api_xxxxx"
         }
       }
     }
   }
   ```

2. **Get API key** from Linear:
   - Go to: https://linear.app/settings/api
   - Create new API key
   - Copy and paste into config

3. **Test API key**:
   ```bash
   curl -H "Authorization: lin_api_xxxxx" https://api.linear.app/graphql \
     -d '{"query":"{ viewer { id name } }"}'
   ```

---

### Context7 MCP Not Working

**Symptoms:**
- Context7 returns no results
- Embeddings not found

**Note:** Context7 requires no authentication, but needs first-time setup

**Solution:**

1. **Initialize Context7**:
   ```bash
   npx @upstash/context7-mcp init
   ```

2. **Index your codebase** (optional):
   ```bash
   npx @upstash/context7-mcp index .
   ```

3. **Verify installation**:
   ```bash
   npx @upstash/context7-mcp --version
   ```

---

## Permission and Guardrail Issues

### "Max Tool Calls Exceeded"

**Symptoms:**
```
Error: Maximum tool calls per session exceeded (100)
Guardrail: max_tool_calls_per_session
```

**Cause:** Agent made too many tool calls in single session

**Solutions:**

1. **Increase limit** (temporary):
   ```json
   {
     "guardrails": {
       "max_tool_calls_per_session": 200
     }
   }
   ```

2. **Break into multiple sessions**:
   - Complete current task
   - Start new session for next task

3. **Optimize agent prompts** to reduce tool calls

4. **Review if agent is in infinite loop**:
   ```bash
   tail -f ~/.config/opencode/logs/audit.log | grep tool_call
   ```

---

### "Daily Budget Exceeded"

**Symptoms:**
```
Error: Daily budget limit exceeded ($100)
Current spend: $102.50
```

**Solutions:**

1. **Wait for daily reset** (midnight UTC)

2. **Increase budget** (if justified):
   ```json
   {
     "cost_controls": {
       "daily_budget_usd": 200
     }
   }
   ```

3. **Review costs** to identify expensive operations:
   ```bash
   bash ~/.config/opencode/scripts/cost-analyzer.sh  # If exists
   ```

4. **Optimize model usage**:
   - Use Haiku-4 for simple tasks
   - Reserve Opus-4 for critical operations

---

### "Operation Blocked by Security Policy"

**Symptoms:**
```
Error: Operation blocked by security policy
Blocked operation: DROP DATABASE
```

**Cause:** Sensitive operation detected by security guardrails

**Solution:**

1. **Review blocked operations** in config:
   ```json
   {
     "security": {
       "block_sensitive_operations": [
         "DROP DATABASE",
         "TRUNCATE TABLE users",
         "DELETE FROM users WHERE 1=1"
       ]
     }
   }
   ```

2. **Use safer alternative**:
   - Instead of `DROP DATABASE`, archive and recreate
   - Instead of `TRUNCATE`, use soft deletes
   - Instead of mass `DELETE`, use batch operations with `LIMIT`

3. **Temporarily disable** (DANGEROUS):
   ```json
   {
     "security": {
       "block_sensitive_operations": []
     }
   }
   ```
   **WARNING:** Only do this if absolutely necessary and you understand the risks

---

## Workflow Issues

### Hotfix Workflow: No Production Access

**Problem:** Need to deploy hotfix but don't have production credentials

**Solution:**

1. **Request emergency access** from SRE team
2. **Use deployment pipeline** with emergency approval
3. **Follow escalation path** in `workflows/hotfix_workflow.md`
4. **Document access request** in incident log

---

### Incident Response: Missing Role Assignments

**Problem:** Incident declared but no one assigned to IC/Tech Lead roles

**Solution:**

1. **Use default assignments** from `workflows/incident_response.md`:
   - **Incident Commander (IC):** First responder or on-call engineer
   - **Tech Lead:** Senior engineer with domain knowledge
   - **Communications:** Engineering manager or PM
   - **Scribe:** Any available team member

2. **Update rotation** in team documentation
3. **Set up PagerDuty/OpsGenie** with automatic role assignment

---

### Security Review: Auto-Trigger Not Working

**Problem:** Changed `auth/login.ts` but security agent not triggered

**Solution:**

1. **Verify auto-trigger is enabled**:
   ```json
   {
     "security": {
       "auto_trigger_security_review": true,
       "security_sensitive_paths": [
         "auth/",
         "payment/",
         "admin/"
       ]
     }
   }
   ```

2. **Check file path matches** pattern (case-sensitive)

3. **Manually trigger** security review:
   ```
   @security Review changes in auth/login.ts
   ```

---

## Skill Issues

### Skill Not Found

**Symptoms:**
```
Error: Skill 'run-tests' not found
```

**Solution:**

1. **Verify skill exists**:
   ```bash
   ls ~/.config/opencode/skills/run-tests/SKILL.md
   ```

2. **Check skill format** (must be `SKILL.md` in subdirectory):
   ```
   skills/
   └── run-tests/
       └── SKILL.md
   ```

3. **Validate YAML frontmatter**:
   ```yaml
   ---
   name: run-tests
   description: Executes test suite and returns results
   version: 1.0.0
   ---
   ```

---

### Skill Execution Failed

**Symptoms:**
```
Error: Skill 'run-tests' execution failed
Exit code: 1
```

**Solution:**

1. **Check skill dependencies**:
   ```bash
   # Example: run-tests skill requires npm
   which npm  # Must return path
   ```

2. **Review skill logs**:
   ```bash
   tail -f ~/.config/opencode/logs/skills/run-tests.log
   ```

3. **Test skill manually**:
   ```bash
   # Read the skill to understand what it does
   cat ~/.config/opencode/skills/run-tests/SKILL.md

   # Execute the underlying command
   npm test
   ```

4. **Update skill** if command has changed

---

## Performance Issues

### Agent Responses Very Slow

**Symptoms:**
- Agent takes >60 seconds to respond
- Frequent timeouts

**Solutions:**

1. **Use faster model** for simple tasks:
   ```json
   {
     "agent": {
       "tester": {
         "model": "anthropic/claude-haiku-4-20250514"  // Fastest
       }
     }
   }
   ```

2. **Reduce context size**:
   - Avoid reading entire large files
   - Use search instead of full file reads
   - Clear conversation history periodically

3. **Check rate limits**:
   ```bash
   cat ~/.config/opencode/opencode.json | grep -A 10 "rate_limits"
   ```

4. **Monitor API status**: https://status.anthropic.com/

---

### High API Costs

**Problem:** Monthly bill is $1000+ for small team

**Solutions:**

1. **Review model strategy**:
   ```json
   {
     "model_strategy": {
       "planning_and_architecture": "sonnet-4 or opus-4",
       "implementation_and_edits": "sonnet-4",
       "testing_and_validation": "haiku-4",      // Cheapest
       "security_critical": "opus-4",
       "routine_refactoring": "haiku-4",         // Cheapest
       "documentation": "haiku-4",               // Cheapest
       "debugging": "sonnet-4"
     }
   }
   ```

2. **Enable cost tracking**:
   ```json
   {
     "cost_controls": {
       "track_usage_per_agent": true
     }
   }
   ```

3. **Set stricter budgets**:
   ```json
   {
     "cost_controls": {
       "daily_budget_usd": 50,
       "per_session_limit_usd": 5
     }
   }
   ```

4. **Analyze usage** (if script exists):
   ```bash
   bash ~/.config/opencode/scripts/cost-analyzer.sh
   ```

---

## Cost and Budget Issues

### Understanding Cost Breakdown

**Cost by Model (approximate, as of 2024):**
- **Haiku-4**: ~$0.25 per 1M input tokens, ~$1.25 per 1M output tokens
- **Sonnet-4**: ~$3 per 1M input tokens, ~$15 per 1M output tokens
- **Opus-4**: ~$15 per 1M input tokens, ~$75 per 1M output tokens

**Typical Feature Implementation Costs:**
- Simple feature (Haiku): $0.10 - $0.50
- Medium feature (Sonnet): $1.00 - $5.00
- Complex feature (Opus): $5.00 - $20.00

**Budget Recommendations:**
- **Solo developer**: $50-100/month
- **Small team (2-5)**: $200-500/month
- **Medium team (5-15)**: $500-2000/month

---

### Cost Warning: "Expensive Operation"

**Symptoms:**
```
Warning: This operation may exceed $5 threshold
Estimated cost: $7.50
Proceed? (y/n)
```

**Cause:** Operation detected that might be expensive (large context, Opus model, etc.)

**Solutions:**

1. **Review operation** before proceeding
2. **Optimize context**:
   - Reduce files being read
   - Use search instead of full reads
   - Split into smaller operations

3. **Switch model** if appropriate:
   - Can this be done with Sonnet instead of Opus?
   - Can this be done with Haiku?

4. **Adjust threshold** if too sensitive:
   ```json
   {
     "cost_controls": {
       "expensive_operation_threshold_usd": 10
     }
   }
   ```

---

## Configuration Issues

### Config File Not Found

**Symptoms:**
```
Error: Configuration file not found
Expected: ~/.config/opencode/opencode.json
```

**Solution:**

1. **Check file exists**:
   ```bash
   ls -la ~/.config/opencode/opencode.json
   ```

2. **Verify permissions**:
   ```bash
   chmod 644 ~/.config/opencode/opencode.json
   ```

3. **Recreate from template** if missing (see `QUICK_START.md`)

---

### Invalid JSON in Config

**Symptoms:**
```
Error: Failed to parse opencode.json
Syntax error at line 42: unexpected token '}'
```

**Solution:**

1. **Validate JSON**:
   ```bash
   cat ~/.config/opencode/opencode.json | python -m json.tool
   ```

2. **Common issues**:
   - Missing comma after object
   - Trailing comma in last object
   - Unescaped quotes in strings
   - Missing closing brace/bracket

3. **Use JSON linter**:
   ```bash
   npm install -g jsonlint
   jsonlint ~/.config/opencode/opencode.json
   ```

---

### Changes to Config Not Taking Effect

**Problem:** Modified `opencode.json` but agents still use old settings

**Solution:**

1. **Restart OpenCode session**:
   - Exit current session
   - Start new session
   - Config is loaded on startup

2. **Verify file is saved**:
   ```bash
   cat ~/.config/opencode/opencode.json | grep "your_change"
   ```

3. **Check for typos** in config keys (case-sensitive)

4. **Clear cache** (if applicable):
   ```bash
   rm -rf ~/.config/opencode/.cache/
   ```

---

## Emergency Procedures

### "Production is Down" - Quick Actions

1. **Declare incident** → `workflows/incident_response.md`
2. **Check monitoring** → Logs, APM, error tracking
3. **Identify IC and Tech Lead** → Assign roles immediately
4. **Create incident channel** → Slack/Teams
5. **Start logging** → Timeline of events
6. **Investigate** → Recent deployments, changes
7. **Communicate** → Internal stakeholders + customers

---

### "Database Corrupted" - Recovery

1. **STOP all writes** → Put app in read-only mode
2. **Assess damage** → Query affected tables
3. **Restore from backup** → Most recent clean backup
4. **Replay transactions** → From replication log (if available)
5. **Verify integrity** → Check constraints, counts
6. **Resume writes** → Gradually, with monitoring
7. **Post-mortem** → Document what happened

---

### "Security Breach" - Containment

1. **Isolate affected systems** → Firewall rules, disable access
2. **Preserve evidence** → Don't delete logs
3. **Assess scope** → What data was accessed?
4. **Revoke credentials** → Rotate all keys/tokens
5. **Notify security team** → Escalate immediately
6. **Customer notification** → If PII/PCI data affected
7. **Forensics** → Root cause analysis

---

## Getting More Help

### Documentation Resources
- **Main Index:** `~/.config/opencode/INDEX.md`
- **Architecture:** `~/.config/opencode/ARCHITECTURE.md`
- **All Workflows:** `~/.config/opencode/workflows/`
- **Glossary:** `~/.config/opencode/GLOSSARY.md`

### Validation Scripts
```bash
# Validate MCP setup
bash ~/.config/opencode/scripts/validate-mcp.sh

# Validate complete setup (if exists)
bash ~/.config/opencode/scripts/validate-setup.sh

# Check agent health (if exists)
bash ~/.config/opencode/scripts/health-check.sh
```

### Audit Logs
```bash
# View recent activity
tail -100 ~/.config/opencode/logs/audit.log

# Search for errors
grep -i "error" ~/.config/opencode/logs/audit.log

# Filter by agent
grep "agent=builder" ~/.config/opencode/logs/audit.log
```

### Community Support
- **OpenCode Discord:** https://discord.gg/opencode (check for actual link)
- **GitHub Issues:** https://github.com/opencode-ai/opencode/issues
- **Documentation:** https://opencode.ai/docs

---

## Still Stuck?

If none of these solutions work:

1. **Check OpenCode status page** for known issues
2. **Search GitHub issues** for similar problems
3. **Create detailed bug report** with:
   - OpenCode version
   - Operating system
   - Full error message
   - Steps to reproduce
   - Configuration (redact tokens!)
4. **Ask in Discord/community** with context

---

**Remember:** Most issues are configuration or permission related. Start with validation scripts and audit logs!

*Last updated: 2026-02-17*
