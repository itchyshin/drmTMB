# After Task: Phase 18 First-Wave Summary Bias Overview Slices 859-868

## Goal

Validate and document the compact aggregate-bias overview in the first-wave
summary report, including a direct visual audit of the rendered plot.

## Implemented

Added `docs/design/104-phase-18-first-wave-summary-bias-overview-slices-859-868.md`
and
`docs/dev-log/figure-audits/2026-05-24-phase18-first-wave-bias-overview-slices-859-868/audit.md`
to record source, test, saved-artifact, and visual evidence. No likelihood,
formula grammar, public API, roxygen topic, pkgdown navigation, package site
output, or formal statistical claim changed.

## Mathematical Contract

No model changed. The checked visual contract is aggregate screening: the plot
uses aggregate bias rows only and does not show raw data, replicate-level
clouds, confidence intervals, profile intervals, bootstrap intervals, or Monte
Carlo uncertainty.

## Files Changed

- `docs/design/104-phase-18-first-wave-summary-bias-overview-slices-859-868.md`
- `docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-bias-overview-slices-859-868.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/figure-audits/2026-05-24-phase18-first-wave-bias-overview-slices-859-868/audit.md`
- `docs/dev-log/figure-audits/2026-05-24-phase18-first-wave-bias-overview-slices-859-868/embedded-plot-01.png`
- `docs/dev-log/figure-audits/2026-05-24-phase18-first-wave-bias-overview-slices-859-868/aggregate-bias-overview-current-template.png`

## Checks Run

```sh
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '114,169p'
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '414,480p'
nl -ba tests/testthat/test-phase18-first-wave-summary-report.R | sed -n '1,170p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-summary-report|first-wave-summary-render-helper)', reporter = 'summary')"
Rscript -e 'p <- "inst/sim/results/slice-859-first-wave-summary-bias-overview-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv"; x <- read.csv(p, check.names = FALSE); cat("rows=", nrow(x), "\n", sep = ""); cat("finite_bias=", sum(is.finite(x[["bias"]])), "\n", sep = ""); cat("surfaces=", paste(sort(unique(x[["source_surface"]])), collapse = ","), "\n", sep = "")'
rg -n "Slice 859|Aggregate Bias Overview|Mean estimate minus truth|Full parameter names are listed below|Warning And Error Summary|collapsing to unique|Interpretation Boundary" inst/sim/results/slice-859-first-wave-summary-bias-overview-smoke/first-wave-summary/report/phase18-first-wave-summary.html
file docs/dev-log/figure-audits/2026-05-24-phase18-first-wave-bias-overview-slices-859-868/embedded-plot-01.png docs/dev-log/figure-audits/2026-05-24-phase18-first-wave-bias-overview-slices-859-868/aggregate-bias-overview-current-template.png
```

Results:

- Source reads confirmed the aggregate-bias helper filters finite bias rows,
  ranks by absolute bias, applies `max_rows`, and labels the plot as aggregate
  rows only.
- The focused first-wave summary-report and render-helper tests completed with
  exit code 0.
- The saved aggregate CSV has 23 finite bias rows across
  `count_mu_random_effect_grid`, `gaussian_ls_grid`, and `meta_v_grid`.
- Rendered HTML scans found `Aggregate Bias Overview`,
  `Mean estimate minus truth`, the aggregate-only caption, warning/error
  summary evidence, and the interpretation boundary.
- Figure audit found the historical saved embedded plot has clipped long labels,
  while the current-template rerender uses compact row ranks and is acceptable
  as a screening plot.
- No files were staged or committed.

## Tests Of The Tests

The report-template test checks the installed Rmd for the bias-overview helper
and section. The render test exercises the HTML path with aggregate, status,
interval, manifest, and failure tables. The visual audit inspected the PNG
itself rather than relying on source inspection alone.

## Consistency Audit

This report validates a screening display only. It does not make inferential
claims from one-replicate smoke evidence and does not change model support,
likelihood code, formula grammar, public API, or unsupported random-effect
submodels.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

The saved self-contained `slice-859` plot is visibly clipped. The current
template rerender with the same CSVs has the later compact-row visual fix, so
the after-task report records both facts instead of calling the historical
artifact publication-ready.

## Team Learning

Florence-style visual gates matter even for internal simulation reports.
Source/tests can pass while a saved plot still needs visual context or a
current-template rerender.

## Known Limitations

The aggregate-bias overview is not a final Florence figure. It shows aggregate
rows only and does not include uncertainty intervals or replicate-level clouds.

## Next Actions

Continue with Slices 869-878 by validating the compact interval-coverage
summary if the current dirty tree contains matching evidence.
