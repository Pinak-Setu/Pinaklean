#!/usr/bin/env zsh

# Smart Detection Module for Pinaklean
# Uses heuristics and patterns to intelligently identify safe-to-delete files

set -euo pipefail

# File pattern database with safety scores (0-100, higher = safer to delete)
declare -A SAFE_PATTERNS=(
  # Build artifacts - very safe
  ["*.o"]=95
  ["*.pyc"]=95
  ["*.pyo"]=95
  ["*.class"]=95
  ["*.dSYM"]=90
  ["*.xcworkspace"]=85
  ["*.xcodeproj"]=85
  
  # Cache files - safe
  ["*.cache"]=90
  ["*.tmp"]=90
  ["*.temp"]=90
  ["*.swp"]=85
  ["*.swo"]=85
  ["*~"]=85
  [".DS_Store"]=95
  ["Thumbs.db"]=95
  
  # Log files - generally safe
  ["*.log"]=80
  ["*.log.*"]=85
  ["*.out"]=75
  ["*.err"]=75
  
  # Package manager artifacts
  ["node_modules"]=90
  [".npm"]=85
  [".yarn"]=85
  [".pnpm-store"]=85
  ["vendor"]=70
  ["bower_components"]=85
  
  # Build directories
  ["dist"]=85
  ["build"]=85
  ["target"]=85
  ["out"]=80
  [".next"]=90
  [".nuxt"]=90
  [".turbo"]=90
  [".parcel-cache"]=95
  
  # IDE artifacts
  [".idea"]=75
  [".vscode"]=70
  ["*.sublime-workspace"]=75
)

# Directory importance scores (lower = less important)
declare -A DIR_IMPORTANCE=(
  ["$HOME/Documents"]=100
  ["$HOME/Desktop"]=95
  ["$HOME/Pictures"]=100
  ["$HOME/Movies"]=95
  ["$HOME/Music"]=95
  ["$HOME/Downloads"]=60
  ["$HOME/Library/Caches"]=20
  ["$HOME/.Trash"]=10
  ["/tmp"]=5
  ["/var/tmp"]=5
)

# File age thresholds (days)
declare -A AGE_THRESHOLDS=(
  [very_old]=365
  [old]=180
  [medium]=90
  [recent]=30
  [new]=7
)

# Initialize smart detection
smart_init() {
  local ml_data_dir="$HOME/.pinaklean/ml_data"
  mkdir -p "$ml_data_dir"
  
  # Load or create usage patterns file
  local usage_file="$ml_data_dir/usage_patterns.json"
  if [[ ! -f "$usage_file" ]]; then
    echo '{"patterns": [], "last_updated": "'$(date -Iseconds)'"}' > "$usage_file"
  fi
  
  echo "Smart detection initialized"
}

# Calculate file importance score
calculate_importance() {
  local file_path="$1"
  local base_score=50  # Start with neutral score
  
  # Check file extension safety
  local basename="$(basename "$file_path")"
  for pattern in "${!SAFE_PATTERNS[@]}"; do
    if [[ "$basename" == $pattern ]]; then
      base_score=${SAFE_PATTERNS[$pattern]}
      break
    fi
  done
  
  # Adjust based on directory importance
  for dir in "${!DIR_IMPORTANCE[@]}"; do
    if [[ "$file_path" == "$dir"* ]]; then
      local dir_score=${DIR_IMPORTANCE[$dir]}
      base_score=$((base_score * dir_score / 100))
      break
    fi
  done
  
  # Adjust based on file age
  if [[ -e "$file_path" ]]; then
    local age_days=$(( ($(date +%s) - $(stat -f %m "$file_path")) / 86400 ))
    
    if [[ $age_days -gt ${AGE_THRESHOLDS[very_old]} ]]; then
      base_score=$((base_score + 20))  # Very old files are safer to delete
    elif [[ $age_days -gt ${AGE_THRESHOLDS[old]} ]]; then
      base_score=$((base_score + 10))
    elif [[ $age_days -lt ${AGE_THRESHOLDS[new]} ]]; then
      base_score=$((base_score - 20))  # New files are riskier to delete
    fi
  fi
  
  # Adjust based on file size
  if [[ -f "$file_path" ]]; then
    local size_mb=$(( $(stat -f %z "$file_path") / 1048576 ))
    if [[ $size_mb -gt 1000 ]]; then
      base_score=$((base_score - 15))  # Large files need more consideration
    elif [[ $size_mb -lt 1 ]]; then
      base_score=$((base_score + 5))   # Small files are generally safer
    fi
  fi
  
  # Ensure score is within bounds
  if [[ $base_score -lt 0 ]]; then
    base_score=0
  elif [[ $base_score -gt 100 ]]; then
    base_score=100
  fi
  
  echo "$base_score"
}

# Detect duplicate files using checksums
detect_duplicates() {
  local base_dir="$1"
  local checksum_file="$HOME/.pinaklean/checksums_$(date +%Y%m%d_%H%M%S).txt"
  
  echo "Detecting duplicate files in $base_dir..."
  
  # Generate checksums for all files
  find "$base_dir" -type f -size +1M 2>/dev/null | while read -r file; do
    if [[ -r "$file" ]]; then
      local checksum=$(shasum -a 256 "$file" 2>/dev/null | awk '{print $1}')
      if [[ -n "$checksum" ]]; then
        echo "$checksum $file" >> "$checksum_file"
      fi
    fi
  done
  
  # Find duplicates
  local duplicates_file="$HOME/.pinaklean/duplicates.txt"
  sort "$checksum_file" | awk '{
    if ($1 == prev_hash) {
      print $2
      if (!printed_prev) {
        print prev_file
        printed_prev = 1
      }
    } else {
      printed_prev = 0
    }
    prev_hash = $1
    prev_file = $2
  }' > "$duplicates_file"
  
  local dup_count=$(wc -l < "$duplicates_file")
  echo "Found $dup_count duplicate files"
  
  # Calculate space savings
  local space_saved=0
  while IFS= read -r dup_file; do
    if [[ -f "$dup_file" ]]; then
      local size=$(stat -f %z "$dup_file" 2>/dev/null || echo 0)
      space_saved=$((space_saved + size))
    fi
  done < "$duplicates_file"
  
  echo "Potential space savings from duplicates: $((space_saved / 1048576))MB"
  echo "$duplicates_file"
}

