# After Task: 100k Species-Pressure Benchmark

## Goal

Run a current-schema benchmark that increases species count while holding rows
at 100,000, to separate tree/species-index scaling from row-count scaling.

## Implemented

No package code changed. This task collected one local benchmark row for
100,000 observations and 5,000 species, then summarized it with
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
- `docs/dev-log/after-task/2026-05-10-benchmark-species-pressure-100k.md`

## Checks Run

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 5000 --eval-max 220 --iter-max 220 --memory-light true --output /tmp/drmTMB-species-pressure-current-schema-25640492608.csv`
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-species-pressure-current-schema-25640492608.csv`
- `Rscript -e "x <- read.csv('/tmp/drmTMB-species-pressure-current-schema-25640492608.csv', check.names = FALSE); print(x[, c('rows','species','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`

## Result

The 100,000-row, 5,000-species memory-light row converged with convergence code
0, optimizer message `relative convergence (4)`, 53 iterations, 66 function
evaluations, and 54 gradient evaluations.

| Scenario | Fit seconds | Fit object MB | Model matrix MB | TMB data MB | Post-fit R heap MB | macOS max RSS bytes | macOS peak footprint bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 100k rows, 5k species, memory-light | 32.492 | 52.764 | 15.261 | 22.669 | 417.313 | 1,654,964,224 | 664,749,976 |

## Tests Of The Tests

The current-schema row included optimizer message and evaluation counts, and
the summary helper marked it as `timing_usable` with `diagnostics_recorded`.

## Consistency Audit

The result supports staged species-pressure testing for the sparse
phylogenetic location path. It does not test high-cardinality fixed-effect
factors, bivariate covariance, or non-Gaussian families.

## What Did Not Go Smoothly

Nothing failed. The important caveat is that the row count remained 100,000;
this is species pressure, not million-row pressure.

## Team Learning

Curie should keep treating row count, species count, factor expansion, and
scale predictors as separate stressors. Rose should block any benchmark table
that merges them into one broad readiness claim.

## Known Limitations

This is one local run on one machine. It does not cover 10,000 species,
million-row workloads, factor-heavy designs, or non-Gaussian families.

## Next Actions

- Repeat this row when building a formal benchmark table.
- Try a 500k-row baseline only after the current CI queue is green and local
  memory remains comfortable.
