#!/bin/bash

# ===============================================
# Linux Guardian - Intrusion Detection System
# Monitors failed logins, suspicious processes,
# unusual network activity, rootkits
# ===============================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.conf"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize log directory
mkdir -p "$LOG_DIR" 2>/dev/null

# Function to check failed login attempts
check_failed_logins() {
    echo -e "${BLUE}[*] Checking failed login attempts...${NC}"

    # Check for failed logins from secure log
    if [ -f /var/log/secure ]; then
        failed_logins=$(grep -c "Failed password" /var/log/secure 2>/dev/null | tail -1)
    elif [ -f /var/log/auth.log ]; then
        failed_logins=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null | tail -1)
    else
        failed_logins=0
    fi

    if [ -z "$failed_logins" ]; then
        failed_logins=0
    fi

    if [ "$failed_logins" -gt "$FAILED_LOGIN_THRESHOLD" ]; then
        echo -e "${RED}[!] ALERT: $failed_logins failed login attempts detected!${NC}"
        echo "ALERT: $failed_logins failed login attempts" >> "$LOG_DIR/$LOG_IDS" 2>/dev/null || true

        # Trigger alert
        if [ -f "$SCRIPT_DIR/alert.sh" ]; then
            bash "$SCRIPT_DIR/alert.sh" "SECURITY ALERT: $failed_logins failed login attempts detected!"
        fi
    else
        echo -e "${GREEN}[✓] Failed logins: $failed_logins (OK)${NC}"
    fi
}

# Function to check suspicious processes
check_suspicious_processes() {
    echo -e "${BLUE}[*] Checking suspicious processes...${NC}"

    # Check for known suspicious processes
    suspicious_found=false

    # Common backdoor/attack tools
    suspicious_list="netcat|nc |nmap|socat|pentestmonkey|地下|powershell|msfvenom|veil|metasploit|nikto|sqlmap|hydra|john|hashcat|Responder|Impacket"

    suspicious_procs=$(ps aux | grep -iE "$suspicious_list" | grep -v grep | grep -v "$$" || true)

    if [ -n "$suspicious_procs" ]; then
        echo -e "${RED}[!] ALERT: Suspicious processes detected!${NC}"
        echo "$suspicious_procs" | tee -a "$LOG_DIR/$LOG_IDS" 2>/dev/null || true
        suspicious_found=true

        if [ -f "$SCRIPT_DIR/alert.sh" ]; then
            bash "$SCRIPT_DIR/alert.sh" "SECURITY ALERT: Suspicious processes detected!"
        fi
    else
        echo -e "${GREEN}[✓] No suspicious processes found${NC}"
    fi
}

# Function to check unusual network connections
check_unusual_network() {
    echo -e "${BLUE}[*] Checking unusual network connections...${NC}"

    # Check for listening ports
    echo -e "${YELLOW}[*] Active network ports:${NC}"
    netstat -tuln 2>/dev/null | grep LISTEN | head -10

    # Check for established connections to suspicious ports
    suspicious_ports="31337|1337|6666|6667|12345|54321"
    unusual_conns=$(netstat -an 2>/dev/null | grep ESTABLISHED | grep -iE "$suspicious_ports" || true)

    if [ -n "$unusual_conns" ]; then
        echo -e "${RED}[!] ALERT: Unusual connections detected!${NC}"
        echo "$unusual_conns" >> "$LOG_DIR/$LOG_IDS" 2>/dev/null || true
    else
        echo -e "${GREEN}[✓] Network connections look normal${NC}"
    fi

    # Check for suspicious foreign IPs
    echo -e "${BLUE}[*] Checking active connections...${NC}"
    netstat -an 2>/dev/null | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort -u | head -10
}

# Function to check last logins
check_last_logins() {
    echo -e "${BLUE}[*] Recent login attempts:${NC}"
    last -10 2>/dev/null | head -10 || echo "Cannot access login records"
}

