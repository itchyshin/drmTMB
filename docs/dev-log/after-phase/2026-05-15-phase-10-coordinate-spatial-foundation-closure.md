# After Phase: Phase 10 Coordinate-Spatial Foundation Closure

Date: 2026-05-15

## Goal

Close the local Phase 10 coordinate-spatial foundation without claiming that the
full spatial programme is complete. The closed surface is one-response
Gaussian `mu` with a coordinate-based spatial intercept and one numeric
coordinate-based spatial slope.

## Implemented

- `spatial(1 | site, coords = coords)` fits a coordinate-spatial random
  intercept in univariate Gaussian `mu`.
- `spatial(1 + x | site, coords = coords)` fits independent intercept and
  slope spatial fields that share the fixed coordinate precision and have
  separate SDs.
- Public output labels the fields as `spatial(1 | site)` and
  `spatial(0 + x | site)` inside the `spatial_mu` block.
- `sdpars$mu`, `ranef(fit, "spatial_mu")`, `profile_targets()`,
  `check_drm()`, prediction, and complete-case handling recognize the fitted
  coordinate-spatial one-slope path.
- The structured-dependence tutorial, model map, formula grammar, source map,
  README, ROADMAP, and validation-debt register separate the implemented
  coordinate path from planned mesh/SPDE and richer spatial covariance paths.

## Scope Boundary

Phase 10 is not fully complete as a spatial research programme. The local
closure only covers the coordinate-spatial foundation. Mesh/SPDE,
multiple spatial slopes, spatial intercept-slope correlations, spatial
`sigma`, bivariate spatial covariance, spatial direct-SD models, and spatial
`corpair()` regressions remain planned until each has likelihood code, recovery
tests, diagnostics, documentation, provenance notes where needed, and its own
after-task evidence.

## Mathematical Contract

For observation `i` at site `l`:

```text
mu_i = X_mu[i, ] beta_mu + s0_l + x_i s1_l
s0 ~ Normal(0, sd_spatial_intercept^2 K_coords)
s1 ~ Normal(0, sd_spatial_slope^2 K_coords)
Cov(s0, s1) = 0
K_coords[l, m] = exp(-d_lm / r)
```

This is an independent-field coordinate model. It is not a mesh/SPDE model, and
it does not estimate a spatial intercept-slope correlation.

## Standing Review Closure

- Ada: close the coordinate foundation and leave the broader spatial roadmap
  visible.
- Gauss: the fitted prior is two independent coordinate precision fields, not a
  new cross-field covariance.
- Noether: equations, syntax, TMB indexing, `sdpars`, `ranef()`, and
  `profile_targets()` agree on the two fitted fields.
- Darwin: the intercept SD and slope SD answer different biological questions:
  baseline spatial heterogeneity versus spatial variation in the environmental
  slope.
- Pat: applied users can find the model in the structured-dependence tutorial
  and can read the fitted SD labels directly.
- Jason: mesh/SPDE remains a separate design/provenance lane.
- Curie: `tests/testthat/test-spatial-gaussian.R` covers the fitted path,
  slope validation, complete-case handling, output labels, and prediction.
- Grace: pkgdown and package checks remain the local gate; GitHub Actions is
  the PR-side gate.
- Rose: stale "spatial slopes planned" wording is valid only when it means
  mesh/SPDE slopes, multiple slopes, slope correlations, or other unfitted
  spatial extensions.

## Files Changed In Gate Slice

- `ROADMAP.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-phase/2026-05-15-phase-10-coordinate-spatial-foundation-closure.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format ROADMAP.md docs/design/16-phylo-spatial-common-math.md docs/design/34-validation-debt-register.md docs/dev-log/check-log.md docs/dev-log/after-phase/2026-05-15-phase-10-coordinate-spatial-foundation-closure.md`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "spatial-gaussian|check-drm|profile-targets|phylo-utils", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`
- `git diff --check`
- Source and rendered scans for Phase 10 coordinate-spatial closure wording and
  stale overclaims about mesh/SPDE or richer spatial support.

All tests and checks passed. `pkgdown::check_pkgdown()` found no problems.
`devtools::check()` passed with 0 errors, 0 warnings, and 0 notes in 2m 17.5s.

## Tests Of The Tests

The `spatial-gaussian` tests are the behavioral guard for this closure. They
exercise fitted coordinate intercepts, one numeric coordinate slope, slope
variable validation, complete-case handling, prediction identity, output term
labels, `sdpars$mu`, `ranef("spatial_mu")`, `profile_targets()`, and
`check_drm()` exposure.

## Consistency Audit

The source and rendered ROADMAP now state that the coordinate-spatial
foundation is locally closed while mesh/SPDE and richer spatial covariance
remain planned. The validation-debt register points to this after-phase report.
The common phylogenetic/spatial math note now says the coordinate-spatial
foundation is fitted and reserves mesh/SPDE, multiple slopes, slope
correlations, spatial scale, and bivariate spatial paths as planned work.
The stale-claim scan found no current source or rendered claim that mesh/SPDE,
multiple spatial slopes, spatial slope correlations, spatial `sigma`,
bivariate spatial covariance, or spatial `corpair()` are implemented.

## What Did Not Go Smoothly

The main risk was wording drift. The package now fits one coordinate-spatial
slope, so old "spatial slopes planned" language is only acceptable when it
clearly names multiple slopes, mesh/SPDE slopes, or slope correlations.

## Known Limitations

- The fitted coordinate-spatial path is univariate Gaussian `mu` only.
- The coordinate covariance path is a dense small-data foundation.
- Only one numeric spatial slope is fitted.
- No spatial intercept-slope correlation is estimated.
- Mesh/SPDE, spatial scale terms, bivariate spatial covariance, spatial
  direct-SD models, and spatial `corpair()` regressions remain planned.
- GitHub Actions remains the PR-side gate.

## Next Actions

1. Move to Phase 11, Phase 12, or Phase 13 only with this coordinate-spatial
   boundary intact.
2. Treat mesh/SPDE as a separate implementation/provenance slice.
3. Keep spatial and phylogenetic correlation layers separate from residual
   `rho12` in future bivariate work.
