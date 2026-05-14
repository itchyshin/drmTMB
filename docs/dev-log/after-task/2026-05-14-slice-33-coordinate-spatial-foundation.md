# After Task: Slice 33 Coordinate Spatial Foundation

## Goal

Fit the first spatial structured-effect path without overclaiming the future
mesh/SPDE model: univariate Gaussian `mu` with
`spatial(1 | site, coords = coords)`.

## Implemented

- Added `extract_gaussian_mu_spatial_term()` and
  `build_spatial_mu_structure()` for intercept-only coordinate spatial `mu`
  terms.
- Accepted coordinates with one row per spatial group or one row per
  observation, with a guard that observation-row coordinates are constant within
  group.
- Built a fixed exponential coordinate covariance from site distances, inverted
  it to a precision matrix, and reused the single structured-effect TMB prior
  backend for the first fitted spatial SD.
- Exposed R-facing outputs as `sdpars$mu["spatial(1 | site)"]`,
  `ranef(fit, "spatial_mu")`, conditional `predict()` contributions, and a
  direct `profile_targets()` row.
- Kept `spatial(1 | site, mesh = mesh)`, spatial slopes, spatial `sigma`,
  bivariate spatial q=4 blocks, spatial direct-SD models, and spatial
  `corpair()` regressions rejected as planned.
- Added a future Phase 18 roadmap entry for visualization, marginal effects,
  `emmeans`-style compatibility, and ggplot-oriented helpers.

## Mathematical Contract

For sites `l = 1, ..., L`, the first spatial path uses:

```text
mu_i = X_mu[i, ] beta_mu + s_site[i]
s ~ Normal(0, sd_spatial^2 K_coords)
K_coords[l, m] = exp(-d_lm / r)
r = median positive pairwise site distance
Q_coords = K_coords^{-1}
```

This is a small-data coordinate covariance foundation. It is not the final
SPDE/GMRF mesh route.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `R/profile.R`
- `R/formula-markers.R`
- `tests/testthat/test-spatial-gaussian.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `NEWS.md`, `README.md`, `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/source-map.Rmd`
- generated `man/spatial.Rd`, `man/ranef.Rd`, and pkgdown pages

## Checks Run

- `air format ...`: passed.
- `Rscript -e 'devtools::document()'`: passed.
- Focused spatial/grammar/profile tests: failed once for stale expectations,
  then passed after fixing test setup and mesh wording.
- Spatial smoke check: confirmed `spatial(1 | site)`, `spatial_mu`, and a
  profile-ready spatial SD target.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::build_site()'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- Stale-wording scans: only mesh-specific planned wording remains.
- `git diff --check`: passed.

## Tests Of The Tests

The new tests failed before the setup fix because `coords = coords` correctly
requires a coordinate object in the formula environment. The focused suite also
caught stale mesh-error wording after `coords` became fitted. The final tests
cover fitting, profile-target exposure, per-observation coordinate input, and
malformed within-site coordinates.

## Consistency Audit

Code, tests, NEWS, formula grammar, likelihood math, spatial design notes,
known limitations, source map, roadmap, roxygen, and pkgdown now agree that
`coords` is fitted for univariate Gaussian `mu`, while `mesh` and richer
spatial models remain planned.

## What Did Not Go Smoothly

The implementation reused the existing single structured-effect TMB parameter
names (`u_phylo`, `log_sd_phylo`) to avoid a larger C++ refactor. That is
acceptable for the first foundation slice, but Rose should keep watching it:
once phylo and spatial can coexist, the backend needs neutral structured-effect
names.

## Team Learning

- Ada: keep the slice narrow when a new structured-effect family first becomes
  fitted.
- Boole: make `coords` and `mesh` distinct in messages; users should not see
  `coords = mesh` suggestions.
- Gauss: the precision-backend reuse is efficient, but neutral TMB names will
  matter when multiple structured layers coexist.
- Noether: always state whether `K` is covariance and `Q` is precision; the
  coordinate foundation is not the SPDE contract.
- Fisher: profile readiness is available for the single spatial SD, but not
  for richer spatial fields or maps.
- Pat: show `sdpars`, `ranef("spatial_mu")`, and conditional predictions in
  docs so users know what to inspect after fitting.
- Darwin: the spatial example should eventually use a real environmental
  question and projected coordinates, not just generic `site`.
- Grace: full tests and pkgdown are required because the change touches R
  grammar, roxygen, tests, articles, and generated site pages.
- Rose: stale wording around "spatial planned" accumulates quickly; scan both
  source vignettes and generated pkgdown pages after each spatial slice.

## Known Limitations

- Coordinate covariance is dense before inversion and is a small-data
  foundation.
- Mesh/SPDE, spatial slopes, spatial scale terms, bivariate spatial covariance,
  `sd_spatial()`, and spatial `corpair()` are still planned.
- The visualization/marginal-effects roadmap phase is design-only in this
  slice.

## Next Actions

1. Add `check_drm()` diagnostics for spatial replication and weak spatial SDs.
2. Decide whether the next spatial slice should harden coordinate diagnostics
   or start the mesh/SPDE contract.
3. Keep the Phase 18 visualization plan separate from spatial implementation,
   then design it around `predict_parameters()`, `marginal_parameters()`, and
   explicit interval provenance.
