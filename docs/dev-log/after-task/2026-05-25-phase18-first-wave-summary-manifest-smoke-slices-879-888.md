# After Task: Phase 18 First-Wave Summary Manifest Smoke Slices 879-888

## Goal

Validate and document compact run-manifest evidence in the first-wave summary
report.

## Implemented

Added `docs/design/106-phase-18-first-wave-summary-manifest-smoke-slices-879-888.md`
to record source, test, saved-artifact, and rendered-report evidence. No
likelihood, formula grammar, public API, roxygen topic, pkgdown navigation,
package site output, or formal statistical claim changed.

## Mathematical Contract

No model changed. The checked contract is report summarisation of available
run-manifest artifacts. Manifest rows stay grouped by `source_surface` and
`status`; one-replicate smoke rows are staging evidence only.

## Files Changed

- `docs/design/106-phase-18-first-wave-summary-manifest-smoke-slices-879-888.md`
- `docs/dev-log/after-task/2026-05-25-phase18-first-wave-summary-manifest-smoke-slices-879-888.md`
- `docs/dev-log/check-log.md`

## Checks Run

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

Results:

- Source reads confirmed `phase18_manifest_summary()` groups manifest rows by
  `source_surface` and `status`.
- Source reads confirmed the summary counts runs, skipped runs, warning-bearing
  runs, total warnings, non-empty errors, and mean elapsed time.
- The focused first-wave summary-report and render-helper tests completed with
  exit code 0.
- The saved smoke has 6 manifest rows across
  `count_mu_random_effect_grid`, `gaussian_ls_grid`, and `meta_v_grid`.
- The manifest summary has 2 count rows, 1 Gaussian location-scale row, and 3
  `meta_V(V = V)` rows, all with status `ok`.
- The saved manifest records one warning-bearing count run, one total warning,
  and no non-empty errors.
- Rendered HTML scans found `Run Manifest Summary`, raw `Run Manifest`,
  warning columns, mean elapsed time, the three `ok` surface rows, and the
  interpretation boundary.
- No files were staged or committed.

## Tests Of The Tests

The report-template test checks for `phase18_manifest_summary()` and the run
manifest section. The render-helper test protects the params that carry
manifest paths into the R Markdown template.

## Consistency Audit

This report validates summary plumbing only. It does not claim final simulation
success rates, add likelihoods, alter formula grammar, or expand unsupported
random-effect submodels.

## GitHub Issue Maintenance

Searched open issues for `"first-wave" manifest OR "run manifest" OR "Phase 18"`.
The only overlap was umbrella issue #59, "Phase 18: comprehensive simulation
framework and reporting". No GitHub issue mutation was done from this mixed
dirty branch.

## What Did Not Go Smoothly

The saved manifest smoke had already been generated, but the prior thread ended
before recording the ledger pair. The continuation therefore had to distinguish
artifact validation from new implementation work.

## Team Learning

Ada should keep treating report-summary slices as evidence-capture work unless
the source template changes. Rose should name that boundary in the design note
so later agents do not read a smoke artifact as a final simulation claim.

## Known Limitations

The manifest rows come from a one-replicate smoke. They show the report can
surface run status, warnings, errors, and elapsed time; they do not estimate
long-run failure rates.

## Next Actions

Continue with Slices 889-898 by validating the first-wave summary over the
saved two-replicate smoke, if that evidence is still present and current.
