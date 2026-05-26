# Phase 18 First-Wave Summary Table Polish Slices 839-848

Reader: `drmTMB` contributors checking that first-wave summary HTML remains
scannable when combined table artifacts become wider or longer than a quick
smoke report can reasonably display.

Slices 839-848 validate first-wave summary table-display polish. The saved
`inst/sim/results/slice-839-first-wave-summary-table-polish-smoke/` artifact
uses the three-surface Gaussian location-scale, `meta_V(V = V)`, and paired
Poisson/NB2 `mu` random-effect smoke. The report keeps full CSV artifacts on
disk while displaying priority provenance and model columns first and capping
long tables in HTML.

## Source Evidence

- `params$max_rows` defaults to 20 in
  `inst/sim/reports/phase18-first-wave-summary-report.Rmd`.
- `phase18_select_columns()` moves requested priority columns to the front while
  preserving all other columns after them.
- `phase18_show_table()` prints a row-cap message and displays the first
  `max_rows` rows when a table is longer than the display cap.
- The aggregate table call prioritizes `source_surface`, `source_artifact`,
  `surface`, `family`, parameter descriptors, estimate summaries, and status
  rates.
- The focused report-template test checks that `max_rows` and
  `phase18_select_columns()` are present, and the render-helper test protects
  downstream report generation.
- The saved `slice-839` rendered HTML contains the row-cap message, provenance
  columns, aggregate operating-characteristic rows, and the interpretation
  boundary.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 839-841 | Validate priority-column table display | Rmd source read and report tests passed |
| 842-844 | Validate HTML row cap without truncating CSV artifacts | Saved HTML and CSV line counts passed |
| 845-846 | Validate count-surface warning ledger still appears | Saved failures CSV and HTML scan passed |
| 847-848 | Preserve table-first interpretation boundaries | Report scan and after-task audit passed |

## Commands

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

## Result

The focused first-wave summary-report and render-helper tests completed with
exit code 0. The saved `slice-839` aggregate CSV has 23 rows and begins with
`source_surface`, `source_artifact`, `surface`, `cell_id`, and `parameter`.
The rendered HTML shows `Showing first 20 of 23 rows.`, keeping the report
scannable while preserving the full CSV. This closes Slices 839-848 as report
display validation only. It does not add likelihoods, formula grammar, public
API, roxygen topics, pkgdown navigation, or new statistical claims.
