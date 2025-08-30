#!/usr/bin/env zsh

# Parallel Processing Module for Pinaklean
# Enables concurrent cleanup operations for improved performance

set -euo pipefail

# Configuration
PARALLEL_WORKERS=${PARALLEL_WORKERS:-4}
CHUNK_SIZE=${CHUNK_SIZE:-100}
PROGRESS_UPDATE_INTERVAL=1

# Initialize parallel processing
parallel_init() {
  # Create named pipes for worker communication
  local pipe_dir="$HOME/.pinaklean/pipes"
  mkdir -p "$pipe_dir"
  
  # Clean up old pipes
  rm -f "$pipe_dir"/*.pipe
  
  # Create worker pipes
  for i in $(seq 1 $PARALLEL_WORKERS); do
    mkfifo "$pipe_dir/worker_$i.pipe"
  done
  
  echo "Initialized $PARALLEL_WORKERS parallel workers"
}

# Worker function
parallel_worker() {
  local worker_id="$1"
  local pipe_dir="$HOME/.pinaklean/pipes"
  local worker_pipe="$pipe_dir/worker_$worker_id.pipe"
  local result_file="$pipe_dir/worker_$worker_id.result"
  
  while true; do
    if read -r task < "$worker_pipe"; then
      if [[ "$task" == "EXIT" ]]; then
        break
      fi
      
      # Process task
      local start_time=$(date +%s)
      eval "$task" 2>&1 | tee -a "$result_file"
      local end_time=$(date +%s)
      local duration=$((end_time - start_time))
      
      echo "[Worker $worker_id] Completed task in ${duration}s: $task" >> "$result_file"
    fi
  done
}

# Distribute tasks to workers
distribute_tasks() {
  local -a tasks=("$@")
  local pipe_dir="$HOME/.pinaklean/pipes"
  local task_count=${#tasks[@]}
  local completed=0
  
  # Start progress monitoring
  (
    while [[ $completed -lt $task_count ]]; do
      sleep $PROGRESS_UPDATE_INTERVAL
      local current_completed=$(find "$pipe_dir" -name "*.result" -exec grep -c "Completed task" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')
      if [[ -n "$current_completed" ]]; then
        completed=$current_completed
        local percent=$((completed * 100 / task_count))
        echo -ne "\rProgress: [$completed/$task_count] $percent%"
      fi
    done
    echo ""
  ) &
  local progress_pid=$!
  
  # Distribute tasks round-robin
  local worker_id=1
  for task in "${tasks[@]}"; do
    echo "$task" > "$pipe_dir/worker_$worker_id.pipe"
    worker_id=$((worker_id % PARALLEL_WORKERS + 1))
  done
  
  # Wait for all tasks to complete
  wait $progress_pid 2>/dev/null
  
  echo "All tasks distributed"
}

# Parallel file deletion with chunking
parallel_delete() {
  local -a files=("$@")
  local total_files=${#files[@]}
  
  if [[ $total_files -eq 0 ]]; then
    echo "No files to delete"
    return 0
  fi
  
  echo "Starting parallel deletion of $total_files files..."
  
  # Initialize workers
  parallel_init
  
  # Start worker processes
  for i in $(seq 1 $PARALLEL_WORKERS); do
    parallel_worker $i &
  done
  
  # Create deletion tasks
  local -a tasks=()
  for file in "${files[@]}"; do
    tasks+=("rm -rf '$file' 2>/dev/null || echo 'Failed to delete: $file'")
  done
  
  # Distribute and execute
  distribute_tasks "${tasks[@]}"
  
  # Cleanup workers
  local pipe_dir="$HOME/.pinaklean/pipes"
  for i in $(seq 1 $PARALLEL_WORKERS); do
    echo "EXIT" > "$pipe_dir/worker_$i.pipe"
  done
  
  wait  # Wait for all workers to finish
  
  echo "Parallel deletion complete"
}

# Parallel cache scanning
parallel_scan() {
  local base_dir="$1"
  local pattern="$2"
  local output_file="$HOME/.pinaklean/scan_results.txt"
  
  echo "Starting parallel scan of $base_dir for pattern: $pattern"
  
  # Use GNU parallel if available, otherwise fall back to xargs
  if command -v parallel >/dev/null 2>&1; then
    find "$base_dir" -type d -name "$pattern" -print0 2>/dev/null | \
      parallel -0 -j$PARALLEL_WORKERS 'echo {}; du -sh {} 2>/dev/null' | \
      tee "$output_file"
  else
    find "$base_dir" -type d -name "$pattern" -print0 2>/dev/null | \
      xargs -0 -P$PARALLEL_WORKERS -I {} sh -c 'echo {}; du -sh {} 2>/dev/null' | \
      tee "$output_file"
  fi
  
  local total_size=$(awk '{sum+=$1} END {print sum}' "$output_file" 2>/dev/null || echo "0")
  echo "Total size found: ${total_size}MB"
}

# Parallel backup creation
parallel_backup() {
  local -a files=("$@")
  local backup_dir="$HOME/pinaklean_backups"
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  
  mkdir -p "$backup_dir"
  
  echo "Creating parallel backups..."
  
  # Split files into chunks
  local chunk_num=0
  local -a current_chunk=()
  
  for file in "${files[@]}"; do
    current_chunk+=("$file")
    
    if [[ ${#current_chunk[@]} -ge $CHUNK_SIZE ]]; then
      chunk_num=$((chunk_num + 1))
      local archive="$backup_dir/backup_${timestamp}_chunk_${chunk_num}.tar.gz"
      
      # Create backup task
      (
        printf "%s\0" "${current_chunk[@]}" | \
          tar -czf "$archive" --null --files-from=- --ignore-failed-read 2>/dev/null
        echo "Created backup chunk $chunk_num: $archive"
      ) &
      
      # Reset chunk
      current_chunk=()
      
      # Limit concurrent backups
      while [[ $(jobs -r | wc -l) -ge $PARALLEL_WORKERS ]]; do
        sleep 0.1
      done
    fi
  done
  
  # Handle remaining files
  if [[ ${#current_chunk[@]} -gt 0 ]]; then
    chunk_num=$((chunk_num + 1))
    local archive="$backup_dir/backup_${timestamp}_chunk_${chunk_num}.tar.gz"
    printf "%s\0" "${current_chunk[@]}" | \
      tar -czf "$archive" --null --files-from=- --ignore-failed-read 2>/dev/null
    echo "Created backup chunk $chunk_num: $archive"
  fi
  
  wait  # Wait for all backup jobs
  
  echo "Parallel backup complete: $chunk_num chunks created"
}

# Cleanup parallel resources
parallel_cleanup() {
  local pipe_dir="$HOME/.pinaklean/pipes"
  
  # Kill any remaining workers
  pkill -f "parallel_worker" 2>/dev/null || true
  
  # Clean up pipes and temporary files
  rm -rf "$pipe_dir"
  
  echo "Parallel processing cleanup complete"
}

# Export functions
export -f parallel_init
export -f parallel_worker
export -f distribute_tasks
export -f parallel_delete
export -f parallel_scan
export -f parallel_backup
export -f parallel_cleanup