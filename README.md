# Pinaklean

Safe macOS cleanup toolkit for developers.

- Safe-by-default guardrails (deny-list of system/personal paths)
- Dry-run mode; confirmations in safe mode
- Snapshot archive before deletion with 7-day retention
- Cleans common dev/user caches: node_modules, .next, dist, build, .turbo, .parcel-cache, npm cache, Docker, Homebrew, Pip, Safari/Chrome caches, Xcode DerivedData, Trash, logs, tmp files

## Usage

```bash
# Preview actions
bin/pinaklean --dry-run

# Run in safe mode (default)
bin/pinaklean --safe

# Run in aggressive mode (skips confirmations, still guarded)
bin/pinaklean --aggressive
```

## Requirements

Best effort if missing:
- terminal-notifier or osascript (notifications)
- docker, brew, pip, npm (optional cleanups)
- tar, find, xargs, bc

## Backups

Creates archives in `~/pinaklean_backups` before deletion. Retains for 7 days.

## License

Apache-2.0 (proposed)
