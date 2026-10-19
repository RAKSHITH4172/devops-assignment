#!/bin/bash
#
# Purpose: Back up webapp configuration and application files.
# Author: Your Name
# Date: 2026-10-19
# Usage: ./backup.sh
#

set -euo pipefail

# Resolve paths relative to the assignment directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASSIGNMENT_DIR="$(dirname -- "$SCRIPT_DIR")"
CONFIG_FILE="$ASSIGNMENT_DIR/config/app.conf"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# app.conf must contain trusted shell variable assignments
# shellcheck disable=SC1090
source "$CONFIG_FILE"

if [[ -z "${BACKUP_DIR:-}" ]]; then
    echo "ERROR: BACKUP_DIR is not defined in app.conf" >&2
    exit 1
fi

if [[ -z "${LOG_DIR:-}" ]]; then
    echo "ERROR: LOG_DIR is not defined in app.conf" >&2
    exit 1
fi

# Resolve relative paths from the assignment directory
if [[ "$BACKUP_DIR" != /* ]]; then
    BACKUP_DIR="$ASSIGNMENT_DIR/$BACKUP_DIR"
fi

if [[ "$LOG_DIR" != /* ]]; then
    LOG_DIR="$ASSIGNMENT_DIR/$LOG_DIR"
fi

LOG_FILE="$LOG_DIR/backup.log"
SOURCE_CONFIG="$ASSIGNMENT_DIR/webapp/config"
SOURCE_APP="$ASSIGNMENT_DIR/webapp/app"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Log messages with timestamps
log_message() {
    local message="$1"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" \
        >> "$LOG_FILE"
}

# Record unexpected errors and exit
on_error() {
    local exit_code=$?
    trap - ERR
    log_message "FAILURE: Backup operation failed (exit code $exit_code)"
    echo "ERROR: Backup operation failed. See $LOG_FILE" >&2
    exit "$exit_code"
}
trap on_error ERR

# Validate backup sources
if [[ ! -d "$SOURCE_CONFIG" || ! -d "$SOURCE_APP" ]]; then
    log_message "FAILURE: Source directory missing"
    echo "ERROR: Required source directories not found." >&2
    exit 1
fi

# Generate a timestamped archive name
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
ARCHIVE="$BACKUP_DIR/webapp_backup_${TIMESTAMP}.tar.gz"

echo "Creating backup: $ARCHIVE"

# Create compressed archive from the assignment directory
tar -czf "$ARCHIVE" -C "$ASSIGNMENT_DIR" \
    webapp/config webapp/app

# Verify the archive and count entries
tar -tzf "$ARCHIVE" > /dev/null
FILE_COUNT="$(tar -tzf "$ARCHIVE" | wc -l)"
FILE_COUNT="$(echo "$FILE_COUNT" | xargs)"

echo "Archive verified successfully."
echo "Files and directory entries in archive: $FILE_COUNT"

# Keep only the newest 3 timestamped backup archives
mapfile -t BACKUPS < <(
    find "$BACKUP_DIR" -maxdepth 1 -type f \
        -name 'webapp_backup_*.tar.gz' -printf '%f\n' |
        sort -r
)

if (( ${#BACKUPS[@]} > 3 )); then
    for OLD_BACKUP in "${BACKUPS[@]:3}"; do
        rm -- "$BACKUP_DIR/$OLD_BACKUP"
        echo "Removed old backup: $OLD_BACKUP"
    done
fi

log_message "SUCCESS: Created and verified $(basename -- "$ARCHIVE"); entries=$FILE_COUNT"
echo "Backup completed successfully."
