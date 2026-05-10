# After Task: Benchmark R-Heap Calculation Fix

## Goal

Fix the optional benchmark harness's approximate R-heap calculation so Ncells
and Vcells from `gc()` use the correct byte weights.

## Implemented

- Updated `bench/large-phylo-location.R` so `gc_used_mb()` weights Ncells by
  56 bytes and Vcells by 8 bytes.
- Updated `bench/README.md` to say the heap columns are calculated from
  `gc()` cell counts.
- Added a caveat to `docs/dev-log/benchmark-results.md` that existing rows
  collected before this fix should treat `R heap after fit MB` as rough
  historical context.

## Mathematical Contract

No likelihood, formula grammar, model API, or fitted-object storage behaviour
changed. This change affects only optional development benchmark reporting.

## Files Changed

- `bench/large-phylo-location.R`
- `bench/README.md`
- `docs/dev-log/benchmark-results.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-gc-used-mb-fix.md`

## Checks Run

- `air format bench/large-phylo-location.R bench/README.md docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-gc-used-mb-fix.md`:
  passed.
- `rg -n "bytes_per_cell|Ncells = 56|Vcells = 8|cell-count|historical context|gc_used_mb\\(\\)" bench/large-phylo-location.R bench/README.md docs/dev-log/benchmark-results.md docs/dev-log/after-task/2026-05-10-benchmark-gc-used-mb-fix.md docs/dev-log/check-log.md`:
  passed and found the corrected cell weights plus the historical-results
  caveat.
- `Rscript bench/large-phylo-location.R --rows 300 --species 20 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-gc-used-mb-fix-smoke.csv`:
  passed and wrote a fresh CSV row.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-gc-used-mb-fix-smoke.csv`:
  passed and marked the row as `timing_usable` with
  `diagnostics_recorded`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-gc-used-mb-fix-smoke.csv', check.names = FALSE); print(x[, c('gc_used_mb_before','gc_used_mb_pre_fit','gc_used_mb_post_fit','convergence','fit_sec')]); stopifnot(all(is.finite(unlist(x[, c('gc_used_mb_before','gc_used_mb_pre_fit','gc_used_mb_post_fit')]))));"`:
  passed; the smoke row reported finite heap summaries of 132.420, 132.587,
  and 135.876 MB.
- `git diff --check`: passed.

## Result

Future benchmark CSV rows report approximate R heap using the standard R
cell-size convention: Ncells are counted at 56 bytes and Vcells at 8 bytes.
The smoke row converged with convergence code 0 and reported finite heap
summaries after the helper change.

## Tests Of The Tests

The validation plan includes a small benchmark smoke run to check that the CSV
still writes and summarizes after the helper change.

## Consistency Audit

The durable benchmark table now warns readers not to interpret historical
post-fit R-heap values as peak memory. Existing object-size, max-RSS, and peak
footprint evidence remains usable.

## What Did Not Go Smoothly

The earlier helper had the Ncells and Vcells byte weights reversed. Curie's
review caught this before the benchmark table became a stronger public claim.

## Team Learning

Curie should keep checking benchmark instrumentation, not only model
convergence. Rose should require caveats when historical benchmark columns are
superseded by better instrumentation.

## Known Limitations

`gc_used_mb()` is still an approximate R-heap summary, not a cross-platform
peak-memory measure. Use operating-system tools for peak memory.

## Next Actions

- Use fresh output paths for future benchmark rows so the corrected heap
  columns are not mixed with historical rows.
- Prefer max RSS and peak footprint for memory-readiness claims.
