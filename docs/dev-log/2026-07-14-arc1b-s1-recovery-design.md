# Arc 1b-S1 retained-denominator recovery design

**Frozen:** 2026-07-14, before the campaign
**Estimator:** native TMB, `REML = TRUE`
**Claim ceiling:** `point_fit_recovery`

This campaign evaluates only the matched labelled bivariate-Gaussian spatial
q2 location-intercept cell admitted in Arc 1b-S1. It does not evaluate
intervals, coverage, slopes, range estimation, scale-side structure, other
providers, non-Gaussian REML, or AI-REML.

## Data-generating model

The simulation follows the equation and parameter order frozen in
`docs/dev-log/2026-07-14-arc1b-s1-symbolic-alignment.md`. It uses distinct
standard-normal predictors `x1` and `x2`, the production fixed coordinate
kernel (ring geometry, median-positive-distance range, `1e-6` diagonal
jitter), and complete paired responses with unit weights.

| Quantity | Truth |
|---|---:|
| `beta_mu1` | `(0.30, 0.50)` |
| `beta_mu2` | `(-0.20, -0.25)` |
| spatial SD `mu1` | `0.80` |
| spatial SD `mu2` | `0.65` |
| spatial correlation | `0.35` |
| residual `sigma1` | `0.30` |
| residual `sigma2` | `0.35` |
| residual `rho12` | `-0.20` |

## Information grid and denominator

Cross `n_site = 16, 32, 64` with `n_each = 3, 6`. Run 200 deterministic
replicates per cell: 6 cells and 1,200 attempted fits total. Every attempt is
retained, including errors, non-zero optimizer codes, non-positive Hessians,
and boundary estimates. The master seed is `2026071403`; a row seed is a
deterministic function of the cell and replicate.

Run a two-replicate local smoke first. The full campaign runs on Totoro with
at most 50 forked workers and `OPENBLAS_NUM_THREADS=1`; it never runs on
GitHub Actions and its raw output remains local under the dev-log simulation
artifact directory.

## Recorded evidence

Each attempted fit records cell, replicate, seed, elapsed time, error and
warning text, optimizer code, `pdHess`, maximum absolute outer gradient,
estimates for the two spatial SDs, spatial correlation, residual SDs and
residual correlation, plus target-boundary flags. Summaries retain the full
attempted denominator and report fit-success, convergence, `pdHess`, and
boundary rates. Per parameter they report usable count, bias, RMSE, empirical
SD, and the Monte Carlo standard error of bias.

## Predeclared interpretation gate

The campaign supports `point_fit_recovery` only if:

1. all 1,200 attempts are present and uniquely keyed;
2. the high-information cells (`n_site >= 32`, `n_each = 6`) have at least
   95% optimizer convergence and 90% `pdHess`;
3. in the highest-information cell, absolute bias is at most `0.10` for each
   spatial SD and `0.12` for the spatial correlation;
4. spatial-SD and correlation RMSE do not increase from 32 to 64 sites at
   `n_each = 6`, allowing one MCSE of the paired cell-level RMSE estimates;
5. any failed gate is reported as a limitation rather than removed from the
   denominator or repaired after seeing the result.

These are recovery gates, not interval or nominal-coverage gates.
