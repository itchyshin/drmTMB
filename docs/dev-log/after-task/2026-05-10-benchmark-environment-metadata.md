# After Task: Benchmark Environment Metadata

## Goal

Make optional large-data benchmark CSV rows easier to interpret by recording
the R, package, and platform context with each run.

## Implemented

- Added run metadata columns to `bench/large-phylo-location.R`.
- Documented the metadata columns in `bench/README.md`.
- Recorded the task in `docs/dev-log/check-log.md`.

## Mathematical Contract

No statistical model, likelihood, or formula grammar changed. The benchmark
harness still fits the same Gaussian phylogenetic location-scale models. The
change only adds context columns to the CSV output.

## Files Changed

- `bench/large-phylo-location.R`
- `bench/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-benchmark-environment-metadata.md`

## Checks Run

- `air format bench/large-phylo-location.R bench/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-benchmark-environment-metadata.md`:
  passed.
- `Rscript -e "parse('bench/large-phylo-location.R'); parse('bench/summarize-results.R')"`:
  passed.
- `Rscript bench/large-phylo-location.R --rows 300 --species 20 --eval-max 80 --iter-max 80 --memory-light true --output /tmp/drmTMB-benchmark-env-metadata-smoke.csv`:
  passed and wrote the smoke benchmark CSV.
- `Rscript bench/summarize-results.R --input /tmp/drmTMB-benchmark-env-metadata-smoke.csv`:
  passed and marked the row as `timing_usable`.
- metadata-column check on the smoke CSV: passed and confirmed
  `run_started_utc`, `r_version`, `platform`, `os`, `machine`,
  `drmTMB_version`, and `TMB_version`.
- `git diff --check`: passed.

## Tests Of The Tests

The smoke benchmark should write the new metadata columns and the summary
helper should still read the CSV because the original required columns remain
present.

## Consistency Audit

The README now tells contributors that schema changes can happen as diagnostics
improve and recommends fresh output paths. This matches the existing schema
guard in `write_result()`.

## What Did Not Go Smoothly

No package behaviour changed, but the first implementation had to avoid relying
on an installed `drmTMB` version because development runs often use
`devtools::load_all()`. The harness now reads the local `DESCRIPTION` version
when available.

## Team Learning

Grace should ask for machine and package context whenever benchmark evidence is
recorded. Without those columns, later comparisons are more fragile than they
need to be.

## Known Limitations

The metadata does not record CPU model, available RAM, BLAS details, or
operating-system peak memory. Peak memory still comes from external tools such
as `/usr/bin/time -l` on macOS.

## Next Actions

- Consider optional CPU/RAM metadata only if it can be collected portably.
- Keep using fresh benchmark output paths when schema changes.
