# After Task: Phase 18 First-Wave Summary n_rep = 2 Revalidation Slices 889-898

## Goal

Revalidate the saved two-replicate first-wave summary smoke without converting
its staging evidence into final simulation claims.

## Implemented

Added `docs/design/107-phase-18-first-wave-summary-nrep2-revalidation-slices-889-898.md`
to record current source, test, saved-artifact, and rendered-report evidence.
This is a revalidation note because `docs/dev-log/after-task/2026-05-20-slices-889-898-phase18-first-wave-nrep2-smoke.md`
already recorded the original smoke. No likelihood, formula grammar, public API,
roxygen topic, pkgdown navigation, package site output, or formal statistical
claim changed.

## Mathematical Contract

No model changed. The checked contract is that the existing first-wave report
still reads and displays a saved `n_rep = 2` three-surface staging smoke. The
artifact remains descriptive simulation staging evidence only.

## Files Changed

- `docs/design/107-phase-18-first-wave-summary-nrep2-revalidation-slices-889-898.md`
- `docs/dev-log/after-task/2026-05-25-phase18-first-wave-summary-nrep2-revalidation-slices-889-898.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
sed -n '1,140p' docs/dev-log/after-task/2026-05-20-slices-889-898-phase18-first-wave-nrep2-smoke.md
sed -n '670,700p' docs/design/41-phase-18-simulation-programme.md
nl -ba tests/testthat/test-phase18-first-wave-summary-smoke-runner.R | sed -n '1,130p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-summary-report|first-wave-summary-render-helper|first-wave-summary-smoke-runner)', reporter = 'summary')"
Rscript -e 'root <- "inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary"; agg <- read.csv(file.path(root, "tables/phase18-first-wave-aggregate.csv"), check.names = FALSE); rep <- read.csv(file.path(root, "tables/phase18-first-wave-replicate.csv"), check.names = FALSE); man <- read.csv(file.path(root, "tables/phase18-first-wave-manifest.csv"), check.names = FALSE); cat("aggregate_rows=", nrow(agg), "\n", sep = ""); cat("replicate_rows=", nrow(rep), "\n", sep = ""); cat("manifest_rows=", nrow(man), "\n", sep = ""); cat("surfaces=", paste(sort(unique(agg[["source_surface"]])), collapse = ","), "\n", sep = ""); cat("replicates=", paste(sort(unique(rep[["replicate"]])), collapse = ","), "\n", sep = ""); cat("manifest_status=", paste(sort(unique(man[["status"]])), collapse = ","), "\n", sep = "")'
Rscript -e 'root <- "inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary/tables"; for (f in c("phase18-first-wave-aggregate.csv", "phase18-first-wave-replicate.csv", "phase18-first-wave-manifest.csv", "phase18-first-wave-failures.csv", "phase18-first-wave-wald-coverage.csv", "phase18-first-wave-profile-coverage.csv")) { x <- read.csv(file.path(root, f), check.names = FALSE); cat(f, nrow(x), "rows", ncol(x), "cols\n") }'
rg -n "Slice 889|n_rep = 2|Run Manifest Summary|Interval Coverage Summary|Aggregate Bias Overview|Warning And Error Summary|count_mu_random_effect_grid|gaussian_ls_grid|meta_v_grid|Interpretation Boundary" inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary/report/phase18-first-wave-summary.html
cat inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/parallel-summary.csv
wc -l inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary/tables/phase18-first-wave-replicate.csv inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary/tables/phase18-first-wave-manifest.csv inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary/tables/phase18-first-wave-failures.csv inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary/tables/phase18-first-wave-wald-coverage.csv inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary/tables/phase18-first-wave-profile-coverage.csv
```

Results:

- Source reads confirmed the existing May 20 after-task note and current
  simulation-programme ledger both describe Slices 889-898 as a two-replicate
  staging smoke, not a final simulation result.
- The focused first-wave summary-report, render-helper, and summary-smoke-runner
  tests completed with exit code 0.
- The saved artifact has 23 aggregate rows, 46 replicate rows, 12 manifest
  rows, 1 failure row, 19 Wald coverage rows, and 4 profile coverage rows by
  `read.csv()` row counts.
- The saved artifact covers `count_mu_random_effect_grid`, `gaussian_ls_grid`,
  and `meta_v_grid`; replicate IDs are 1 and 2.
- All manifest rows have status `ok`; the report still surfaces one count
  warning in the warning/error summary.
- `parallel-summary.csv` records `multicore` runs with requested cores of 3 and
  actual cores of 2, 3, 2, and 2.
- Rendered HTML scans found the `n_rep = 2` note, aggregate-bias,
  interval-coverage, run-manifest, warning/error, surface-name, and
  interpretation-boundary evidence.
- No files were staged or committed.

## Tests Of The Tests

The focused report tests protect the R Markdown display sections. The
summary-smoke-runner test now exercises the current expanded reusable smoke
path, so the saved `slice-889` artifact remains the direct evidence for the
older three-surface `n_rep = 2` claim.

## Consistency Audit

This is current-state revalidation, not a new implementation claim. It does not
change supported model surfaces, issue a coverage conclusion, or update
pkgdown navigation.

## GitHub Issue Maintenance

Reused the open-issue search from the preceding slice. Umbrella issue #59 covers
Phase 18 reporting; no issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

Raw `wc -l` counts are not reliable row counts for all saved CSVs because one
field in the replicate table contains embedded newlines. The report records
`read.csv()` row counts as authoritative.

## Team Learning

Rose should flag revalidation slices when older same-number slice notes already
exist. Grace should prefer parser row counts over raw line counts for CSVs that
may contain multiline condition messages.

## Known Limitations

Two replicates per cell are not enough for final bias, RMSE, coverage, or
failure-rate claims. The count warning remains visible and unresolved by this
validation-only slice.

## Next Actions

Continue with Slices 899-908 by validating the reusable private first-wave
summary smoke runner and its requested-versus-actual worker summary, if that
evidence is still present and current.
