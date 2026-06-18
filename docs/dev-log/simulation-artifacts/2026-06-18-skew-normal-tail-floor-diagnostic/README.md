# Skew-Normal Tail-Floor Diagnostic

This artifact records a source-level diagnostic for the skew-normal tail log
floor in `src/drmTMB.cpp`. It is a numerical-guard artifact, not a fit-level
simulation, interval-calibration study, or release-promotion claim.

## ADEMP Summary

**Aim.** Check when the TMB expression `log(Phi(alpha * z) + 1e-300)` matches
the exact `log(Phi(alpha * z))` contribution and when the floor deliberately
caps an extreme tail contribution.

**Data-generating mechanism.** No fitted data are generated. The diagnostic
evaluates a deterministic grid of `alpha * z` values, because the guard acts on
that scalar tail-CDF argument inside the skew-normal log density.

**Estimands.** Exact log-CDF contribution, floored log-CDF contribution,
log-density lift from the floor, whether the floor dominates the raw CDF, and
whether the floored contribution remains finite.

**Methods.** The exact reference uses `pnorm(alpha_z, log.p = TRUE)`. The TMB
source-level reference uses `log(pnorm(alpha_z) + 1e-300)`, matching the C++
guard expression. The diagnostic evaluates ordinary tail cells, near-floor
cells, and floor-dominated extreme-tail cells.

**Performance measures.** Maximum absolute log-CDF lift, number of
floor-dominated points, the threshold where `Phi(alpha * z) = 1e-300`, and
finite-value status.

## Files

- `run-pilot.R`: reproducible runner.
- `skew-normal-tail-floor-run-summary.csv`: one-row run summary.
- `session-info.txt`: R session information.
- `tables/skew-normal-tail-floor-grid.csv`: point-level diagnostic grid.
- `tables/skew-normal-tail-floor-summary.csv`: cell-level diagnostic summary.

## Results

The floor starts to dominate at about `alpha * z = -37.0471`, where
`Phi(alpha * z)` is approximately `1e-300` and the floored log contribution is
near `log(1e-300) = -690.7755`.

For ordinary tail values from `alpha * z = -8` through `8`, the maximum absolute
log-CDF lift was `4.434133e-17`, so the floor is numerically invisible at this
source-level scale. For near-floor values, the largest lift was `35.78169` log
units at `alpha * z = -38`. For floor-dominated extreme tails, the largest lift
was `2514.526` log units at `alpha * z = -80`, because the source-level guard
caps the tail contribution at `log(1e-300)` instead of allowing a much smaller
exact log probability.

All floored values were finite.

## Interpretation

This diagnostic supports a narrow statement: the skew-normal tail floor is
effectively inactive for ordinary `alpha * z` values in this grid, and it
becomes a deliberate finite-tail cap only in extreme source-level tail cells.
It does not show that fitted skew-normal estimates, standard errors, Hessian
status, intervals, or scientific conclusions are unchanged under strong-skew
or outlier-heavy data. Those remain future fit-level guard-sensitivity work.

## Boundary

This artifact does not support random effects, structured effects, bivariate
skew-normal models, residual `rho12`, latent `skew(id)`, profile/bootstrap
interval calibration, external comparator parity, coverage, power, release
readiness, or CRAN readiness.
