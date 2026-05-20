# Slices 869-878: Phase 18 First-Wave Interval Coverage Summary

## Goal

Ada made interval evidence visible in the first-wave summary report before
readers reach raw interval diagnostics or individual coverage tables.

## Implemented

`phase18-first-wave-summary-report.Rmd` now reads optional Wald, profile, and
bootstrap coverage CSVs from the first-wave table bundle. It binds available
coverage rows, records the interval method, and summarises each
`source_surface` by method with the number of parameters, total intervals,
covered intervals, and empirical coverage.

`phase18_render_first_wave_summary_report()` now forwards those coverage-table
paths into the report params when the table bundle writes them.

## Validation

Focused tests:

```sh
air format inst/sim/run/sim_render_first_wave_summary_report.R tests/testthat/test-phase18-first-wave-summary-report.R
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-report|first-wave-summary-render-helper)$')"
```

Result:

- 45 expectations passed, 0 failures, 0 warnings, 0 skips.

Tiny real smoke:

- Output root:
  `inst/sim/results/slice-869-first-wave-summary-interval-coverage-smoke/`
- Rendered report:
  `inst/sim/results/slice-869-first-wave-summary-interval-coverage-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- Wald coverage rows: 19.
- Profile coverage rows: 4.
- The rendered report includes `Interval Coverage Summary`, `wald`, `profile`,
  `Aggregate Bias Overview`, and `Warning And Error Summary`.

## Mathematical Contract

No interval method, likelihood, or coverage calculation changed. The report
summarises existing coverage artifacts from the grid writers. One-replicate
coverage rows remain smoke evidence only.

## Team Learning

- Ada: interval evidence belongs near the top-level operating-characteristic
  screen, not only in per-method CSV files.
- Fisher: method-specific coverage summaries prevent Wald and profile evidence
  from being mixed silently.
- Pat: the report now answers which interval methods have evidence before the
  reader opens raw tables.
- Grace: the render helper can pass optional coverage paths without breaking
  fixtures that do not include them.
- Rose: bootstrap coverage is present only when supplied, which keeps planned
  bootstrap evidence from being implied.

## Known Limitations

- This is not a final coverage estimate; the current smoke is one replicate per
  surface cell.
- Bootstrap coverage remains absent for surfaces that did not run bootstrap
  intervals.

## Next Actions

1. Add a compact coverage figure only after larger first-wave grids have enough
   replicate counts to make visual coverage meaningful.
2. Continue keeping Wald, profile, and bootstrap rows method-separated.
