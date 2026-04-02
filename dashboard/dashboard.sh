#!/bin/bash

# ===============================================
# Linux Guardian - Terminal Dashboard
# Real-time visual monitoring dashboard
# ===============================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.conf"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Box drawing characters
TOP_LEFT="╔"
TOP_RIGHT="╗"
BOTTOM_LEFT="╚"
BOTTOM_RIGHT="╝"
HORIZONTAL="═"
VERTICAL="║"
T_LEFT="╠"
T_RIGHT="╣"
T_UP="╦"
T_DOWN="╩"
CROSS="╬"

# Function to get system stats
get_system_stats() {
    # CPU
    cpu=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
    [ -z "$cpu" ] && cpu=0

    # Memory
    mem=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')

    # Disk
    disk=$(df -h / | tail -1 | sed 's/%//' | awk '{print $5}')

    # Load
    load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

    # Processes
    procs=$(ps aux | wc -l)
    procs=$((procs - 1))

    # Uptime
    uptime=$(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}' | sed 's/,//')

    # Running
    running=$(ps aux | grep -c " R " | head -1)
    [ -z "$running" ] && running=0
}

# Function to get security stats
get_security_stats() {
    # Failed logins
    if [ -f /var/log/secure ]; then
        failed_logins=$(grep -c "Failed password" /var/log/secure 2>/dev/null | tail -1)
    elif [ -f /var/log/auth.log ]; then
        failed_logins=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null | tail -1)
    else
        failed_logins=0
    fi
    [ -z "$failed_logins" ] && failed_logins=0

    # Last login
    last_login=$(last -1 | head -1 | awk '{print $1, $3, $4, $5}')

    # Active connections
    connections=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)

    # Suspicious processes
    suspicious_list="netcat|nc |nmap|socat|pentestmonkey|metasploit|nikto|sqlmap|hydra|john|hashcat"
    suspicious_procs=$(ps aux | grep -iE "$suspicious_list" | grep -v grep | wc -l)
}

# Function to create progress bar
create_bar() {
    local percent=$1
    local color=$2

    local bars=$((percent / 5))
    [ $bars -gt 20 ] && bars=20

    local printf_string="${color}"
    for ((i=0; i<bars; i++)); do
        printf_string+="█"
    done

    local spaces=$((20 - bars))
    for ((i=0; i<spaces; i++)); do
        printf_string+="░"
    done

    printf_string+="${NC}"

    echo -ne "$printf_string"
}

# Function to get status color based on value
get_status_color() {
    local value=$1
    local threshold=$2

    if [ "$value" -ge "$threshold" ]; then
        echo -e "$RED"
    elif [ "$value" -ge $((threshold - 15)) ]; then
        echo -e "$YELLOW"
    else
        echo -e "$GREEN"
    fi
}

