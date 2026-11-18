# After Task: Student-t SD likelihood oracle

## 1. Goal

Check the native Student-t ordinary random-intercept SD likelihood against an
independent calculation and confirm that the calculation uses the correct
group-level SD predictor.

## 2. Implemented

Added a one-dimensional Laplace reference to the Student SD integration test.
It evaluates the Student-t conditional density and Gaussian random-intercept
prior, finds each group mode independently, and applies the analytic scalar
curvature correction. Reversing the group-to-predictor mapping serves as a
negative control.

## 3a. Decisions and Rejected Alternatives

The check compares the fitted Laplace objective with a test-local calculation.
It does not use a second package fitting the same model, and it does not treat
profile or bootstrap routing smoke tests as interval calibration.

## 4. Files Touched

- `tests/testthat/test-student-sd-integration.R`
- `docs/dev-log/check-log.d/2026-10-18-student-sd-oracle.md`
- `docs/dev-log/after-task/2026-10-18-student-sd-oracle.md`

## 5. Checks Run

- `Rscript -e 'devtools::test(reporter="summary", filter="student-sd-integration")'`: exit 0, 15 expectations passed.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py <absolute report paths>`: 0 findings for both notes.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-10-18-student-sd-oracle.md`: the report structure passed; the full command exited 1 because nine broader programme ledgers still have unmet gates.
- `git diff --check`: pass for tracked changes. A direct whitespace scan found no trailing whitespace in the three touched files.

## 6. Tests of the Tests

The fitted objective is compared with a test-local calculation using
`stats::dt`, `stats::dnorm`, numerical mode optimization, and analytic
curvature. The reversed predictor-label control changes the oracle likelihood
by more than the asserted minimum. Existing Student tests also exercise profile
and bootstrap refitting for the SD slope target; the two bootstrap refits are
workflow smoke tests only.

## 7a. Issue Ledger

No issue was changed. The GitHub API was unreachable in the previous repository
check, so live issue overlap remains unverified. The standard `docs/dev-log/check-log.md`
was not edited because path-specific preflight found 423 refs with changes not
present in this checkout. The slice is recorded in the new `check-log.d` entry.

## 8. Consistency Audit

The slice adds tests and records their result. It does not change formula parsing, the
likelihood implementation, public support claims, examples, or pkgdown
navigation. The test uses existing `sd(id) ~ w` syntax and Student link
definitions. No capability row or roadmap status was changed.

## 9. What Did Not Go Smoothly

The broad check-log path has extensive divergent ref history. Path-specific
preflight confirmed that the new `check-log.d` and after-task paths are new and
do not overwrite another ref. An unquoted skill path initially failed to
resolve; it was corrected before editing the report.

## 10. Known Residuals

The check supports the native Student-t intercept SD likelihood and exercises
existing profile/bootstrap target routing. It does not establish repeated-
sampling calibration, other Student endpoints or effect structures, or Julia
parity. The broader family and effect-type programme remains open.

## 11. Team Learning

For random-effect SD models, a family-specific Laplace oracle should reproduce
the conditional density, group prior, mode, and curvature directly. A
group-label permutation provides a compact check that the oracle does not
silently reuse the fitted predictor order.

## 12. Cross-Product Coverage

This test covers the native R/TMB Student-t ordinary location-intercept SD
likelihood, its group-level fixed predictor mapping, and existing profile and
bootstrap refit routing. It does NOT cover Julia, Student scale or shape SD
regression, random slopes or structured effects, or interval calibration.
