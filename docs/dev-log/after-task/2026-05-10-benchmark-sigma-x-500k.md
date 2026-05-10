# After-Task Report: 500k `sigma ~ x1` Benchmark

## Purpose

Test whether the current Gaussian phylogenetic benchmark harness can fit a
500,000-row, 1,000-species model when the residual scale has a predictor,
`sigma ~ x1`.

## Work Completed

- Ran the benchmark with 500,000 rows, 1,000 species, `sigma ~ x1`, and
  memory-light output storage.
- Summarized the output with `bench/summarize-results.R`.
- Added the benchmark row to `docs/dev-log/benchmark-results.md`.
- Recorded the command evidence in `docs/dev-log/check-log.md`.

## Result

The run converged with convergence code 0 and optimizer message
`relative convergence (4)`. The fit used 72 optimizer iterations, 105 function
evaluations, and 73 gradient evaluations. The measured fit time was
389.028 seconds. The fitted object was 228.837 MB, the model matrix was
80.111 MB, and the TMB data object was 109.064 MB. The corrected post-fit R
heap summary was 292.102 MB. macOS `/usr/bin/time -l` reported a maximum
resident set size of 5,451,743,232 bytes and a peak footprint of
2,023,231,496 bytes.

## Interpretation

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
