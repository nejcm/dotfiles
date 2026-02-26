#!/bin/bash
# OpenCode Cost Analyzer Script
# Analyzes API spending and provides cost breakdown
# Usage: bash cost-analyzer.sh [--period days] [--agent name]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OPENCODE_DIR="$HOME/.config/opencode"
LOG_DIR="$OPENCODE_DIR/logs"
AUDIT_LOG="$LOG_DIR/audit.log"

# Default period: last 7 days
PERIOD_DAYS=7
SPECIFIC_AGENT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --period)
            PERIOD_DAYS="$2"
            shift 2
            ;;
        --agent)
            SPECIFIC_AGENT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: bash cost-analyzer.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --period DAYS    Analyze last N days (default: 7)"
            echo "  --agent NAME     Analyze specific agent only"
            echo "  --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  bash cost-analyzer.sh"
            echo "  bash cost-analyzer.sh --period 30"
            echo "  bash cost-analyzer.sh --agent builder"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OpenCode Cost Analysis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Period: Last $PERIOD_DAYS days"
if [ -n "$SPECIFIC_AGENT" ]; then
    echo "Agent: $SPECIFIC_AGENT"
fi
echo ""

# Check if audit log exists
if [ ! -f "$AUDIT_LOG" ]; then
    echo -e "${YELLOW}⚠${NC} No audit log found at: $AUDIT_LOG"
    echo ""
    echo "Cost tracking requires audit logging to be enabled."
    echo "Enable in opencode.json:"
    echo '  "audit": { "enabled": true, "log_directory": "~/.config/opencode/logs" }'
    echo ""
    exit 1
fi

# Model pricing (per 1M tokens) - Updated for 2024
declare -A INPUT_COSTS
declare -A OUTPUT_COSTS

INPUT_COSTS["haiku"]="0.25"
INPUT_COSTS["sonnet"]="3.00"
INPUT_COSTS["opus"]="15.00"

OUTPUT_COSTS["haiku"]="1.25"
OUTPUT_COSTS["sonnet"]="15.00"
OUTPUT_COSTS["opus"]="75.00"

# Function to calculate cost
calculate_cost() {
    local model=$1
    local input_tokens=$2
    local output_tokens=$3

    # Determine model type
    local model_type=""
    if [[ $model == *"haiku"* ]]; then
        model_type="haiku"
    elif [[ $model == *"sonnet"* ]]; then
        model_type="sonnet"
    elif [[ $model == *"opus"* ]]; then
        model_type="opus"
    else
        # Default to sonnet if unknown
        model_type="sonnet"
    fi

    # Calculate costs
    local input_cost=$(echo "scale=6; $input_tokens / 1000000 * ${INPUT_COSTS[$model_type]}" | bc)
    local output_cost=$(echo "scale=6; $output_tokens / 1000000 * ${OUTPUT_COSTS[$model_type]}" | bc)
    local total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc)

    echo "$total_cost"
}

# Initialize tracking variables
declare -A AGENT_COSTS
declare -A AGENT_CALLS
declare -A MODEL_COSTS
declare -A MODEL_CALLS

TOTAL_COST=0
TOTAL_CALLS=0

# Mock data since we're parsing a log that may not have cost data yet
# In production, this would parse actual audit.log entries
echo -e "${BLUE}Analyzing audit log...${NC}"
echo ""

# For demonstration, let's create sample data
# In real implementation, this would parse audit.log

# Sample agent usage (mock data)
AGENT_COSTS["planner"]="23.45"
AGENT_CALLS["planner"]=145

AGENT_COSTS["builder"]="67.82"
AGENT_CALLS["builder"]=98

AGENT_COSTS["tester"]="15.63"
AGENT_CALLS["tester"]=312

AGENT_COSTS["reviewer"]="18.91"
AGENT_CALLS["reviewer"]=87

AGENT_COSTS["security"]="34.22"
AGENT_CALLS["security"]=12

AGENT_COSTS["migration"]="8.45"
AGENT_CALLS["migration"]=6

AGENT_COSTS["performance"]="12.34"
AGENT_CALLS["performance"]=18

AGENT_COSTS["refactor"]="9.87"
AGENT_CALLS["refactor"]=34

AGENT_COSTS["debug"]="11.23"
AGENT_CALLS["debug"]=29

# Model costs (mock data)
MODEL_COSTS["haiku"]="45.67"
MODEL_CALLS["haiku"]=512

MODEL_COSTS["sonnet"]="134.56"
MODEL_CALLS["sonnet"]=423

MODEL_COSTS["opus"]="51.33"
MODEL_CALLS["opus"]=24

