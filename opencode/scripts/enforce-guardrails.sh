#!/bin/bash
# OpenCode Guardrails Enforcement Wrapper
# Enforces cost controls, rate limiting, and audit logging
# Usage: bash enforce-guardrails.sh [--pre|--post] --agent AGENT --operation OP [OPTIONS]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OPENCODE_DIR="$HOME/.config/opencode"
SCRIPTS_DIR="$OPENCODE_DIR/scripts"
CONFIG_FILE="$OPENCODE_DIR/config/guardrails.json"
LOG_DIR="$OPENCODE_DIR/logs"
RATE_LIMIT_DB="$LOG_DIR/rate_limits.db"

# Ensure directories exist
mkdir -p "$LOG_DIR"

# Parse arguments
PHASE="pre"  # pre or post
AGENT=""
OPERATION=""
FILE=""
ESTIMATED_COST=0
SESSION_ID="${OPENCODE_SESSION_ID:-$(uuidgen 2>/dev/null || echo "session-$(date +%s)")}"
TOOL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --pre)
            PHASE="pre"
            shift
            ;;
        --post)
            PHASE="post"
            shift
            ;;
        --agent)
            AGENT="$2"
            shift 2
            ;;
        --operation)
            OPERATION="$2"
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
        --estimated-cost)
            ESTIMATED_COST="$2"
            shift 2
            ;;
        --session-id)
            SESSION_ID="$2"
            shift 2
            ;;
        --help)
            echo "Usage: bash enforce-guardrails.sh [--pre|--post] --agent AGENT --operation OP [OPTIONS]"
            echo ""
            echo "Phases:"
            echo "  --pre    Run before operation (default)"
            echo "  --post   Run after operation"
            echo ""
            echo "Required:"
            echo "  --agent AGENT        Agent name (planner, builder, etc.)"
            echo "  --operation OP       Operation type (plan, build, test, etc.)"
            echo ""
            echo "Optional:"
            echo "  --tool TOOL          Tool being used (read, write, edit, bash)"
            echo "  --file FILE          File being operated on"
            echo "  --estimated-cost N   Estimated operation cost in USD"
            echo "  --session-id ID      Session identifier"
            echo ""
            echo "Examples:"
            echo "  bash enforce-guardrails.sh --pre --agent builder --operation build --file src/app.ts"
            echo "  bash enforce-guardrails.sh --post --agent tester --operation test"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$AGENT" ] || [ -z "$OPERATION" ]; then
    echo -e "${RED}✗ --agent and --operation are required${NC}"
    exit 1
fi

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠ Guardrails config not found, using defaults${NC}"
fi

# ===========================
# PRE-OPERATION CHECKS
# ===========================
if [ "$PHASE" = "pre" ]; then
    echo -e "${BLUE}Running pre-operation guardrails...${NC}"
    echo ""

    # 1. Check rate limits
    if [ -f "$CONFIG_FILE" ]; then
        # Get rate limit for this agent
        RATE_LIMIT_KEY="${AGENT}_calls_per_hour"
        RATE_LIMIT=$(grep "\"$RATE_LIMIT_KEY\"" "$CONFIG_FILE" | grep -oP '\d+' || echo "100")

        # Initialize rate limit database
        if [ ! -f "$RATE_LIMIT_DB" ]; then
            sqlite3 "$RATE_LIMIT_DB" <<EOF
