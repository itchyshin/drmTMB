# Phase 18 First-Wave Summary Polished Smoke Slices 819-828

Reader: `drmTMB` contributors checking whether mixed first-wave report tables
carry enough provenance to audit rows after surfaces are combined.

Slices 819-828 validate the first-wave table-bundle provenance polish. The
saved `inst/sim/results/slice-819-first-wave-summary-polished-smoke/` artifact
contains the historical Gaussian location-scale plus `meta_V(V = V)` rendered
summary HTML, with `source_surface` and `source_artifact` leading the combined
tables. Later slices expanded the reusable smoke runner to count, random-slope,
and spatial surfaces; this slice remains a saved-artifact and table-bundle
provenance check, not a new operating-characteristic claim.

## Source Evidence

- `phase18_collect_first_wave_table()` adds `source_surface` and
  `source_artifact` to every non-empty artifact table before binding.
- `phase18_row_bind_fill()` moves `source_surface` and `source_artifact` to the
  front of the combined table, preserving surface-specific columns behind the
  provenance columns.
- Empty or missing artifact tables return the same provenance-column skeleton
  instead of changing the table contract.
- `test-phase18-first-wave-table-bundle.R` checks the provenance column order,
  heterogeneous aggregate columns, empty failure tables, missing artifacts,
  overwrite protection, and malformed input paths.
- The saved `slice-819` rendered HTML contains `gaussian_ls_grid`,
  `meta_v_grid`, aggregate operating-characteristic rows, and the
  interpretation boundary.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 819-821 | Validate provenance columns lead combined tables | Source read and table-bundle tests passed |
| 822-824 | Validate heterogeneous table binding keeps source identity | Test fixture and saved aggregate CSV passed |
| 825-826 | Validate empty and missing artifacts keep a stable contract | Test fixture passed |
| 827-828 | Validate saved polished smoke artifact | Saved HTML and table files exist |

## Commands

```sh
nl -ba inst/sim/run/sim_write_first_wave_table_bundle.R | sed -n '1,230p'
nl -ba tests/testthat/test-phase18-first-wave-table-bundle.R | sed -n '1,180p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-table-bundle|first-wave-summary-render-helper|first-wave-summary-report)', reporter = 'summary')"
Rscript -e "p <- 'inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv'; x <- read.csv(p, check.names = FALSE); cat('rows=', nrow(x), '\n', sep = ''); cat('first_cols=', paste(names(x)[seq_len(min(4L, ncol(x)))], collapse = ','), '\n', sep = '')"
rg -n "Slice 819|source_surface|source_artifact|gaussian_ls_grid|meta_v_grid|Aggregate Operating Characteristics|Interpretation Boundary" inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/tables/phase18-first-wave-wald-coverage.csv
```

## Result

The focused first-wave table-bundle, render-helper, and summary-report tests
completed with exit code 0. The saved `slice-819` aggregate table has 13 rows,
and its first columns are `source_surface`, `source_artifact`, `surface`, and
`cell_id`. The saved rendered HTML exists and shows the provenance columns in
the aggregate table. This closes Slices 819-828 as provenance and rendered-smoke
validation only. It does not change likelihood code, formula grammar, roxygen
topics, pkgdown navigation, public API, or formal statistical claims.
