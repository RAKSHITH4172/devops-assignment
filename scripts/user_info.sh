#!/bin/bash
#
# Purpose: Display users with UID 1000 or above.
# Author: RAKSHITH
# Date: 2026-10-19
# Usage: ./user_info.sh
#

set -euo pipefail

# Function to print the table header
print_header() {
    printf "%-25s %-10s %-30s %-25s\n" \
        "USERNAME" "UID" "HOME DIRECTORY" "SHELL"
    printf '%s\n' "------------------------------------------------------------------------------------------"
}

echo "User Accounts (UID >= 1000)"
echo

print_header

# Read /etc/passwd line by line using colon as the delimiter
while IFS=: read -r username password uid gid gecos home shell; do
    if [[ "$uid" =~ ^[0-9]+$ ]] && (( uid >= 1000 )); then
        printf "%-25s %-10s %-30s %-25s\n" \
            "$username" "$uid" "$home" "$shell"
    fi
done < /etc/passwd
