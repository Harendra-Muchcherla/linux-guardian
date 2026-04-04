# Linux Guardian 🔒

A comprehensive Linux monitoring and security dashboard that tracks system resources, detects intrusions, and sends email alerts.

## Features

- **System Monitoring**: CPU, Memory, Disk, Load Average
- **Intrusion Detection**: Failed logins, suspicious processes, unusual network activity
- **Real-time Dashboard**: Terminal-based visual dashboard with colored output
- **Email Alerts**: Instant notifications when thresholds exceeded or threats detected

## Quick Start

```bash
# Clone or download this project
cd linux-guardian

# Edit config.conf with your email settings
nano config.conf

# Run the dashboard
./monitor.sh --dashboard

# Or run in monitor mode (no dashboard, just logging)
./monitor.sh --monitor
```

## Requirements

```bash
# Install required tools
sudo apt update
sudo apt install mailutils htop sysstat net-tools
```

## Project Structure

```
linux-guardian/
├── config.conf          # Configuration settings
├── monitor.sh          # Main orchestration script
├── system_stats.sh     # CPU/RAM/Disk monitoring
├── ids.sh              # Intrusion detection system
├── alert.sh            # Email alerting
├── dashboard/
│   └── dashboard.sh    # Terminal dashboard
├── logs/               # Log files
└── README.md
```

## Usage

### Dashboard Mode (Recommended)
```bash
./monitor.sh --dashboard
```

### Monitor Mode (Background)
```bash
./monitor.sh --monitor
```

### Check System Stats Once
```bash
./system_stats.sh
```

### Run IDS Check
```bash
./ids.sh
```

## Configuration

Edit `config.conf` to customize:

- Email settings for alerts
- CPU/Memory/Disk threshold percentages
- Process monitoring rules
- Network port monitoring
- Log file locations

## Dashboard Preview

```
╔════════════════════════════════════════════════════════════╗
║            LINUX GUARDIAN MONITORING DASHBOARD            ║
╠════════════════════════════════════════════════════════════╣
║  SYSTEM STATUS                    SECURITY STATUS        ║
║  ──────────────                   ──────────────          ║
║  CPU:     ████████████░░ 75%     Last Login: user        ║
║  Memory:  ██████████████ 88%     Failed Logins: 0       ║
║  Disk:    ████████░░░░░░ 45%     Suspicious: None       ║
║  Load:    2.45                       Network: OK        ║
║                                                            ║
║  Uptime:  15 days, 3 hours    Processes: 342             ║
╚════════════════════════════════════════════════════════════╝
```

## Security Checks

Linux Guardian checks for:

1. **Failed Login Attempts** - brute force detection
2. **Suspicious Processes** - netcat, nmap, backdoors
3. **Unusual Network Connections** - suspicious ports
4. **Rootkit Indicators** - known malware patterns
