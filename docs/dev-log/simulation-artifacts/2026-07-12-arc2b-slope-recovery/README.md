# Arc 2b — mu random slope `(0 + x | id)` recovery evidence

**Date:** 2026-07-12 · **Scope:** the five families that gained a `mu` random
intercept in Arc 2a — binomial, cumulative_logit, skew_normal, tweedie,
zero_one_beta — now also accept one independent `mu` random slope `(0 + x | id)`.

## What this is

Fisher's plan-review flagged that a single-seed point fit is blind to the
systematic ML-Laplace small-cluster RE-SD bias, so a smoke test cannot earn a
"recovery-verified" tick. This is the **≥50-seed local bias sweep** that backs the
claim: 60 seeds per family at `n_id = 40`, `n_each = 15`, true slope SD = 0.50,
ML-Laplace. Generator: `scratchpad/arc2b_slope_bias_sweep.R` (each family reuses the
Arc-2a per-family DGP with the additive intercept replaced by a multiplicative slope
`slope[id] * x` on the linear predictor). BLUP-vs-truth correlation is measured on
the linear-predictor scale (the scale the slope RE lives on for all five families).

## Result (`bias-table.tsv`)

| family | n_ok/60 | sd_hat mean (true 0.50) | rel-bias mean | BLUP cor median (min) |
|---|---|---|---|---|
| binomial (trials>1) | 60 | 0.490 | −2.1% | 0.945 (0.902) |
| skew_normal | 60 | 0.487 | −2.6% | 0.929 (0.869) |
| zero_one_beta | 60 | 0.485 | −3.0% | 0.899 (0.807) |
| tweedie | 60 | 0.484 | −3.2% | 0.861 (0.733) |
| cumulative_logit | 60 | 0.457 | −8.7% | 0.695 (0.428) |

## Reading it honestly

- **Point recovery is real:** every family converges 60/60 with `pdHess`, recovers
  the slope-SD magnitude to within single-digit-percent bias, and recovers the
  per-group slopes (BLUP correlation 0.69–0.95).
- **The bias is downward and small-cluster, as expected.** cumulative_logit is the
  noisiest (−8.7%, the lowest-information family — ordinal categories × modest
  per-group n), the rest sit at −2% to −3% at `n_id = 40`. This is the documented
  Laplace bias; it shrinks as the number of groups grows.
- **This is `point_fit_recovery`, not coverage.** No interval-coverage claim is made
  here; DG3 coverage (a Totoro campaign) is deferred and would be needed before any
  `supported`/`inference_ready` promotion.

Per-family single-seed DG2 sentinels with these thresholds:
`tests/testthat/test-arc2b-mu-random-slope.R`.
