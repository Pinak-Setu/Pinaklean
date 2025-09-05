#!/usr/bin/env bash
# Pinaklean agent bootstrap
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULES="$ROOT_DIR/.cursor/rules/ironclad-bootstrap.mdc"
if [[ -f "$RULES" ]]; then
  echo "Agent rules found: $RULES"
else
  echo "Missing $RULES. Please import the canonical rules before starting."
  exit 1
fi
echo "Agents: follow $ROOT_DIR/AGENTS.md and the ironclad bootstrap rules."
