# After-Task Report: Benchmark Reproducibility Metadata

## Task

Improve issue #4 benchmark evidence by recording enough metadata to rerun a
large-data benchmark row.

## Reader

This note is for package contributors who collect optional large-data benchmark
rows and need to distinguish reproducible timing evidence from informal local
runs.

## What Changed

- Added `git_sha`, `git_dirty`, and `benchmark_command` columns to
  `bench/large-phylo-location.R` output.
- Updated `bench/README.md` so the output schema explains the new
  reproducibility columns.
- Updated `docs/design/23-large-data-memory.md` so the design plan names
  command and Git metadata as part of the benchmark evidence contract.
- Kept the change outside package runtime code; it affects only the optional
  non-CRAN benchmark harness and documentation.

## Checks Run

- `air format bench/large-phylo-location.R bench/README.md docs/design/23-large-data-memory.md docs/dev-log/after-task/2026-05-11-benchmark-repro-metadata.md docs/dev-log/check-log.md`:
  passed.
- `Rscript -e 'e <- new.env(parent = globalenv()); sys.source("bench/large-phylo-location.R", e); args <- e$parse_args(c("--rows", "50", "--species", "8", "--memory-light", "true")); env <- e$benchmark_environment(args); stopifnot(grepl("--rows", env$benchmark_command), nzchar(env$git_sha), is.logical(env$git_dirty) || is.na(env$git_dirty))'`:
  passed.
- `rg -n "benchmark_command|git_sha|git_dirty|reconstructed benchmark command|issue #4" bench/large-phylo-location.R bench/README.md docs/design/23-large-data-memory.md docs/dev-log/after-task/2026-05-11-benchmark-repro-metadata.md docs/dev-log/check-log.md`:
  confirmed source and documentation coverage.
- `git diff --check`: passed.

## Known Limitations

- This changes the benchmark CSV schema; append to a fresh output path or remove
  older ignored CSV files before collecting new rows.
- It does not run a new large benchmark or prove million-row readiness.