# Function to draw the dashboard
draw_dashboard() {
    clear

    # Header
    echo -e "${CYAN}${TOP_LEFT}${HORIZONTAL}══════════════════════════════════════════════════════════════════════${TOP_RIGHT}${NC}"
    echo -e "${CYAN}${VERTICAL}                                                                          ${VERTICAL}${NC}"
    echo -e "${CYAN}${VERTICAL}                    ${BOLD}${WHITE}🔒 LINUX GUARDIAN MONITORING DASHBOARD                    ${NC}${CYAN}${VERTICAL}${NC}"
    echo -e "${CYAN}${VERTICAL}                                                                          ${VERTICAL}${NC}"
    echo -e "${CYAN}${T_LEFT}${HORIZONTAL}══════════════════════════════════════════════════════════════════════${T_RIGHT}${NC}"

    # System Status Section
    echo -e "${CYAN}${VERTICAL}  ${BOLD}SYSTEM STATUS${NC}                                                            ${VERTICAL}${NC}"
    echo -e "${CYAN}${VERTICAL}  ─────────────────                                                            ${VERTICAL}${NC}"

    # CPU
    cpu_color=$(get_status_color "$cpu" "$CPU_THRESHOLD")
    echo -ne "${CYAN}${VERTICAL}  CPU:      "
    create_bar "$cpu" "$cpu_color"
    echo -e " ${cpu_color}${cpu}%${NC}"

    # Memory
    mem_color=$(get_status_color "$mem" "$MEMORY_THRESHOLD")
    echo -ne "${CYAN}${VERTICAL}  Memory:   "
    create_bar "$mem" "$mem_color"
    echo -e " ${mem_color}${mem}%${NC}"

    # Disk
    disk_color=$(get_status_color "$disk" "$DISK_THRESHOLD")
    echo -ne "${CYAN}${VERTICAL}  Disk:     "
    create_bar "$disk" "$disk_color"
    echo -e " ${disk_color}${disk}%${NC}"

    # Load
    load_color=$(get_status_color "${load%.*}" "$LOAD_AVG_THRESHOLD")
    echo -e "${CYAN}${VERTICAL}  Load:     ${load_color}$load${NC}  ${CYAN}(Threshold: $LOAD_AVG_THRESHOLD)${NC}"

    echo -e "${CYAN}${VERTICAL}                                                                          ${VERTICAL}${NC}"

    # Info Section
    echo -e "${CYAN}${VERTICAL}  Processes: ${WHITE}$procs${NC}   |   Running: ${WHITE}$running${NC}   |   Uptime: ${WHITE}$uptime${NC}    ${VERTICAL}${NC}"
    echo -e "${CYAN}${VERTICAL}                                                                          ${VERTICAL}${NC}"

    # Separator
    echo -e "${CYAN}${T_LEFT}${HORIZONTAL}══════════════════════════════════════════════════════════════════════${T_RIGHT}${NC}"

    # Security Status Section
    echo -e "${CYAN}${VERTICAL}  ${BOLD}SECURITY STATUS${NC}                                                          ${VERTICAL}${NC}"
    echo -e "${CYAN}${VERTICAL}  ──────────────────                                                          ${VERTICAL}${NC}"

    # Failed Logins
    if [ "$failed_logins" -gt "$FAILED_LOGIN_THRESHOLD" ]; then
        echo -e "${CYAN}${VERTICAL}  Failed Logins: ${RED}$failed_logins ⚠️${NC}  ${CYAN}(Exceeds threshold!)${NC}                 ${VERTICAL}${NC}"
    else
        echo -e "${CYAN}${VERTICAL}  Failed Logins: ${GREEN}$failed_logins ✓${NC}  ${CYAN}(OK)${NC}                                          ${VERTICAL}${NC}"
    fi

    # Last Login
    echo -e "${CYAN}${VERTICAL}  Last Login:   ${WHITE}$last_login${NC}                                      ${VERTICAL}${NC}"

    # Connections
    if [ "$connections" -gt 50 ]; then
        echo -e "${CYAN}${VERTICAL}  Connections:  ${YELLOW}$connections${NC}  ${CYAN}(Moderate)${NC}                                      ${VERTICAL}${NC}"
    else
        echo -e "${CYAN}${VERTICAL}  Connections:  ${GREEN}$connections${NC}  ${CYAN}(OK)${NC}                                              ${VERTICAL}${NC}"
    fi

    # Suspicious Processes
    if [ "$suspicious_procs" -gt 0 ]; then
        echo -e "${CYAN}${VERTICAL}  Suspicious:   ${RED}$suspicious_procs ⚠️${NC}  ${CYAN}(ALERT!)${NC}                                        ${VERTICAL}${NC}"
    else
        echo -e "${CYAN}${VERTICAL}  Suspicious:   ${GREEN}None ✓${NC}                                             ${VERTICAL}${NC}"
    fi

    echo -e "${CYAN}${VERTICAL}                                                                          ${VERTICAL}${NC}"

    # Footer
    echo -e "${CYAN}${T_LEFT}${HORIZONTAL}══════════════════════════════════════════════════════════════════════${T_RIGHT}${NC}"
    echo -e "${CYAN}${VERTICAL}  Press ${WHITE}Ctrl+C${NC} to exit   |   Refresh: ${WHITE}${REFRESH_INTERVAL}s${NC}   |   Linux Guardian v1.0  ${VERTICAL}${NC}"
    echo -e "${CYAN}${BOTTOM_LEFT}${HORIZONTAL}══════════════════════════════════════════════════════════════════════${BOTTOM_RIGHT}${NC}"
}

# Function to check alerts and send notifications
check_alerts() {
    # Check CPU
    if [ "$cpu" -gt "$CPU_THRESHOLD" ]; then
        [ -f "$SCRIPT_DIR/alert.sh" ] && bash "$SCRIPT_DIR/alert.sh" "High CPU Usage" "CPU at ${cpu}%"
    fi

    # Check Memory
    if [ "$mem" -gt "$MEMORY_THRESHOLD" ]; then
        [ -f "$SCRIPT_DIR/alert.sh" ] && bash "$SCRIPT_DIR/alert.sh" "High Memory Usage" "Memory at ${mem}%"
    fi

    # Check Disk
    if [ "$disk" -gt "$DISK_THRESHOLD" ]; then
        [ -f "$SCRIPT_DIR/alert.sh" ] && bash "$SCRIPT_DIR/alert.sh" "High Disk Usage" "Disk at ${disk}%"
    fi
}

# Main loop
main() {
    # Check for --once flag
    if [ "$1" = "--once" ]; then
        get_system_stats
        get_security_stats
        draw_dashboard
        echo ""
        exit 0
    fi

    echo -e "${BLUE}[*] Starting Linux Guardian Dashboard...${NC}"
    echo -e "${BLUE}[*] Press Ctrl+C to exit${NC}"
    sleep 1

    while true; do
        get_system_stats
        get_security_stats
        draw_dashboard
        check_alerts
        sleep "$REFRESH_INTERVAL"
    done
}

# Run main
main "$@"