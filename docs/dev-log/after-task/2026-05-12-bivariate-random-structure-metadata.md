# After Task: Bivariate Random-Structure Metadata Parity

## Goal

Make the internal bivariate `mu1`/`mu2` random-effect structure carry the same
metadata fields as the bivariate `sigma1`/`sigma2` structure.

## Implemented

`build_biv_mu_random_structure()` now returns `coef_names`, `group_names`, and
`covariance_labels`. The combined bivariate covariance regression asserts those
fields for both `mu` and `sigma` random-effect structures.

## Mathematical Contract

This slice does not change the likelihood. It keeps the internal description of
the fitted mean-mean and scale-scale random-intercept blocks aligned: each block
records its coefficient name, grouping variable, and covariance label alongside
the labels already used for `corpairs()` and `profile_targets()`.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-biv-gaussian.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-bivariate-random-structure-metadata.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with
  235 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 2014 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

The new assertions are on the fitted object produced by the combined
`mu1`/`mu2` plus `sigma1`/`sigma2` bivariate regression. They would fail if the
metadata fields were removed, renamed, or populated with the wrong group or
block label.

## Consistency Audit

This is an internal metadata parity patch. No user-facing formula syntax,
likelihood equations, or documentation claims changed. The check-log records
the implemented claim and validation evidence.

## What Did Not Go Smoothly

Nothing operationally failed. The asymmetry was a small internal inconsistency
that became visible while preparing for larger cross-parameter covariance
blocks.

## Team Learning

Emmy's architecture lens is useful between feature slices: aligning object
metadata before adding larger covariance surfaces should reduce future special
cases.

## Known Limitations

The patch does not add new covariance parameters. Cross-parameter bivariate
covariance, bivariate random slopes, structured phylogenetic covariance, and
random effects in `rho12` remain planned.

## Next Actions

Use these metadata fields when designing the first true cross-parameter
bivariate covariance block or when adding source-map diagnostics for fitted
random-effect structures.
