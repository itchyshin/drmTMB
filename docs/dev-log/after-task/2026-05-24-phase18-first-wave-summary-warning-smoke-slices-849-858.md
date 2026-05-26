# After Task: Phase 18 First-Wave Summary Warning Smoke Slices 849-858

## Goal

Validate and document the compact warning/error summary in the first-wave
summary report.

## Implemented

Added `docs/design/103-phase-18-first-wave-summary-warning-smoke-slices-849-858.md`
to record source, test, and saved-artifact evidence. No likelihood, formula
grammar, public API, roxygen topic, pkgdown navigation, package site output, or
formal statistical claim changed.

## Mathematical Contract

No model changed. The checked contract is report visibility: warning/error
events are grouped for quick review, but the raw ledger remains visible for
diagnosis.

## Files Changed

- `docs/design/103-phase-18-first-wave-summary-warning-smoke-slices-849-858.md`
- `docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-warning-smoke-slices-849-858.md`
- `docs/dev-log/check-log.md`

## Checks Run

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

Results:

- Source reads confirmed `phase18_failure_summary()` groups by source surface
  and severity and keeps an example message.
- Source reads confirmed the compact warning/error summary appears before the
  raw warning/error ledger.
- The focused first-wave summary-report and render-helper tests completed with
  exit code 0.
- The saved `slice-849` failures CSV has one event from
  `count_mu_random_effect_grid` with severity `warning`.
- Rendered HTML scans found `Warning And Error Summary`, `Warning And Error
  Ledger`, `n_event`, `example_message`, the interpretation boundary, and the
  count warning `collapsing to unique 'x' values`.
- The saved artifact-status CSV has 4 lines, the aggregate CSV has 24 lines,
  and the failures CSV has 2 lines including headers.
- No files were staged or committed.

## Tests Of The Tests

The report-template test checks the installed Rmd for the summary helper,
warning/error summary section, event-count column, raw warning/error ledger,
reader checks, and interpretation boundary. The render-helper test protects the
downstream report-generation path.

## Consistency Audit

This report validates warning visibility only. It does not diagnose the warning
or change count-model fitting, likelihoods, formula grammar, public API,
unsupported random-effect submodels, or formal simulation claims.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

Searching the self-contained HTML for a broad `unique` pattern matched bundled
JavaScript/CSS noise. The durable check uses the narrower
`collapsing to unique` phrase.

## Team Learning

For self-contained R Markdown HTML, search for specific model/report phrases
rather than generic words that may appear in bundled assets.

## Known Limitations

The summary groups events for fast review only. It does not suppress the count
warning, explain its numerical cause, or upgrade one-replicate smoke evidence
into a simulation claim.

## Next Actions

Continue with Slices 859-868 by validating the compact aggregate-bias overview
if the current dirty tree contains matching evidence.
