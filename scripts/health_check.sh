#!/bin/bash
#
# Purpose: Check systemd service health and log each result.
# Author: Your Name
# Date: 2026-10-19
# Usage: ./health_check.sh service1 [service2 ...]
#

set -euo pipefail

# Require at least one service argument
if (( $# == 0 )); then
    echo "Usage: $0 service1 [service2 ...]" >&2
    exit 2
fi

# Locate the assignment directory relative to this script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASSIGNMENT_DIR="$(dirname -- "$SCRIPT_DIR")"
LOG_DIR="$ASSIGNMENT_DIR/webapp/logs"
LOG_FILE="$LOG_DIR/health.log"

# Create the log directory if it does not exist
mkdir -p "$LOG_DIR"

# Track whether every service is healthy
ALL_HEALTHY=true

# Check each service supplied as an argument
for SERVICE in "$@"; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    if systemctl is-active --quiet "$SERVICE"; then
        RESULT="[OK]"
        MESSAGE="$TIMESTAMP $RESULT $SERVICE is active"
    else
        RESULT="[FAIL]"
        MESSAGE="$TIMESTAMP $RESULT $SERVICE is not active"
        ALL_HEALTHY=false
    fi

    # Display and append the result
    echo "$MESSAGE"
    echo "$MESSAGE" >> "$LOG_FILE"
done

# Return the required exit code
if [[ "$ALL_HEALTHY" == true ]]; then
    exit 0
else
    exit 1
fi
