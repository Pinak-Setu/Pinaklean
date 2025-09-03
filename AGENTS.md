# Repository Guidelines

## Project Structure & Module Organization
- `PinakleanApp/` (SwiftPM): primary workspace.
  - `Core/`: shared framework target `PinakleanCore` (security, engine, backup).
  - `Sources/PinakleanApp/`: macOS app executable `Pinaklean` (SwiftUI UI, utilities).
  - `Tests/`: Swift tests (Quick/Nimble, snapshots). Some CLI tests are archived.
- `tests/`: shell-based Bats tests for the CLI wrapper.
- `scripts/`: CI helpers, coverage gates, and tooling.
- `.github/`: CI workflows; `security/`: policies; `perf/`: k6 perf smoke; `docs/`: diagrams.

## Build, Test, and Development Commands
- Build app: `cd PinakleanApp && swift build`
- Run app: `cd PinakleanApp && swift run Pinaklean`
- Run Swift tests: `cd PinakleanApp && swift test --enable-code-coverage`
- CI helpers: `make ci/status`, `make ci/rerun`, `make ci/open`
- Integration smoke (CLI if enabled): `make integration/smoke` (best-effort)
- SBOM/Licenses (Node required): `make sbom`, `make licenses`

## Coding Style & Naming Conventions
- Swift 5.9+, macOS 14 target. Use 4-space indentation.
- Types: UpperCamelCase; methods/properties: lowerCamelCase; files match primary type.
- Lint: SwiftLint configured via `.swiftlint.yml` (applies to `PinakleanApp/Sources`, excludes `Tests`). Run `swiftlint` locally if available.
- Prefer small, testable units; avoid `print` in production code (use `swift-log`).

## Testing Guidelines
- Frameworks: Quick + Nimble; SnapshotTesting (guarded in CI). Shell tests use Bats.
- Coverage: aim for ≥95% lines on new/changed code.
- Layout: Swift tests under `PinakleanApp/Tests`; name test types `ThingTests.swift` with `describe/it`.
- Run targeted suites: `swift test --filter SecurityTests` (similar for others).

## Commit & Pull Request Guidelines
- Conventional Commits: `feat(scope): summary`, `fix(ci): …`, `docs(ui): …`. Emojis optional.
- Branches: `feature/...`, `fix/...`, or `chore/...`.
- PRs must: describe changes and rationale, link issues, include test coverage notes; add screenshots/GIFs for UI changes; pass CI on macOS 14.

## Security & Configuration Tips
- Do not commit secrets; credentials are stored via Keychain at runtime.
- Respect safety guardrails in `PinakleanCore` and policies under `security/`.
- CodeQL and lint run in CI; run locally when possible.

Note: The CLI target is currently archived in `Package.swift`; integration smoke tolerates its absence.

