Pinaklean Agent Guide

Purpose
- Align coding agents on consistent, safe, and efficient workflows tailored to this repo.
- Codify startup steps, guardrails, and conventions. Treat this as the source of truth in addition to .cursor rules.

Session Bootstrap
- Always import .cursor/rules/ironclad-bootstrap.mdc if present.
- If missing, pause and request approval to import from the canonical path provided by the maintainer.
- Use this guide plus the ironclad rules as the baseline for behavior.

Repo Essentials
- Project: SwiftPM workspace under PinakleanApp.
- Build: `cd PinakleanApp && swift build`.
- Run: `cd PinakleanApp && swift run Pinaklean`.
- Tests: `cd PinakleanApp && swift test --enable-code-coverage`.
- Lint: SwiftLint via `.swiftlint.yml` (scope: Sources/PinakleanApp, excludes Tests).
- CI helpers: `make ci/status`, `make ci/rerun`, `make ci/open` (if available).
- Integration smoke: `make integration/smoke` (best-effort; CLI may be archived).

Code Style & Safety
- Swift 5.9+, target macOS 14, 4-space indent.
- Types UpperCamelCase; methods/properties lowerCamelCase; filenames match main type.
- No print in production; use swift-log. Prefer small, testable units.
- Never commit secrets. Use Keychain at runtime.
- Respect guardrails in PinakleanCore and security policies.

Testing
- Frameworks: Quick, Nimble, SnapshotTesting; ViewInspector for view trees.
- Coverage goal: ≥95% for new/changed code.
- Name tests `ThingTests.swift` with Quick/Nimble `describe/it`.
- Prefer deterministic, injected file roots over scanning the full system.

Agent Workflow
- Planning: Use a concise step plan; keep exactly one step in progress. Update as you go.
- Preambles: Before tool calls, briefly explain what’s next (1–2 sentences).
- Patch changes: Use apply_patch only. Keep edits minimal and consistent with repo style.
- Validation: Run targeted tests for changed areas. Expand scope as confidence grows.
- Approvals: Request when reading/writing outside workspace, using network, or performing destructive ops.
- Don’t fix unrelated issues; call them out briefly if discovered.

Engine/UI Realism
- Default to safe operations: move to Trash (not hard delete) where applicable, require confirmation for risky actions, and surface SecurityAuditor warnings.
- Keep external tooling (e.g., lsof, gh) behind explicit user consent and OS-appropriate guards.

Production Readiness (definition)
- Safe-by-default deletion with Undo/Restore; minimal required privileges; reproducible signed builds; vetted dependencies (SBOM/licensing); strong tests; clear privacy & backup consent flows.

Startup Checklist (per session)
- Verify `.cursor/rules/ironclad-bootstrap.mdc` exists and is imported.
- Build + unit tests locally (or request approval to do so).
- SwiftLint if configured locally.
- Update plan and proceed.

Contact & Ownership
- When ambiguous, pause and ask for scope clarification.

