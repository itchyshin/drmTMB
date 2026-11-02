# After Task: Bernoulli independent-slope SD regression rerun

## 1. Goal

Rerun the focused native Bernoulli test for a predictor-dependent SD on one independent random slope in the active implementation worktree.

## 2. Implemented

The existing test passed against the current dirty candidate source. Production code stayed unchanged during this rerun.

## 3a. Decisions and Rejected Alternatives

Run only the Bernoulli integration test file because this check verifies one existing fixture. A broader test sweep or calibration campaign was outside this bounded rerun.

## 4. Files Touched

This report and `docs/dev-log/check-log.d/2026-10-22-bernoulli-slope-sd-rerun.md` were created. The already-dirty test, model source, and user-facing documentation were not modified by this rerun. The tested source hashes and worktree HEAD are recorded in the check log.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^binomial-sd-integration$", reporter = "summary")'`: PASS, no failed assertions.
- `git diff --check -- tests/testthat/test-binomial-sd-integration.R`: reports an added blank line at EOF on line 225; the test file was left unchanged.
- The open-issue query for `Bernoulli random effect SD slope` returned no matches.
- The after-task structure checker is run separately from the overall programme ledger, whose eight gates remain unmet.

## 6. Tests of the Tests

The test uses fixed-seed synthetic data to check point recovery, workflow outputs, and the marginal likelihood against a separate scalar Laplace oracle. Repeated-sample recovery and interval coverage require separate simulation evidence.

## 7a. Issue Ledger

No matching open issue was found. No issue was opened, edited, closed, or commented on.

## 8. Consistency Audit

The test syntax is `sd(id) ~ w` with `y ~ x + (0 + x | id)`, so `w` varies between groups and is constant within each group. This rerun did not alter formulas, documentation, or capability claims. Testthat filters use the file stem after removing `test-` and `.R`.

## 9. What Did Not Go Smoothly

Two attempted commands stopped before running tests: `devtools::test_file()` is defunct in the installed devtools version, and the next filter string contained an invalid R escape. A third filter included the filename prefix and extension and matched no files. Reading testthat’s local help established the required file-stem filter; the corrected command passed.

## 10. Known Residuals

The test output reports zero live Julia tests. The programme still has eight unmet gates. Continue the required family, effect-type, and backend rows in the existing `codex/general-sd-regression` lane. Keep calibration and programme closeout open until their evidence passes. No merge or publication occurred.

## 11. Team Learning

Use `devtools::test(filter = "^<file-stem>$")` for one test file. The stem excludes both the `test-` prefix and `.R` suffix.

## 12. Cross-Product Coverage

This test covers the native Bernoulli independent random-slope SD fixture in one dirty candidate worktree. It does NOT cover a live Julia run, structured-effect parity, other families, interval calibration, or a clean full-suite result.
