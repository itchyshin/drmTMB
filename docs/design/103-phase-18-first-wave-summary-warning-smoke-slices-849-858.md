# Phase 18 First-Wave Summary Warning Smoke Slices 849-858

Reader: `drmTMB` contributors checking that first-wave summary reports surface
warning and error patterns without hiding the raw event ledger.

Slices 849-858 validate the compact warning/error summary. The saved
`inst/sim/results/slice-849-first-wave-summary-warning-smoke/` artifact uses
the three-surface Gaussian location-scale, `meta_V(V = V)`, and paired
Poisson/NB2 `mu` random-effect smoke. The report groups warning/error events by
surface and severity before showing the raw warning/error ledger.

## Source Evidence

- `phase18_failure_summary()` groups failures by `source_surface` and
  `severity`, counts events, counts unique messages, and keeps one example
  message.
- The `Warning And Error Summary` section displays `source_surface`,
  `severity`, `n_event`, `n_unique_message`, and `example_message`.
- The `Warning And Error Ledger` section remains present below the summary, so
  the grouped view does not replace raw event evidence.
- The focused report-template test checks for `phase18_failure_summary()`,
  `Warning And Error Summary`, `n_event`, and the warning/error ledger.
- The saved `slice-849` rendered HTML includes one count-surface warning:
  `collapsing to unique 'x' values`.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 849-851 | Validate compact warning/error grouping | Rmd source read and report tests passed |
| 852-854 | Validate raw warning/error ledger remains visible | Rmd source read and HTML scan passed |
| 855-856 | Validate saved count warning is exposed | Saved failures CSV and HTML scan passed |
| 857-858 | Preserve smoke-scale interpretation boundaries | After-task audit passed |

## Commands

```sh
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '87,115p'
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '560,605p'
nl -ba tests/testthat/test-phase18-first-wave-summary-report.R | sed -n '1,170p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-summary-report|first-wave-summary-render-helper)', reporter = 'summary')"
Rscript -e 'p <- "inst/sim/results/slice-849-first-wave-summary-warning-smoke/first-wave-summary/tables/phase18-first-wave-failures.csv"; x <- read.csv(p, check.names = FALSE); cat("events=", nrow(x), "\n", sep = ""); cat("surfaces=", paste(sort(unique(x[["source_surface"]])), collapse = ","), "\n", sep = ""); cat("severity=", paste(sort(unique(x[["severity"]])), collapse = ","), "\n", sep = "")'
rg -n "Slice 849|Warning And Error Summary|Warning And Error Ledger|n_event|example_message|Interpretation Boundary" inst/sim/results/slice-849-first-wave-summary-warning-smoke/first-wave-summary/report/phase18-first-wave-summary.html
rg -n "collapsing to unique" inst/sim/results/slice-849-first-wave-summary-warning-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-849-first-wave-summary-warning-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv inst/sim/results/slice-849-first-wave-summary-warning-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv inst/sim/results/slice-849-first-wave-summary-warning-smoke/first-wave-summary/tables/phase18-first-wave-failures.csv
```

## Result

The focused first-wave summary-report and render-helper tests completed with
exit code 0. The saved `slice-849` failures CSV has one event from
`count_mu_random_effect_grid` with severity `warning`. The rendered HTML shows
the compact warning/error summary, the raw ledger, and the count warning
message. This closes Slices 849-858 as warning-summary validation only. It does
not diagnose, suppress, or reinterpret the warning, and it does not add
likelihoods, formula grammar, public API, roxygen topics, pkgdown navigation,
or new statistical claims.
