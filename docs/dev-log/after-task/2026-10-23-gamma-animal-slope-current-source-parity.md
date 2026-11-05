# After Task: Current-Source Gamma Animal-Slope Parity Rerun

## 1. Goal

Recheck the existing synthetic Gamma animal-slope comparison against the
current native and paired Julia candidates, because its earlier source
manifest no longer matched the current builders.

## 2. Implemented

No model code changed. The exact existing live parity test passed on both
current candidate worktrees. A fresh 199-file source manifest binds the tested
native and Julia trees, the executed R test, the paired Julia project files,
and the retained console log. The result remains partial slope-only evidence;
no required capability row was promoted.

## 3a. Decisions and Rejected Alternatives

The previous 2026-10-22 result cannot serve as current-source evidence because
its source manifest predates edits to both engines. I reran the existing test
instead of adding a duplicate test or changing the likelihood. This refresh
does not justify promoting a broader capability row.

## 3b. Mathematical Contract

The test uses one Gamma location animal random slope with a group-level SD
regression and unit-diagonal supplied covariance. It compares coefficient
names and estimates, convergence, group SD predictions, and Julia rowwise SD
predictions for the same synthetic data in both engines.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261023/test-console-current-source.log`
- `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261023/source-manifest-current.json`
- This report and `docs/dev-log/check-log.d/2026-10-23-gamma-animal-slope-current-source-parity.md`

## 5. Checks Run

- The full `julia-gamma-sd` test file passed, with five live Julia tests.
- The exact test, `live Julia Gamma animal slope SD estimates agree with native TMB`, passed again with one live Julia test.
- The exact run is bound to native HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1` and paired Julia HEAD `70dbf564eb670144c63c08f61ea099084d95add2`.
- The retained console log SHA-256 is `03d6ddff081db772e94e11a1cc6c715d01434c7986b212d3061fa6f3c3c522ed`. The source manifest SHA-256 is `3b62c0448f7f279aa4000f9a6078040dc3fee9c58aa399c610d9a710a1afa01a`.
- JuliaCall emitted the known non-fatal extension/dependency-install warning; the live test completed successfully.

## 6. Tests of the Tests

The exact test runs through the live Julia bridge and compares the two engines
on identical data. The first current-source run used the test-file filter and
passed five live tests. The following exact-description run retained the
one-test console log used in the source manifest.

## 8. Consistency Audit

The previous 2026-10-22 report remains a valid record of that earlier run, but
its source manifest is stale for current builders. This report supersedes it
for current-source status. The exercised slope-only shape does not establish
the broader animal intercept-plus-slope capability row. No equations, formula
grammar, examples, or public claims changed.

## 7a. Issue Ledger

Open issues #1463 and #59 were inspected. They track a broad package test sweep
and simulation reporting framework, respectively; neither is specific to this
source-bound parity rerun. No issue was changed.

## 9. What Did Not Go Smoothly

The initial exact-description filter passed to `devtools::test()` selected no
test files and ran no fits. I then ran the containing Gamma test file, followed
by the exact test with `testthat::test_file(desc = ...)`, which passed and
produced the retained console log.

## 11. Team Learning

When refreshing cross-engine evidence, distinguish a matching commit from a
matching source tree. Dirty working-tree source hashes must be refreshed even
when both HEAD values are unchanged.

## 10. Known Residuals

This is one unit-diagonal, q1 animal slope-only Gamma fixture. It does not
verify animal intercept-plus-slope blocks, non-unit covariance scaling,
precision or pedigree inputs, other families, or calibrated uncertainty. The
two candidate worktrees remain dirty, and this evidence is not a broad parity
claim.

## 12. Cross-Product Coverage

The tested cell is Gamma location, animal numeric slope only, supplied
unit-diagonal `A`, one group-level SD predictor, and the native R/TMB and Julia
engines on identical synthetic data. It does not cover intercept-plus-slope
blocks, alternate covariance inputs or scaling, other families, other
endpoints, or interval calibration.

## Next Actions

Continue with exact required rows that match the exercised effect shape, then
complete the remaining family, provider, output, recovery, and calibrated
uncertainty requirements in the active goal.
