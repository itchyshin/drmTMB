# After Task: 100k Storage-Mode Benchmark Comparison

## Goal

Compare current-schema 100,000-row benchmark output for memory-light and
default fitted-object storage on the same phylogenetic Gaussian location
scenario.

## Implemented

No package code changed. This task collected two local benchmark rows in a
temporary CSV and summarized them with `bench/summarize-results.R`.

## Mathematical Contract

Both runs used the existing univariate Gaussian phylogenetic location model:

```r
y ~ x1 + x2 + phylo(1 | species, tree = tree)
sigma ~ 1
```

No likelihood, parameterization, formula grammar, or fitted-model API changed.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-storage-comparison-100k.md`

## Checks Run

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --memory-light true --output /tmp/drmTMB-storage-current-schema-25640258868.csv`
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --memory-light false --output /tmp/drmTMB-storage-current-schema-25640258868.csv`
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-storage-current-schema-25640258868.csv`
- `Rscript -e "x <- read.csv('/tmp/drmTMB-storage-current-schema-25640258868.csv', check.names = FALSE); print(x[, c('memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit')]);"`

## Result

Both rows converged with convergence code 0, optimizer message
`relative convergence (4)`, 45 iterations, 69 function evaluations, and 46
gradient evaluations.

| Storage mode | Fit seconds | Fit object MB | Model matrix MB | TMB data MB | Post-fit R heap MB | macOS max RSS bytes | macOS peak footprint bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| memory-light | 25.074 | 45.730 | 15.261 | 21.326 | 405.741 | 1,415,626,752 | 723,666,504 |
| default | 25.070 | 54.935 | 15.261 | 21.326 | 500.926 | 1,399,848,960 | 678,839,880 |

The memory-light fitted object was about 9.205 MB smaller, and the post-fit R
heap was about 95.185 MB lower in this run. The single-run macOS peak-memory
numbers did not move in the same direction, so they should be treated as noisy
local operating-system evidence rather than a storage-control guarantee.

## Tests Of The Tests

The two rows used the same generated scenario, optimizer budget, and output
schema. `bench/summarize-results.R` confirmed both rows had current optimizer
diagnostics.

## Consistency Audit

The result supports the current documentation claim: `drm_control()` helps
post-fit storage, but it does not remove the dense model matrices or TMB data
needed during fitting. It does not prove million-row readiness.

## What Did Not Go Smoothly

The OS peak-memory figures were not monotone with the fitted-object storage
choice. That is a reminder to repeat benchmark rows before making hardware
claims.

## Team Learning

Curie should separate R object-size evidence from OS peak-memory evidence.
Grace should prefer repeated rows before treating a peak-memory difference as
meaningful. Rose should continue blocking broad readiness claims from one
100k-row pair.

## Known Limitations

This is one local 100k-row pair on one machine. It does not cover factor-heavy
fixed effects, `sigma ~ x`, 5,000 species, or million-row workloads.

## Next Actions

- Repeat the pair when a stable benchmark-results table is prepared.
- Run a current-schema `sigma ~ x` 100k row after the CI queue is green.
