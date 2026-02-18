#!/bin/bash
# OpenCode Audit Logger
# Logs all tool calls, file changes, and API calls for compliance
# Usage: bash audit-log.sh --type TYPE --agent AGENT [OPTIONS]

set -e

OPENCODE_DIR="$HOME/.config/opencode"
CONFIG_FILE="$OPENCODE_DIR/config/guardrails.json"
LOG_DIR="$OPENCODE_DIR/logs"
AUDIT_LOG="$LOG_DIR/audit.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Set secure permissions (owner-only read/write)
chmod 700 "$LOG_DIR" 2>/dev/null || true

# Load audit configuration
ENABLED="true"
if [ -f "$CONFIG_FILE" ]; then
    AUDIT_ENABLED=$(grep -A1 '"audit"' "$CONFIG_FILE" | grep '"enabled"' | grep -oP '(true|false)' | head -1)
    ENABLED=${AUDIT_ENABLED:-true}
fi

if [ "$ENABLED" = "false" ]; then
    # Audit logging disabled
    exit 0
fi

# Parse arguments
TYPE=""
AGENT=""
TOOL=""
FILE=""
ACTION=""
DIFF=""
SERVICE=""
OPERATION=""
DECISION=""
REASON=""
USER="${USER:-unknown}"
SESSION_ID="${OPENCODE_SESSION_ID:-unknown}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TYPE="$2"
            shift 2
            ;;
        --agent)
            AGENT="$2"
            shift 2
            ;;
        --tool)
            TOOL="$2"
            shift 2
            ;;
        --file)
            FILE="$2"
            shift 2
            ;;
        --action)
            ACTION="$2"
            shift 2
            ;;
        --diff)
            DIFF="$2"
            shift 2
            ;;
        --service)
            SERVICE="$2"
            shift 2
            ;;
        --operation)
            OPERATION="$2"
            shift 2
            ;;
        --decision)
            DECISION="$2"
            shift 2
            ;;
        --reason)
            REASON="$2"
            shift 2
            ;;
        --user)
            USER="$2"
            shift 2
            ;;
        --session-id)
            SESSION_ID="$2"
            shift 2
            ;;
        --help)
            echo "Usage: bash audit-log.sh --type TYPE --agent AGENT [OPTIONS]"
            echo ""
            echo "Types:"
            echo "  tool_call      - Log a tool invocation"
            echo "  file_change    - Log a file modification"
            echo "  api_call       - Log an external API call"
            echo "  decision       - Log an agent decision"
            echo ""
            echo "Options:"
            echo "  --agent AGENT        Agent name (planner, builder, etc.)"
            echo "  --tool TOOL          Tool name (read, write, edit, bash)"
            echo "  --file FILE          File path"
            echo "  --action ACTION      Action performed (create, edit, delete)"
            echo "  --diff DIFF          File diff"
            echo "  --service SERVICE    External service name"
            echo "  --operation OP       Operation performed"
            echo "  --decision DEC       Decision made"
            echo "  --reason REASON      Reason for decision"
            echo "  --user USER          User identifier"
            echo "  --session-id ID      Session identifier"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$TYPE" ] || [ -z "$AGENT" ]; then
    echo "Error: --type and --agent are required"
    echo "Use --help for usage information"
    exit 1
fi

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build JSON log entry
LOG_ENTRY="{"
LOG_ENTRY+="\"timestamp\":\"$TIMESTAMP\""
LOG_ENTRY+=",\"type\":\"$TYPE\""
LOG_ENTRY+=",\"agent\":\"$AGENT\""
LOG_ENTRY+=",\"user\":\"$USER\""
LOG_ENTRY+=",\"session_id\":\"$SESSION_ID\""

case $TYPE in
    tool_call)
        LOG_ENTRY+=",\"tool\":\"$TOOL\""
        if [ -n "$FILE" ]; then
            LOG_ENTRY+=",\"file\":\"$FILE\""
        fi
        ;;
    file_change)
        LOG_ENTRY+=",\"file\":\"$FILE\""
        LOG_ENTRY+=",\"action\":\"$ACTION\""
        if [ -n "$DIFF" ]; then
            # Escape diff for JSON (basic escaping)
            ESCAPED_DIFF=$(echo "$DIFF" | sed 's/"/\\"/g' | tr '\n' ' ')
            LOG_ENTRY+=",\"diff\":\"$ESCAPED_DIFF\""
        fi
        ;;
    api_call)
        LOG_ENTRY+=",\"service\":\"$SERVICE\""
        LOG_ENTRY+=",\"operation\":\"$OPERATION\""
        if [ -n "$FILE" ]; then
            LOG_ENTRY+=",\"target\":\"$FILE\""
        fi
        ;;
    decision)
        LOG_ENTRY+=",\"decision\":\"$DECISION\""
        LOG_ENTRY+=",\"reason\":\"$REASON\""
        ;;
esac

LOG_ENTRY+="}"

# Write to audit log
echo "$LOG_ENTRY" >> "$AUDIT_LOG"

# Log rotation: if audit.log > 10MB, rotate it
if [ -f "$AUDIT_LOG" ]; then
    SIZE=$(stat -f%z "$AUDIT_LOG" 2>/dev/null || stat -c%s "$AUDIT_LOG" 2>/dev/null || echo "0")
    MAX_SIZE=$((10 * 1024 * 1024))  # 10MB

    if [ "$SIZE" -gt "$MAX_SIZE" ]; then
        # Rotate: audit.log -> audit.log.1, audit.log.1 -> audit.log.2, etc.
        for i in 4 3 2 1; do
            if [ -f "$LOG_DIR/audit.log.$i" ]; then
                mv "$LOG_DIR/audit.log.$i" "$LOG_DIR/audit.log.$((i+1))"
            fi
        done
        mv "$AUDIT_LOG" "$LOG_DIR/audit.log.1"
        touch "$AUDIT_LOG"
        chmod 600 "$AUDIT_LOG"
    fi
fi

# Cleanup old logs based on retention policy
if [ -f "$CONFIG_FILE" ]; then
    RETENTION_DAYS=$(grep '"retention_days"' "$CONFIG_FILE" | grep -oP '\d+' || echo "90")

    # Delete logs older than retention period
    find "$LOG_DIR" -name "audit.log.*" -type f -mtime "+$RETENTION_DAYS" -delete 2>/dev/null || true
fi

exit 0
