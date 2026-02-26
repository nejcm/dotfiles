#!/bin/bash
# OpenCode Budget Checker
# Enforces daily budget and per-session limits
# Usage: bash check-budget.sh [--session-id ID] [--estimated-cost COST]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

OPENCODE_DIR="$HOME/.config/opencode"
CONFIG_FILE="$OPENCODE_DIR/config/guardrails.json"
LOG_DIR="$OPENCODE_DIR/logs"
COST_DB="$LOG_DIR/cost_tracking.db"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Load guardrails configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Guardrails configuration not found${NC}"
    echo "Expected: $CONFIG_FILE"
    exit 1
fi

# Extract configuration values using basic JSON parsing
# (In production, use jq if available)
ENABLED=$(grep -A1 '"enabled"' "$CONFIG_FILE" | grep -v 'enabled' | tr -d ' ,:' | head -1)
DAILY_BUDGET=$(grep '"daily_budget_usd"' "$CONFIG_FILE" | grep -oP '\d+')
SESSION_LIMIT=$(grep '"per_session_limit_usd"' "$CONFIG_FILE" | grep -oP '\d+')

if [ "$ENABLED" = "false" ]; then
    echo -e "${YELLOW}⚠ Cost controls disabled${NC}"
    exit 0
fi

# Default values if not found
DAILY_BUDGET=${DAILY_BUDGET:-100}
SESSION_LIMIT=${SESSION_LIMIT:-10}

# Parse arguments
SESSION_ID=""
ESTIMATED_COST=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --session-id)
            SESSION_ID="$2"
            shift 2
            ;;
        --estimated-cost)
            ESTIMATED_COST="$2"
            shift 2
            ;;
        --daily-budget)
            DAILY_BUDGET="$2"
            shift 2
            ;;
        --help)
            echo "Usage: bash check-budget.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --session-id ID          Current session ID"
            echo "  --estimated-cost COST    Estimated operation cost in USD"
            echo "  --daily-budget BUDGET    Override daily budget (default: $DAILY_BUDGET)"
            echo "  --help                   Show this help"
            echo ""
            echo "Exit codes:"
            echo "  0 = Budget OK"
            echo "  1 = Daily budget exceeded"
            echo "  2 = Session limit exceeded"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Initialize SQLite database if not exists
if [ ! -f "$COST_DB" ]; then
    sqlite3 "$COST_DB" <<EOF
CREATE TABLE IF NOT EXISTS costs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    date TEXT NOT NULL,
    session_id TEXT,
    agent TEXT,
    model TEXT,
    input_tokens INTEGER,
    output_tokens INTEGER,
    cost_usd REAL
);

CREATE INDEX IF NOT EXISTS idx_date ON costs(date);
CREATE INDEX IF NOT EXISTS idx_session ON costs(session_id);
EOF
fi

# Get today's date
TODAY=$(date -u +%Y-%m-%d)

# Calculate today's total spend
DAILY_SPEND=$(sqlite3 "$COST_DB" "SELECT COALESCE(SUM(cost_usd), 0) FROM costs WHERE date = '$TODAY';" 2>/dev/null || echo "0")

# Calculate session spend if session ID provided
SESSION_SPEND=0
if [ -n "$SESSION_ID" ]; then
    SESSION_SPEND=$(sqlite3 "$COST_DB" "SELECT COALESCE(SUM(cost_usd), 0) FROM costs WHERE session_id = '$SESSION_ID';" 2>/dev/null || echo "0")
fi

# Add estimated cost to current totals
NEW_DAILY_TOTAL=$(echo "$DAILY_SPEND + $ESTIMATED_COST" | bc)
NEW_SESSION_TOTAL=$(echo "$SESSION_SPEND + $ESTIMATED_COST" | bc)

# Check daily budget
if (( $(echo "$NEW_DAILY_TOTAL > $DAILY_BUDGET" | bc -l) )); then
    echo -e "${RED}✗ DAILY BUDGET EXCEEDED${NC}"
    echo ""
    echo "Daily Budget:    \$$DAILY_BUDGET"
    echo "Current Spend:   \$$DAILY_SPEND"
    echo "Estimated Cost:  \$$ESTIMATED_COST"
    echo "New Total:       \$$NEW_DAILY_TOTAL"
    echo ""
    echo "Cannot proceed. Budget limit reached."
    echo "Reset at midnight UTC or increase budget in:"
    echo "  $CONFIG_FILE"
    echo ""
    exit 1
fi

# Check session limit
if [ -n "$SESSION_ID" ]; then
    if (( $(echo "$NEW_SESSION_TOTAL > $SESSION_LIMIT" | bc -l) )); then
        echo -e "${RED}✗ SESSION LIMIT EXCEEDED${NC}"
        echo ""
        echo "Session Limit:   \$$SESSION_LIMIT"
        echo "Current Spend:   \$$SESSION_SPEND"
        echo "Estimated Cost:  \$$ESTIMATED_COST"
        echo "New Total:       \$$NEW_SESSION_TOTAL"
        echo ""
        echo "Cannot proceed. Session limit reached."
        echo "Start new session or increase limit in:"
        echo "  $CONFIG_FILE"
        echo ""
        exit 2
    fi
fi

# Budget checks passed
echo -e "${GREEN}✓ Budget checks passed${NC}"
echo ""
echo "Daily Budget:    \$$DAILY_BUDGET"
echo "Daily Spend:     \$$DAILY_SPEND ($(echo "scale=1; $DAILY_SPEND * 100 / $DAILY_BUDGET" | bc)%)"
echo "Daily Remaining: \$$(echo "$DAILY_BUDGET - $DAILY_SPEND" | bc)"
echo ""

if [ -n "$SESSION_ID" ]; then
    echo "Session Limit:   \$$SESSION_LIMIT"
    echo "Session Spend:   \$$SESSION_SPEND ($(echo "scale=1; $SESSION_SPEND * 100 / $SESSION_LIMIT" | bc)%)"
    echo "Session Remain:  \$$(echo "$SESSION_LIMIT - $SESSION_SPEND" | bc)"
    echo ""
fi

if (( $(echo "$ESTIMATED_COST > 0" | bc -l) )); then
    echo "Estimated Cost:  \$$ESTIMATED_COST"
    echo ""
fi

# Warning if approaching limits
DAILY_PCT=$(echo "scale=1; $NEW_DAILY_TOTAL * 100 / $DAILY_BUDGET" | bc)
if (( $(echo "$DAILY_PCT > 80" | bc -l) )); then
    echo -e "${YELLOW}⚠ Warning: Daily budget at $DAILY_PCT%${NC}"
    echo ""
fi

if [ -n "$SESSION_ID" ]; then
    SESSION_PCT=$(echo "scale=1; $NEW_SESSION_TOTAL * 100 / $SESSION_LIMIT" | bc)
    if (( $(echo "$SESSION_PCT > 80" | bc -l) )); then
        echo -e "${YELLOW}⚠ Warning: Session limit at $SESSION_PCT%${NC}"
        echo ""
    fi
fi

exit 0
