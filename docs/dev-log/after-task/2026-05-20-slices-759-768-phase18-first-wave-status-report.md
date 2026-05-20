# Slices 759-768: Phase 18 First-Wave Status Report Template

## Goal

Ada added the first report-staging template that reads first-wave artifact
status before any larger simulation report consumes surface-specific tables.

## Implemented

`inst/sim/reports/phase18-first-wave-status-report.Rmd` reads the bound
artifact-manifest CSV and surface-status CSV written by
`phase18_write_first_wave_artifact_status()`. With `require_complete = TRUE`,
the template stops during setup when any surface reports missing artifacts.

The rendered page includes:

- surface-level artifact counts;
- the bound artifact manifest;
- a filtered missing-or-empty artifact table;
- reader checks;
- an interpretation boundary that keeps artifact readiness separate from
  statistical operating-characteristic evidence.

## Mathematical Contract

No model, likelihood, uncertainty method, or operating-characteristic metric
changed. This is a report preflight gate.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/reports/phase18-first-wave-status-report.Rmd`
- `tests/testthat/test-phase18-first-wave-status-report.R`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-first-wave-status-report$')"
air format tests/testthat/test-phase18-first-wave-status-report.R
Rscript -e "devtools::test(filter = '^phase18-first-wave-status-report$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-artifact-status|first-wave-status-report|sim-runner)$')"
```

Result:

- Before and after formatting, 14 expectations passed with 0 failures, 0
  warnings, and 0 skips.
- The writer, status-report, and runner bundle passed with 100 expectations, 0
  failures, 0 warnings, and 0 skips.

## Tests Of The Tests

The tests verify template installation, successful rendering with complete
artifact status, and the intended error path when `n_missing > 0` and
`require_complete = TRUE`.

## Consistency Audit

The README, roadmap, NEWS, and Phase 18 simulation programme now name the
status report template and keep it scoped as private simulation report
staging.

## What Did Not Go Smoothly

Nothing major. The render-failure test prints a normal knitr "Quitting from"
line because it intentionally exercises the missing-artifact setup error.

## Team Learning

- Ada: report templates should fail before reading downstream tables when the
  artifact preflight says a surface is incomplete.
- Pat: the reader-facing page names missing and empty artifacts directly.
- Fisher: a status page remains artifact evidence, not coverage evidence.
- Grace: the render test covers both success and expected failure without
  running a simulation grid.
- Rose: this closes the loop from manifest helper to writer to report gate.

## Known Limitations

- The report does not validate statistical content inside the CSVs.
- The report does not read per-replicate RDS results.
- The report is a staging page, not the final first-wave simulation report.

## Next Actions

1. Add a first-wave report skeleton that reads the status page outputs and then
   combines aggregate, interval, manifest, and failure-ledger tables.
2. Rerun a broader Phase 18 test bundle after the next report-skeleton slice.
