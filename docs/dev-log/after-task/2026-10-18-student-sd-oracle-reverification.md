# After Task: Student SD evidence recheck

## 1. Goal

Verify the existing native Student-t random-effect SD regression oracle and inference-routing tests, then bring the active family plan and adapter map up to date.

## 2. Implemented

The focused Student tests passed 34 assertions. The current plan now records the independent fixed-parameter Laplace oracle, wrong-group negative control, and profile/bootstrap target-routing smoke as complete. It keeps Student interval calibration and Julia Student support open and advances the next-action list.

## 3a. Decisions and Rejected Alternatives

- Counted the oracle as independent fixed-parameter Laplace evidence, not exact integration or family-level calibration.
- Left the dated earlier reports intact; revised the active plan and adapter map to show the current evidence.
- Assumption: the current source and test files in this worktree are the intended pinned Student slice; the full campaign denominator remains unfrozen.

## 4. Files Touched

- `tests/testthat/test-student-sd-regression.R` (executed, unchanged in this recheck)
- `tests/testthat/test-student-sd-integration.R` (executed, unchanged in this recheck)
- `docs/dev-log/general-sd-regression/native-family-wave-plan.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `docs/dev-log/check-log.d/2026-10-18-student-sd-oracle-reverification.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-18-student-sd-oracle-reverification.md`

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "student-sd-(regression|integration)")'` passed 34 assertions: 15 integration and 19 regression, with zero failures, warnings, or skips, in 13.9 seconds. `git diff --check` passed. The general SD gates G0-G8 remain open.

## 6. Tests of the Tests

The integration test compares the fitted model's log likelihood with a separately coded groupwise Laplace calculation and checks a deliberately wrong group-predictor assignment. The regression test also exercises synthetic recovery, constant-SD reduction, public prediction, save/reload, and finite profile/bootstrap target-routing results.

## 7a. Issue Ledger

No issue was changed; this was a focused evidence recheck and plan correction.

## 8. Consistency Audit

The Student adapter map and wave plan now distinguish the independent oracle from interval calibration. The test implementation and updated wording agree. The broader family table still identifies Student intercept SD as a native scoped route; no claim of Julia Student SD support was added.

## 9. What Did Not Go Smoothly

The active wave plan still listed an independent Student oracle and profile/bootstrap smoke as future work even though those tests were present. The discrepancy came from plan drift, not a failing test.

## 10. Known Residuals

This is one native Student intercept cell. It does not establish interval coverage, random slopes, structured effects, other distributional-parameter endpoints, or Julia parity. The independent slice review and all broad programme gates remain open.

## 11. Team Learning

Before selecting the next implementation task from an older wave plan, compare its proposed checks with the current test tree and latest receipts. The route helper found no LOAD-FIRST manifest for this checkout, so no routed brain notes were available; the Golden Set was not run because this recheck did not target a known-mistake fixture.

## 12. Cross-Product Coverage

- Native R/TMB Student ordinary location-intercept SD regression: recovery, independent fixed-parameter Laplace oracle, wrong-group control, prediction, refit-target smoke, and constant-SD comparison are covered by the focused tests.
- Julia Student SD regression, interval calibration, random slopes, structured effects, and other endpoints: does NOT cover these surfaces.
