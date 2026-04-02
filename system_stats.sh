#!/bin/bash

# ===============================================
# Linux Guardian - System Statistics Module
# Monitors CPU, Memory, Disk, Load Average
# ===============================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.conf"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'
}

# Function to get Memory usage
get_memory_usage() {
    free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}'
}

# Function to get Disk usage
get_disk_usage() {
    df -h / | tail -1 | sed 's/%//' | awk '{print $5}'
}

# Function to get Load Average
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
}

# Function to get Process Count
get_process_count() {
    ps aux | wc -l
}

# Function to get Uptime
get_uptime() {
    uptime -p 2>/dev/null || uptime | awk '{print $3,$4}' | sed 's/,//'
}

# Function to get Running Processes
get_running_processes() {
    ps aux | grep -v grep | grep -c "Running\|S\|R"
}

# Function to create progress bar
progress_bar() {
    local percent=$1
    local bars=$((percent / 5))
    local spaces=$((20 - bars))
    printf "█%.0s" $(seq 1 $bars)
    printf "░%.0s" $(seq 1 $spaces)
}

# Function to check thresholds and alert
check_thresholds() {
    local cpu=$1
    local mem=$2
    local disk=$3
    local load=$4

    local alert=false

    # CPU Check
    if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        echo "HIGH CPU: ${cpu}%" >> "$LOG_DIR/$LOG_SYSTEM" 2>/dev/null || true
        alert=true
    fi

    # Memory Check
    if [ "$mem" -gt "$MEMORY_THRESHOLD" ]; then
        echo "HIGH MEMORY: ${mem}%" >> "$LOG_DIR/$LOG_SYSTEM" 2>/dev/null || true
        alert=true
    fi

    # Disk Check
    if [ "$disk" -gt "$DISK_THRESHOLD" ]; then
        echo "HIGH DISK: ${disk}%" >> "$LOG_DIR/$LOG_SYSTEM" 2>/dev/null || true
        alert=true
    fi

    # Load Average Check
    local load_int=$(echo "$load" | cut -d'.' -f1)
    if [ "$load_int" -gt "$LOAD_AVG_THRESHOLD" ]; then
        echo "HIGH LOAD: $load" >> "$LOG_DIR/$LOG_SYSTEM" 2>/dev/null || true
        alert=true
    fi

    if [ "$alert" = true ]; then
        # Trigger alert if alert.sh exists
        if [ -f "$SCRIPT_DIR/alert.sh" ]; then
            bash "$SCRIPT_DIR/alert.sh" "System Alert: High resource usage detected"
        fi
    fi
}

# Function to display stats (non-dashboard mode)
display_stats() {
    cpu=$(get_cpu_usage)
    mem=$(get_memory_usage)
    disk=$(get_disk_usage)
    load=$(get_load_average)
    procs=$(get_process_count)
    uptime=$(get_uptime)
    running=$(get_running_processes)

    echo "==============================================="
    echo "         LINUX GUARDIAN - SYSTEM STATS        "
    echo "==============================================="
    echo "  CPU Usage:     ${cpu}%"
    echo "  Memory Usage: ${mem}%"
    echo "  Disk Usage:   ${disk}%"
    echo "  Load Average: $load"
    echo "  Processes:    $procs (Running: $running)"
    echo "  Uptime:       $uptime"
    echo "==============================================="

    # Check thresholds
    check_thresholds "$cpu" "$mem" "$disk" "$load"
}

# Function for dashboard mode - outputs JSON
get_stats_json() {
    cpu=$(get_cpu_usage)
    mem=$(get_memory_usage)
    disk=$(get_disk_usage)
    load=$(get_load_average)
    procs=$(get_process_count)
    uptime=$(get_uptime)
    running=$(get_running_processes)

    # Check thresholds
    check_thresholds "$cpu" "$mem" "$disk" "$load"

    # Output as JSON for dashboard
    cat <<EOF
{"cpu":"$cpu","memory":"$mem","disk":"$disk","load":"$load","processes":"$procs","running":"$running","uptime":"$uptime"}
EOF
}

# Main execution
case "${1:-stats}" in
    --json)
        get_stats_json
        ;;
    *)
        display_stats
        ;;
esac