# Slices 819-828: Phase 18 First-Wave Report Table Polish

## Goal

Ada polished the first-wave table bundle so rendered summary reports show the
source surface and source artifact before surface-specific columns.

## Implemented

`phase18_row_bind_fill()` now moves these provenance columns to the front when
they are present:

- `source_surface`
- `source_artifact`

This keeps mixed-surface aggregate, manifest, interval, and failure tables
readable after row-binding columns that differ across surfaces.

## Validation

Focused tests:

```sh
air format inst/sim/run/sim_write_first_wave_table_bundle.R tests/testthat/test-phase18-first-wave-table-bundle.R
Rscript -e "devtools::test(filter = '^phase18-(first-wave-table-bundle|first-wave-summary-render-helper|first-wave-summary-report)$')"
```

Result:

- 51 expectations passed, 0 failures, 0 warnings, 0 skips.

Tiny real smoke:

- Output root:
  `inst/sim/results/slice-819-first-wave-summary-polished-smoke/`
- Rendered report:
  `inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- Bundled aggregate rows: 13.
- First aggregate columns: `source_surface`, `source_artifact`.

## Mathematical Contract

No estimand, likelihood, interval method, or summary metric changed. This is a
display/provenance-column ordering change for report readability.

## Team Learning

- Ada: provenance columns should lead combined report tables, especially when
  surfaces have different metric columns.
- Pat: the table is easier to read when the source is visible before `NA`
  padding from other surfaces.
- Fisher: provenance moved; values and metrics did not.
- Grace: the change is covered by both synthetic tests and a tiny real rendered
  smoke.
- Rose: this fixes a strange-looking report artifact before figures are added.

## Known Limitations

- The report remains table-first and does not yet draw Florence-reviewed
  figures.
- The tiny smoke is still not a formal operating-characteristic grid.

## Next Actions

1. Consider adding the count `mu` random-effect surface to the first-wave smoke
   if runtime remains acceptable.
2. Start figure polish only after the count/continuous/meta table mix remains
   readable.
