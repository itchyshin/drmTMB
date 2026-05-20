# Slices 879-888: Phase 18 First-Wave Run Manifest Summary

## Goal

Ada made run provenance visible in the first-wave summary report before the raw
manifest table.

## Implemented

`phase18-first-wave-summary-report.Rmd` now derives a run-manifest summary from
the bundled manifest CSV. The summary groups by `source_surface` and `status`,
then reports run counts, skipped rows, warning-bearing runs, total warnings,
error counts, and mean elapsed time.

The raw manifest table remains below the summary.

## Validation

Focused tests:

```sh
air format tests/testthat/test-phase18-first-wave-summary-report.R
Rscript -e "devtools::test(filter = '^phase18-first-wave-summary-report$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-report|first-wave-summary-render-helper)$')"
```

Result:

- 32 expectations passed, 0 failures, 0 warnings, 0 skips.
- The broader report/render-helper bundle then passed 48 expectations, 0
  failures, 0 warnings, 0 skips.

Tiny real smoke:

- Output root:
  `inst/sim/results/slice-879-first-wave-summary-manifest-smoke/`
- Rendered report:
  `inst/sim/results/slice-879-first-wave-summary-manifest-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- Manifest rows: 6.
- Manifest warning total: 1.
- The rendered report includes `Run Manifest Summary`,
  `Interval Coverage Summary`, `Aggregate Bias Overview`, and
  `Warning And Error Summary`.

## Mathematical Contract

No simulation result, likelihood, interval method, or CSV artifact changed.
The summary is a derived provenance display over existing manifest rows.

## Team Learning

- Ada: first-wave reports need status summaries before detailed manifest rows.
- Grace: skipped rows, warning counts, errors, and elapsed time are now visible
  without opening the manifest CSV.
- Fisher: run-status summaries help separate execution problems from estimator
  performance.
- Pat: readers get an immediate answer to whether the displayed tables came
  from successful runs.
- Rose: this closes another hidden-provenance gap before larger grids.

## Known Limitations

- The summary is not a convergence or timing benchmark.
- Smoke-scale elapsed times should not be treated as performance claims.

## Next Actions

1. Run a slightly larger first-wave staging smoke only after the report
   summaries remain stable.
2. Keep execution provenance separate from statistical operating
   characteristics in final figures.
