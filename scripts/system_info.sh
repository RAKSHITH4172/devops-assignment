#!/bin/bash
#
# Purpose: Display system information and warn about high disk usage.
# Author: Your Name
# Date: 2026-10-19
# Usage: ./system_info.sh
#

set -euo pipefail

# Collect system information
HOSTNAME=$(hostname)
CURRENT_USER=$(whoami)
CURRENT_DATE=$(date '+%Y-%m-%d')
CURRENT_TIME=$(date '+%H:%M:%S')

OS_NAME=$(. /etc/os-release && echo "$PRETTY_NAME")
KERNEL_VERSION=$(uname -r)
UPTIME=$(uptime -p)
CPU_CORES=$(nproc)

# Memory information in MB
TOTAL_MEMORY=$(free -m | awk '/^Mem:/ {print $2}')
AVAILABLE_MEMORY=$(free -m | awk '/^Mem:/ {print $7}')

# Root disk usage percentage (remove the % sign for comparison)
DISK_USAGE=$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')

# Count unique logged-in usernames
LOGGED_IN_USERS=$(who | awk '{print $1}' | sort -u | wc -l)
LOGGED_IN_USERS=$(echo "$LOGGED_IN_USERS" | xargs)

# Display report
echo "========================================"
echo "       SYSTEM INFORMATION REPORT"
echo "========================================"
echo "Hostname             : $HOSTNAME"
echo "Current User         : $CURRENT_USER"
echo "Date                 : $CURRENT_DATE"
echo "Time                 : $CURRENT_TIME"
echo "Operating System     : $OS_NAME"
echo "Kernel Version       : $KERNEL_VERSION"
echo "Uptime               : $UPTIME"
echo "CPU Core Count       : $CPU_CORES"
echo "Total Memory         : ${TOTAL_MEMORY} MB"
echo "Available Memory     : ${AVAILABLE_MEMORY} MB"
echo "Root Disk Usage      : ${DISK_USAGE}%"
echo "Logged-in Users      : $LOGGED_IN_USERS"
echo "========================================"

# Warn if root disk usage is above 80%
if (( DISK_USAGE > 80 )); then
    echo "WARNING: Root disk usage is above 80%!"
fi
