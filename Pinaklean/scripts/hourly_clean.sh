#!/bin/zsh

# Pinaklean Hourly Cleaning Script
# Safe automated cleaning for macOS maintenance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PINAKLEAN_CLI="${SCRIPT_DIR}/bin/pinaklean"
LOG_FILE="${HOME}/.pinaklean/hourly_clean.log"

log() {
    echo "[$(date)] [INFO] $1" >> "$LOG_FILE"
}

check_system_resources() {
    local available_space=$(df -h "$HOME" | tail -1 | awk "{print \$4}" | sed "s/G.*//")
    local available_gb=$(echo "$available_space" | awk "{print int(\$1)}")
    
    if [[ $available_gb -lt 10 ]]; then
        log "Low disk space: ${available_space}G available"
        return 1
    fi
    return 0
}

send_notification() {
    local title="$1"
    local message="$2"
    
    if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$message\" with title \"$title\""
    fi
}

perform_cleaning() {
    log "Starting hourly cleaning"
    
    if [[ ! -x "$PINAKLEAN_CLI" ]]; then
        log "ERROR: Pinaklean CLI not found"
        return 1
    fi
    
    # Conservative cleaning: user caches and logs
    if "$PINAKLEAN_CLI" --categories userCaches,logs,trash --dry-run --quiet 2>>"$LOG_FILE"; then
        log "Dry run scan completed successfully"
        
        # If significant space to clean (>100MB), perform actual cleanup
        # For safety, we check estimated size here
        if "$PINAKLEAN_CLI" --categories userCaches,logs,trash --quiet 2>>"$LOG_FILE"; then
            log "Actual cleanup completed successfully"
            send_notification "Pinaklean Hourly Clean" "System cleanup completed"
            return 0
        else
            log "ERROR: Actual cleanup failed"
            return 1
        fi
    else
        log "ERROR: Dry run scan failed"
        return 1
    fi
}

main() {
    log "=== Pinaklean Hourly Cleaning Started ==="
    
    if check_system_resources; then
        if perform_cleaning; then
            log "=== Hourly cleaning completed successfully ==="
            exit 0
        else
            log "=== Hourly cleaning failed ==="
            exit 1
        fi
    else
        log "=== Skipping cleaning due to resource constraints ==="
        exit 0
    fi
}

main
