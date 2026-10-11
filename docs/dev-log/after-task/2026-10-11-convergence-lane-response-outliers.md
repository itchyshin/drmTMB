# Convergence lane: response-outlier check and validator-issue triage

## 1. Goal

Clear the convergence and diagnostics cluster assigned by the 2026-10-11
coordinator (session_01V7zBZfvrcwsDxKrZRgzS5s). After de-duplication with
other lanes, this lane kept #1335, #1007, #1008 and #1011.

## 2. Implemented

- **#1335 (fixed).** New `check_drm()` row `response_residual_outliers`
  (`R/check-response-outliers.R`). It reads quantile residuals with a fixed
  seed, counts `|r| > 3`, and warns when the one-sided binomial p-value under
  `2 * pnorm(-3)` is below 1e-4. If quantile residuals are unavailable, the
  fit gets no row. The caller's RNG state is restored.
- **#1007 (already fixed on main, verified).** Here is how the
  missing-response G5 reconciler now checks completeness:
  - `tools/mr-g5-reconcile*.R` keep the full `expected_registry`.
  - `mr_g5_validate_cohort_registry()` stops when a selected route drops
    expected cells.
  - `mr_g5_reconcile_checkpoints()` and `mr_g5_validate_campaign()` require
    `setequal()` over every planned attempt key.
  - The artifact stores `expected_registry` and `expected_cell_count`.
  - Tests are in `test-missing-response-g4g5-foundation.R`: "a G5 cohort
    retains its pre-selection expected registry".
- **#1008 (already fixed on main, verified).** `interval_method` is frozen
  in the target manifest. `mr_g4_validate_runtime_interval_method()` is
  called for every G4 and G5 attempt through `mr_g4_run_target_manifest()`.
  It hard-errors when the frozen method disagrees with the live
  `profile_targets()`. The static `profile_ready == interval_method` check
  is still a consistency check, but it is no longer the guard. Tests are in
  the same file.
- **#1011 (planned).** Posted a scoped plan comment. The #1026 live-prose
  contracts cover suggested fixes 1 and 2 for contracted rows only. Still
  open:
  - an all-row retired-predicate scan;
  - a route cross-reference contract rule, which needs a convention
    decision;
  - keyed cross-reference columns, which is a schema decision.

## 3a. Decisions and Rejected Alternatives

- Quantile residuals rather than Pearson residuals: they are N(0, 1) for
  every family under a correct model, so one threshold works across
  families.
- The threshold is a binomial tail test, not a fixed share. It stays quiet
  on a clean n = 400 fit (1 residual beyond |3|, p = 0.66). It fires on the
  Dinnage-style sentinel (10 beyond |3|, p = 2e-7) even after the `sigma`
  submodel has absorbed most of the damage.
- The function sits in a new file and the row is inserted after
  `check_scale_positive()`. This keeps clear of the `R/check.R` hunks in
  open PRs #1503, #1505 and the Lane C branch.

## 4. Files Touched

- `R/check-response-outliers.R` (new), `R/check.R` (row and docs
  paragraph), `man/check_drm.Rd`
- `tests/testthat/test-check-response-outliers.R` (new)
- `NEWS.md`, this report.

## 5. Verification

- The new test file passes. Its sentinel test fails when the row is not
  wired in.
- `test-check-drm.R` and `test-dinnage-audit-wave4b1.R`: 0 failures.
- Full suite, sharded 4 ways with `NOT_CRAN=true`: see the PR body.

## 6. Covered elsewhere

#1452 (PR #1503); #1470 and #1478 (PR #1505); #1458 (PR #1501). Lane C
(session_01UPk7YUNWMuHX2TeWAGg61x) owns #1315, #1317 and #1469, plus
#1452, #1458, #1470 and #1478 within its own scope.
