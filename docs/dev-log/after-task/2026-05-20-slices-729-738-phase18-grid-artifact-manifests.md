# Slices 729-738: Phase 18 Grid Artifact Manifests

## Goal

Ada added a small report-staging manifest so every Phase 18 grid writer can
return the CSV artifacts it wrote, whether each file exists, and how many rows
the file contains.

## Implemented

`phase18_grid_artifact_manifest()` now builds one manifest row per named
artifact path. All first-wave grid writers return this table as
`artifact_manifest`. The helper treats present-but-empty optional CSVs as
zero-row artifacts, which matters for profile or bootstrap tables that are
written even when no rows were requested.

## Mathematical Contract

No statistical model or performance measure changed. This is report-staging
metadata for simulation artifacts.

## Files Changed

- `inst/sim/R/sim_runner.R`
- `inst/sim/run/sim_write_*_grid.R`
- `tests/testthat/test-phase18-sim-runner.R`
- focused grid-writer tests
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-(sim-runner|gaussian-ls-grid-writer|meta-v-grid-writer|count-mu-random-effect-grid-writer|random-slope-grid-writers|biv-rho12-grid-writer|student-shape-grid-writer)$')"
```

Result:

- 169 expectations passed after the empty-CSV fix.

## Tests Of The Tests

The first focused run failed on empty optional interval CSVs for Student-t and
bivariate `rho12` grids. That failure proved the manifest was reading real
files rather than only checking paths. The helper now records such files with
`n_row = 0`.

## Consistency Audit

All current first-wave grid writers return `artifact_manifest`. The README and
simulation-programme design note explain the manifest's role for report
staging.

## What Did Not Go Smoothly

Empty CSVs exposed a practical edge in the first implementation. The fix keeps
the manifest useful for optional artifacts without hiding whether a file exists.

## Team Learning

- Ada: report-staging helpers should handle valid empty artifacts.
- Curie: a failing test on a real optional artifact is better than a purely
  synthetic helper test.
- Fisher: artifact row counts help distinguish no requested intervals from
  failed or missing interval evidence.
- Rose: file-existence checks alone are too weak for simulation report inputs.

## Known Limitations

- The helper does not inspect RDS replicate files.
- It records row counts, not semantic completeness.

## Next Actions

1. Build a first-wave report staging helper or audit table that consumes these
   artifact manifests.
2. Rerun full focused Phase 18 tests before the next broad checkpoint.
