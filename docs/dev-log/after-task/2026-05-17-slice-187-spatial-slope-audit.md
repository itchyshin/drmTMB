# After Task: Slice 187 Spatial Slope Audit

## Goal

Confirm spatial one-slope support, docs, diagnostics, and parity boundaries.

## Implemented

The coordinate-spatial one-slope test now profiles the slope-field SD target
`sd:mu:spatial(0 + x | site)`, confirming that it is a direct
`log_sd_phylo` profile target with bounded positive response-scale limits. A
new boundary test keeps the fitted spatial one-slope path limited to
univariate Gaussian `mu`, with multiple spatial slopes, spatial scale terms,
and bivariate spatial syntax still rejected before fitting.

## Mathematical Contract

The fitted spatial one-slope path is:

```text
mu_i = X_i beta + z_0(site_i) + x_i z_1(site_i)
z_0, z_1 ~ independent structured spatial fields
```

Slice 187 confirms direct interval support for `sd(z_1)`. It does not estimate
`cor(z_0, z_1)`, add a second slope field, move spatial terms into `sigma`, or
fit bivariate spatial covariance blocks.

## Files Changed

- `tests/testthat/test-spatial-gaussian.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-187-spatial-slope-audit.md`

## Checks Run

- `air format tests/testthat/test-spatial-gaussian.R NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/16-phylo-spatial-common-math.md docs/design/33-phase-6c-core-random-effects.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "spatial-gaussian|gaussian-location-scale", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The added interval check profiles the second spatial SD target rather than
only listing it in `profile_targets()`. The boundary test exercises multiple
spatial slopes, spatial syntax in `sigma`, and bivariate spatial syntax.

## Consistency Audit

The roadmap and structured-effect design notes now state that the fitted
coordinate-spatial path has direct slope-SD interval coverage, while mesh/SPDE,
multiple slopes, spatial scale effects, bivariate spatial covariance, and
slope correlations remain planned.

## What Did Not Go Smoothly

The spatial path already had strong tests for fitted values, `ranef()`,
`sdpars`, `profile_targets()`, and `check_drm()`. The missing piece was a real
profile interval for the slope-field SD and a compact test that kept the
one-slope support from spilling into neighbouring surfaces.

## Team Learning

Ada treated Slice 187 as confirmation rather than feature expansion. Fisher
asked for an actual interval check. Curie kept the profile fixture small
enough for routine tests. Noether kept the model equation independent of
intercept-slope correlation. Pat wanted the unsupported neighbours named
plainly. Grace watched the test runtime and pkgdown boundary. Rose recorded
the fitted-versus-planned line for the pre-simulation gate.

## Known Limitations

This slice does not add mesh/SPDE spatial fields, multiple spatial slopes,
spatial slope correlations, spatial terms in `sigma`, bivariate spatial
covariance, or spatial `corpair()` models.

## Next Actions

Slice 188 should publish the one-slope-per-layer status table and remaining
Gaussian double-hierarchical limits before closing the Gaussian random-effect
gate.
