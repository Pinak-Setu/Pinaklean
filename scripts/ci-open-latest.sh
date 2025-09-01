#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) not installed. Install from https://cli.github.com/" >&2
  exit 1
fi

url=$(gh run list --limit 1 --json url --jq '.[0].url')
if [ -z "${url:-}" ]; then
  echo "No runs found." >&2
  exit 0
fi

echo "Opening ${url}..."
gh browse "${url}"

