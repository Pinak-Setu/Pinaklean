#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) not installed. Install from https://cli.github.com/" >&2
  exit 1
fi

run_id=$(gh run list --json databaseId,conclusion --jq '.[] | select(.conclusion=="failure") | .databaseId' | head -n1)
if [ -z "${run_id:-}" ]; then
  echo "No failed runs found." >&2
  exit 0
fi

echo "Re-running run ${run_id}..."
gh run rerun "${run_id}" --failed

