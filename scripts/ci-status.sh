#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) not installed. Install from https://cli.github.com/" >&2
  exit 1
fi

gh run list --limit 10 --json databaseId,headBranch,status,conclusion,workflowName,createdAt --jq '.[] | {id: .databaseId, wf: .workflowName, branch: .headBranch, status: .status, result: .conclusion, at: .createdAt}'

