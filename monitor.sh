#!/bin/bash

# ===============================================
# Linux Guardian - Main Orchestration Script
# Entry point for all monitoring features
# ===============================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Print usage
usage() {
    echo -e "${CYAN}Linux Guardian - Usage:${NC}"
    echo ""
    echo "  $0 --dashboard         # Run visual dashboard (recommended)"
    echo "  $0 --monitor           # Run in background monitoring mode"
    echo "  $0 --system            # Check system stats only"
    echo "  $0 --security          # Run security scan only"
    echo "  $0 --test              # Send test alert"
    echo "  $0 --help              # Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --dashboard         # Start the visual dashboard"
    echo "  $0 --system            # Get system stats once"
    echo "  $0 --security          # Run security check once"
}

# Check requirements
check_requirements() {
    echo -e "${BLUE}[*] Checking requirements...${NC}"

    local missing=0

    # Check for required commands
    local required_cmds="top free df ps grep awk sed netstat mail"

    for cmd in $required_cmds; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${YELLOW}[!] Missing: $cmd${NC}"
            missing=1
        fi
    done

    if [ $missing -eq 1 ]; then
        echo -e "${YELLOW}[!] Some commands missing. Install coreutils:${NC}"
        echo "  sudo apt install procps net-tools mailutils"
    fi

    # Create logs directory
    mkdir -p "$SCRIPT_DIR/logs"

    echo -e "${GREEN}[✓] Requirements checked${NC}"
}

# Run dashboard mode
run_dashboard() {
    check_requirements

    if [ -f "$SCRIPT_DIR/dashboard/dashboard.sh" ]; then
        bash "$SCRIPT_DIR/dashboard/dashboard.sh"
    else
        echo -e "${RED}[!] Dashboard not found!${NC}"
        exit 1
    fi
}

# Run monitor mode (background with logging)
run_monitor() {
    check_requirements

    echo -e "${BLUE}[*] Starting background monitor...${NC}"
    echo -e "${YELLOW}[!] This mode runs continuous monitoring in foreground (Ctrl+C to stop)${NC}"
    echo ""

    source "$SCRIPT_DIR/config.conf"

    while true; do
        echo "========================================"
        echo "Run: $(date)"
        echo "========================================"

        # Run system stats
        bash "$SCRIPT_DIR/system_stats.sh"
        echo ""

        # Run security check
        bash "$SCRIPT_DIR/ids.sh"
        echo ""

        sleep 60
    done
}

# Run system stats only
run_system() {
    check_requirements
    bash "$SCRIPT_DIR/system_stats.sh"
}

# Run security check only
run_security() {
    check_requirements
    bash "$SCRIPT_DIR/ids.sh"
}

# Run test alert
run_test() {
    if [ -f "$SCRIPT_DIR/alert.sh" ]; then
        bash "$SCRIPT_DIR/alert.sh" --test
    else
        echo -e "${RED}[!] Alert script not found!${NC}"
        exit 1
    fi
}

# Main
case "${1:-}" in
    --dashboard|-d)
        run_dashboard
        ;;
    --monitor|-m)
        run_monitor
        ;;
    --system|-s)
        run_system
        ;;
    --security|--ids)
        run_security
        ;;
    --test|-t)
        run_test
        ;;
    --help|-h)
        usage
        ;;
    *)
        usage
        echo ""
        echo -e "${GREEN}Try: $0 --dashboard${NC}"
        ;;
esac