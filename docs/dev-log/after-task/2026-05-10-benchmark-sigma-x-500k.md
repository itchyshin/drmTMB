# After Task: 500k `sigma ~ x1` Benchmark

## Goal

Test whether the current Gaussian phylogenetic benchmark harness can fit a
500,000-row, 1,000-species model when the residual scale has a predictor,
`sigma ~ x1`.

## Implemented

- Ran the benchmark with 500,000 rows, 1,000 species, `sigma ~ x1`, and
  memory-light output storage.
- Summarized the output with `bench/summarize-results.R`.
- Added the benchmark row to `docs/dev-log/benchmark-results.md`.
- Recorded the command evidence in `docs/dev-log/check-log.md`.

## Mathematical Contract

No likelihood, parameterization, or formula grammar changed. The benchmark uses
the existing Gaussian phylogenetic location-scale contract:

```r
bf(y ~ x1 + x2 + phylo(1 | species, tree = tree), sigma ~ x1)
```

The result is evidence about current memory and timing behaviour only.

## Files Changed

- `docs/dev-log/benchmark-results.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-sigma-x-500k.md`

## Checks Run

The run converged with convergence code 0 and optimizer message
`relative convergence (4)`. The fit used 72 optimizer iterations, 105 function
evaluations, and 73 gradient evaluations. The measured fit time was
389.028 seconds. The fitted object was 228.837 MB, the model matrix was
80.111 MB, and the TMB data object was 109.064 MB. The corrected post-fit R
heap summary was 292.102 MB. macOS `/usr/bin/time -l` reported a maximum
resident set size of 5,451,743,232 bytes and a peak footprint of
2,023,231,496 bytes.

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 500000 --species 1000 --eval-max 260 --iter-max 260 --sigma-x true --memory-light true --output /tmp/drmTMB-gc-fixed-500k-sigma-x-a67891b.csv`:
  passed with convergence code 0.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-gc-fixed-500k-sigma-x-a67891b.csv`:
  passed and marked the row as `timing_usable`.
- `Rscript -e "x <- read.csv('/tmp/drmTMB-gc-fixed-500k-sigma-x-a67891b.csv', check.names = FALSE); print(x[, c('rows','species','sigma_x','memory_light','convergence','convergence_message','iterations','function_evaluations','gradient_evaluations','fit_sec','fit_object_mb','model_matrix_mb','tmb_data_mb','gc_used_mb_post_fit','sigma_hat','sd_phylo_hat')]);"`:
  passed and printed the recorded evidence fields.
- `air format docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-sigma-x-500k.md`:
  passed.
- `rg -n "sigma ~ x1|389\\.028|5,451,743,232|gc-fixed-500k-sigma-x|72 iterations|105 function" docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-sigma-x-500k.md`:
  passed and found the evidence strings.
- `git diff --check`: passed.

## Tests Of The Tests

This task adds benchmark evidence, not package behaviour. The useful
"test of the test" was to verify the same row through three independent views:
the benchmark CSV, `bench/summarize-results.R`, and the recorded Markdown
evidence.

## Consistency Audit

The benchmark row is scoped to current-schema Gaussian phylogenetic
location-scale fitting. It does not change README status, NEWS, formula grammar,
pkgdown navigation, or the distribution roadmap. The language in
`docs/dev-log/benchmark-results.md` keeps the result as internal development
evidence rather than a public performance claim.

## What Did Not Go Smoothly

The first after-task note was too compact and omitted several required protocol
sections. It also wrote the mathematical-contract example as `y ~ x1` even
though the benchmark harness uses `y ~ x1 + x2`. Curie's benchmark review
caught that mismatch, and the report plus benchmark-table preamble were
corrected before closing the task.

## Team Learning

Rose and Curie should remain part of every benchmark task: benchmark numbers
are easy to record, but the interpretation needs a clear boundary between
evidence, planning, and public claims, and the reported formula must match the
harness exactly.

## Known Limitations

The result supports the claim that predictor-dependent residual scale is
feasible for a 500k-row current-schema Gaussian phylogenetic benchmark on this
local machine. It also shows that `sigma ~ x1` is substantially more expensive
than the repeated `sigma ~ 1` baseline: about 389 seconds versus about
134 seconds, with max RSS above 5.4 GB. This should be treated as development
evidence, not as a public performance guarantee.

## Follow-Up

- Keep bivariate, coscale, and non-Gaussian large-data benchmarks separate from
  this row.
- Add sparse fixed-effect design-matrix support before presenting stronger
  million-row guidance.
- Revisit predictor-dependent scale benchmarks after sufficient-statistic or
  chunked data pathways are designed.
