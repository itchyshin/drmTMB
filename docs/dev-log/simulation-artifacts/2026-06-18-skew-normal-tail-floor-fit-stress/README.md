# Skew-Normal Tail-Floor Fit-Stress Diagnostic

This artifact records a fit-level diagnostic pilot for the skew-normal tail log
floor in `src/drmTMB.cpp`. It follows the source-level tail-floor diagnostic in
`../2026-06-18-skew-normal-tail-floor-diagnostic/`, but asks a narrower fitted
model question: when data are deliberately stressed near the
`log(Phi(alpha * z) + 1e-300)` floor, does a fitted fixed-effect
`skew_normal()` model actually evaluate observations in the floor-dominated
tail regime?

This is a diagnostic pilot, not interval calibration, coverage evidence, power
evidence, release evidence, CRAN evidence, or Julia bridge evidence.

## ADEMP Summary

**Aim.** Compare generating-scale and fitted-scale tail-floor exposure for a
small fixed-effect skew-normal stress grid, while recording convergence,
`pdHess`, fixed gradients, warnings, `check_drm()` status rows, log likelihood,
information criteria, and coefficient errors.

**Data-generating mechanisms.** Three cells use the existing Phase 18
fixed-effect skew-normal DGP with `n = 120`, `nu = 6`, `sigma` slope `0.15`,
and three replicates per cell. The ordinary reference cell leaves simulated
responses unchanged. The near-floor cell replaces 3% of observations with
values whose generating-scale `alpha * z` is `-38`. The floor-dominated cell
replaces 3% of observations with values whose generating-scale `alpha * z` is
`-45`. The source-level threshold is approximately `alpha * z = -37.0471`.

**Estimands.** The pilot tracks fixed-effect coefficient truth, estimates,
errors, bias, RMSE, and MCSE; fit-level convergence, `pdHess`, fixed-gradient,
warning, objective, log-likelihood, AIC, and BIC diagnostics; and tail-floor
exposure on both generating and fitted scales.

**Methods.** Each replicate is fit with the current fixed-effect
`skew_normal()` route and `drm_control(optimizer_preset = "careful")`. There is
no unguarded TMB likelihood comparator in this pilot, so this artifact cannot
estimate default-vs-reference likelihood differences.

**Performance measures.** The committed summaries report convergence and
`pdHess` rates, maximum fixed-gradient magnitude, warning counts, maximum
fitted-scale log-CDF lift, number of fitted floor-dominated observations,
minimum fitted `alpha * z`, coefficient bias, RMSE, and MCSE.

## Files

- `run-pilot.R`: reproducible runner.
- `skew-normal-tail-floor-fit-run-summary.csv`: one-row run summary.
- `session-info.txt`: R session information.
- `tables/skew-normal-tail-floor-fit-conditions.csv`: pilot cells.
- `tables/skew-normal-tail-floor-fit-diagnostics.csv`: one row per fit.
- `tables/skew-normal-tail-floor-fit-tail-exposure.csv`: generating and fitted
  tail-floor exposure rows.
- `tables/skew-normal-tail-floor-fit-coefficients.csv`: replicate coefficient
  estimates and errors.
- `tables/skew-normal-tail-floor-fit-coefficient-summary.csv`: coefficient
  bias, RMSE, and MCSE.
- `tables/skew-normal-tail-floor-fit-condition-summary.csv`: cell-level fit
  and fitted-tail summaries.
- `tables/skew-normal-tail-floor-fit-failures.csv`: fit failures, if any.

## Results

The pilot ran 9 requested fits across 3 cells. No fit errored. The injected
stress cells created generating-scale tail-floor exposure: the near-floor cell
had 4 floor-dominated observations per replicate at `alpha * z = -38`, and the
floor-dominated cell had 4 floor-dominated observations per replicate at
`alpha * z = -45`.

The fitted models did not evaluate any observation in the floor-dominated
regime. Across all 9 fits, the maximum fitted-scale absolute log-CDF lift was
`4.440892e-16`, the maximum fitted floor-dominated count was `0`, and the
minimum fitted `alpha * z` was `-2.701865`.

The diagnostic also shows why convergence cannot be treated as the whole
answer. The ordinary reference cell had one non-converged, non-positive-Hessian
replicate with a large fixed-gradient row and a very large fitted
`skew_normal_nu` diagnostic (`max_abs=103384102`). The stress cells converged
with positive Hessians and no warnings, but their fitted slant flipped sign and
the coefficient summaries show large slant and location shifts under the
outlier injection. This is not evidence of estimate stability; it is evidence
that the fitted model can adapt away from the source-level floor while still
requiring fit diagnostics.

## Interpretation

This pilot supports one narrow statement: in this small fixed-effect stress
grid, deliberately injected generating-scale tail-floor observations did not
produce fitted-scale floor-dominated likelihood evaluations. It also supports
Hao Qin's warning operationally: the artifact keeps non-convergence,
non-positive Hessian, fixed-gradient warnings, and large slant diagnostics in
the evidence table instead of treating convergence or finite likelihood values
as sufficient.

## Boundary

This artifact does not promote fitted skew-normal estimate stability, standard
error reliability, Wald/profile/bootstrap intervals, coverage, power, random
effects, structured effects, bivariate skew-normal models, residual `rho12`,
external comparator parity, release readiness, CRAN readiness, or Julia bridge
parity.
