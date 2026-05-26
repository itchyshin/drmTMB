# Phase 18 First-Wave Summary n_rep = 2 Revalidation Slices 889-898

Reader: `drmTMB` contributors checking that the first-wave summary report still
works when the saved three-surface smoke has two replicates per cell.

This is a current-state revalidation of Slices 889-898. The original May 20
after-task note recorded the saved smoke under
`inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/`. This note checks
that the same artifact is still readable and that the current report tests still
cover the relevant summary path. The saved artifact remains staging evidence;
two replicates per cell do not support final bias, RMSE, coverage, or failure
rate claims.

## Source Evidence

- `docs/design/41-phase-18-simulation-programme.md` records Slices 889-898 as a
  slightly larger three-surface first-wave staging smoke with `n_rep = 2`.
- The saved summary report displays aggregate operating characteristics,
  aggregate bias, interval coverage, run-manifest, warning/error, and
  interpretation-boundary sections.
- The saved `parallel-summary.csv` records a `multicore` backend with requested
  cores of 3 and actual cores of 2, 3, 2, and 2 across the Gaussian
  location-scale, `meta_V(V = V)`, Poisson count, and NB2 count surfaces.
- Current focused report and summary-smoke-runner tests pass. The current runner
  test now exercises the expanded reusable smoke path, so the saved slice-889
  artifact remains the direct evidence for the original three-surface claim.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 889-891 | Revalidate saved two-replicate artifact presence | File listing and CSV reads passed |
| 892-894 | Revalidate report section visibility | Saved HTML scan passed |
| 895-896 | Revalidate bounded multicore evidence | `parallel-summary.csv` read passed |
| 897-898 | Preserve staging interpretation boundary | After-task audit passed |

## Commands

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

## Result

The focused first-wave summary-report, render-helper, and summary-smoke-runner
tests completed with exit code 0. The saved two-replicate smoke has 23
aggregate rows, 46 replicate rows, 12 manifest rows, 1 failure row, 19 Wald
coverage rows, and 4 profile coverage rows. The summary covers
`count_mu_random_effect_grid`, `gaussian_ls_grid`, and `meta_v_grid`; replicate
IDs are 1 and 2; all manifest rows have status `ok`. The rendered HTML shows
`Aggregate Bias Overview`, `Interval Coverage Summary`, `Run Manifest Summary`,
`Warning And Error Summary`, the three surface names, the `n_rep = 2` note, and
the interpretation boundary. This closes the current-state revalidation only.
It does not add likelihoods, formula grammar, public API, roxygen topics,
pkgdown navigation, or formal operating-characteristic claims.
