# Binomial GLM Parity Comparator Artifact

## Purpose

This is the first executable Phase 19 comparator artifact for the plain
fixed-effect Bernoulli/binomial response family. It compares the native
`drmTMB` fixed-effect `stats::binomial(link = "logit")` route with
`stats::glm()` on the two supported response encodings:

- 0/1 Bernoulli rows;
- `cbind(successes, failures)` binomial counts.

The artifact supports only the parity claim: on the overlapping fixed-effect
logit likelihood, `drmTMB` and `stats::glm()` agree on coefficients, standard
errors, `logLik`, AIC, and BIC to numerical precision. It is not a speed
benchmark, interval-calibration result, random-effect result, structured-effect
result, bivariate result, or Julia-bridge result.

## Provenance

- Label: `parity`
- Generated: 2026-06-16
- Source SHA before artifact generation:
  `e32654479c5f177a9de7e076e9b49db8a4cf2ac6`
- Branch: `codex/comparator-release-prep`
- Dirty state before generation: clean branch off `origin/main`
- Dirty state after generation: the files in this directory were new
- R: 4.5.2
- drmTMB: 0.1.4
- TMB: 1.9.21
- testthat: 3.3.2
- Platform: `aarch64-apple-darwin20`
- OS: `Darwin 25.5.0 arm64`
- Master seed: `20260616`
- Replicates: `3` per condition
- Threads/cores used by writer: `1`

## Command

```r
devtools::load_all(".", quiet = TRUE)
paths <- c(
  "sim/R/sim_registry.R",
  "sim/R/sim_utils.R",
  "sim/R/sim_runner.R",
  "sim/R/sim_aggregate.R",
  "sim/R/sim_uncertainty.R",
  "sim/dgp/sim_dgp_binomial_fixed_effect.R",
  "sim/fit/sim_summarise_binomial_fixed_effect.R",
  "sim/run/sim_run_binomial_fixed_effect_smoke.R",
  "sim/run/sim_summary_binomial_fixed_effect_smoke.R",
  "sim/run/sim_write_binomial_fixed_effect_grid.R"
)
for (path in paths) {
  source(system.file(path, package = "drmTMB", mustWork = TRUE),
    local = globalenv()
  )
}
phase18_write_binomial_fe_grid_outputs(
  output_dir = "docs/dev-log/comparator-results/2026-06-16-binomial-glm-parity",
  conditions = phase18_binomial_fe_conditions(
    encoding = c("binary", "cbind"),
    n = 320L,
    trial_min = 12L,
    trial_max = 24L
  ),
  n_rep = 3L,
  master_seed = 20260616L,
  overwrite = TRUE,
  cores = 1L
)
```

## Tables

| File | Rows | Meaning |
| --- | ---: | --- |
| `tables/binomial-fe-aggregate.csv` | 4 | Bias, RMSE, convergence, `pdHess`, warning, elapsed-time, and MCSE summaries for the two coefficients in each encoding. |
| `tables/binomial-fe-replicates.csv` | 12 | Per-replicate coefficient, standard-error, likelihood, AIC, BIC, convergence, `pdHess`, warning, and timing rows. |
| `tables/binomial-fe-manifest.csv` | 6 | Seed, status, warning count, error, and elapsed time for each replicate. |
| `tables/binomial-fe-failures.csv` | 0 | Failure ledger; header-only here because every fit returned `ok`. |
| `tables/binomial-fe-wald-intervals.csv` | 12 | Wald interval rows on the formula-coefficient scale. |
| `tables/binomial-fe-wald-coverage.csv` | 4 | Tiny-run Wald coverage summaries. These are diagnostic only and do not support interval-calibration language. |
| `tables/binomial-fe-glm-parity.csv` | 4 | `drmTMB` versus `stats::glm()` parity summary. |

## Comparator Result

The largest absolute `drmTMB` versus `stats::glm()` differences in this artifact
are:

- coefficient: `1.894251e-11`;
- standard error: `6.393821e-08`;
- `logLik`: `2.728484e-12`;
- AIC: `5.456968e-12`;
- BIC: `5.456968e-12`.

All six target fits converged, all six reported `pdHess = TRUE`, and the
failure ledger has zero rows.

## Boundary

The Wald coverage table is included because the writer produces it, but
`n_rep = 3` is intentionally too small for interval-calibration language. Any
claim about calibrated binomial intervals needs a separate MCSE-backed
promotion run with substantially larger replicate counts and a failure audit.
