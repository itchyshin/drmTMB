# Slices 739-748: Phase 18 Artifact Manifest Status Helpers

## Goal

Ada added the next small report-staging layer on top of the grid artifact
manifests.

## Implemented

`phase18_bind_grid_artifact_manifests()` binds artifact manifests from manifest
data frames or grid-writer result objects.
`phase18_summarise_grid_artifact_manifests()` summarizes each surface by
artifact count, present files, missing files, empty CSV artifacts, and total
CSV rows.

## Mathematical Contract

No simulation estimand, model, or metric changed. This is artifact-readiness
metadata for reports.

## Files Changed

- `inst/sim/R/sim_runner.R`
- `tests/testthat/test-phase18-sim-runner.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-sim-runner$')"
```

Result:

- 70 expectations passed.

## Tests Of The Tests

The new tests bind one manifest data frame and one grid-writer-like result
object, then check missing-file and empty-CSV counts. They also cover malformed
manifest inputs.

## Consistency Audit

The README and simulation-programme note now describe both per-grid manifests
and cross-grid status summaries.

## What Did Not Go Smoothly

Nothing major. This was intentionally a small utility slice.

## Team Learning

- Ada: report staging is cleaner when artifact readiness is summarized before
  table-reading code starts.
- Curie: synthetic manifest tests are enough here because the previous slice
  already exercised real CSV files.
- Rose: status summaries should name missing and empty separately.

## Known Limitations

- These helpers do not inspect semantic table contents.
- They do not summarize per-replicate RDS files.

## Next Actions

1. Use these helpers in a first-wave report staging script or template.
2. Rerun full focused Phase 18 tests before a broader validation checkpoint.
