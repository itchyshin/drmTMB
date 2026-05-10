# After Task: 500k Row-Pressure Benchmark

## Goal

Run a current-schema benchmark that increases row count while keeping species
count moderate, to separate observation-count scaling from species-index
pressure.

## Implemented

No package code changed. This task collected one local benchmark row for
500,000 observations and 1,000 species, then summarized it with
`bench/summarize-results.R`.

## Mathematical Contract

The benchmark used the existing univariate Gaussian phylogenetic location
model:

```r
y ~ x1 + x2 + phylo(1 | species, tree = tree)
sigma ~ 1
```

No likelihood, parameterization, formula grammar, or fitted-model API changed.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-row-pressure-500k.md`

## Checks Run

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 500000 --species 1000 --eval-max 220 --iter-max 220 --memory-light true --output /tmp/drmTMB-row-pressure-current-schema-087c000.csv`
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-row-pressure-current-schema-087c000.csv`
- `Rscript -e "x <- read.csv('/tmp/drmTMB-row-pressure-current-schema-087c000.csv', check.names = FALSE); print(x[, c('rows','species','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`

## Result

The 500,000-row, 1,000-species memory-light row converged with convergence code
0, optimizer message `relative convergence (4)`, 50 iterations, 74 function
evaluations, and 50 gradient evaluations.

| Scenario | Fit seconds | Fit object MB | Model matrix MB | TMB data MB | Post-fit R heap MB | macOS max RSS bytes | macOS peak footprint bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 500k rows, 1k species, memory-light | 131.407 | 221.206 | 76.296 | 105.249 | 1092.205 | 5,050,040,320 | 2,045,808,360 |

## Tests Of The Tests

The current-schema row included optimizer message and evaluation counts, and
the summary helper marked it as `timing_usable` with `diagnostics_recorded`.

## Consistency Audit

The result supports staged row-pressure testing for the sparse phylogenetic
location path. It does not test high-cardinality fixed-effect factors,
bivariate covariance, scale predictors at this row count, or non-Gaussian
families.

## What Did Not Go Smoothly

Nothing failed. The important caveat is that macOS max RSS is much larger than
the fitted object and post-fit R heap, so local operating-system peak memory
should be treated as a machine-specific pressure signal, not a stable package
metric.

## Team Learning

Curie should keep separating row-count evidence from species-count evidence.
Rose should reject any readiness claim that hides the 5 GB local max-RSS signal.

## Known Limitations

This is one local run on one machine. It does not cover million-row workloads,
10,000 species, factor-heavy designs, bivariate covariance, scale predictors at
500,000 rows, or non-Gaussian families.

## Next Actions

- Repeat this row in a formal benchmark table before making public performance
  claims.
- Add factor-heavy and bivariate rows before calling large-data support mature.
