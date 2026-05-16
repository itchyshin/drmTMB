# After Task: Phase 10 Coordinate Spatial One-Slope

## Goal

Move Phase 10 beyond the intercept-only coordinate spatial path by fitting one
numeric spatial `mu` slope for univariate Gaussian models without adding an
intercept-slope correlation or claiming mesh/SPDE support.

## Implemented

- `spatial(1 + x | site, coords = coords)` now fits in univariate Gaussian
  `mu` as two independent coordinate-spatial fields sharing the same fixed
  coordinate precision.
- Public SD labels are `spatial(1 | site)` for the intercept field and
  `spatial(0 + x | site)` for the slope field.
- The TMB univariate Gaussian structured-effect branch now accepts a
  coefficient design matrix and evaluates `s0_site[i] + x_i s1_site[i]`.
- `ranef(fit, "spatial_mu")`, `sdpars$mu`, `profile_targets()`, `predict()`,
  and `check_drm()` are q-aware for the fitted coordinate-spatial slope.
- Spatial one-slope tests simulate independent intercept and slope fields from
  the same coordinate covariance, check the output names, profile-target
  indices, prediction identity, complete-case handling, and slope-variable
  validation.
- Documentation now separates the implemented coordinate-spatial one-slope path
  from planned mesh/SPDE, multiple-slope, slope-correlation, spatial `sigma`,
  bivariate spatial, and spatial `corpair()` paths.

## Mathematical Contract

For site `l` and observation `i`:

```text
mu_i = X_mu[i, ] beta_mu + s0_site[i] + x_i s1_site[i]
s0 ~ Normal(0, sd_spatial_intercept^2 K_coords)
s1 ~ Normal(0, sd_spatial_slope^2 K_coords)
Cov(s0, s1) = 0
K_coords[l, m] = exp(-d_lm / r)
```

This is an independent-field spatial slope, not a correlated intercept-slope
block. The internal TMB parameter names still reuse `u_phylo`, `log_sd_phylo`,
and `Q_phylo`; the public output uses `spatial_mu` and spatial labels.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `R/check.R`
- `R/formula-markers.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-spatial-gaussian.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `tests/testthat/test-phylo-utils.R`
- `README.md`, `NEWS.md`, `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/32-phase-6b-tutorial-source-map.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- generated `man/spatial.Rd`

## Checks Run

- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH air format ...`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::document()'`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::test(filter = "spatial-gaussian", reporter = "summary")'`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::test(filter = "gaussian-location-scale", reporter = "summary")'`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::test(filter = "phylo-utils", reporter = "summary")'`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::test(filter = "check-drm", reporter = "summary")'`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::test(filter = "profile-targets", reporter = "summary")'`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'pkgdown::build_site()'`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`: passed with 0 errors, 0 warnings, and 0 notes in 2m 26.2s.
- `git diff --check`: passed.
- `rg -n 'spatial slopes.*planned|spatial terms are planned|spatial terms.*not implemented|spatial likelihood is not implemented|coords = coords\\).*not implemented|spatial\\(1 \\+ x \\| site, coords = coords\\).*Planned|spatial random slopes should stay planned|spatial slopes should stay planned|structured slopes remain planned' README.md ROADMAP.md NEWS.md R docs/design docs/dev-log/known-limitations.md vignettes tests man pkgdown-site --glob '!pkgdown-site/search.json' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/after-phase/**' --glob '!pkgdown-site/dev-log/**'`: found only valid planned references to mesh/SPDE, multiple spatial slopes, slope correlations, or historical rendered wording.

## Tests Of The Tests

The new spatial slope test would fail under the old implementation because
`extract_gaussian_mu_spatial_term()` rejected `spatial(1 + x | site, coords =
coords)` and the TMB branch only accepted one structured field. The direct
TMB-data phylo utility test also protects the new `phylo_mu_value` data input.

## Consistency Audit

No spatial intercept-slope `corpair()` row was added. Mesh/SPDE, multiple
spatial slopes, spatial `sigma`, bivariate spatial covariance, and spatial
`corpair()` regressions remain planned in the roadmap, design docs, known
limitations, README, NEWS, and tutorials.

## What Did Not Go Smoothly

The implementation still reuses the phylogenetic-shaped internal names
`u_phylo`, `log_sd_phylo`, and `Q_phylo` for spatial fields. That was the
smallest safe extension of the existing coordinate path, but Rose should keep
the neutral structured-effect backend on the refactor list before phylo and
spatial effects can coexist in one model.

## Team Learning

- Ada: keep Phase 10 slices narrow; one fitted spatial slope is enough when the
  output and documentation are complete.
- Gauss: the prior is two independent `Q_coords` fields, not a new covariance
  or correlation parameter.
- Noether: public equations, R syntax, TMB indexing, `sdpars`, and
  `profile_targets()` now agree on the two coefficient fields.
- Curie: the CRAN-safe simulation should use one deterministic moderate dataset
  plus focused edge tests, not repeated recovery grids.
- Darwin: the slope SD answers whether the environmental effect varies among
  sites; the intercept SD answers whether baseline expected response varies
  spatially.
- Pat: expose both `ranef("spatial_mu")$terms` and `profile_targets()` because
  users need to see which SD is the intercept and which is the slope.
- Grace: generated docs and full tests are necessary because the change crosses
  R parsing, TMB data, prediction, diagnostics, and pkgdown prose.
- Rose: stale "spatial slopes planned" wording is now valid only when it says
  multiple slopes, mesh/SPDE slopes, or slope correlations remain planned.

## Known Limitations

- `spatial(1 + x | site, coords = coords)` requires a numeric finite slope
  variable.
- The coordinate covariance path remains dense before inversion and is still a
  small-data foundation.
- Mesh/SPDE, phylogenetic slopes, multiple spatial slopes, spatial slope
  correlations, spatial `sigma`, bivariate spatial covariance, and spatial
  `corpair()` regressions remain planned.
- GitHub Actions remains the PR-side gate after push.