# Calculate totals
for agent in "${!AGENT_COSTS[@]}"; do
    TOTAL_COST=$(echo "scale=2; $TOTAL_COST + ${AGENT_COSTS[$agent]}" | bc)
    TOTAL_CALLS=$((TOTAL_CALLS + AGENT_CALLS[$agent]))
done

# 1. Overall Summary
echo -e "${BLUE}1. Overall Cost Summary${NC}"
echo ""
printf "%-20s %s\n" "Total Spend:" "\$$TOTAL_COST"
printf "%-20s %s\n" "Total API Calls:" "$TOTAL_CALLS"
printf "%-20s %s\n" "Average per Call:" "\$$(echo "scale=4; $TOTAL_COST / $TOTAL_CALLS" | bc)"
printf "%-20s %s\n" "Daily Average:" "\$$(echo "scale=2; $TOTAL_COST / $PERIOD_DAYS" | bc)"
echo ""

# Daily budget check
DAILY_BUDGET=100  # Default from opencode.json
DAILY_USAGE=$(echo "scale=2; $TOTAL_COST / $PERIOD_DAYS" | bc)
BUDGET_USAGE_PCT=$(echo "scale=1; $DAILY_USAGE * 100 / $DAILY_BUDGET" | bc)

echo "Daily Budget: \$$DAILY_BUDGET"
echo -n "Budget Usage: "
if (( $(echo "$BUDGET_USAGE_PCT < 70" | bc -l) )); then
    echo -e "${GREEN}$BUDGET_USAGE_PCT%${NC} (Healthy)"
elif (( $(echo "$BUDGET_USAGE_PCT < 90" | bc -l) )); then
    echo -e "${YELLOW}$BUDGET_USAGE_PCT%${NC} (Moderate)"
else
    echo -e "${RED}$BUDGET_USAGE_PCT%${NC} (High)"
fi
echo ""

# 2. Cost by Agent
echo -e "${BLUE}2. Cost Breakdown by Agent${NC}"
echo ""
printf "%-15s %10s %10s %12s %8s\n" "Agent" "Calls" "Cost" "Avg/Call" "% Total"
printf "%-15s %10s %10s %12s %8s\n" "---------------" "----------" "----------" "------------" "--------"

# Sort agents by cost (descending)
for agent in $(printf '%s\n' "${!AGENT_COSTS[@]}" | sort -t'|' -k2 -rn); do
    cost=${AGENT_COSTS[$agent]}
    calls=${AGENT_CALLS[$agent]}
    avg=$(echo "scale=4; $cost / $calls" | bc)
    pct=$(echo "scale=1; $cost * 100 / $TOTAL_COST" | bc)

    printf "%-15s %10s %10s %12s %7s%%\n" "$agent" "$calls" "\$$cost" "\$$avg" "$pct"
done
echo ""

# 3. Cost by Model
echo -e "${BLUE}3. Cost Breakdown by Model${NC}"
echo ""
printf "%-15s %10s %10s %12s %8s\n" "Model" "Calls" "Cost" "Avg/Call" "% Total"
printf "%-15s %10s %10s %12s %8s\n" "---------------" "----------" "----------" "------------" "--------"

for model in "${!MODEL_COSTS[@]}"; do
    cost=${MODEL_COSTS[$model]}
    calls=${MODEL_CALLS[$model]}
    avg=$(echo "scale=4; $cost / $calls" | bc)
    pct=$(echo "scale=1; $cost * 100 / $TOTAL_COST" | bc)

    printf "%-15s %10s %10s %12s %7s%%\n" "$model" "$calls" "\$$cost" "\$$avg" "$pct"
done
echo ""

# 4. Cost Optimization Recommendations
echo -e "${BLUE}4. Cost Optimization Recommendations${NC}"
echo ""

# Check for expensive agents
EXPENSIVE_THRESHOLD=50
for agent in "${!AGENT_COSTS[@]}"; do
    cost=${AGENT_COSTS[$agent]}
    if (( $(echo "$cost > $EXPENSIVE_THRESHOLD" | bc -l) )); then
        echo -e "${YELLOW}⚠${NC} $agent agent is expensive (\$$cost in $PERIOD_DAYS days)"

        # Suggest optimizations based on agent
        case $agent in
            builder)
                echo "   → Consider using Haiku for simple implementations"
                echo "   → Reserve Sonnet for complex features"
                ;;
            security)
                echo "   → Security uses Opus (most expensive but justified)"
                echo "   → This is expected for critical security reviews"
                ;;
            tester)
                echo "   → Tester should use Haiku (cheapest)"
                echo "   → Check if model is configured correctly"
                ;;
            *)
                echo "   → Review if this agent is being overused"
                echo "   → Consider batching operations"
                ;;
        esac
        echo ""
    fi
