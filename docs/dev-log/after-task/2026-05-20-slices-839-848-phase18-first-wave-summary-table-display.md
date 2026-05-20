# Slices 839-848: Phase 18 First-Wave Summary Table Display

## Goal

Ada made the first-wave summary report easier to scan before any figure layer
is added.

## Implemented

`phase18-first-wave-summary-report.Rmd` now:

- places priority columns first for artifact status, aggregate rows, interval
  diagnostics, interval failures, manifests, and warning/error ledgers;
- supports `params$max_rows`;
- prints a row-cap message when a displayed table is longer than `max_rows`;
- leaves the underlying CSV files unchanged.

## Validation

Focused tests:

```sh
air format tests/testthat/test-phase18-first-wave-summary-report.R
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-report|first-wave-summary-render-helper)$')"
```

Result:

- 33 expectations passed, 0 failures, 0 warnings, 0 skips.

Tiny real smoke:

- Output root:
  `inst/sim/results/slice-839-first-wave-summary-table-polish-smoke/`
- Rendered report:
  `inst/sim/results/slice-839-first-wave-summary-table-polish-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- Bundled aggregate rows: 23.
- The rendered report shows "Showing first 20 of 23 rows."
- The rendered aggregate table leads with `source_surface` and
  `source_artifact`.
- The warning/error ledger exposes one count warning:
  `collapsing to unique 'x' values`.

## Mathematical Contract

No CSV schema, estimand, likelihood, interval method, or metric changed. This
is display-only report polish.

## Team Learning

- Ada: table-first reports need priority columns before figures are worth
  designing.
- Pat: row caps make the summary page readable without hiding the full CSVs.
- Fisher: warning ledgers remain visible beside aggregate rows.
- Grace: the render helper still passes after the report template change.
- Rose: the count warning surfaced in the report, which validates the
  failure-ledger design.

## Known Limitations

- This is still a table-first report with no Florence-reviewed figures.
- The count warning is visible but not interpreted in a dedicated report note.
- The smoke remains one replicate per surface cell.

## Next Actions

1. Add a compact warning/diagnostic summary above the raw warning/error ledger.
2. Then consider the first simple first-wave figure.
