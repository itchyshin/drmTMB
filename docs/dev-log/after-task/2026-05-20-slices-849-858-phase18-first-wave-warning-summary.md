# Slices 849-858: Phase 18 First-Wave Warning Summary

## Goal

Ada made the first-wave summary report show warning/error problems before the
reader reaches the raw event ledger.

## Implemented

`phase18-first-wave-summary-report.Rmd` now derives a compact warning/error
summary from the bundled failures CSV. The summary groups by `source_surface`
and `severity`, reports the number of events, counts unique messages, and shows
one example message. The full warning/error ledger remains unchanged below the
summary.

## Validation

Focused tests:

```sh
air format tests/testthat/test-phase18-first-wave-summary-report.R
Rscript -e "devtools::test(filter = '^phase18-first-wave-summary-report$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-report|first-wave-summary-render-helper)$')"
```

Result:

- 22 expectations passed, 0 failures, 0 warnings, 0 skips.
- The broader report/render-helper bundle then passed 38 expectations, 0
  failures, 0 warnings, 0 skips.

Tiny real smoke:

- Output root:
  `inst/sim/results/slice-849-first-wave-summary-warning-smoke/`
- Rendered report:
  `inst/sim/results/slice-849-first-wave-summary-warning-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- Surfaces:
  `count_mu_random_effect_grid`, `gaussian_ls_grid`, `meta_v_grid`
- Artifact-status rows: 3.
- Bundled aggregate rows: 23.
- Warning/error events: 1.
- The rendered report includes `Warning And Error Summary` and shows
  `collapsing to unique 'x' values`.

## Mathematical Contract

No simulation estimand, likelihood, interval method, reported scale, CSV
artifact, or figure grammar changed. This is report summarisation over the
existing failures table.

## Team Learning

- Ada: summary reports should surface diagnostics before raw ledgers.
- Pat: a one-row warning summary is easier to scan than a long event table.
- Fisher: the count warning is now visible as an operating-characteristic
  caveat rather than buried display text.
- Grace: the change stays inside the Rmd template and focused report tests.
- Rose: this closes the loose end from Slices 839-848 where the warning was
  visible but not summarised.

## Known Limitations

- The summary does not interpret or suppress warnings.
- The smoke remains a one-replicate staging run, not final simulation evidence.
- No Florence-reviewed first-wave figure has been added yet.

## Next Actions

1. Add the first compact first-wave figure only after the table/report summary
   remains stable.
2. Keep warnings attached to surfaces when larger first-wave grids start.
