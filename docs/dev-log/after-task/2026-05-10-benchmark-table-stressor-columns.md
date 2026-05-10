# After Task: Benchmark Table Stressor Columns

## Goal

Make `docs/dev-log/benchmark-results.md` separate benchmark stressors clearly
so row count, species count, scale predictors, fixed-effect factor pressure,
and memory-light storage are not hidden inside one overloaded column.

## Implemented

- Replaced the benchmark table's `Storage` column with explicit columns for
  `Family`, `Sigma formula`, `Factor levels`, `Memory-light`, and `Status`.
- Added a caveat that `R heap after fit MB` is a post-fit garbage-collector
  summary, not peak memory.

## Mathematical Contract

No model likelihood, parameterization, formula grammar, fitted-object API, or
benchmark generator changed.

## Files Changed

- `docs/dev-log/benchmark-results.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-table-stressor-columns.md`

## Checks Run

- `air format docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-table-stressor-columns.md`:
  passed.
- `rg -n "Family \\| Sigma formula|Factor levels|Memory-light|diagnostic only|post-fit garbage-collector|not peak memory|Storage" docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-table-stressor-columns.md`:
  passed and found the new column names, diagnostic status, R-heap caveat, and
  recorded replacement of the old `Storage` column.
- `git diff --check`: passed.

## Result

Readers can now tell which benchmark rows are ordinary Gaussian location rows,
which add `sigma ~ x1`, which are factor-heavy diagnostic rows, and which
compare memory-light storage to default storage.

## Tests Of The Tests

The validation scan checks for the new column names, the `diagnostic only`
status, and the post-fit R-heap caveat.

## Consistency Audit

The table still describes the same Gaussian phylogenetic benchmark harness.
It does not introduce bivariate, coscale, non-Gaussian, or million-row claims.

## What Did Not Go Smoothly

Nothing failed during editing. The improvement came from Curie's review: the
old table was compact but mixed stressors in a way that could mislead later
planning.

## Team Learning

Curie should keep benchmark tables machine-readable enough to audit stressors.
Rose should keep asking whether a compact table is hiding different claims.

## Known Limitations

The table still contains selected local rows only. It does not yet include
repeated runs, million-row rows, 10,000-species rows, bivariate rows, or
non-Gaussian families.

## Next Actions

- Repeat the 500k baseline row before adding the next stressor.
- Add `sigma ~ x1` at 500k rows after the repeated baseline is stable.
