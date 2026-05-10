# After Task: Benchmark Diagnostics

## Goal

Record enough optimizer diagnostics in large-data benchmark output to explain
why a stress run did or did not converge.

## Implemented

- Added optimizer message, iteration count, function-evaluation count, and
  gradient-evaluation count to `bench/large-phylo-location.R` output.
- Added a schema check before appending benchmark rows so an older ignored CSV
  cannot silently receive rows with different columns.
- Updated `bench/README.md` to describe the new output columns.

## Mathematical Contract

No package likelihood, formula grammar, optimizer default, or fitted-model API
changed. The edit affects only a development benchmark script and its
documentation.

## Files Changed

- `bench/large-phylo-location.R`
- `bench/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-diagnostics.md`

## Checks Run

- `air format bench/large-phylo-location.R`
- `Rscript bench/large-phylo-location.R --rows 1000 --species 50 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-benchmark-diagnostics.csv`
- `Rscript -e "x <- read.csv('/tmp/drmTMB-benchmark-diagnostics.csv', check.names = FALSE); print(names(x)); print(x[, c('convergence', 'convergence_message', 'iterations', 'function_evaluations', 'gradient_evaluations')]);"`
- `Rscript bench/large-phylo-location.R --rows 1000 --species 50 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-benchmark-diagnostics.csv`
- `Rscript -e "x <- read.csv('/tmp/drmTMB-benchmark-diagnostics.csv', check.names = FALSE); print(dim(x)); print(x[, c('convergence', 'convergence_message', 'iterations', 'function_evaluations', 'gradient_evaluations')]);"`
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --factor-heavy true --memory-light true --output /tmp/drmTMB-factor-heavy-diagnostics.csv`
- `Rscript -e "x <- read.csv('/tmp/drmTMB-factor-heavy-diagnostics.csv', check.names = FALSE); print(x[, c('convergence', 'convergence_message', 'iterations', 'function_evaluations', 'gradient_evaluations', 'fit_sec', 'fit_object_mb', 'model_matrix_mb', 'gc_used_mb_post_fit')]);"`
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 400 --iter-max 400 --factor-heavy true --memory-light true --output /tmp/drmTMB-factor-heavy-diagnostics-400.csv`
- `Rscript -e "x <- read.csv('/tmp/drmTMB-factor-heavy-diagnostics-400.csv', check.names = FALSE); print(x[, c('convergence', 'convergence_message', 'iterations', 'function_evaluations', 'gradient_evaluations', 'fit_sec', 'fit_object_mb', 'model_matrix_mb', 'gc_used_mb_post_fit')]);"`

Both smoke benchmark runs completed and the second run appended to the same
CSV with the new schema.

## Result

The smoke benchmark output now has 28 columns. The optimizer diagnostics
reported convergence code 0, optimizer message `relative convergence (4)`, 40
iterations, 49 function evaluations, and 41 gradient evaluations.

The 100k factor-heavy diagnostic rerun reported convergence code 1, optimizer
message `function evaluation limit reached without convergence (9)`, 147
iterations, 180 function evaluations, and 147 gradient evaluations. That
confirms the earlier factor-heavy row stopped at the benchmark evaluation
limit rather than proving a stable timing result.

Increasing the benchmark limits to `eval.max = 400` and `iter.max = 400` did
not make that stress case clean. The rerun reported convergence code 1,
optimizer message `false convergence (8)`, 301 iterations, 382 function
evaluations, and 301 gradient evaluations.

## Known Limitations

Existing local `bench/results/*.csv` files with the old schema need a new
output path or manual removal before appending rows from the updated script.
The 100k factor-heavy row needs model-specific convergence diagnostics before
it supports a timing claim; increasing optimizer limits alone was not enough.

## Next Actions

1. Use a fresh output file for the next factor-heavy convergence rerun.
2. Add a short benchmark-results table only for rows with clearly documented
   optimizer diagnostics.
