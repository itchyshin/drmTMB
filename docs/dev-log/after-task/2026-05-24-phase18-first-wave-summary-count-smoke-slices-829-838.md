# After Task: Phase 18 First-Wave Summary Count Smoke Slices 829-838

## Goal

Validate and document the first-wave rendered summary smoke that adds paired
Poisson/NB2 `mu` random-effect grid outputs beside Gaussian location-scale and
`meta_V(V = V)` surfaces.

## Implemented

Added `docs/design/101-phase-18-first-wave-summary-count-smoke-slices-829-838.md`
to record source, test, and saved-artifact evidence for the count `mu`
random-effect first-wave summary smoke. No likelihood, formula grammar, public
API, roxygen topic, pkgdown navigation, package site output, or formal
statistical claim changed.

## Mathematical Contract

No model changed. The checked contract is smoke-scale report integration for
already-supported Poisson and NB2 location (`mu`) random effects. The slice does
not make claims about random effects in shape, zero-inflation, hurdle,
one-inflation, conditional-one-inflation, or mixed-response bivariate
non-Gaussian submodels.

## Files Changed

- `docs/design/101-phase-18-first-wave-summary-count-smoke-slices-829-838.md`
- `docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-count-smoke-slices-829-838.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
nl -ba inst/sim/run/sim_write_count_mu_random_effect_grid.R | sed -n '1,140p'
nl -ba tests/testthat/test-phase18-count-mu-random-effect-grid-writer.R | sed -n '1,120p'
Rscript -e "devtools::test(filter = 'phase18-(count-mu-random-effect-grid-writer|first-wave-summary-smoke-runner|first-wave-table-bundle|first-wave-summary-render-helper|first-wave-summary-report)', reporter = 'summary')"
Rscript -e 'p <- "inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv"; x <- read.csv(p, check.names = FALSE); cat("rows=", nrow(x), "\n", sep = ""); cat("surfaces=", paste(sort(unique(x[["source_surface"]])), collapse = ","), "\n", sep = ""); cat("first_cols=", paste(names(x)[seq_len(min(5L, ncol(x)))], collapse = ","), "\n", sep = "")'
rg -n "Slice 829|count_mu_random_effect_grid|gaussian_ls_grid|meta_v_grid|profile|Aggregate Operating Characteristics|Interpretation Boundary" inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv inst/sim/results/slice-829-first-wave-summary-count-smoke/first-wave-summary/tables/phase18-first-wave-profile-coverage.csv
```

Results:

- Source reads confirmed the count grid writer creates aggregate, replicate,
  manifest, failure, Wald, and profile artifacts for paired Poisson/NB2 `mu`
  random-effect surfaces.
- The focused count grid-writer, first-wave smoke-runner, table-bundle,
  render-helper, and summary-report tests completed with exit code 0.
- The saved `slice-829` aggregate table has 23 rows and three source surfaces:
  `count_mu_random_effect_grid`, `gaussian_ls_grid`, and `meta_v_grid`.
- The aggregate table begins with `source_surface`, `source_artifact`,
  `surface`, `cell_id`, and `parameter`.
- The saved artifact-status CSV has 4 lines, the aggregate CSV has 24 lines,
  and the profile-coverage CSV has 5 lines including headers.
- Rendered HTML scans found `Slice 829`, `count_mu_random_effect_grid`,
  `gaussian_ls_grid`, `meta_v_grid`, profile evidence, aggregate operating
  characteristics, and the interpretation boundary.
- No files were staged or committed.

## Tests Of The Tests

The count grid-writer test checks both Poisson and NB2 surfaces, serial fallback
metadata when 10 cores are requested under a serial backend, output file
existence, aggregate and interval row counts, overwrite protection, and
malformed `output_dir`/`overwrite` inputs. The first-wave report tests protect
the downstream rendered report and combined table contracts.

## Consistency Audit

This report validates first-wave summary integration only. It does not expand
NB2 sigma phylogeny, zero-inflated NB2 phylogeny, q4 count covariance, broad NB2
structured parity, formula grammar, likelihood code, or user-facing API.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

One artifact-summary command initially used unescaped `$` inside shell double
quotes. I reran the read with single-quoted R code and recorded the corrected
surface list.

## Team Learning

For shell-embedded R checks that access data-frame columns, prefer `x[["col"]]`
inside single-quoted R code. It avoids accidental shell interpolation and keeps
check-log evidence reproducible.

## Known Limitations

The saved `slice-829` smoke uses one replicate and is not a formal simulation
grid. It validates report integration for existing count `mu` random-effect
surfaces only.

## Next Actions

Continue with Slices 839-848 by validating first-wave summary table display
polish if the current dirty tree contains matching evidence.
