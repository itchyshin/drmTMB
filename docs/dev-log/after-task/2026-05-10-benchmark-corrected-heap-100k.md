# After Task: Corrected-Heap 100k Benchmark Row

## Goal

Collect one fresh 100,000-row, 1,000-species memory-light benchmark row after
fixing `gc_used_mb()` so the durable table has at least one corrected R-heap
value.

## Implemented

- Ran a fresh 100k Gaussian phylogenetic memory-light baseline with the fixed
  benchmark helper.
- Added the corrected-heap row to `docs/dev-log/benchmark-results.md`.
- Recorded the command and summary in `docs/dev-log/check-log.md`.

## Mathematical Contract

The benchmark used the existing univariate Gaussian phylogenetic location
model:

```r
y ~ x1 + x2 + phylo(1 | species, tree = tree)
sigma ~ 1
```

No likelihood, parameterization, formula grammar, fitted-object API, or
benchmark generator changed.

## Files Changed

- `docs/dev-log/benchmark-results.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-corrected-heap-100k.md`

## Checks Run

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 220 --iter-max 220 --memory-light true --output /tmp/drmTMB-gc-fixed-100k-baseline-d9d5240.csv`:
  passed.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-gc-fixed-100k-baseline-d9d5240.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-gc-fixed-100k-baseline-d9d5240.csv', check.names = FALSE); print(x[, c('rows','species','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`:
  passed.
- `air format docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-corrected-heap-100k.md`:
  passed.
- `rg -n "corrected heap|Corrected|165\\.544|gc-fixed-100k|1,401,323,520|timing usable, corrected heap" docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-corrected-heap-100k.md`:
  passed and found the corrected-heap row and after-task evidence.
- `git diff --check`: passed.

## Result

The fresh corrected-heap 100,000-row, 1,000-species memory-light row converged
with convergence code 0, optimizer message `relative convergence (4)`, 45
iterations, 69 function evaluations, and 46 gradient evaluations.

| Scenario | Fit seconds | Fit object MB | Model matrix MB | TMB data MB | Corrected post-fit R heap MB | macOS max RSS bytes | macOS peak footprint bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 100k rows, 1k species, memory-light | 28.450 | 45.730 | 15.261 | 21.326 | 165.544 | 1,401,323,520 | 721,061,472 |

## Tests Of The Tests

The summary helper marked the row as `timing_usable` with
`diagnostics_recorded`. The row was collected after the `gc_used_mb()` cell
weights were corrected.

## Consistency Audit

The corrected row supports interpretation of the R-heap column for this one
scenario. Historical rows remain useful for object sizes, convergence, and OS
peak-memory evidence, but their R-heap values should be treated cautiously.

## What Did Not Go Smoothly

Nothing failed. The corrected R-heap value is much lower than the historical
row, confirming that the caveat was necessary.

## Team Learning

Curie should ask for one fresh post-fix row whenever benchmark instrumentation
changes. Rose should keep historical rows labelled when a column's meaning
changes.

## Known Limitations

This is one corrected-heap row only. It does not recompute every historical
scenario, and it does not change the package model behaviour.

## Next Actions

- Use corrected-heap rows for future benchmark claims.
- Keep OS max RSS and peak footprint as the main peak-memory evidence.
