# Phase 18 First-Wave Summary Count Smoke Slices 829-838

Reader: `drmTMB` contributors checking whether the first-wave report can carry
continuous, known-variance meta-analysis, and count mixed-model surfaces in one
rendered smoke artifact.

Slices 829-838 validate the first-wave count `mu` random-effect summary smoke.
The saved `inst/sim/results/slice-829-first-wave-summary-count-smoke/` artifact
combines Gaussian location-scale, `meta_V(V = V)`, and paired Poisson/NB2 `mu`
random-effect grid outputs. This is the first saved rendered first-wave smoke
that includes non-Gaussian location random effects. It remains a one-replicate
smoke, not a formal operating-characteristic grid.

## Source Evidence

- `phase18_write_count_mu_re_grid_outputs()` writes paired Poisson and NB2
  `mu` random-effect aggregate, replicate, manifest, failure, Wald-interval,
  Wald-coverage, profile-interval, and profile-coverage CSV artifacts.
- The count grid writer records the surface as `count_mu_random_effect_grid`
  and exposes an artifact manifest.
- The focused count grid-writer test checks Poisson and NB2 surfaces, serial
  fallback metadata under a requested 10-core run, output file existence,
  aggregate/replicate/manifest row counts, interval row counts, overwrite
  protection, and malformed `output_dir`/`overwrite` inputs.
- The saved `slice-829` rendered HTML contains `count_mu_random_effect_grid`,
  `gaussian_ls_grid`, `meta_v_grid`, aggregate operating-characteristic rows,
  profile evidence, and the interpretation boundary.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 829-831 | Validate paired Poisson/NB2 `mu` random-effect grid artifacts | Count grid-writer source and tests passed |
| 832-834 | Validate first-wave report integration beside Gaussian and meta surfaces | Saved HTML and aggregate CSV passed |
| 835-836 | Validate profile artifact propagation for count `mu` random effects | Saved profile-coverage CSV passed |
| 837-838 | Preserve smoke-scale interpretation boundaries | Report scan and after-task audit passed |

## Commands

```sh
nl -ba inst/sim/run/sim_write_count_mu_random_effect_grid.R | sed -n '1,140p'
nl -ba tests/testthat/test-phase18-count-mu-random-effect-grid-writer.R | sed -n '1,120p'
Rscript -e "devtools::test(filter = 'phase18-(count-mu-random-effect-grid-writer|first-wave-summary-smoke-runner|first-wave-table-bundle|first-wave-summary-render-helper|first-wave-summary-report)', reporter = 'summary')"
Rscript -e 'p <- "inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv"; x <- read.csv(p, check.names = FALSE); cat("rows=", nrow(x), "\n", sep = ""); cat("surfaces=", paste(sort(unique(x[["source_surface"]])), collapse = ","), "\n", sep = ""); cat("first_cols=", paste(names(x)[seq_len(min(5L, ncol(x)))], collapse = ","), "\n", sep = "")'
rg -n "Slice 829|count_mu_random_effect_grid|gaussian_ls_grid|meta_v_grid|profile|Aggregate Operating Characteristics|Interpretation Boundary" inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/tables/phase18-first-wave-profile-coverage.csv
```

## Result

The focused count grid-writer, first-wave smoke-runner, table-bundle,
render-helper, and summary-report tests completed with exit code 0. The saved
`slice-829` aggregate table has 23 rows and three source surfaces:
`count_mu_random_effect_grid`, `gaussian_ls_grid`, and `meta_v_grid`. The saved
artifact-status CSV has 4 lines, the aggregate CSV has 24 lines, and the
profile-coverage CSV has 5 lines including headers. This closes Slices 829-838
as count `mu` random-effect report-smoke validation. It does not add or expand
likelihoods, formula grammar, random effects in shape/zi/hu/zoi/coi submodels,
mixed-response non-Gaussian bivariate models, roxygen topics, pkgdown
navigation, public API, or formal statistical claims.
