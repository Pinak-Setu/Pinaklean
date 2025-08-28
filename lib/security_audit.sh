#!/usr/bin/env zsh

# Security Audit Module for Pinaklean
# Provides comprehensive security validation before cleanup operations

set -euo pipefail

# Security configuration
declare -A SECURITY_CONFIG=(
  [max_file_age_days]=90
  [min_backup_retention_days]=30
  [max_deletion_size_gb]=50
  [require_sudo_for_system]=true
  [enable_integrity_check]=true
)

# Critical system paths that must never be touched
declare -a CRITICAL_PATHS=(
  "/System"
  "/Library/Security"
  "/Library/Keychains"
  "/private/var/db"
  "/private/etc"
  "$HOME/.ssh"
  "$HOME/.gnupg"
  "$HOME/.aws"
  "$HOME/.config/git"
  "$HOME/Library/Keychains"
  "$HOME/Library/Application Support/1Password"
  "$HOME/Library/Application Support/com.apple.sharedfilelist"
)

# Sensitive file patterns
declare -a SENSITIVE_PATTERNS=(
  "*.key"
  "*.pem"
  "*.crt"
  "*.pfx"
  "*.p12"
  "*_rsa"
  "*_dsa"
  "*_ecdsa"
  "*_ed25519"
  "*.kdbx"
  "*.keychain"
  "*.keystore"
  "id_*"
  "*.vault"
  "*.credentials"
  "*.secret"
)

# Security audit functions
audit_init() {
  local audit_log="$HOME/.pinaklean/audit.log"
  mkdir -p "$(dirname "$audit_log")"
  echo "[$(date -Iseconds)] Security audit initialized" >> "$audit_log"
}

# Check if path is in critical system locations
is_critical_path() {
  local path="$1"
  for critical in "${CRITICAL_PATHS[@]}"; do
    if [[ "$path" == "$critical"* ]]; then
      return 0
    fi
  done
  return 1
}

# Check if file matches sensitive patterns
is_sensitive_file() {
  local file="$1"
  local basename="$(basename "$file")"
  
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if [[ "$basename" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

# Verify file integrity before deletion
verify_file_integrity() {
  local file="$1"
  
  # Check if file is locked or in use
  if lsof "$file" >/dev/null 2>&1; then
    echo "WARNING: File is currently in use: $file"
    return 1
  fi
  
  # Check file permissions
  if [[ ! -w "$file" ]]; then
    echo "WARNING: No write permission for: $file"
    return 1
  fi
  
  # Check if file is a symlink to critical location
  if [[ -L "$file" ]]; then
    local target="$(readlink "$file")"
    if is_critical_path "$target"; then
      echo "WARNING: Symlink points to critical path: $file -> $target"
      return 1
    fi
  fi
  
  return 0
}

# Calculate risk score for deletion
calculate_risk_score() {
  local path="$1"
  local risk_score=0
  
  # Check if in user home
  if [[ "$path" == "$HOME"* ]]; then
    risk_score=$((risk_score + 10))
  fi
  
  # Check if in system directories
  if [[ "$path" == "/Library"* ]] || [[ "$path" == "/System"* ]]; then
    risk_score=$((risk_score + 50))
  fi
  
  # Check file age (newer = higher risk)
  if [[ -e "$path" ]]; then
    local age_days=$(( ($(date +%s) - $(stat -f %m "$path")) / 86400 ))
    if [[ $age_days -lt 7 ]]; then
      risk_score=$((risk_score + 30))
    elif [[ $age_days -lt 30 ]]; then
      risk_score=$((risk_score + 20))
    fi
  fi
  
  # Check file size (larger = higher risk)
  if [[ -f "$path" ]]; then
    local size_mb=$(( $(stat -f %z "$path") / 1048576 ))
    if [[ $size_mb -gt 1000 ]]; then
      risk_score=$((risk_score + 25))
    elif [[ $size_mb -gt 100 ]]; then
      risk_score=$((risk_score + 15))
    fi
  fi
  
  echo "$risk_score"
}

# Perform comprehensive security audit
perform_security_audit() {
  local -a paths_to_audit=("$@")
  local audit_report="$HOME/.pinaklean/audit_report_$(date +%Y%m%d_%H%M%S).json"
  local total_risk=0
  local high_risk_count=0
  
  mkdir -p "$(dirname "$audit_report")"
  
  echo "{" > "$audit_report"
  echo '  "timestamp": "'$(date -Iseconds)'",' >> "$audit_report"
  echo '  "total_paths": '${#paths_to_audit[@]}',' >> "$audit_report"
  echo '  "audited_paths": [' >> "$audit_report"
  
  for i in "${!paths_to_audit[@]}"; do
    local path="${paths_to_audit[$i]}"
    local risk_score=$(calculate_risk_score "$path")
    total_risk=$((total_risk + risk_score))
    
    if [[ $risk_score -gt 50 ]]; then
      high_risk_count=$((high_risk_count + 1))
    fi
    
    echo '    {' >> "$audit_report"
    echo '      "path": "'$path'",' >> "$audit_report"
    echo '      "risk_score": '$risk_score',' >> "$audit_report"
    echo '      "is_critical": '$(is_critical_path "$path" && echo "true" || echo "false")',' >> "$audit_report"
    echo '      "is_sensitive": '$(is_sensitive_file "$path" && echo "true" || echo "false")',' >> "$audit_report"
    echo '      "integrity_valid": '$(verify_file_integrity "$path" && echo "true" || echo "false") >> "$audit_report"
    
    if [[ $i -lt $((${#paths_to_audit[@]} - 1)) ]]; then
      echo '    },' >> "$audit_report"
    else
      echo '    }' >> "$audit_report"
    fi
  done
  
  echo '  ],' >> "$audit_report"
  echo '  "summary": {' >> "$audit_report"
  echo '    "total_risk_score": '$total_risk',' >> "$audit_report"
  echo '    "average_risk_score": '$((total_risk / ${#paths_to_audit[@]}))',' >> "$audit_report"
  echo '    "high_risk_count": '$high_risk_count >> "$audit_report"
  echo '  }' >> "$audit_report"
  echo '}' >> "$audit_report"
  
  echo "Security audit complete. Report: $audit_report"
  
  # Return non-zero if high risk
  if [[ $high_risk_count -gt 0 ]]; then
    echo "WARNING: $high_risk_count high-risk paths detected!"
    return 1
  fi
  
  return 0
}

# Validate cleanup operation
validate_cleanup() {
  local operation="$1"
  shift
  local -a targets=("$@")
  
  echo "Validating cleanup operation: $operation"
  
  # Check for critical paths
  for target in "${targets[@]}"; do
    if is_critical_path "$target"; then
      echo "ERROR: Attempting to clean critical path: $target"
      return 1
    fi
    
    if is_sensitive_file "$target"; then
      echo "WARNING: Sensitive file detected: $target"
      read -r "?Confirm deletion of sensitive file? [y/N] " ans
      if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
        return 1
      fi
    fi
  done
  
  # Perform full audit
  if ! perform_security_audit "${targets[@]}"; then
    echo "Security audit failed. Aborting operation."
    return 1
  fi
  
  return 0
}

# Export functions for use in main script (if needed)
# Note: Functions are available when sourced