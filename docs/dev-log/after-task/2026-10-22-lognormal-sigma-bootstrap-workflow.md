# After Task: LogNormal sigma-SD bootstrap workflow

## 1. Goal

Check that a bootstrap refit for a predictor-dependent random-effect SD on the LogNormal `sigma` endpoint preserves target identity and exposes usable per-refit diagnostics.

## 2. Implemented

No production code changed. The existing informative LogNormal slope-profile test now also requests three serial bootstrap refits with a fixed seed and checks their results.

## 3a. Decisions and Rejected Alternatives

Treat this as a workflow-integrity check. It does not support a claim about confidence-interval coverage or general bootstrap performance.

## 4. Files Touched

- `tests/testthat/test-lognormal-sigma-sd-regression.R` adds the three-refit target-integrity checks.
- `docs/dev-log/general-sd-regression/inventory.md` records the narrow result.
- `docs/dev-log/check-log.d/2026-10-22-lognormal-sigma-bootstrap-workflow.md` records the command, result, and source binding.
- `docs/dev-log/check-log.md` records this check.
- This report records the scope and limits.

## 5. Checks Run

- The focused profile-and-bootstrap test passed 20 assertions with no failures, warnings, or skips.
- After-task structure, prose, and scoped whitespace checks are recorded at closeout.
- No Julia test or interval-coverage simulation ran.

## 6. Tests of the Tests

The test asserts the requested SD target is returned unchanged, the method/status identify a bootstrap interval, all three requested refits are counted as successful, and each diagnostic row names the same target and records convergence, availability, and draw use.

## 7a. Issue Ledger

No GitHub issue was changed or queried for this bounded workflow test.

## 8. Consistency Audit

The inventory labels this result as bootstrap workflow evidence only. The implementation goal still defers interval calibration; the test does not change that boundary.

## 9. What Did Not Go Smoothly

The `graft` executable is unavailable in this checkout. The repository lane preflight completed and found no missing-reference work on the test path.

## 10. Known Residuals

This is one native LogNormal `sigma` endpoint, q1 iid-intercept route, one SD slope, and three successful refits. This test does NOT cover coverage, other response families, structured providers, Julia, or general bootstrap validity.

## 11. Team Learning

The generic direct-target bootstrap route already handles this LogNormal SD target. A small workflow test can verify target retention and refit accounting without presenting the interval as calibrated.

## 12. Cross-Product Coverage

The exercised cell is native TMB, LogNormal `sigma`, q1 iid random intercept, predictor-dependent SD, three serial bootstrap refits, and one synthetic profile fixture. This test does NOT cover Julia, other endpoints, other effect types, other providers, or interval calibration.
