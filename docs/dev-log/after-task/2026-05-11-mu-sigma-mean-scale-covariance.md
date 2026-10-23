# After Task: Mu Sigma Mean-Scale Covariance

## Goal

Implement the first univariate cross-formula covariance block: matching
labelled Gaussian random intercepts in `mu` and `sigma`, such as
`bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id))`, estimate one group-level
mean-scale correlation.

## Implemented

- Added R-side matching for labelled `mu` and `sigma` random intercepts with
  the same block label and grouping factor.
- Added the TMB parameter `eta_cor_mu_sigma` and the corresponding bounded
  correlation transform.
- Constructed the residual-scale random intercept as a conditional standard
  normal combination so the fitted `sigma` random intercept has the requested
  correlation with the matched `mu` random intercept.
- Exposed the fitted SDs in `sdpars$mu` and `sdpars$sigma`.
- Exposed the fitted mean-scale correlation in `corpars$mu_sigma`,
  `corpairs(class = "mean-scale")`, and `profile_targets()`.
- Added direct profile-likelihood interval coverage for `sd:mu:(1 | p | id)`,
  `sd:sigma:(1 | p | id)`, and
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)`.
- Updated tutorials and status inventories so users see this as implemented
  only for matching random intercepts, with random slopes and richer
  cross-formula blocks still planned.

## Mathematical Contract

For group `g`, the implemented model is:

```text
mu_i = X_mu[i, ] beta_mu + b_g[i]
log(sigma_i) = X_sigma[i, ] beta_sigma + a_g[i]

b_g = sd_mu * u_g
a_g = sd_sigma * (rho_mu_sigma * u_g +
      sqrt(1 - rho_mu_sigma^2) * v_g)
u_g, v_g ~ Normal(0, 1)
rho_mu_sigma = 0.999999 * tanh(eta_cor_mu_sigma)
```

This is a group-level mean-scale correlation between random intercepts. It is
not residual bivariate `rho12`, and it is not a phylogenetic, spatial, or
species-level covariance layer.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `R/methods.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-corpairs.R`
- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/04-random-effects.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/which-scale.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/source-map.Rmd`
- generated reference text in `man/corpairs.Rd`

## Checks Run

- `air format R/methods.R tests/testthat/test-gaussian-random-intercepts.R tests/testthat/test-profile-targets.R NEWS.md vignettes/location-scale.Rmd vignettes/which-scale.Rmd vignettes/formula-grammar.Rmd`:
  passed.
- `air format tests/testthat/test-corpairs.R`: passed.
- `air format docs/design/12-profile-likelihood-cis.md`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 204 expectations.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 206
  expectations.
- `Rscript -e "devtools::test(filter = 'corpairs')"`: passed with 59
  expectations.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|profile-targets|corpairs')"`:
  passed with 469 expectations.
- `Rscript -e "devtools::test()"`: passed with 1850 expectations.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/corpairs.Rd`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.

## Tests Of The Tests

The new recovery test simulates matched `mu` and `sigma` random intercepts from
the same latent normal pair and checks SD recovery, correlation sign, bounded
correlation magnitude, `profile_targets()` metadata, and positive fitted
`sigma`. The `corpairs()` test is intentionally in the extractor test file and
checks the response labels, class, parameter name, link transform,
model-frame-dropped response labels, and residual-`rho12` separation. This test
would have caught the manual probe that briefly reported `to_response = "z"`
for the `sigma` endpoint before `random_effect_response_name()` was fixed to
use the original response for univariate `sigma`.

The profile-interval test exercises the same fitted model through
`confint(method = "profile")` and checks the internal TMB parameters
`log_sd_mu`, `log_sd_sigma`, and `eta_cor_mu_sigma`, response-scale
transformations, bounded correlation intervals, and separation from residual
`rho12`.

## Consistency Audit

- `rg -n 'does not yet share covariance|cross-formula.*future|cross-formula.*planned|mu.*sigma.*planned|planned.*mu.*/sigma|mu1.*/mu2.*only|corpairs.*ordinary univariate Gaussian `mu` random-effect correlations' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man _pkgdown.yml`:
  found only intentional boundaries for random slopes, richer labelled
  covariance blocks, phylogenetic/spatial layers, and richer bivariate
  covariance.
- `rg -n 'mean-scale|mu_sigma|eta_cor_mu_sigma|cor:mu_sigma|sd:sigma:\(1 \| p \| id\)|residual `rho12`|residual rho12' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man`:
  confirmed the implemented mean-scale target names and residual-`rho12`
  separation are visible in source, tests, docs, tutorials, and generated help.
- `rg -n 'rho ~|meta_gaussian|tau ~|meta_known_V\([^V]|planned.*implemented|implemented.*planned' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man _pkgdown.yml`:
  found only intentional guardrails, planned-feature wording, and meta-analysis
  design notes.

## What Did Not Go Smoothly

One exploratory probe sourced a test file directly and tripped over an
interactive snapshot plus shell expansion of `$data`; the probe was rerun with
the simulation inline. Two early stale-wording scans used double quotes around
backticked terms, so `zsh` attempted command substitution. The final audit
commands above use single quotes.

The useful bug caught during this pass was in `corpairs()`: the first
mean-scale row used the `sigma` model frame to infer `to_response`, which
reported the first residual-scale predictor (`z`) instead of the original
response (`y`). `random_effect_response_name()` now maps univariate `mu` and
`sigma` endpoints back to the `mu` response.

## Team Learning

- Ada kept the slice narrow: matching random intercepts only.
- Boole and Noether kept the syntax, equations, and TMB parameter names aligned.
- Gauss checked the bounded correlation transform and conditional-normal
  construction.
- Curie added recovery, extractor, and profile-interval tests rather than
  relying on one happy-path fit.
- Pat and Darwin pushed the tutorials toward the user question: do higher-mean
  groups also have higher or lower residual SD?
- Rose caught stale future-only wording and the response-label mismatch.
- Grace verified tests, roxygen, pkgdown, and package check.
- Emmy kept the extractor output under `corpars$mu_sigma` and `corpairs()`
  without inventing a new public API.

## Known Limitations

- Only matching labelled random intercepts are implemented for univariate
  `mu`/`sigma` covariance.
- Random slopes, full four-effect double-hierarchical blocks, bivariate
  residual-scale random effects, and structured phylogenetic/spatial covariance
  layers remain planned.
- The tests check recovery and profile-interval plumbing for moderate simulated
  data, not long-run coverage of the profile intervals.

## Next Actions

1. Add the four-effect univariate block only after a separate design and
   simulation pass.
2. Keep `corpairs()` as the visible reporting surface for each newly fitted
   correlation layer.
3. Add applied tutorial examples only when the examples can stay short enough
   for a new applied user to run and interpret.
