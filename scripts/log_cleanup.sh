#!/bin/bash
#
# Purpose: Compress log files older than 7 days.
# Author: RAKSHITH
# Date: 2026-10-19
# Usage: ./log_cleanup.sh [--dry-run]
#

set -euo pipefail

# Locate the assignment directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASSIGNMENT_DIR="$(dirname -- "$SCRIPT_DIR")"
CONFIG_FILE="$ASSIGNMENT_DIR/config/app.conf"

# Validate command-line arguments
DRY_RUN=false

if (( $# > 1 )); then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

if (( $# == 1 )); then
    if [[ "$1" == "--dry-run" ]]; then
        DRY_RUN=true
    else
        echo "Usage: $0 [--dry-run]" >&2
        exit 2
    fi
fi

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# app.conf must contain trusted shell variable assignments
# shellcheck disable=SC1090
source "$CONFIG_FILE"

if [[ -z "${LOG_DIR:-}" ]]; then
    echo "ERROR: LOG_DIR is not defined in app.conf" >&2
    exit 1
fi

# Resolve relative log paths from the assignment directory
if [[ "$LOG_DIR" != /* ]]; then
    LOG_DIR="$ASSIGNMENT_DIR/$LOG_DIR"
fi

if [[ ! -d "$LOG_DIR" ]]; then
    echo "ERROR: Log directory does not exist: $LOG_DIR" >&2
    exit 1
fi

echo "Log directory: $LOG_DIR"

# Find .log files older than 7 days
mapfile -d '' -t OLD_LOGS < <(
    find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' \
        -mmin +10080 -print0
)

if (( ${#OLD_LOGS[@]} == 0 )); then
    echo "No .log files older than 7 days found."
    echo "Files compressed: 0"
    exit 0
fi

# Dry run: list candidates without changing files
if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN: The following files would be compressed:"
    printf '  %s\n' "${OLD_LOGS[@]}"
    echo "Files that would be compressed: ${#OLD_LOGS[@]}"
    exit 0
fi

# Compress eligible files
COMPRESSED=0

for FILE in "${OLD_LOGS[@]}"; do
    if gzip -- "$FILE"; then
        echo "[OK] Compressed: $(basename -- "$FILE")"
        ((COMPRESSED += 1))
    else
        echo "[FAIL] Could not compress: $FILE" >&2
    fi
done

echo "Files compressed: $COMPRESSED"
