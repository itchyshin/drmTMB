# Binomial fixed-effect interval-calibration artifact

This artifact banks an MCSE-backed fixed-effect interval-calibration run for
the native `stats::binomial(link = "logit")` first slice. It uses the existing
Phase 18 `binomial_fixed_effect` writer and covers the two public response
encodings: a 0/1 Bernoulli column and `cbind(successes, failures)`.

Interpretation label: `promotion_candidate`. The artifact is strong enough for
bounded pilot-language about Wald interval calibration in these fixed-effect
cells. It is not headline coverage evidence for every binomial use case.

## Provenance

- Source SHA before artifact generation:
  `a34757604d44a3c1650b72d1677b553990005284`
- Branch: `codex/binomial-interval-calibration`
- Package version: `drmTMB 0.1.3.9000`
- R version: `R version 4.5.2 (2025-10-31)`
- TMB version: `1.9.21`
- testthat version: `3.3.2`
- Master seed: `20260617`
- Conditions: 6 cells
- Replicates: 500 per cell
- Backend: `multicore`, requested `10` cores
- Dirty state after generation: this artifact directory only

The run command sourced the Phase 18 simulation helpers from the installed
package namespace after `devtools::load_all(".", quiet = TRUE)`, then called:

```r
phase18_write_binomial_fe_grid_outputs(
  output_dir = "docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration",
  conditions = phase18_binomial_fe_conditions(
    encoding = c("binary", "cbind"),
    n = c(240L, 480L),
    trial_min = c(10L, 20L),
    trial_max = c(18L, 30L)
  ),
  n_rep = 500L,
  master_seed = 20260617L,
  overwrite = TRUE,
  cores = 10L,
  backend = "multicore"
)
```

The temporary per-replicate RDS cache was removed before commit. The committed
artifact is the CSV evidence only.

## Files

- `binomial-fe-interval-calibration-run-summary.csv`: one-row headline summary.
- `tables/binomial-fe-aggregate.csv`: bias, RMSE, MCSE, convergence,
  `pdHess`, warning rate, and elapsed summaries by cell and coefficient.
- `tables/binomial-fe-replicates.csv`: replicate-level coefficient and
  `stats::glm()` comparator summaries.
- `tables/binomial-fe-manifest.csv`: one row per fit attempt.
- `tables/binomial-fe-failures.csv`: failure ledger; header-only for this run.
- `tables/binomial-fe-wald-intervals.csv`: replicate-level Wald intervals.
- `tables/binomial-fe-wald-coverage.csv`: coverage and coverage MCSE by cell
  and coefficient.
- `tables/binomial-fe-glm-parity.csv`: maximum `drmTMB` versus `stats::glm()`
  coefficient, standard-error, `logLik`, AIC, and BIC differences.

## Results

The run attempted 3,000 fixed-effect binomial fits and produced 6,000
coefficient rows.

| Metric | Value |
| --- | ---: |
| Fit attempts | 3,000 |
| `ok` fits | 3,000 |
| Failure rows | 0 |
| Minimum convergence rate | 1.000 |
| Minimum `pdHess` rate | 1.000 |
| Maximum warning rate | 0.000 |
| Minimum Wald coverage | 0.946 |
| Maximum Wald coverage | 0.964 |
| Maximum coverage MCSE | 0.01010782 |
| Maximum absolute bias | 0.009026694 |
| Maximum RMSE | 0.1413425 |
| Maximum bias MCSE | 0.006326178 |
| Maximum RMSE MCSE | 0.004502070 |
| Maximum absolute coefficient difference versus `stats::glm()` | 1.502857e-08 |
| Maximum absolute SE difference versus `stats::glm()` | 1.545213e-05 |
| Maximum absolute `logLik` difference versus `stats::glm()` | 1.750777e-11 |
| Maximum absolute AIC/BIC difference versus `stats::glm()` | 3.501555e-11 |

The Wald coverage rows all use 500 intervals. Coverage ranges from 0.946 to
0.964 across the 12 cell-by-parameter summaries, with maximum coverage MCSE
0.01010782.

## Boundaries

This artifact supports only the fixed-effect native TMB binomial first slice:

```text
Y_i ~ Binomial(n_i, mu_i)
logit(mu_i) = beta_0 + beta_1 x_i
```

It does not support binomial random effects, structured effects, bivariate or
mixed-response binomial models, non-logit links, proportions plus `weights`,
weights-as-trials, a `bernoulli()` alias, Julia bridge support, speed claims,
or release readiness.
