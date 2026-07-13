# Arc 2c — sigma random intercept `(1 | id)` recovery evidence

**Date:** 2026-07-12 · **Scope:** the two positive-continuous families that gained
a `mu` random intercept in Arc 2a — lognormal and Gamma — now also accept one
independent residual-scale random intercept `sigma ~ (1 | id)`, mirroring the
existing gaussian/nbinom2 sigma-RE machinery.

## What this is

Fisher's plan-review bar: a single-seed point fit is blind to the systematic
ML-Laplace small-cluster RE-SD bias, so a smoke test cannot earn a
"recovery-verified" tick. This is the **≥50-seed local bias sweep** that backs the
claim: 60 seeds per family at `n_id = 40`, `n_each = 15`, true sigma-RE SD = 0.40,
ML-Laplace. Generator: `generate.R` (in this directory). The random intercept
lives on the **log-sigma** scale for both families (lognormal `sigma` is the sdlog;
Gamma `sigma` is the coefficient of variation), so BLUP-vs-truth correlation is
measured there.

Data-generating processes (per-group log-scale deviation `u[id]`, SD 0.40):

- **lognormal:** `y ~ rlnorm(meanlog = 0.2 + 0.5 x, sdlog = exp(-0.5 + u[id]))`.
- **Gamma (log link):** `mu = exp(0.2 + 0.5 x)`, `sigma = exp(-0.6 + u[id])`,
  `shape = 1 / sigma^2`, `scale = mu * sigma^2`.

## Result (`bias-table.tsv`)

| family | n_ok/60 | sd_hat mean (true 0.40) | rel-bias mean | BLUP cor median (min) |
|---|---|---|---|---|
| lognormal | 60 | 0.385 | −3.7% | 0.905 (0.821) |
| gamma | 60 | 0.388 | −3.0% | 0.911 (0.836) |

## Reading it honestly

- **Point recovery is real:** both families converge 60/60 with `pdHess`, recover
  the sigma-RE-SD magnitude to within single-digit-percent mean bias, and recover
  the per-group log-sigma deviations (BLUP correlation median ~0.91, min ~0.82).
- **The bias is downward and small-cluster, as expected.** −3% to −4% at
  `n_id = 40`; this is the documented Laplace RE-SD bias and it shrinks as the
  number of groups grows.
- **This is `point_fit_recovery`, not coverage.** No interval-coverage claim is
  made here; DG3 coverage (a Totoro campaign) is deferred and would be needed
  before any `supported`/`inference_ready` promotion.

Per-family single-seed DG2 sentinels with these thresholds (plus the two rejection
gates — no `mu`+`sigma` random-effect combination, intercepts only):
`tests/testthat/test-arc2c-sigma-random-intercept.R`.