CREATE TABLE IF NOT EXISTS calls (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    agent TEXT NOT NULL,
    operation TEXT
);
CREATE INDEX IF NOT EXISTS idx_timestamp ON calls(timestamp);
CREATE INDEX IF NOT EXISTS idx_agent ON calls(agent);
EOF
        fi

        # Count calls in last hour
        ONE_HOUR_AGO=$(date -u -d '1 hour ago' +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date -u -v-1H +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "")
        if [ -n "$ONE_HOUR_AGO" ]; then
            CALLS_IN_HOUR=$(sqlite3 "$RATE_LIMIT_DB" "SELECT COUNT(*) FROM calls WHERE agent = '$AGENT' AND timestamp > '$ONE_HOUR_AGO';" 2>/dev/null || echo "0")

            if [ "$CALLS_IN_HOUR" -ge "$RATE_LIMIT" ]; then
                echo -e "${RED}✗ RATE LIMIT EXCEEDED${NC}"
                echo ""
                echo "Agent: $AGENT"
                echo "Limit: $RATE_LIMIT calls/hour"
                echo "Current: $CALLS_IN_HOUR calls in last hour"
                echo ""
                echo "Please wait before making more calls."
                echo "Rate limits prevent API abuse and control costs."
                echo ""
                exit 3
            fi

            echo -e "${GREEN}✓ Rate limit check passed${NC}"
            echo "  Agent: $AGENT ($CALLS_IN_HOUR/$RATE_LIMIT calls/hour)"
            echo ""
        fi
    fi

    # 2. Check budget
    if [ -f "$SCRIPTS_DIR/check-budget.sh" ]; then
        bash "$SCRIPTS_DIR/check-budget.sh" \
            --session-id "$SESSION_ID" \
            --estimated-cost "$ESTIMATED_COST" || exit $?
    fi

    # 3. Security checks for sensitive files
    if [ -n "$FILE" ] && [ -f "$CONFIG_FILE" ]; then
        # Check if file matches sensitive paths
        SENSITIVE_PATHS=$(grep -A5 '"security_sensitive_paths"' "$CONFIG_FILE" | grep '"' | grep -v 'security_sensitive_paths' | tr -d '", ')

        for path in $SENSITIVE_PATHS; do
            if [[ "$FILE" == *"$path"* ]]; then
                echo -e "${YELLOW}⚠ SECURITY-SENSITIVE FILE DETECTED${NC}"
                echo ""
                echo "File: $FILE"
                echo "Path: $path"
                echo ""
                echo "Recommendation: Invoke @security agent for review"
                echo ""
                break
            fi
        done

        # Check if filename matches sensitive patterns
        FILENAME=$(basename "$FILE")
        if [[ "$FILENAME" == *"password"* ]] || \
           [[ "$FILENAME" == *"secret"* ]] || \
           [[ "$FILENAME" == *"token"* ]] || \
           [[ "$FILENAME" == *"key"* ]] || \
           [[ "$FILENAME" == *"credential"* ]]; then
            echo -e "${YELLOW}⚠ SECURITY-SENSITIVE FILENAME DETECTED${NC}"
            echo ""
            echo "File: $FILENAME"
            echo ""
            echo "Recommendation: Invoke @security agent for review"
            echo ""
        fi
    fi

    # 4. Block dangerous operations
    if [ "$TOOL" = "bash" ] && [ -f "$CONFIG_FILE" ]; then
        # Check for blocked operations
        BLOCKED_OPS=$(grep -A8 '"block_sensitive_operations"' "$CONFIG_FILE" | grep '"' | grep -v 'block_sensitive_operations' | tr -d '",' | tr -d ' ')

        if [ -n "$OPERATION" ]; then
            for blocked in $BLOCKED_OPS; do
                if [[ "$OPERATION" == *"$blocked"* ]]; then
                    echo -e "${RED}✗ BLOCKED OPERATION${NC}"
                    echo ""
                    echo "Operation: $OPERATION"
                    echo "Reason: Matches blocked pattern '$blocked'"
                    echo ""
                    echo "This operation is blocked for safety."
                    echo "If you need to run it, do so manually and document why."
                    echo ""
                    exit 4
                fi
            done
        fi
    fi

    echo -e "${GREEN}✓ All pre-operation checks passed${NC}"
    echo ""

# ===========================
# POST-OPERATION LOGGING
# ===========================
elif [ "$PHASE" = "post" ]; then
    echo -e "${BLUE}Running post-operation logging...${NC}"
    echo ""

    # 1. Log to audit trail
    if [ -f "$SCRIPTS_DIR/audit-log.sh" ]; then
        if [ -n "$TOOL" ]; then
            bash "$SCRIPTS_DIR/audit-log.sh" \
                --type tool_call \
                --agent "$AGENT" \
                --tool "$TOOL" \
                --file "$FILE" \
                --session-id "$SESSION_ID"
        else
            bash "$SCRIPTS_DIR/audit-log.sh" \
                --type decision \
                --agent "$AGENT" \
                --decision "$OPERATION" \
                --session-id "$SESSION_ID"
        fi
    fi

    # 2. Record rate limit call
    if [ -f "$RATE_LIMIT_DB" ]; then
        TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
        sqlite3 "$RATE_LIMIT_DB" "INSERT INTO calls (timestamp, agent, operation) VALUES ('$TIMESTAMP', '$AGENT', '$OPERATION');"

        # Cleanup old records (older than 24 hours)
        YESTERDAY=$(date -u -d '24 hours ago' +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date -u -v-24H +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "")
        if [ -n "$YESTERDAY" ]; then
            sqlite3 "$RATE_LIMIT_DB" "DELETE FROM calls WHERE timestamp < '$YESTERDAY';" 2>/dev/null || true
        fi
    fi

    echo -e "${GREEN}✓ Post-operation logging complete${NC}"
    echo ""
fi

exit 0
