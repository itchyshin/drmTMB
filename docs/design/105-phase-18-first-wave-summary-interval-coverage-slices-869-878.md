# Phase 18 First-Wave Summary Interval Coverage Slices 869-878

Reader: `drmTMB` contributors checking that first-wave summary reports expose
available interval-coverage rows before readers inspect raw interval diagnostic
tables.

Slices 869-878 validate the compact interval-coverage summary. The saved
`inst/sim/results/slice-869-first-wave-summary-interval-coverage-smoke/`
artifact uses the three-surface Gaussian location-scale, `meta_V(V = V)`, and
paired Poisson/NB2 `mu` random-effect smoke. The summary is descriptive staging
evidence for the artifacts present in the smoke; one-replicate smoke output does
not estimate final coverage.

## Source Evidence

- `phase18_bind_interval_coverage()` combines Wald, profile, and bootstrap
  coverage tables and tags each row with `interval_method`.
- `phase18_interval_coverage_summary()` groups rows by `source_surface` and
  `interval_method`, counts distinct parameters, sums interval and covered
  counts when available, and reports grouped coverage.
- `phase18_first_wave_summary_report_params()` passes Wald, profile, and
  bootstrap coverage paths to the report when the bundled artifacts exist.
- The `Interval Coverage Summary` section displays `source_surface`,
  `interval_method`, `n_parameter`, `n_interval_total`, `n_covered_total`, and
  `coverage` before raw interval diagnostics.
- The focused report and render-helper tests protect the summary template and
  report parameter plumbing.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 869-871 | Validate interval-coverage table binding | Source read and report tests passed |
| 872-874 | Validate summary grouping by surface and method | Source read and saved HTML passed |
| 875-876 | Validate saved Wald/profile rows | Saved CSV row counts passed |
| 877-878 | Preserve one-replicate smoke interpretation boundary | After-task audit passed |

## Commands

```sh
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '180,280p'
nl -ba inst/sim/reports/phase18-first-wave-summary-report.Rmd | sed -n '486,540p'
nl -ba inst/sim/run/sim_render_first_wave_summary_report.R | sed -n '1,120p'
nl -ba tests/testthat/test-phase18-first-wave-summary-render-helper.R | sed -n '1,170p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-summary-report|first-wave-summary-render-helper)', reporter = 'summary')"
Rscript -e 'root <- "inst/sim/results/slice-869-first-wave-summary-interval-coverage-smoke/first-wave-summary/tables"; w <- read.csv(file.path(root, "phase18-first-wave-wald-coverage.csv"), check.names = FALSE); p <- read.csv(file.path(root, "phase18-first-wave-profile-coverage.csv"), check.names = FALSE); cat("wald_rows=", nrow(w), "\n", sep = ""); cat("profile_rows=", nrow(p), "\n", sep = ""); cat("wald_surfaces=", paste(sort(unique(w[["source_surface"]])), collapse = ","), "\n", sep = ""); cat("profile_surfaces=", paste(sort(unique(p[["source_surface"]])), collapse = ","), "\n", sep = "")'
rg -n "Slice 869|Interval Coverage Summary|count_mu_random_effect_grid +profile|count_mu_random_effect_grid +wald|gaussian_ls_grid +wald|meta_v_grid +wald|Interpretation Boundary" inst/sim/results/slice-869-first-wave-summary-interval-coverage-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-869-first-wave-summary-interval-coverage-smoke/first-wave-summary/tables/phase18-first-wave-wald-coverage.csv inst/sim/results/slice-869-first-wave-summary-interval-coverage-smoke/first-wave-summary/tables/phase18-first-wave-profile-coverage.csv inst/sim/results/slice-869-first-wave-summary-interval-coverage-smoke/first-wave-summary/tables/phase18-first-wave-bootstrap-coverage.csv
```

## Result

The focused first-wave summary-report and render-helper tests completed with
exit code 0. The saved smoke has 19 Wald coverage rows across
`count_mu_random_effect_grid`, `gaussian_ls_grid`, and `meta_v_grid`, plus 4
profile coverage rows for `count_mu_random_effect_grid`. The bootstrap coverage
CSV contains only a header because this smoke does not supply bootstrap rows.
This closes Slices 869-878 as interval-summary validation only. It does not add
bootstrap evidence, formal coverage claims, likelihoods, formula grammar,
public API, roxygen topics, or pkgdown navigation.
