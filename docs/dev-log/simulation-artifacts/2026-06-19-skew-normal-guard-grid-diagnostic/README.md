# Skew-Normal Guard Grid Diagnostic

This artifact records a fixed-effect skew-normal guard-grid diagnostic for
the numerical-guard ledger. It follows the first fixed-effect pilot and the
source/fit tail-floor diagnostics, but keeps the question narrow: do
ordinary, moderate-tail, extreme-tail, and deliberately injected tail cells
surface floor exposure and fit-health warnings as explicit artifact data?

This is native R/TMB diagnostic evidence only. It is not interval
calibration, coverage evidence, power evidence, release readiness, CRAN
readiness, direct Julia evidence, or Julia-via-R evidence.

## ADEMP Summary

**Aim.** Separate generating-scale and fitted-scale skew-normal tail-floor
exposure while recording optimizer convergence, Hessian status, fixed
gradients, `check_drm()` rows, warnings, and coefficient errors.

**Data-generating mechanisms.** Eight complete-data fixed-effect cells use
`bf(y ~ x, sigma ~ z, nu ~ w), family = skew_normal()`. The grid includes a
near-symmetric reference, moderate left/right slant, a moderate slant-slope
cell, strong left/right slant cells, and two injected-tail cells with
`alpha * z` targets of -38 and -45.

**Estimands.** Formula-scale fixed effects for `mu`, `sigma`, and `nu`, plus
generating- and fitted-scale tail-floor exposure summaries.

**Methods.** Each replicate uses `drm_control(optimizer_preset = "careful")`.
No profile intervals, bootstrap intervals, random effects, bivariate
responses, structured effects, or Julia bridge paths are requested.

**Performance measures.** Fit convergence, `pdHess`, fixed-gradient status,
warning rates, floor-dominated observation counts, maximum floor log-lift,
coefficient bias/RMSE, and conservative cell decision labels.

## Files

- `run-pilot.R`: reproducible runner.
- `skew-normal-guard-grid-run-summary.csv`: one-row run summary.
- `session-info.txt`: R session information.
- `tables/skew-normal-guard-grid-conditions.csv`: simulation cells.
- `tables/skew-normal-guard-grid-fit-diagnostics.csv`: one row per fitted model.
- `tables/skew-normal-guard-grid-check-drm.csv`: `check_drm()` rows by fit.
- `tables/skew-normal-guard-grid-tail-exposure.csv`: generating/fitted tail exposure rows.
- `tables/skew-normal-guard-grid-coefficients.csv`: replicate coefficient estimates.
- `tables/skew-normal-guard-grid-coefficient-summary.csv`: coefficient bias/RMSE summaries.
- `tables/skew-normal-guard-grid-condition-summary.csv`: cell-level fit and exposure summaries.
- `tables/skew-normal-guard-grid-failures.csv`: fit failures, if any.

## Results

The grid requested 200 fits across 8 cells with 25 replicates per cell. It returned 200 fits and 0 fit errors.

Minimum convergence rate was 1, minimum `pdHess` rate was 1, and minimum fixed-gradient ok rate was 0.68.

The maximum generating-scale floor-dominated count was 8. The maximum fitted-scale floor-dominated count was 0, with maximum fitted absolute log-CDF lift 8.8817842e-16.

Overall decision label: `diagnostic_hold`.

## Interpretation

Interpretation for applied users: these rows ask whether rare, extreme
residual-tail observations make the internal skew-normal tail floor active
after fitting. A clean row means the fitted-scale floor count is zero and
the fit diagnostics are also clean. A row with non-convergence, `pdHess =
FALSE`, a large fixed gradient, or a large `skew_normal_nu` diagnostic is
not a usable inference result even if the likelihood is finite.

The decision labels are intentionally conservative. `needs_larger_grid`
means a cell had a clean guard-screen in this diagnostic and can be expanded
later if formal operating-characteristic evidence is needed.
`diagnostic_hold` means at least one fit-health or fitted-floor warning must
travel with any future claim.

What to try next for a warned applied fit: run `check_drm()`, inspect
`fit$optimizer_attempts`, simplify the `nu` formula first, rescale the
response or predictors, compare with a Gaussian location-scale model, and
avoid Wald interval interpretation until convergence, Hessian, and gradient
diagnostics are clean.

## Boundary

This artifact does not promote skew-normal recovery accuracy, standard-error
reliability, Wald/profile/bootstrap intervals, coverage, power, random
effects, structured effects, bivariate skew-normal models, residual `rho12`,
external comparator parity, release readiness, CRAN readiness, direct Julia
parity, Julia-via-R parity, or non-Gaussian REML/AI-REML.
