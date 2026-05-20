# Slices 779-788: Phase 18 First-Wave Summary Report Skeleton

## Goal

Ada added the first table-first summary report skeleton for Phase 18 first-wave
simulation outputs.

## Implemented

`inst/sim/reports/phase18-first-wave-summary-report.Rmd` reads:

- artifact-status CSV;
- aggregate operating-characteristic CSV;
- run-manifest CSV;
- warning/error ledger CSV;
- interval-diagnostics CSV;
- interval-failure CSV.

The report keeps artifact status visible before aggregate or interval rows,
and it can stop when the status table reports missing artifacts and
`require_complete = TRUE`.

## Mathematical Contract

No model, likelihood, interval method, or performance metric changed. This is a
reader-facing staging report over existing Phase 18 artifact schemas.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/reports/phase18-first-wave-summary-report.Rmd`
- `tests/testthat/test-phase18-first-wave-summary-report.R`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-first-wave-summary-report$')"
air format tests/testthat/test-phase18-first-wave-summary-report.R
Rscript -e "devtools::test(filter = '^phase18-first-wave-summary-report$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-artifact-status|first-wave-status-report|first-wave-table-bundle|first-wave-summary-report|sim-runner)$')"
```

Result:

- Before and after formatting, 14 expectations passed with 0 failures, 0
  warnings, and 0 skips.
- The first-wave staging, report, table-bundle, summary-report, and runner
  bundle passed with 134 expectations, 0 failures, 0 warnings, and 0 skips.

## Tests Of The Tests

The tests verify template installation and render the report from synthetic
artifact-status, aggregate, interval-diagnostics, interval-failure, manifest,
and warning/error CSVs.

## Consistency Audit

The README, roadmap, NEWS, and Phase 18 simulation programme now identify the
summary report skeleton as table-first staging rather than final simulation
evidence.

## What Did Not Go Smoothly

Nothing major.

## Team Learning

- Ada: the first-wave report path now has a complete staging ladder: status,
  table bundle, summary report.
- Pat: table-first reporting is easier to audit before Florence designs the
  figure layer.
- Fisher: interval diagnostics and failures are visible beside aggregate rows,
  so coverage evidence cannot be silently cherry-picked.
- Grace: synthetic CSV render tests keep the template portable and fast.
- Rose: the report still says it is staging, not final operating-characteristic
  evidence.

## Known Limitations

- The report does not yet draw figures.
- The report does not validate semantic correctness inside the CSVs.
- The report assumes table bundles were created by the companion first-wave
  table-bundle writer or an equivalent schema.

## Next Actions

1. Add a small first-wave orchestration smoke that creates status, bundle, and
   summary-report artifacts from fake or tiny grid outputs.
2. Run the broader focused Phase 18 test bundle after the orchestration smoke.
