# After Task: Bivariate Gaussian Slope-Only Recovery Lane

## Goal

Continue the Phase 18 evidence work (#59) with the lightest bivariate Gaussian
recovery candidate: the slope-only `mu1`/`mu2` lane (`(0 + x | p | id)`, two
random effects). It was chosen deliberately after the q6 lane showed that
heavier 6-random-effect models do not reach a positive-definite Hessian
reliably across platforms in a few fast replicates; a 2-random-effect model
converges robustly.

## Implemented

- Recovery summary and grid writer
  (`sim_summary_biv_gaussian_mu_slope_recovery.R`,
  `sim_write_biv_gaussian_mu_slope_recovery_grid.R`) reusing the smoke DGP, fit
  summariser, and runner, adding Wald intervals and an interval-coverage table.
- Opt-in `biv_gaussian_mu_slope_recovery` Actions task (choices, dispatcher,
  task paths, workflow matrix `include_in_all: false`), registry row
  `bivariate_gaussian_slope_only_recovery` (`ready_grid`, `random_slopes`), the
  recovery test, and README/NEWS notes.

## Interval Scoping And Test Stance

The lane has 10 estimands: 4 fixed `mu` coefficients, 2 residual scales, 2 slope
random-effect SDs, the slope-slope correlation, and residual `rho12`. Wald
intervals are computed only for the fixed `mu` coefficients; the two SDs and the
correlation have no Wald standard error, so they stay
`derived_interval_unavailable`. Following the q6 lesson, the CI test asserts the
coverage machinery (columns present, derived rows Wald-unavailable) rather than
finite fixed-effect Wald intervals, which are a convergence property best left
to the formal opt-in run.

## Checks Run

Local R has no package dependencies here, so the model-fitting recovery test
relies on GitHub Actions `R-CMD-check`. The registry plan logic is pure base R
and was executed against the updated CSV to set every count empirically
(registry 42, `ready_grid` 25, random-slope plan 14, operating-characteristic
14 / 10-without-source-test, preflight rows 15, bundle random_slopes 14, task
lists setequal, new row dispatches cleanly). All R files parse; CSV well-formed.

## Status Of The Recovery-Lane Track

The bivariate Gaussian recovery lanes now cover slope-only, q4 location, q6
location, and q2 scale-intercept. The same-response location-scale block is the
next candidate, but it is both convergence-fragile and depends on a likelihood
path still under design, so it should wait for a local-R session rather than a
fast CI lane.
