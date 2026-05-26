# Phase 18 First-Wave Summary Manifest Smoke Slices 879-888

Reader: `drmTMB` contributors checking that first-wave summary reports expose
run-manifest status before readers inspect raw replicate ledgers.

Slices 879-888 validate the compact run-manifest summary. The saved
`inst/sim/results/slice-879-first-wave-summary-manifest-smoke/` artifact uses
the three-surface Gaussian location-scale, `meta_V(V = V)`, and paired
Poisson/NB2 `mu` random-effect smoke. The summary is descriptive staging
evidence for the runs present in the smoke; it is not a final simulation
success-rate claim.

## Source Evidence

- `phase18_manifest_summary()` groups manifest rows by `source_surface` and
  `status`.
- The summary counts runs, skipped runs, warning-bearing runs, total warnings,
  non-empty errors, and mean elapsed time.
- The `Run Manifest Summary` section appears before the raw `Run Manifest`
  table so a reviewer can spot skipped, warning, or error rows before scanning
  replicate-level details.
- The focused report and render-helper tests protect the summary helper,
  section heading, and report parameter plumbing.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 879-881 | Validate manifest summary grouping | Source read and report tests passed |
| 882-884 | Validate saved manifest row counts | Saved CSV checks passed |
| 885-886 | Validate rendered summary visibility | Saved HTML scan passed |
| 887-888 | Preserve smoke interpretation boundary | After-task audit passed |

## Commands

```sh
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '250,350p'
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '530,570p'
nl -ba tests/testthat/test-phase18-first-wave-summary-report.R | sed -n '1,180p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-summary-report|first-wave-summary-render-helper)', reporter = 'summary')"
Rscript -e 'root <- "inst/sim/results/slice-879-first-wave-summary-manifest-smoke/first-wave-summary"; m <- read.csv(file.path(root, "tables/phase18-first-wave-manifest.csv"), check.names = FALSE); s <- read.csv(file.path(root, "status/phase18-first-wave-artifact-status.csv"), check.names = FALSE); a <- read.csv(file.path(root, "status/phase18-first-wave-artifact-manifest.csv"), check.names = FALSE); cat("manifest_rows=", nrow(m), "\n", sep = ""); cat("manifest_surfaces=", paste(sort(unique(m[["source_surface"]])), collapse = ","), "\n", sep = ""); cat("manifest_status=", paste(sort(unique(m[["status"]])), collapse = ","), "\n", sep = ""); cat("status_rows=", nrow(s), "\n", sep = ""); cat("artifact_manifest_rows=", nrow(a), "\n", sep = "")'
Rscript -e 'root <- "inst/sim/results/slice-879-first-wave-summary-manifest-smoke/first-wave-summary/tables"; m <- read.csv(file.path(root, "phase18-first-wave-manifest.csv"), check.names = FALSE); cat("rows=", nrow(m), "\n", sep = ""); print(stats::aggregate(list(n_run = m[["status"]]), list(source_surface = m[["source_surface"]], status = m[["status"]]), length), row.names = FALSE); cat("warning_total=", sum(as.numeric(m[["warning_count"]]), na.rm = TRUE), "\n", sep = ""); cat("error_nonempty=", sum(nzchar(as.character(m[["error"]])) & !is.na(m[["error"]])), "\n", sep = "")'
rg -n "Slice 879|Run Manifest Summary|Run Manifest|count_mu_random_effect_grid +ok|gaussian_ls_grid +ok|meta_v_grid +ok|n_warning_run|warning_total|mean_elapsed|Interpretation Boundary" inst/sim/results/slice-879-first-wave-summary-manifest-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-879-first-wave-summary-manifest-smoke/first-wave-summary/tables/phase18-first-wave-manifest.csv inst/sim/results/slice-879-first-wave-summary-manifest-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv inst/sim/results/slice-879-first-wave-summary-manifest-smoke/first-wave-summary/status/phase18-first-wave-artifact-manifest.csv
```

## Result

The focused first-wave summary-report and render-helper tests completed with
exit code 0. The saved smoke has 6 manifest rows: 2 for
`count_mu_random_effect_grid`, 1 for `gaussian_ls_grid`, and 3 for
`meta_v_grid`. All rows have status `ok`; the manifest records one warning
from the count surface and no non-empty errors. The rendered report shows the
`Run Manifest Summary`, the raw `Run Manifest`, the three `ok` surface rows,
warning columns, mean elapsed time, and the interpretation boundary. This closes
Slices 879-888 as manifest-summary validation only. It does not add likelihoods,
formula grammar, public API, roxygen topics, pkgdown navigation, or formal
simulation success-rate claims.
