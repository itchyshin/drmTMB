# After Task: Phase 18 First-Wave Summary Interval Coverage Slices 869-878

## Goal

Validate and document compact interval-coverage evidence in the first-wave
summary report.

## Implemented

Added `docs/design/105-phase-18-first-wave-summary-interval-coverage-slices-869-878.md`
to record source, test, and saved-artifact evidence. No likelihood, formula
grammar, public API, roxygen topic, pkgdown navigation, package site output, or
formal statistical claim changed.

## Mathematical Contract

No model changed. The checked contract is report summarisation of available
interval artifacts. Wald, profile, and bootstrap rows stay labelled by method;
coverage rows in a one-replicate smoke are staging evidence only.

## Files Changed

- `docs/design/105-phase-18-first-wave-summary-interval-coverage-slices-869-878.md`
- `docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-interval-coverage-slices-869-878.md`
- `docs/dev-log/check-log.md`

## Checks Run

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

Results:

- Source reads confirmed Wald, profile, and bootstrap coverage tables are bound
  with explicit `interval_method` labels.
- Source reads confirmed the summary groups by `source_surface` and
  `interval_method`, then reports parameter counts, interval totals, covered
  totals, and coverage.
- The focused first-wave summary-report and render-helper tests completed with
  exit code 0.
- The saved smoke has 19 Wald coverage rows across
  `count_mu_random_effect_grid`, `gaussian_ls_grid`, and `meta_v_grid`.
- The saved smoke has 4 profile coverage rows for
  `count_mu_random_effect_grid`.
- The bootstrap coverage CSV contains only a header.
- Rendered HTML scans found `Interval Coverage Summary`, grouped Wald/profile
  rows, and the interpretation boundary.
- No files were staged or committed.

## Tests Of The Tests

The report-template test checks for `phase18_interval_coverage_summary()` and
the interval coverage section. The render-helper test protects the params that
carry Wald, profile, and bootstrap coverage paths into the R Markdown template.

## Consistency Audit

This report validates summary plumbing only. It does not claim formal interval
coverage, add bootstrap evidence, change likelihoods, alter formula grammar, or
expand unsupported random-effect submodels.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

A broad HTML search for `wald|profile|bootstrap` matched bundled JavaScript and
repository text noise. The durable scan uses specific summary-row patterns.

## Team Learning

Self-contained report HTML should be searched with specific row or heading
patterns. Generic statistical words are too common in embedded assets.

## Known Limitations

One-replicate smoke rows are not formal coverage estimates. Bootstrap coverage
is absent here because no grid writer supplied bootstrap coverage rows.

## Next Actions

Continue with Slices 879-888 by validating the compact run-manifest summary if
the current dirty tree contains matching evidence.
