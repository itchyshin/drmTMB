# After Task: 100k Sigma-Predictor Benchmark

## Goal

Run a current-schema 100,000-row benchmark for a large phylogenetic Gaussian
location-scale model with a predictor in the residual-scale formula.

## Implemented

No package code changed. This task collected one local benchmark row for
`sigma ~ x1` and summarized it with `bench/summarize-results.R`.

## Mathematical Contract

The benchmark used the existing univariate Gaussian phylogenetic
location-scale model:

```r
y ~ x1 + x2 + phylo(1 | species, tree = tree)
sigma ~ x1
```

No likelihood, parameterization, formula grammar, or fitted-model API changed.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-sigma-x-100k.md`

## Checks Run

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 220 --iter-max 220 --sigma-x true --memory-light true --output /tmp/drmTMB-sigma-x-current-schema-25640258868.csv`
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-sigma-x-current-schema-25640258868.csv`
- `Rscript -e "x <- read.csv('/tmp/drmTMB-sigma-x-current-schema-25640258868.csv', check.names = FALSE); print(x[, c('sigma_x','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat')]);"`

## Result

The 100,000-row, 1,000-species `sigma ~ x1` memory-light row converged with
convergence code 0, optimizer message `relative convergence (4)`, 65
iterations, 97 function evaluations, and 66 gradient evaluations.

| Scenario | Fit seconds | Fit object MB | Model matrix MB | TMB data MB | Post-fit R heap MB | macOS max RSS bytes | macOS peak footprint bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sigma ~ x1`, memory-light | 62.701 | 47.257 | 16.024 | 22.089 | 416.295 | 1,779,056,640 | 742,148,088 |

## Tests Of The Tests

The current-schema row included optimizer message and evaluation counts, and
the summary helper marked it as `timing_usable` with `diagnostics_recorded`.

## Consistency Audit

The row supports the staged benchmark story: a scale predictor can be run at
100k rows in this simple phylogenetic Gaussian scenario, but it takes longer
than the `sigma ~ 1` baseline and does not prove factor-heavy or million-row
readiness.

## What Did Not Go Smoothly

Nothing failed. The main caveat is that this benchmark used a simple numeric
scale predictor rather than high-cardinality scale factors.

## Team Learning

Curie should keep adding one stressor at a time. Rose should block any summary
that turns this into a general large-data guarantee.

## Known Limitations

This is one local 100k-row run on one machine. It does not cover factor-heavy
models, bivariate models, non-Gaussian families, or million-row workloads.

## Next Actions

- Repeat this row when preparing a benchmark-results table.
- Try a 100k, 5,000-species row only after the current CI queue is green.
