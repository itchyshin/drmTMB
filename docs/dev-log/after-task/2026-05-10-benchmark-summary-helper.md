# After Task: Benchmark Summary Helper

## Goal

Help package contributors read large-data benchmark CSV files without
overclaiming from non-converged rows or older benchmark schemas.

## Implemented

- Added `bench/summarize-results.R`.
- The helper prints a Markdown table with scenario labels, convergence status,
  diagnostic status, fit time, fitted-object size, model-matrix size, TMB-data
  size, post-fit R heap use, and fitted `sigma` and phylogenetic SD summaries.
- It labels rows with nonzero convergence as diagnostic only.
- It labels older CSV files without optimizer messages and evaluation counts
  as `legacy_schema`.
- Updated `bench/README.md` with the summary command and interpretation
  cautions.

## Mathematical Contract

No model likelihood, formula grammar, fitted-object API, or benchmark data
generator changed. The helper summarizes existing benchmark output only.

## Files Changed

- `bench/summarize-results.R`
- `bench/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-summary-helper.md`

## Checks Run

- `air format bench/summarize-results.R bench/README.md`: passed.
- `Rscript bench/summarize-results.R --input bench/results/large-phylo-location.csv`:
  passed; it identified the local ignored CSV as `legacy_schema` and marked
  the non-converged factor-heavy row as diagnostic only.
- `Rscript bench/large-phylo-location.R --rows 1000 --species 50 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-summary-smoke.csv`:
  passed and wrote a fresh current-schema benchmark CSV.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-summary-smoke.csv`:
  passed and printed optimizer diagnostics for the current-schema row.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-summary-smoke.csv --converged-only true`:
  passed.
- `Rscript bench/summarize-results.R --help`: passed.
- `rg -n "summarize-results|Summarising Results|converged-only|legacy_schema|diagnostic_only" bench/README.md bench/summarize-results.R`:
  passed.
- `git diff --check`: passed.

## Tests Of The Tests

The helper was tested on both the existing ignored local CSV with the older
schema and a fresh current-schema smoke benchmark. That checks the two cases
the helper is meant to distinguish.

## Consistency Audit

The helper follows the benchmark guide's caution: converged rows can support
timing summaries, while non-converged rows are diagnostic only. It does not
claim million-row readiness or convert local benchmark output into package
tests.

## What Did Not Go Smoothly

The first local results file still uses an older schema. The helper now makes
that visible instead of silently mixing old and new evidence.

## Team Learning

Curie should keep benchmark evidence machine-readable, and Rose should keep
blocking readiness claims when the CSV lacks optimizer diagnostics or includes
non-converged rows.

## Known Limitations

The helper summarizes CSV files; it does not measure peak resident memory,
compare repeated runs statistically, or validate that a benchmark scenario is
biologically meaningful.

## Next Actions

- Use a fresh current-schema output file for the next 100k benchmark rows.
- Add peak-memory evidence beside any benchmark row used in user-facing
  readiness claims.
