# Skew-Normal Fixed-Effect Pilot

This pilot extends the evidence ledger for the implemented fixed-effect
`skew_normal()` first slice. It is **diagnostic pilot evidence**, not promotion
evidence for a release headline.

## ADEMP Summary

**Aim.** Check whether the existing fixed-effect `skew_normal()` runner gives
stable point estimates, Wald intervals, convergence diagnostics, and positive
Hessian diagnostics across left-skew, near-symmetric, and right-skew cells.

**Data-generating mechanism.** Each replicate uses
`bf(y ~ x, sigma ~ z, nu ~ w)` with `n = 720`, `beta_mu = (0.20, 0.40)`,
`beta_sigma = (log(0.70), 0.15)`, `rho(x, w) = 0.20`, `nu` intercepts
`-1.20`, `0`, and `1.20`, and `nu` slopes `0` and `0.35`. Responses are drawn
from the public moment parameterization and transformed internally to the
Azzalini-style native skew-normal parameters.

**Estimands.** Formula-scale fixed effects for `mu`, `sigma`, and `nu`; the
main diagnostic terms are `nu:(Intercept)` and `nu:w`.

**Methods.** `drmTMB(..., family = skew_normal())` with
`drm_control(optimizer_preset = "careful")`, using the existing Phase 18
fixed-effect skew-normal runner. No external comparator is fitted here.

**Performance measures.** Bias, RMSE, mean absolute error, convergence rate,
`pdHess` rate, warning rate, elapsed time, 70% Wald interval coverage, and MCSE
columns produced by the existing Phase 18 summariser.

## Files

- `run-pilot.R`: reproducible runner.
- `skew-normal-fixed-effect-pilot-summary.csv`: one-row run summary.
- `session-info.txt`: R session information.
- `tables/skew-normal-fe-conditions.csv`: simulation cells.
- `tables/skew-normal-fe-condition-summary.csv`: cell-level diagnostics.
- `tables/skew-normal-fe-aggregate.csv`: parameter-level aggregate bias/RMSE.
- `tables/skew-normal-fe-replicates.csv`: replicate-level estimates.
- `tables/skew-normal-fe-manifest.csv`: replicate status ledger.
- `tables/skew-normal-fe-failures.csv`: warning/error ledger.
- `tables/skew-normal-fe-wald-intervals.csv`: Wald intervals.
- `tables/skew-normal-fe-wald-coverage.csv`: Wald coverage summary.
- `figures/skew-normal-fixed-effect-pilot.png`: diagnostic visual summary.

The raw per-replicate RDS files are generated transiently by the runner and
deleted before the artifact is committed.

## Conditions

| Cell | n | nu intercept | nu slope | sigma slope | rho(x, w) |
| --- | ---: | ---: | ---: | ---: | ---: |
| C1 | 720 | -1.20 | 0.00 | 0.15 | 0.20 |
| C2 | 720 | 0.00 | 0.00 | 0.15 | 0.20 |
| C3 | 720 | 1.20 | 0.00 | 0.15 | 0.20 |
| C4 | 720 | -1.20 | 0.35 | 0.15 | 0.20 |
| C5 | 720 | 0.00 | 0.35 | 0.15 | 0.20 |
| C6 | 720 | 1.20 | 0.35 | 0.15 | 0.20 |

Each cell uses 25 replicates, for 150 fitted models.

## Results

All 150 fits returned `ok`; there were no skipped fits, no errors, and no
captured warnings. Each cell had convergence rate 1.000 and `pdHess` rate
1.000. The mean elapsed time recorded by the runner was 0.119 seconds per fit
on this local 4-core multicore run.

For the slant terms, the largest absolute bias was 0.307 on the formula scale,
and the largest RMSE was 0.671. The slant-term 70% Wald coverage ranged from
0.64 to 0.96, with coverage MCSE between 0.039 and 0.096 at 25 replicates per
cell.

Interpretation: this pilot supports the fixed-effect skew-normal route as
stable enough for further formal operating-characteristic work in these six
cells. It does **not** support calibrated interval language: the replicate
count is too small, the MCSE is large, and the slant Wald intervals vary around
the nominal 70% target.

## Boundary

This artifact does not support random effects, `sd(group)`, structured effects,
known sampling covariance, bivariate skew-normal models, residual `rho12`,
latent `skew(id)`, external fitted-comparator parity, speed claims,
profile/bootstrap interval calibration, or release promotion.

The reporting follows the ADEMP framing from Morris, White, and Crowther (2019)
and the simulation-reporting discipline in Williams et al. (2024).
