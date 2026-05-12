# After Task: Bivariate Group Covariance Bridge

## Goal

Start the second worktree lane on the ordinary grouped bivariate covariance
bridge, supporting future phylogenetic location-coscale work without editing
the phylogenetic implementation path.

## Implemented

- Created the branch `codex/biv-group-covariance-bridge` in a separate
  worktree at `../drmTMB-biv-group-covariance-bridge`.
- Added `group` and `block` filters to `corpairs()` so users can directly
  request fitted group-level covariance rows.
- Tightened the bivariate Gaussian `corpairs()` test for the implemented
  labelled `mu1`/`mu2` random-intercept covariance block.
- Corrected `docs/design/20-coscale-correlation-pairs.md` so implemented
  extractor examples use `level = "group"` and `class = "mean-mean"`.
- Added a `vignettes/bivariate-coscale.Rmd` snippet showing residual and
  group-level `corpairs()` calls side by side.

## Mathematical Contract

Residual `rho12` remains the row-level bivariate Gaussian residual
correlation. The labelled `mu1`/`mu2` random-intercept covariance block is a
group-level mean-mean correlation. These are separate rows in `corpairs()`, not
two names for the same correlation. The `group` and `block` filters subset
group-level rows by grouping factor and covariance-block label; residual rows
have neither field.

## Files Changed

- `R/methods.R`
- `NEWS.md`
- `man/corpairs.Rd`
- `tests/testthat/test-biv-gaussian.R`
- `vignettes/bivariate-coscale.Rmd`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-bivariate-group-covariance-bridge.md`

## Checks Run

- `air format R/methods.R tests/testthat/test-biv-gaussian.R docs/design/20-coscale-correlation-pairs.md vignettes/bivariate-coscale.Rmd NEWS.md man/corpairs.Rd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|corpairs')"`:
  passed with 180 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "pkgdown::build_article('bivariate-coscale')"`: passed.
- `rg -n "level = \"ID\"|class = \"mean-scale\"|corpairs\\(fit, level|corpairs\\(fit, class" docs/design vignettes README.md ROADMAP.md tests/testthat`:
  found only corrected implemented examples and tests.

## Tests Of The Tests

The strengthened test now checks one model that contains both residual
`rho12` and a labelled group-level `mu1`/`mu2` covariance block, then verifies
that `corpairs()` separates them under `level = "residual"`,
`level = "group"`, `group = "id"`, `block = "p"`, `class = "residual"`,
and `class = "mean-mean"`.

## Consistency Audit

The design note now matches the implemented extractor API. This branch did not
claim support for bivariate random slopes, random effects in `sigma1`,
`sigma2`, or `rho12`, phylogenetic bivariate covariance, spatial covariance,
or structured covariance blocks.

## What Did Not Go Smoothly

The first design-note example used `level = "ID"`, which confused the grouping
factor with the implemented `level` column. The correction keeps grouping
factor names in the `group` column and adds a real `group` filter.

## Team Learning

- Ada kept this lane complementary to the phylogenetic bivariate route.
- Noether kept residual and group-level correlation definitions separate.
- Rose caught an extractor-documentation drift before it hardened into user
  guidance.
- Grace kept validation focused on extractor tests and pkgdown checks because
  no likelihood code changed.

## Known Limitations

- Bivariate `sigma1`/`sigma2` random effects, bivariate random slopes,
  phylogenetic bivariate covariance, spatial covariance, and structured
  covariance remain planned.

## Next Actions

1. Design the next ordinary bivariate covariance slice before starting
   phylogenetic bivariate covariance work in this lane.
2. If this branch continues, scope bivariate `sigma1`/`sigma2` random effects
   separately from phylogenetic covariance.
