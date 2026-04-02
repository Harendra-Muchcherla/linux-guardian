#!/bin/bash

# ===============================================
# Linux Guardian - Email Alert System
# Sends email alerts when issues detected
# ===============================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.conf"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if mail is configured
check_mail_config() {
    if [ "$ALERT_EMAIL" = "your-email@example.com" ]; then
        echo -e "${YELLOW}[!] Warning: Email not configured in config.conf${NC}"
        echo -e "${YELLOW}[!] Please set ALERT_EMAIL and other SMTP settings${NC}"
        return 1
    fi
    return 0
}

# Send email alert
send_alert() {
    local subject="$1"
    local message="$2"

    # Check mail configuration
    check_mail_config || return 1

    # Add timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname=$(hostname)

    # Build email body
    local email_body="
=====================================
     LINUX GUARDIAN ALERT
=====================================

Host: $hostname
Time: $timestamp

Alert: $subject

Message: $message

=====================================
This is an automated alert from
Linux Guardian monitoring system
=====================================
"

    # Try to send email
    echo -e "${RED}[!] Sending alert: $subject${NC}"

    # Method 1: Using mail command
    if command -v mail &> /dev/null; then
        echo "$email_body" | mail -s "[LINUX GUARDIAN] $subject" "$ALERT_EMAIL"
        echo -e "${GREEN}[✓] Alert sent successfully${NC}"
        return 0
    fi

    # Method 2: Using sendmail
    if command -v sendmail &> /dev/null; then
        echo -e "To: $ALERT_EMAIL
Subject: [LINUX GUARDIAN] $subject
$email_body" | sendmail -t
        echo -e "${GREEN}[✓] Alert sent successfully${NC}"
        return 0
    fi

    # Method 3: Using msmtp (common on modern systems)
    if command -v msmtp &> /dev/null; then
        echo -e "To: $ALERT_EMAIL
Subject: [LINUX GUARDIAN] $subject
$email_body" | msmtp "$ALERT_EMAIL"
        echo -e "${GREEN}[✓] Alert sent successfully${NC}"
        return 0
    fi

    # Method 4: Using ssmtp
    if command -v ssmtp &> /dev/null; then
        echo -e "To: $ALERT_EMAIL
Subject: [LINUX GUARDIAN] $subject
$email_body" | ssmtp "$ALERT_EMAIL"
        echo -e "${GREEN}[✓] Alert sent successfully${NC}"
        return 0
    fi

    # No mail utility found
    echo -e "${RED}[!] Error: No mail utility found${NC}"
    echo -e "${YELLOW}[!] Install mailutils: sudo apt install mailutils${NC}"
    echo -e "${YELLOW}[!] Or configure ssmtp/msmtp for external SMTP${NC}"

    # Log alert to file instead
    echo "[$timestamp] ALERT: $subject - $message" >> "$LOG_DIR/$LOG_ALERTS" 2>/dev/null || true
    return 1
}

# Send test email
send_test_alert() {
    echo -e "${BLUE}[*] Sending test alert...${NC}"
    send_alert "TEST ALERT" "This is a test alert from Linux Guardian"
}

# Quick alert (just prints to console and logs)
quick_alert() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "${RED}[!] ALERT: $message${NC}"

    # Log to file
    echo "[$timestamp] $message" >> "$LOG_DIR/$LOG_ALERTS" 2>/dev/null || true
}

# Main execution
case "${1:-test}" in
    --test)
        send_test_alert
        ;;
    *)
        if [ -n "$1" ]; then
            send_alert "$1" "${2:-System alert}"
        else
            echo "Usage: $0 [--test] [alert_subject] [alert_message]"
            echo ""
            echo "Examples:"
            echo "  $0 --test                    # Send test email"
            echo "  $0 'High CPU' 'CPU at 95%'  # Send custom alert"
        fi
        ;;
esac