# Function to check for rootkits (basic check)
check_rootkits_basic() {
    echo -e "${BLUE}[*] Running basic rootkit checks...${NC}"

    # Check for hidden processes
    hidden_procs=$(ps aux | awk '{print $11}' | grep "^/" | sort | uniq -c | sort -rn | head -5)

    if [ -n "$hidden_procs" ]; then
        echo -e "${YELLOW}[*] Top processes by memory:${NC}"
        ps aux --sort=-%mem | head -6
    fi

    # Check for suspicious files in /tmp
    suspicious_files=$(find /tmp -name "*.sh" -o -name "nc*" -o -name "*backdoor*" 2>/dev/null | head -5 || true)

    if [ -n "$suspicious_files" ]; then
        echo -e "${YELLOW}[!] Warning: Suspicious files in /tmp:${NC}"
        echo "$suspicious_files" | tee -a "$LOG_DIR/$LOG_IDS"
    else
        echo -e "${GREEN}[✓] No suspicious files in /tmp${NC}"
    fi
}

# Function to check user account changes
check_user_changes() {
    echo -e "${BLUE}[*] Checking for new user accounts...${NC}"

    if [ -f /var/log/secure ]; then
        new_users=$(grep -i "new user\|useradd" /var/log/secure 2>/dev/null | tail -5 || true)
        if [ -n "$new_users" ]; then
            echo -e "${YELLOW}[!] Recent user account changes:${NC}"
            echo "$new_users"
        else
            echo -e "${GREEN}[✓] No new user accounts${NC}"
        fi
    fi
}

# Function to check sudo attempts
check_sudo_attempts() {
    echo -e "${BLUE}[*] Checking sudo attempts...${NC}"

    if [ -f /var/log/secure ]; then
        sudo_attempts=$(grep -c "sudo:.*COMMAND=" /var/log/secure 2>/dev/null | tail -1 || echo "0")

        if [ -z "$sudo_attempts" ]; then
            sudo_attempts=0
        fi

        echo -e "${YELLOW}[*] Total sudo commands executed: $sudo_attempts${NC}"

        # Show recent sudo commands
        recent_sudo=$(grep "sudo:.*COMMAND=" /var/log/secure 2>/dev/null | tail -5 || true)
        if [ -n "$recent_sudo" ]; then
            echo -e "${BLUE}[*] Recent sudo commands:${NC}"
            echo "$recent_sudo" | awk '{print $NF}' | tail -5
        fi
    fi
}

# Main IDS check function
run_ids_check() {
    echo "=============================================="
    echo "     LINUX GUARDIAN - SECURITY SCAN         "
    echo "=============================================="
    echo ""

    if [ "$CHECK_FAILED_LOGINS" = true ]; then
        check_failed_logins
        echo ""
    fi

    if [ "$CHECK_SUSPICIOUS_PROCESSES" = true ]; then
        check_suspicious_processes
        echo ""
    fi

    if [ "$CHECK_UNUSUAL_PORTS" = true ]; then
        check_unusual_network
        echo ""
    fi

    check_last_logins
    echo ""

    if [ "$CHECK_ROOTKITS" = true ]; then
        check_rootkits_basic
        echo ""
    fi

    check_user_changes
    echo ""

    check_sudo_attempts
    echo ""

    echo "=============================================="
    echo "          SECURITY SCAN COMPLETE            "
    echo "=============================================="
}

# JSON output for dashboard
get_ids_json() {
    # Get failed login count
    if [ -f /var/log/secure ]; then
        failed_logins=$(grep -c "Failed password" /var/log/secure 2>/dev/null | tail -1)
    elif [ -f /var/log/auth.log ]; then
        failed_logins=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null | tail -1)
    else
        failed_logins=0
    fi

    [ -z "$failed_logins" ] && failed_logins=0

    # Get suspicious process count
    suspicious_list="netcat|nc |nmap|socat|pentestmonkey|metasploit|nikto|sqlmap|hydra|john|hashcat"
    suspicious_count=$(ps aux | grep -iE "$suspicious_list" | grep -v grep | wc -l)

    # Get last login
    last_login=$(last -1 | head -1)

    # Get connection count
    conn_count=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)

    cat <<EOF
{"failed_logins":"$failed_logins","suspicious_procs":"$suspicious_count","last_login":"$last_login","connections":"$conn_count"}
EOF
}

# Main execution
case "${1:-check}" in
    --json)
        get_ids_json
        ;;
    *)
        run_ids_check
        ;;
esac