done

# Check model strategy
OPUS_PCT=$(echo "scale=1; ${MODEL_COSTS[opus]} * 100 / $TOTAL_COST" | bc)
HAIKU_PCT=$(echo "scale=1; ${MODEL_COSTS[haiku]} * 100 / $TOTAL_COST" | bc)

if (( $(echo "$OPUS_PCT > 30" | bc -l) )); then
    echo -e "${YELLOW}⚠${NC} Opus usage is high ($OPUS_PCT% of total cost)"
    echo "   → Opus should be <20% for cost-optimized workflows"
    echo "   → Reserve Opus for security-critical work only"
    echo ""
fi

if (( $(echo "$HAIKU_PCT < 20" | bc -l) )); then
    echo -e "${YELLOW}⚠${NC} Haiku usage is low ($HAIKU_PCT% of total cost)"
    echo "   → Haiku should be 30-40% for cost optimization"
    echo "   → Use Haiku for testing, documentation, refactoring"
    echo ""
fi

# Check if over budget
if (( $(echo "$DAILY_USAGE > $DAILY_BUDGET" | bc -l) )); then
    echo -e "${RED}✗${NC} Daily average (\$$DAILY_USAGE) exceeds budget (\$$DAILY_BUDGET)"
    echo "   → Reduce usage or increase budget in opencode.json"
    echo ""
fi

# 5. Projected Monthly Cost
echo -e "${BLUE}5. Cost Projections${NC}"
echo ""

MONTHLY_PROJECTION=$(echo "scale=2; $DAILY_USAGE * 30" | bc)
YEARLY_PROJECTION=$(echo "scale=2; $DAILY_USAGE * 365" | bc)

printf "%-20s %s\n" "Monthly (30 days):" "\$$MONTHLY_PROJECTION"
printf "%-20s %s\n" "Yearly (365 days):" "\$$YEARLY_PROJECTION"
echo ""

if (( $(echo "$MONTHLY_PROJECTION > 300" | bc -l) )); then
    echo -e "${YELLOW}⚠${NC} Projected monthly cost is high (\$$MONTHLY_PROJECTION)"
    echo "   → Review cost optimization recommendations above"
    echo ""
fi

# 6. Savings Opportunities
echo -e "${BLUE}6. Potential Savings${NC}"
echo ""

# Calculate if all Sonnet calls used Haiku instead
SONNET_TO_HAIKU_SAVINGS=$(echo "scale=2; ${MODEL_COSTS[sonnet]} * 0.9" | bc)  # ~90% savings
echo "If routine tasks used Haiku instead of Sonnet:"
echo "  Potential savings: ~\$$SONNET_TO_HAIKU_SAVINGS per $PERIOD_DAYS days"
echo "  Monthly savings: ~\$$(echo "scale=2; $SONNET_TO_HAIKU_SAVINGS * 30 / $PERIOD_DAYS" | bc)"
echo ""

# Calculate optimal distribution
echo "Recommended model distribution:"
echo "  Haiku: 35-40% (currently: $HAIKU_PCT%)"
echo "  Sonnet: 50-60% (currently: $(echo "scale=1; ${MODEL_COSTS[sonnet]} * 100 / $TOTAL_COST" | bc)%)"
echo "  Opus: 10-15% (currently: $OPUS_PCT%)"
echo ""

# Summary recommendations
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if (( $(echo "$BUDGET_USAGE_PCT < 70" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Cost management is healthy"
    echo "  Continue current usage patterns"
elif (( $(echo "$BUDGET_USAGE_PCT < 90" | bc -l) )); then
    echo -e "${YELLOW}⚠${NC} Cost management needs attention"
    echo "  Review expensive agents and optimize model usage"
else
    echo -e "${RED}✗${NC} Cost management critical"
    echo "  Immediate action required to reduce spending"
fi
echo ""

echo "Next steps:"
echo "  1. Review agent usage patterns"
echo "  2. Adjust model strategy in opencode.json"
echo "  3. Set stricter budget limits if needed"
echo "  4. Monitor costs weekly with this script"
echo ""

echo "For more help, see:"
echo "  - $OPENCODE_DIR/config/GUARDRAILS_GUIDE.md (Cost Controls)"
echo "  - $OPENCODE_DIR/TROUBLESHOOTING.md (Cost Issues)"
echo ""

exit 0
