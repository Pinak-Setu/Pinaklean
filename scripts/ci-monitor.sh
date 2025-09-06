#!/bin/bash

# 🚀 Pinaklean CI Monitor - Real-time CI Pipeline Monitoring
# Monitors CI status and ensures all checks stay green

set -euo pipefail

# Configuration
REPO_PATH="/Users/abhijita/Projects/Pinaklean"
LOG_FILE="$REPO_PATH/ci_monitor_$(date +%Y%m%d_%H%M%S).log"
CHECK_INTERVAL=30  # seconds
MAX_FAILURES=3
FAILURE_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Check CI status
check_ci_status() {
    log "INFO" "🔍 Checking CI pipeline status..."
    
    cd "$REPO_PATH"
    
    # Get latest runs
    local runs=$(gh run list --limit 5 --json status,conclusion,workflowName,createdAt,url)
    
    # Check for failures
    local failures=$(echo "$runs" | jq -r '.[] | select(.conclusion == "failure") | .workflowName')
    local in_progress=$(echo "$runs" | jq -r '.[] | select(.status == "in_progress") | .workflowName')
    
    if [ -n "$failures" ]; then
        log "ERROR" "❌ CI Failures detected:"
        echo "$failures" | while read -r workflow; do
            log "ERROR" "  - $workflow"
        done
        return 1
    elif [ -n "$in_progress" ]; then
        log "INFO" "⏳ CI runs in progress:"
        echo "$in_progress" | while read -r workflow; do
            log "INFO" "  - $workflow"
        done
        return 2
    else
        log "SUCCESS" "✅ All CI checks are green!"
        return 0
    fi
}

# Get detailed failure information
get_failure_details() {
    log "INFO" "🔍 Getting detailed failure information..."
    
    cd "$REPO_PATH"
    
    # Get the latest failed run
    local failed_run=$(gh run list --limit 1 --json databaseId,conclusion | jq -r '.[] | select(.conclusion == "failure") | .databaseId')
    
    if [ -n "$failed_run" ] && [ "$failed_run" != "null" ]; then
        log "INFO" "📋 Failure details for run $failed_run:"
        gh run view "$failed_run" --log-failed | head -50 | while read -r line; do
            log "ERROR" "  $line"
        done
    fi
}

# Fix common CI issues
fix_ci_issues() {
    log "INFO" "🔧 Attempting to fix common CI issues..."
    
    cd "$REPO_PATH"
    
    # Fix 1: ML Model Info.plist conflicts
    log "INFO" "Fixing ML model Info.plist conflicts..."
    find PinakleanApp -name "Info.plist" -path "*/Models/*" -exec rm -f {} \; 2>/dev/null || true
    
    # Fix 2: SwiftLint issues
    log "INFO" "Running SwiftLint fixes..."
    if command -v swiftlint >/dev/null 2>&1; then
        cd PinakleanApp
        swiftlint --fix --quiet || true
        cd ..
    fi
    
    # Fix 3: Build issues
    log "INFO" "Cleaning build artifacts..."
    cd PinakleanApp
    swift package clean || true
    rm -rf .build || true
    cd ..
    
    log "INFO" "✅ Common fixes applied"
}

# Trigger new CI run
trigger_ci_run() {
    log "INFO" "🚀 Triggering new CI run..."
    
    cd "$REPO_PATH"
    
    # Create empty commit to trigger CI
    git commit --allow-empty -m "ci: trigger validation run - $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin "$(git branch --show-current)"
    
    log "INFO" "✅ New CI run triggered"
}

# Main monitoring loop
monitor_ci() {
    log "INFO" "🚀 Starting Pinaklean CI Monitor"
    log "INFO" "Repository: $REPO_PATH"
    log "INFO" "Check interval: ${CHECK_INTERVAL}s"
    log "INFO" "Log file: $LOG_FILE"
    
    while true; do
        local status_code
        check_ci_status
        status_code=$?
        
        case $status_code in
            0)  # All green
                FAILURE_COUNT=0
                log "SUCCESS" "🎉 All CI checks are green! Monitoring continues..."
                ;;
            1)  # Failures detected
                FAILURE_COUNT=$((FAILURE_COUNT + 1))
                log "ERROR" "❌ CI failures detected (count: $FAILURE_COUNT/$MAX_FAILURES)"
                
                get_failure_details
                
                if [ $FAILURE_COUNT -ge $MAX_FAILURES ]; then
                    log "ERROR" "🚨 Maximum failure count reached. Attempting fixes..."
                    fix_ci_issues
                    trigger_ci_run
                    FAILURE_COUNT=0
                fi
                ;;
            2)  # In progress
                log "INFO" "⏳ CI runs in progress, waiting for completion..."
                ;;
        esac
        
        log "INFO" "💤 Sleeping for ${CHECK_INTERVAL} seconds..."
        sleep $CHECK_INTERVAL
    done
}

# Signal handlers
cleanup() {
    log "INFO" "🛑 CI Monitor stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Check prerequisites
check_prerequisites() {
    log "INFO" "🔍 Checking prerequisites..."
    
    if ! command -v gh >/dev/null 2>&1; then
        log "ERROR" "❌ GitHub CLI (gh) not found. Please install it first."
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        log "ERROR" "❌ jq not found. Please install it first."
        exit 1
    fi
    
    if [ ! -d "$REPO_PATH" ]; then
        log "ERROR" "❌ Repository path not found: $REPO_PATH"
        exit 1
    fi
    
    log "INFO" "✅ Prerequisites check passed"
}

# Main execution
main() {
    check_prerequisites
    monitor_ci
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi