# Slice 245 NB2 Mu Random Effects

## Goal

Move ordinary non-zero-inflated NB2 `mu` random effects from planned to fitted
for the first narrow count-family slice before broader Phase 18 simulations.

## Implemented

- `drm_build_nbinom2_spec()` now parses ordinary `mu` random intercepts and
  independent numeric random slopes for non-zero-inflated `nbinom2()` models.
- The NB2 TMB data path now passes the `mu` random-effect design, latent
  indices, SD rows, and `u_mu` random vector instead of dummy random-effect
  structures.
- The model-type 7 likelihood adds `Z_mu b_mu` to the log-mean predictor and
  includes the standard normal latent-effect prior used by the Poisson path.
- `sdpars$mu`, `random_effects$mu`, and `profile_targets()` now expose the
  fitted NB2 `log_sd_mu` targets.
- Documentation, roadmap, NEWS, and the validation-debt register now distinguish
  fitted ordinary NB2 `mu` random effects from still-planned NB2 `sigma`, zero-
  inflated NB2, correlated-slope, and labelled covariance paths.

## Mathematical Contract

The fitted non-zero-inflated NB2 random-effect path is:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
log(mu_i) = offset_i + X_mu[i, ] beta_mu + Z_mu[i, ] b_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
size_i = 1 / sigma_i^2
b_mu = sd_mu * u_mu
u_mu ~ Normal(0, 1)
```

Only independent random-effect terms are admitted in this slice. Correlated
NB2 slope blocks such as `(1 + x | id)`, labelled blocks such as `(1 | p | id)`,
NB2 `sigma` random effects, and zero-inflated NB2 random effects remain closed.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-nbinom2-location-scale.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `vignettes/count-nbinom2.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`

## Checks Run

- `air format R/drmTMB.R src/drmTMB.cpp tests/testthat/test-nbinom2-location-scale.R`
- `Rscript -e "devtools::test(filter = 'nbinom2-location-scale', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'count-kernels|zi-nbinom2|hurdle-nbinom2|profile-targets|summary|check-drm', reporter = 'summary')"`
- `git diff --check`
- `Rscript -e "devtools::test(filter = 'nbinom2-location-scale|count-kernels|zi-nbinom2|hurdle-nbinom2|profile-targets|summary|check-drm|gaussian-random-intercepts', reporter = 'summary')"`

## Tests Of The Tests

The new NB2 recovery test simulates known fixed effects, overdispersion, a group
random intercept, and an independent random slope. It checks convergence,
positive fitted SDs, rough fixed-effect and SD recovery, random-effect
extraction, direct `profile_targets()` rows for both `log_sd_mu` parameters,
and prediction-scale positivity.

## Consistency Audit

This is intentionally parallel to the Poisson `mu` path, not a general
non-Gaussian random-effect framework. The zero-inflated NB2 builder still
rejects count-side random effects before fitting, and the validator rejects
correlated or labelled NB2 random-slope blocks.

## What Did Not Go Smoothly

The first implementation parsed NB2 random terms but left the model-type 7 TMB
data block on dummy random-effect fields. That made the Laplace path invalid.
The fix was to thread the same `mu_re_*` data fields that Poisson already uses
and then add the NB2 likelihood contribution on the same log-mean scale.

## Team Learning

Gauss and Noether kept the likelihood contract aligned with Poisson while
preserving the NB2 `sigma` interpretation. Curie kept the recovery test
deterministic and small. Fisher insisted on direct profile-target evidence for
both SDs. Pat and Darwin kept the user-facing boundary explicit. Grace watched
the count-kernel and summary regression tests. Rose caught stale roadmap and
tutorial wording that still called NB2 random effects planned.

## Known Limitations

This slice does not add a Phase 18 NB2 smoke runner, interval-coverage summary,
weak-SD grid, zero-truncated NB2 random effects, zero-inflated NB2 random
effects, NB2 `sigma` random effects, or correlated/labelled NB2 random-slope
blocks.

## Next Actions

Add a CRAN-safe NB2 `mu` random-effect smoke runner, then attach Wald and direct
profile interval coverage in the same staged pattern used for Poisson.
