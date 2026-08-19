# Change impact from rejected candidate `6b45164b…` to `1d6445db…`

Source comparison: `5485ccb8aeca404412fd346a3a538d0e57808c79..6170fbeeea65f22444d7b0934f4e808c40744d22`.

Eleven repository files changed: 383 insertions and 84 deletions.

## Shipped-byte changes

- `NEWS.md` removes the semantic contradiction between current MSPL probit/cloglog admission and a stale logit-only statement.
- `inst/trust-dossier/README.md` and `inst/trust-dossier/run.R` stop claiming that drmTMB itself is already on CRAN; the exact candidate/source must be installed under review, while comparator dependencies may come from CRAN.
- `tests/testthat.R` and new `tests/testthat/helper-cran-lane.R` implement an explicit 48-context CRAN allowlist for `NOT_CRAN=false` while preserving the full 334-file suite for `NOT_CRAN=true`.
- `tests/testthat/test-cran-lane-filter.R` verifies the allowlist under the bare filenames used by `testthat::test_check()` and under full paths.
- `tests/testthat/test-release-identity.R` guards the two shipped contradiction classes.

These changes alter installed bytes and invalidate all artifact/platform evidence for predecessor hash `6b45164b…`. They are the reason the candidate was rebuilt and every exact-byte external gate is being rerun.

## Build-excluded governance changes

- `AGENTS.md`, `docs/dev-log/coordination-board.md`, and `docs/dev-log/handover/2026-08-18-codex-handover.md` identify the superseded candidates and current release lane.
- `docs/dev-log/after-task/2026-08-18-current-main-070-gate7-repair.md` records the repair and verification.

These files do not enter the built source archive but require fresh governance review. No capability was added, no likelihood/C++ code changed, and PR #1033 plus `_julia_skip2_artifacts/` remain outside scope.
