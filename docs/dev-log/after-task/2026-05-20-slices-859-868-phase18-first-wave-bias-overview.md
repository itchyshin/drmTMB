# Slices 859-868: Phase 18 First-Wave Aggregate-Bias Overview

## Goal

Ada added the first compact visual screen to the first-wave summary report
while keeping the final simulation-figure work separate.

## Implemented

`phase18-first-wave-summary-report.Rmd` now derives finite aggregate-bias rows
from the bundled aggregate CSV and plots the largest displayed signed-bias rows
with a dashed zero line. The plot is explicitly captioned as aggregate-only:
replicate-level clouds remain a later Florence-reviewed figure layer.

The helper is defensive. It skips cleanly when aggregate rows, finite `bias`
values, or `ggplot2` are unavailable, and it leaves all CSV artifacts unchanged.

## Validation

Focused tests:

```sh
air format tests/testthat/test-phase18-first-wave-summary-report.R
Rscript -e "devtools::test(filter = '^phase18-first-wave-summary-report$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-report|first-wave-summary-render-helper)$')"
```

Result:

- 25 expectations passed, 0 failures, 0 warnings, 0 skips.
- The broader report/render-helper bundle then passed 41 expectations, 0
  failures, 0 warnings, 0 skips.

Tiny real smoke:

- Output root:
  `inst/sim/results/slice-859-first-wave-summary-bias-overview-smoke/`
- Rendered report:
  `inst/sim/results/slice-859-first-wave-summary-bias-overview-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- Bundled aggregate rows: 23.
- Warning/error events: 1.
- The rendered report includes `Aggregate Bias Overview`,
  `Warning And Error Summary`, the aggregate-only caption, and
  `collapsing to unique 'x' values`.
- A lightweight HTML check confirmed that the report contains an embedded plot
  image.

## Mathematical Contract

No estimand, likelihood, interval method, reported scale, or CSV artifact
changed. The plot displays existing aggregate `bias` rows as
`mean estimate minus truth`.

## Team Learning

- Ada: add visual layers only after the table provenance and diagnostic
  summaries are stable.
- Florence: this is a review screen, not the final replicate-level operating
  characteristic figure.
- Fisher: the caption keeps aggregate bias separate from replicate-level error
  distributions.
- Pat: the zero line and source facets make the first-wave report easier to
  scan before reading the tables.
- Grace: the section degrades to text if `ggplot2` is not available.
- Rose: the earlier visual inconsistency concern is handled by naming the
  figure's limited purpose rather than overclaiming it.

## Known Limitations

- This does not replace the planned raincloud-style replicate-error figures.
- The displayed rows are capped for readability; full rows remain in the CSV.
- The smoke remains one replicate per surface cell.

## Next Actions

1. Add a compact interval-status figure or table summary for Wald/profile/
   bootstrap evidence.
2. Keep the replicate-level visual grammar separate from this aggregate screen.
