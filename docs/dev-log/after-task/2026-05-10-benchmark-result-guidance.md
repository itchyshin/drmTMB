# After Task: Benchmark Result Guidance

## Goal

Help applied users and package contributors run the large-data benchmark in a
repeatable way, compare default and memory-light fitted objects, and avoid
overclaiming million-row readiness from one small run.

## Implemented

- Added `bench/README.md`.
- Added `.gitignore` rules for local benchmark CSV outputs and
  `bench/results/`.

## Mathematical Contract

No likelihood, parameterization, formula grammar, or optimizer path changed.
The guide documents how to run the existing `bench/large-phylo-location.R`
harness and interpret its recorded columns.

## Files Changed

- `.gitignore`
- `bench/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-result-guidance.md`

## Checks Run

- `git diff --check`
- `rg -n "Recommended Matrix|Output Columns|memory-light false|bench/results" bench/README.md .gitignore`

`git diff --check` passed, and the search confirmed that the README contains
the benchmark matrix, output-column section, default-versus-memory-light
comparison, and ignored local output paths.

## Tests Of The Tests

This task did not add tests because it only documents an optional development
benchmark and `.gitignore` rules. The benchmark script itself was smoke-tested
in the preceding large-data workflow task on balanced-tree, star-tree, and CSV
output paths.

## Consistency Audit

The guide states that base R object sizes are not peak resident memory and
points users to operating-system tools for peak-memory evidence. It also says
not to claim million-row readiness from one small benchmark, matching the
current roadmap and known limitations.

## What Did Not Go Smoothly

The first version of the benchmark harness could create local CSV outputs that
would appear as untracked files. The new ignore rules keep those run artifacts
out of the package history while leaving the benchmark script and guide
tracked.

## Team Learning

Pat needs not only a command but also the meaning of each output column. Rose
should keep checking large-data prose for accidental readiness claims. Grace
should keep repository-only benchmark artifacts separate from the R package
tarball and CI checks.

## Known Limitations

The guide does not add real 100k to 5M row benchmark evidence. It gives a
matrix for collecting that evidence. Windows peak-memory measurement still
needs a documented equivalent to the macOS and Linux examples.

## Next Actions

1. Collect the first 100k-row benchmark result on the local machine.
2. Design the `keep_model_frame = FALSE` method-dependency map before dropping
   the stored model frame.
3. Add sparse fixed-effect matrix experiments only after dense-versus-sparse
   parity tests are scoped.
