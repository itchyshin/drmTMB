# Slices 749-758: Phase 18 First-Wave Artifact Status Writer

## Goal

Ada used the new artifact-manifest helpers in a concrete first-wave staging
writer, so reports can check all required CSV artifacts before reading them.

## Implemented

`phase18_write_first_wave_artifact_status()` accepts a list of grid-writer
outputs or manifest data frames, binds their artifact manifests, summarizes
present, missing, empty, and total CSV rows by surface, and writes two CSVs:

- `phase18-first-wave-artifact-manifest.csv`
- `phase18-first-wave-artifact-status.csv`

The returned object also has its own artifact manifest for those two staging
CSVs.

## Mathematical Contract

No model, estimand, likelihood, or uncertainty method changed. This is report
preflight metadata for the Phase 18 simulation artifact layer.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/run/sim_write_first_wave_artifact_status.R`
- `tests/testthat/test-phase18-first-wave-artifact-status.R`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-first-wave-artifact-status$')"
air format inst/sim/run/sim_write_first_wave_artifact_status.R tests/testthat/test-phase18-first-wave-artifact-status.R
Rscript -e "devtools::test(filter = '^phase18-(sim-runner|first-wave-artifact-status)$')"
```

Result:

- 16 expectations passed, 0 failures, 0 warnings, 0 skips.
- After formatting, the runner plus first-wave writer bundle passed with 86
  expectations, 0 failures, 0 warnings, 0 skips.

## Tests Of The Tests

The focused test uses one direct manifest data frame and one grid-writer-like
object. It verifies output CSV row counts, missing-artifact summaries,
empty-CSV counts, overwrite protection, overwrite replacement, and malformed
input errors.

## Consistency Audit

The simulation README, Phase 18 design document, roadmap, NEWS, and check-log
now name the first-wave artifact-status writer and keep it scoped as private
simulation/report infrastructure.

## What Did Not Go Smoothly

Nothing major. The first edit left an awkward closing parenthesis in the test
file; Ada fixed it before running the focused test.

## Team Learning

- Ada: first-wave reports now have a cheap artifact preflight before table
  reading begins.
- Curie: fake-manifest tests keep this slice fast while still exercising the
  writer behavior.
- Fisher: artifact status is not statistical evidence; it is only a guard that
  the evidence tables exist and have expected row counts.
- Pat: a status CSV should make a missing or empty artifact obvious without
  opening the full report.
- Grace: overwrite guards matter because scheduled simulation outputs should
  not be silently replaced.
- Rose: the report-staging contract is now documented where future report work
  will look first.

## Known Limitations

- The writer does not inspect semantic correctness of each table.
- It does not summarize per-replicate RDS files.
- It does not render a report; it only stages manifest and status CSVs for one.

## Next Actions

1. Add a first-wave report template that reads the status CSV before the
   aggregate and interval tables.
2. Rerun the focused Phase 18 bundle now that the staging writer exists.