# Analyze file access patterns
analyze_access_patterns() {
  local file_path="$1"
  local access_score=50
  
  if [[ -e "$file_path" ]]; then
    # Check last access time
    local last_access=$(stat -f %a "$file_path")
    local days_since_access=$(( ($(date +%s) - last_access) / 86400 ))
    
    if [[ $days_since_access -gt 365 ]]; then
      access_score=$((access_score + 30))  # Not accessed in a year
    elif [[ $days_since_access -gt 180 ]]; then
      access_score=$((access_score + 20))  # Not accessed in 6 months
    elif [[ $days_since_access -gt 90 ]]; then
      access_score=$((access_score + 10))  # Not accessed in 3 months
    elif [[ $days_since_access -lt 7 ]]; then
      access_score=$((access_score - 30))  # Recently accessed
    fi
    
    # Check if file is in active git repository
    if git -C "$(dirname "$file_path")" rev-parse --git-dir >/dev/null 2>&1; then
      # Check if file is tracked
      if git -C "$(dirname "$file_path")" ls-files --error-unmatch "$file_path" >/dev/null 2>&1; then
        access_score=$((access_score - 20))  # Tracked files are important
      else
        access_score=$((access_score + 10))  # Untracked files in git repos
      fi
    fi
  fi
  
  echo "$access_score"
}

# Smart recommendation engine
recommend_for_deletion() {
  local -a candidates=("$@")
  local recommendations_file="$HOME/.pinaklean/recommendations_$(date +%Y%m%d_%H%M%S).json"
  
  echo "{" > "$recommendations_file"
  echo '  "timestamp": "'$(date -Iseconds)'",' >> "$recommendations_file"
  echo '  "recommendations": [' >> "$recommendations_file"
  
  local safe_count=0
  local risky_count=0
  local total_size=0
  
  for i in "${!candidates[@]}"; do
    local file="${candidates[$i]}"
    local importance=$(calculate_importance "$file")
    local access_score=$(analyze_access_patterns "$file")
    local combined_score=$(( (importance + access_score) / 2 ))
    
    local recommendation="skip"
    if [[ $combined_score -gt 70 ]]; then
      recommendation="safe_to_delete"
      safe_count=$((safe_count + 1))
    elif [[ $combined_score -gt 50 ]]; then
      recommendation="review_recommended"
    else
      recommendation="keep"
      risky_count=$((risky_count + 1))
    fi
    
    local size=0
    if [[ -e "$file" ]]; then
      size=$(stat -f %z "$file" 2>/dev/null || echo 0)
      total_size=$((total_size + size))
    fi
    
    echo '    {' >> "$recommendations_file"
    echo '      "path": "'$file'",' >> "$recommendations_file"
    echo '      "importance_score": '$importance',' >> "$recommendations_file"
    echo '      "access_score": '$access_score',' >> "$recommendations_file"
    echo '      "combined_score": '$combined_score',' >> "$recommendations_file"
    echo '      "size_bytes": '$size',' >> "$recommendations_file"
    echo '      "recommendation": "'$recommendation'"' >> "$recommendations_file"
    
    if [[ $i -lt $((${#candidates[@]} - 1)) ]]; then
      echo '    },' >> "$recommendations_file"
    else
      echo '    }' >> "$recommendations_file"
    fi
  done
  
  echo '  ],' >> "$recommendations_file"
  echo '  "summary": {' >> "$recommendations_file"
  echo '    "total_files": '${#candidates[@]}',' >> "$recommendations_file"
  echo '    "safe_to_delete": '$safe_count',' >> "$recommendations_file"
  echo '    "risky_files": '$risky_count',' >> "$recommendations_file"
  echo '    "total_size_mb": '$((total_size / 1048576)) >> "$recommendations_file"
  echo '  }' >> "$recommendations_file"
  echo '}' >> "$recommendations_file"
  
  echo "Smart recommendations generated: $recommendations_file"
  echo "Safe to delete: $safe_count files ($((total_size / 1048576))MB)"
}

# Learn from user feedback
learn_from_feedback() {
  local action="$1"  # deleted|kept
  local file_path="$2"
  local ml_data_dir="$HOME/.pinaklean/ml_data"
  local feedback_file="$ml_data_dir/feedback.log"
  
  # Record feedback
  echo "$(date -Iseconds)|$action|$file_path|$(basename "$file_path")" >> "$feedback_file"
  
  # Update patterns based on feedback
  if [[ "$action" == "deleted" ]]; then
    # User deleted this file, increase safety score for similar files
    echo "Learning: User deleted $file_path"
  elif [[ "$action" == "kept" ]]; then
    # User kept this file, decrease safety score for similar files
    echo "Learning: User kept $file_path"
  fi
}

# Export functions
export -f smart_init
export -f calculate_importance
export -f detect_duplicates
export -f analyze_access_patterns
export -f recommend_for_deletion
export -f learn_from_feedback