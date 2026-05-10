# After Task: 100k-Row Large-Data Benchmark

## Goal

Run the first 100,000-row, 1,000-species memory-light benchmark for the
phylogenetic Gaussian location path.

## Implemented

No package code changed. This task exercised the existing benchmark harness and
recorded the result in the check log.

## Mathematical Contract

The benchmark used the existing univariate Gaussian phylogenetic location
model with `sigma ~ 1` and an intercept-only phylogenetic location effect. No
likelihood or parameterization changed.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-large-data-benchmark-100k.md`

## Checks Run

- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 160 --iter-max 160 --memory-light true --output bench/results/large-phylo-location.csv`

The run converged with convergence code 0. The benchmark result recorded
100,000 rows, 1,000 species, 25.547 seconds of fit time, 48.027 MB
fitted-object size, 15.261 MB model-matrix size, and 21.326 MB TMB-data size.
macOS `/usr/bin/time -l` reported 1,425,932,288 bytes maximum resident set
size and 671,073,984 bytes peak memory footprint.

## Tests Of The Tests

The benchmark appended a second CSV row after the 10k smoke run. The result was
read back with `read.csv()` to confirm both rows were parseable.

## Consistency Audit

The result supports the benchmark guide's staged matrix: 10k smoke first, then
100k baseline. It still does not support a million-row readiness claim.

## What Did Not Go Smoothly

Nothing failed in this run. The main caveat is that this scenario used few
fixed effects and `sigma ~ 1`, so it does not stress dense factor expansion or
distributional scale predictors.

## Team Learning

Curie should keep scaling one dimension at a time. Grace should keep recording
OS peak memory in addition to R object sizes. Rose should block claims that
generalize from this baseline to factor-heavy or million-row workloads.

## Known Limitations

This is a baseline memory-light run only. The next benchmark rows should test
default storage, factor-heavy fixed effects, and `sigma ~ x`.

## Next Actions

1. Run the 100k-row scenario with `--memory-light false`.
2. Run the 100k-row factor-heavy scenario.
3. Run the 100k-row `sigma ~ x` scenario.
