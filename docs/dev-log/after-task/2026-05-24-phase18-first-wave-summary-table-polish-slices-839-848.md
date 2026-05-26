# After Task: Phase 18 First-Wave Summary Table Polish Slices 839-848

## Goal

Validate and document first-wave summary table-display polish: priority columns
for readability and row caps for long rendered HTML tables.

## Implemented

Added `docs/design/102-phase-18-first-wave-summary-table-polish-slices-839-848.md`
to record source, test, and saved-artifact evidence. No likelihood, formula
grammar, public API, roxygen topic, pkgdown navigation, package site output, or
formal statistical claim changed.

## Mathematical Contract

No model changed. The checked contract is report display. The full CSV tables
remain the authoritative artifacts; the rendered HTML may show capped table
previews with provenance and model columns first.

## Files Changed

- `docs/design/102-phase-18-first-wave-summary-table-polish-slices-839-848.md`
- `docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-table-polish-slices-839-848.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '1,90p'
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '140,175p'
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '380,470p'
nl -ba tests/testthat/test-phase18-first-wave-summary-report.R | sed -n '1,190p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-summary-report|first-wave-summary-render-helper)', reporter = 'summary')"
Rscript -e 'p <- "inst/sim/results/slice-839-first-wave-summary-table-polish-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv"; x <- read.csv(p, check.names = FALSE); cat("rows=", nrow(x), "\n", sep = ""); cat("first_cols=", paste(names(x)[seq_len(min(5L, ncol(x)))], collapse = ","), "\n", sep = "")'
rg -n "Slice 839|Showing first 20 of 23 rows|source_surface|source_artifact|collapsing to unique 'x' values|Aggregate Operating Characteristics|Interpretation Boundary" inst/sim/results/slice-839-first-wave-summary-table-polish-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-839-first-wave-summary-table-polish-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv inst/sim/results/slice-839-first-wave-summary-table-polish-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv inst/sim/results/slice-839-first-wave-summary-table-polish-smoke/first-wave-summary/tables/phase18-first-wave-failures.csv
```

Results:

- Source reads confirmed `params$max_rows`, `phase18_select_columns()`, and
  `phase18_show_table()` are present in the first-wave summary report template.
- The focused first-wave summary-report and render-helper tests completed with
  exit code 0.
- The saved `slice-839` aggregate CSV has 23 rows and begins with
  `source_surface`, `source_artifact`, `surface`, `cell_id`, and `parameter`.
- The rendered HTML shows `Showing first 20 of 23 rows.`
- The saved artifact-status CSV has 4 lines, the aggregate CSV has 24 lines,
  and the failures CSV has 2 lines including headers.
- Rendered HTML scans found `Slice 839`, provenance columns, aggregate
  operating characteristics, the row-cap message, and the interpretation
  boundary.
- No files were staged or committed.

## Tests Of The Tests

The report-template test checks that the installed Rmd contains `max_rows`,
`phase18_select_columns()`, expected report sections, warning/error summary
hooks, reader checks, and the interpretation boundary. The render test renders
a minimal HTML report with status, aggregate, interval, manifest, and failure
tables.

## Consistency Audit

This report validates rendered table readability only. It does not expand model
support, likelihood code, formula grammar, random-effect submodel support, or
statistical operating-characteristic claims.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

One source-read command combined two `nl` calls while I was exploring. The
durable command list records the reads separately so the check-log remains easy
to rerun.

## Team Learning

Report-display polish should distinguish full CSV artifacts from capped HTML
previews. Grace should keep checking both because a readable report is not a
replacement for complete artifact files.

## Known Limitations

The saved `slice-839` smoke is one replicate and table-first. It does not add a
figure layer or formal operating-characteristic interpretation.

## Next Actions

Continue with Slices 849-858 by validating the compact warning/error summary if
the current dirty tree contains matching evidence.
