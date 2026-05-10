# After Task: Benchmark Model-Frame Storage

## Goal

Make the large-data benchmark harness exercise the implemented
`keep_model_frame = FALSE` control when `--memory-light true` is used.

## Implemented

- Updated `bench/large-phylo-location.R` so memory-light benchmark runs set
  `keep_data = FALSE`, `keep_model_frame = FALSE`, and
  `keep_tmb_object = FALSE`.
- Updated `bench/README.md` to describe the benchmark storage controls.
- Added `docs/dev-log/benchmark-results.md` with selected durable results from
  ignored benchmark CSV output.
- Re-ran 10k and 100k memory-light benchmark rows after the harness update.
- Ran 100k `sigma ~ x1` and 100k factor-heavy stress rows.

## Mathematical Contract

No likelihood, parameter transform, formula grammar, optimizer, or inference
method changed. The benchmark harness changed only which post-fit storage
controls are used during memory-light timing runs.

## Files Changed

- `bench/large-phylo-location.R`
- `bench/README.md`
- `docs/dev-log/benchmark-results.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-model-frame-storage.md`

## Checks Run

- `air format bench/large-phylo-location.R`
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 10000 --species 100 --eval-max 120 --iter-max 120 --memory-light true --output bench/results/large-phylo-location.csv`
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 160 --iter-max 160 --memory-light true --output bench/results/large-phylo-location.csv`
- `Rscript -e "x <- read.csv('bench/results/large-phylo-location.csv'); print(tail(x, 6));"`
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --factor-heavy true --memory-light true --output bench/results/large-phylo-location.csv`
- `/usr/bin/time -l Rscript bench/large-phylo-location.R --rows 100000 --species 1000 --eval-max 180 --iter-max 180 --sigma-x true --memory-light true --output bench/results/large-phylo-location.csv`
- `Rscript -e "x <- read.csv('bench/results/large-phylo-location.csv'); print(tail(x, 5));"`

The 10k, 100k baseline, and 100k `sigma ~ x1` memory-light runs converged with
convergence code 0. The 100k factor-heavy stress run completed with
convergence code 1 under the benchmark iteration settings.

## Result

The 100k memory-light rerun used all three storage controls and produced a
45.730 MB fitted object. The default-storage comparison produced a 54.935 MB
fitted object. Operating-system peak memory was similar, which matches the
design expectation that these controls reduce retained post-fit state rather
than construction-time peak memory.

The 100k `sigma ~ x1` memory-light run converged and produced a 47.257 MB
fitted object. The 100k factor-heavy stress run produced a 105.289 MB fitted
object and a 45.019 MB model matrix, but did not converge under the benchmark
iteration settings, so it is evidence of dense fixed-effect pressure rather
than an accepted timing result.

## Tests Of The Tests

The benchmark CSV was read back with `read.csv()` after appending new rows.
The durable result table records the command-level outputs because
`bench/results/*.csv` is intentionally ignored.

## Consistency Audit

The benchmark README, durable result table, and check log now agree that
memory-light benchmark runs use `keep_data = FALSE`,
`keep_model_frame = FALSE`, and `keep_tmb_object = FALSE`.

## Known Limitations

The factor-heavy run needs a convergence-focused rerun or sparse fixed-effect
design work before supporting a performance claim. None of these rows support
million-row readiness.

## Next Actions

1. Add optimizer-message and evaluation-count columns to the benchmark CSV.
2. Rerun the factor-heavy case with convergence-focused settings or after
   sparse fixed-effect design work.
3. Use the benchmark table to keep public-facing claims conservative.
