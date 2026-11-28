# After-task: converged rule gradient (#1452)

## Goal

Land the adopted converged rule on `main`, including the stored-gradient Newton
step test that closes drmTMB #1452, and confirm #1462 Student kernel tests still
pass.

## Changes

- Merged `origin/claude/converged-rule-drm-20261118` into
  `cursor/convergence-gradient-1452-beb6` (`convergence_info()`, four-valued
  `convergence_status()`, `drm_newton_step_se()` with 1e-3 SE tolerance).
- Kept `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`
  identical to `main` (no C17 recertify in cloud).
- Added `test-convergence-status-twin.R` cars ×1e4 regression for #1452.

## Checks

Local Ubuntu, R 4.3.x, TMB from CRAN, `pkgload::load_all`:

- `test-student-large-nu.R`: 23 pass (`NOT_CRAN=true`)
- `test-convergence-status-twin.R`: 80 pass after the new test

## Issues

- #1462: already fixed on `main` (stable Student kernel); verified by tests.
- #1452: fixed on this branch via `not_converged` when the Newton step exceeds
  1e-3 SE; cars ×1e4 repro matches the issue write-up.

## Next

- Coordinate with draft PR #1781 (same rule family) before merge to avoid
  duplicate expectation churn.
- Fit-time warning naming the max gradient component (#1452 polish) is not in
  this slice.