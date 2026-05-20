# Slices 769-778: Phase 18 First-Wave Table Bundle Writer

## Goal

Ada added the first table-bundling layer for first-wave Phase 18 reports, so a
future report can consume combined aggregate, interval, manifest, or
failure-ledger tables without hand-binding one grid output at a time.

## Implemented

`phase18_write_first_wave_table_bundle()` accepts grid-writer outputs, reads
selected CSV artifacts, row-binds matching artifact tables across surfaces, and
writes one combined CSV per artifact. The helper adds:

- `source_surface`
- `source_artifact`

When tables have different columns, `phase18_row_bind_fill()` fills missing
columns with `NA`. Empty or missing artifact inputs become empty tables with
the source columns, which keeps downstream report code deterministic.

## Mathematical Contract

No simulation estimand, likelihood, interval method, or coverage calculation
changed. This is table plumbing for first-wave report staging.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/run/sim_write_first_wave_table_bundle.R`
- `tests/testthat/test-phase18-first-wave-table-bundle.R`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-first-wave-table-bundle$')"
air format inst/sim/run/sim_write_first_wave_table_bundle.R tests/testthat/test-phase18-first-wave-table-bundle.R
Rscript -e "devtools::test(filter = '^phase18-first-wave-table-bundle$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-artifact-status|first-wave-status-report|first-wave-table-bundle|sim-runner)$')"
```

Result:

- Before and after formatting, 20 expectations passed with 0 failures, 0
  warnings, and 0 skips.
- The first-wave staging plus runner bundle passed with 120 expectations, 0
  failures, 0 warnings, and 0 skips.

## Tests Of The Tests

The focused test combines two fake grid outputs with different aggregate-table
columns, checks filled `NA` values, verifies empty and missing artifacts are
still represented by deterministic empty tables, and covers overwrite and
malformed-input errors.

## Consistency Audit

The README, roadmap, NEWS, and Phase 18 simulation programme now name the table
bundle writer as private first-wave report-staging infrastructure.

## What Did Not Go Smoothly

Nothing major. This was a straightforward plumbing slice.

## Team Learning

- Ada: first-wave report code should consume combined artifact tables, not
  repeat per-surface file handling.
- Curie: fake grid-output objects are enough to test table-binding behavior
  without running fits.
- Fisher: the bundle adds provenance columns but does not alter the statistical
  rows.
- Pat: source columns make mixed-surface report tables easier to read.
- Grace: deterministic empty tables avoid brittle report branches.
- Rose: the report path now has manifest, status, and table-bundle layers with
  separate responsibilities.

## Known Limitations

- The writer does not validate semantic correctness inside each table.
- Missing artifacts are skipped here; the artifact-status preflight remains the
  place to decide whether missing files should fail a report.
- The writer does not read per-replicate RDS files.

## Next Actions

1. Add the first first-wave summary report skeleton that consumes the table
   bundle outputs.
2. Run a broader focused Phase 18 test bundle after the report skeleton is in
   place.
