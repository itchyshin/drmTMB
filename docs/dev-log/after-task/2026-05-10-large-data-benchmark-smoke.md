# After Task: Large-Data Benchmark Smoke

## Goal

Run the documented benchmark harness on a local 10,000-row phylogenetic
location model before attempting larger 100k-row and million-row experiments.

## Implemented

No package code changed. This task exercised the existing
`bench/large-phylo-location.R` script and recorded the result in the check log.

## Mathematical Contract

The benchmark fit used the existing univariate Gaussian phylogenetic location
model with `sigma ~ 1` and an intercept-only phylogenetic location effect. No
likelihood, formula grammar, or parameterization changed.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-large-data-benchmark-smoke.md`

## Checks Run

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 10000 --species 100 --eval-max 120 --iter-max 120 --memory-light true --output bench/results/large-phylo-location.csv`

The run converged with convergence code 0. The benchmark result recorded
10,000 rows, 100 species, 2.261 seconds of fit time, 4.896 MB fitted-object
size, 1.528 MB model-matrix size, and 2.140 MB TMB-data size. macOS
`/usr/bin/time -l` reported 462,323,712 bytes maximum resident set size and
331,891,768 bytes peak memory footprint.

## Tests Of The Tests

The benchmark wrote one CSV row with the documented columns. The result was
read back with `read.csv()` to confirm the command produced parseable output.

## Consistency Audit

The result matches the benchmark guide's warning: this smoke run checks the
toolchain and output file, but it does not prove million-row readiness.

## What Did Not Go Smoothly

Nothing failed in this run. The important process note is that benchmark CSV
outputs are intentionally ignored by git, so durable results need a separate
curated table if they should become public evidence.

## Team Learning

Grace should keep recording both package-level object sizes and
operating-system peak-memory evidence. Curie should scale the matrix gradually:
10k rows first, then 100k rows, then factor-heavy and `sigma ~ x` variants.
Rose should keep blocking any wording that turns one smoke run into a readiness
claim.

## Known Limitations

This run used 10,000 rows and 100 species. It is a toolchain smoke test, not a
large-data guarantee. The next run should use 100,000 rows and 1,000 species if
local memory and time allow.

## Next Actions

1. Run the 100k-row, 1,000-species memory-light benchmark.
2. Run the same scenario with `--memory-light false` when local memory allows.
3. Add factor-heavy and `sigma ~ x` benchmark rows after the baseline run.
