# Structured SD target resolver, 2026-10-20

- Added explicit validation for missing or invalid structured target levels and
  incomplete provider, group, dpar, coefficient, and block metadata.
- Added fit-free tests for coefficient and block selection among structured
  members sharing a group and level.
- Focused red runs reproduced missing-level and incomplete-identity failures
  before the fix. The green run passed with `stop_on_failure = TRUE`.
- `git diff --check` passed. No model fit, Julia engine, or package-wide suite
  ran.
- The after-task structure check passed. Its overall completion check returned
  nonzero because the parent SD programme and ten child ledgers remain
  open; this resolver slice does not close those gates.
- Open-issue search for `structured random-effect SD target resolver` returned
  no matches.
- Production structured formula admission and all broader capability gates
  remain open. See
  `docs/dev-log/after-task/2026-10-20-structured-sd-target-resolver.md`.
