# Phase 18 First-Wave Summary Bias Overview Slices 859-868

Reader: `drmTMB` contributors checking that the first-wave summary report can
show a compact aggregate-bias screen without pretending it is a final
publication figure.

Slices 859-868 validate the aggregate-bias overview. The saved
`inst/sim/results/slice-859-first-wave-summary-bias-overview-smoke/` artifact
uses the three-surface Gaussian location-scale, `meta_V(V = V)`, and paired
Poisson/NB2 `mu` random-effect smoke. The visual data grain is aggregate rows
only: no raw observations, no replicate-level clouds, and no interval
uncertainty.

## Source Evidence

- `phase18_bias_overview_data()` filters finite bias rows, orders by absolute
  bias, applies the report row cap, and stores the total number of finite rows.
- The `Aggregate Bias Overview` section plots aggregate bias against row rank,
  colours by `source_surface`, and states that replicate-level clouds belong to
  later Florence-reviewed simulation figures.
- The report then lists priority columns for the displayed aggregate-bias rows
  so readers can map row ranks back to full parameter names.
- The focused report-template test checks for `phase18_bias_overview_data()`
  and `Aggregate Bias Overview`; the render-helper test protects downstream
  report generation.
- A visual audit extracted the historical saved embedded PNG and rerendered the
  same slice-859 CSVs through the current report template. The historical saved
  plot has clipped long labels; the current-template rerender uses compact row
  ranks and passes as a screening plot.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 859-861 | Validate aggregate-bias helper and report section | Source read and report tests passed |
| 862-864 | Validate saved three-surface aggregate evidence | Saved aggregate CSV and HTML scans passed |
| 865-866 | Perform visual audit of the embedded plot | Historical and current-template PNGs inspected |
| 867-868 | Preserve aggregate-screening interpretation boundary | Figure audit and after-task audit passed |

## Commands

```sh
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '114,169p'
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '414,480p'
nl -ba tests/testthat/test-phase18-first-wave-summary-report.R | sed -n '1,170p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-summary-report|first-wave-summary-render-helper)', reporter = 'summary')"
Rscript -e 'p <- "inst/sim/results/slice-859-first-wave-summary-bias-overview-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv"; x <- read.csv(p, check.names = FALSE); cat("rows=", nrow(x), "\n", sep = ""); cat("finite_bias=", sum(is.finite(x[["bias"]])), "\n", sep = ""); cat("surfaces=", paste(sort(unique(x[["source_surface"]])), collapse = ","), "\n", sep = "")'
rg -n "Slice 859|Aggregate Bias Overview|Mean estimate minus truth|Full parameter names are listed below|Warning And Error Summary|collapsing to unique|Interpretation Boundary" inst/sim/results/slice-859-first-wave-summary-bias-overview-smoke/first-wave-summary/report/phase18-first-wave-summary.html
file docs/dev-log/figure-audits/2026-05-24-phase18-first-wave-bias-overview-slices-859-868/embedded-plot-01.png docs/dev-log/figure-audits/2026-05-24-phase18-first-wave-bias-overview-slices-859-868/aggregate-bias-overview-current-template.png
```

## Result

The focused first-wave summary-report and render-helper tests completed with
exit code 0. The saved aggregate CSV has 23 finite bias rows across
`count_mu_random_effect_grid`, `gaussian_ls_grid`, and `meta_v_grid`. The saved
HTML contains `Aggregate Bias Overview`, the axis text
`Mean estimate minus truth`, the aggregate-only caption, the warning/error
summary, and the interpretation boundary. The visual audit records the saved
historical plot as clipped, and the current-template rerender as acceptable for
aggregate screening. This closes Slices 859-868 as report-visual validation
only; it does not change likelihoods, formula grammar, public API, roxygen
topics, pkgdown navigation, or statistical claims.
