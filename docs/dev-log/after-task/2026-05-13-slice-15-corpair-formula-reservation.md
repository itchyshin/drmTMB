# After Task: Slice 15 corpair Formula Reservation

## Goal

Reserve the singular `corpair()` formula syntax for future predictor-dependent
latent random-effect correlations without fitting that model family yet.

## Implemented

`drm_formula()` now parses formulas such as:

```r
bf(corpair(id, block = "p", class = "location-scale") ~ w)
```

The parsed entry records the group, optional covariance-block label, and
optional latent correlation class. `drmTMB()` rejects the entry before building
a likelihood, with an error that tells users to use `rho12 = ~ w` for residual
within-observation correlation and `corpairs(fit)` for fitted constant latent
correlations.

## Mathematical Contract

No likelihood changed. The reserved syntax names a future model for predictors
on latent random-effect correlations, not residual `rho12`. Supported planned
classes are `location-location`, `location-scale`, and `scale-scale`.

## Files Changed

- `R/parse-formula.R`
- `R/drmTMB.R`
- `R/formula-markers.R`
- `tests/testthat/test-package-skeleton.R`
- `NAMESPACE`
- `man/corpair.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::test(filter = "package-skeleton|biv-gaussian", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

The package-skeleton tests cover successful parsing, marker no-op behaviour,
invalid non-string options, invalid latent class names, named-formula misuse,
and the `drmTMB()` deferred-fit error. The bivariate Gaussian filter was rerun
beside the parser test to make sure the new top-level rejection did not disturb
ordinary bivariate fits.

## Consistency Audit

Updated formula grammar, the correlation-pair design note, known limitations,
NEWS, roxygen documentation, and `_pkgdown.yml`. The docs explicitly keep
`corpair()` separate from residual `rho12` and from the `corpairs()` extractor.

## What Did Not Go Smoothly

No modelling blocker. The main design choice was to parse `corpair()` in
`drm_formula()` but stop in `drmTMB()`, matching the existing pattern for
reserved syntax that needs a stable likelihood before fitting.

## Team Learning

The singular/plural naming split is useful: `corpair()` is a future formula
target, while `corpairs()` remains the fitted-summary extractor.

## Known Limitations

No predictor-dependent latent random-effect correlation is fitted. Phylogenetic
and spatial `corpair()` targets remain design-only until their constant
structured covariance blocks, diagnostics, and recovery tests are stable.

## Next Actions

Choose the next slice between q4 diagnostics, q4 profile-target hardening, or
Family B `sd_phylo()` design/implementation scaffolding.
