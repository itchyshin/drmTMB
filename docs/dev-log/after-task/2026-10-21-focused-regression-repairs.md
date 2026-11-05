# After Task: Focused Regression Repairs

## 1. Goal

Resolve the eight failures reported by the focused NB2, Poisson animal-SD, and
Student location-scale regression run, while preserving the broader random-SD
programme's in-flight changes.

## 2. Implemented

The NB2 structured-sigma fixture now draws its latent phylogenetic effect with
a Cholesky factor and uses the reviewed clear-signal seed and mean-versus-scale
gain contrast. The Poisson animal-SD test now compares predicted scales in the
covariance provider's group order. `student_ls_start()` now passes only
arguments accepted by `gaussian_ls_start()` and keeps the separate call that
initializes the Student model's phylogenetic location effect.

## 3a. Decisions and Rejected Alternatives

No likelihood or parameterization changed. The Poisson check now follows the
existing provider-order prediction contract. The NB2 test checks whether the
scale model explains the scale-structured data and whether the mean model
outperforms the scale model for a mean-structured dataset. The Student start
repair preserves its existing structured location initialization. We kept the
test-only Poisson repair because no evidence showed a prediction-order defect.
We removed the invalid Student helper arguments rather than broadening the
Gaussian helper API.

## 4. Files Touched

- `R/drmTMB.R`: removed two invalid arguments from the Gaussian-start call in
  `student_ls_start()`.
- `tests/testthat/test-poisson-animal-sd-regression.R`: aligned expected values
  and names with the covariance provider order.
- `tests/testthat/test-nbinom2-sigma-structured-recovery.R`: replaced the
  platform-sensitive eigen-based draw and repaired the comparison guard.
- `docs/dev-log/check-log.md`: recorded the focused rerun and its limits.

## 5. Checks Run

Ran:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "poisson-animal-sd-regression|nbinom2-sigma-structured-recovery|^student-location-scale$", reporter = "summary")'
```

All three files passed: NB2 structured recovery, 6 expectations; Poisson
animal SD, 11 expectations; Student location scale, 47 expectations. The test
runner reported that no live Julia engine tests ran. The package-wide suite,
`R CMD check`, and live Julia engine tests were not run.
The after-task structure check passed. Its combined completion check remains
red because the general-SD ledger still has eleven unmet programme gates; this
focused repair does not close those gates.

The broader filter `nbinom2|student-location-scale|animal-sd-regression` was
run with one thread and interrupted after exceeding the estimated 10-minute
bound, while executing the Phase 18 truncated-NB2 random-intercept grid-writer
test. It had not reported a failure before interruption, but its result is
incomplete and is not a passing check.

## 6. Tests of the Tests

The NB2 and Poisson tests were among the eight failing assertions in the
preceding focused run. The Student test reproduced four start errors before the
repair and passed afterward. The NB2 draw and seed follow the reviewed change
recorded in commits `77032e34f` and `462dd19b1`; this run did not independently
repeat their multi-seed or cross-platform checks.

## 7a. Issue Ledger

Issue #1444 remains open. It tracks the NB2 structured-sigma guard and
platform evidence. This worktree-only repair does not establish that the issue
is ready to close or update. No issue comment or status change was made.

## 8. Consistency Audit

The repairs affect a synthetic recovery fixture, a test's expected ordering,
and internal start plumbing. They do not change public syntax, fitted
likelihoods, or documentation claims. The earlier check-log entry accurately
records the failures at that time; this report supersedes it for the three
focused files. No README, vignette, roadmap, NEWS, design document, or pkgdown
navigation change was needed.

## 9. What Did Not Go Smoothly

The first Student audit inspected the base checkout rather than this active
worktree and incorrectly concluded that the bad argument forwarding was
absent. Rerunning the exact test from the active worktree reproduced the four
errors and identified the stale audit's path mistake.

## 10. Known Residuals

These checks close the eight failures in the named targeted run only. They do
not establish full-suite health, calibrated uncertainty, all-family support,
or live Julia parity. The NB2 multi-seed and Windows evidence remain those
recorded in the referenced prior commits, not newly generated evidence.

## 11. Team Learning

For parallel audits, require each reviewer to report the exact checkout path
and source commit before making a claim about whether a failure is present.
For structured predictions, compare values by returned group names rather than
assuming factor order.

## 12. Cross-Product Coverage

This checkpoint covers the named native R/TMB test routes only. It does NOT cover
live Julia execution, Julia bridge parity for these routes, other
distribution families or random-effect providers, full-suite health, or
programme-level uncertainty calibration. Continue from the active ledger and
checkpoint; keep those gates open until their own evidence passes.
