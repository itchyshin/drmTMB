# After Task: Gaussian Sigma Random Slopes

## Goal

Implement the next small double-hierarchical prerequisite: ordinary unlabelled
Gaussian residual-scale random slopes in the `sigma` formula, without claiming
the full labelled `mu`/`sigma` four-effect covariance block.

## Implemented

- Added unlabelled `sigma` random slopes such as `sigma ~ z + (0 + z | id)`.
- Added unlabelled ordinary residual-scale intercept-slope covariance blocks
  such as `sigma ~ z + (1 + z | id)`.
- Added the TMB parameter `eta_cor_sigma` with the same guarded
  `0.999999 * tanh()` response-scale transform used by ordinary `mu`
  random-effect correlations.
- Exposed residual-scale random-slope SDs in `sdpars$sigma`, correlations in
  `corpars$sigma`, and scale-slope rows in `corpairs(class = "scale-slope")`.
- Kept labelled residual-scale random slopes rejected with a direct error,
  because labelled cross-formula random-slope covariance still needs its own
  positive-definite covariance contract.

## Mathematical Contract

For a Gaussian residual-scale block,

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
log(sigma_i) = X_sigma[i, ] beta_sigma + a_0,g[i] + z_i a_1,g[i]

a_0,g = sd_sigma0 * v_0,g
a_1,g = sd_sigma1 * (rho_sigma * v_0,g +
        sqrt(1 - rho_sigma^2) * v_1,g)
rho_sigma = 0.999999 * tanh(eta_cor_sigma)
v_g ~ Normal([0, 0]', I)
```

The public R syntax is:

```r
bf(y ~ x, sigma ~ z + (1 + z | id))
```

This is a group-level residual-scale correlation. It is not residual `rho12`
and not an `sd(id) ~ x_group` random-effect scale model.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `R/methods.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-corpairs.R`
- `tests/testthat/test-phylo-utils.R`
- `NEWS.md`, `README.md`, `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/04-random-effects.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/design/13-gaussian-location-scale-math.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/source-map.Rmd`
- `vignettes/which-scale.Rmd`
- generated `man/drmTMB.Rd` and `man/corpairs.Rd`

## Checks Run

- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 240 expectations.
- `Rscript -e "devtools::test(filter = 'corpairs|profile-targets')"`:
  passed with 282 expectations.
- `air format R/drmTMB.R R/methods.R src/drmTMB.cpp tests/testthat/test-gaussian-random-intercepts.R tests/testthat/test-corpairs.R tests/testthat/test-phylo-utils.R NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/04-random-effects.md docs/design/12-profile-likelihood-cis.md docs/design/13-gaussian-location-scale-math.md docs/design/16-phylo-spatial-common-math.md docs/design/17-correlated-random-effect-blocks.md docs/design/18-random-effect-scale-models.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/drmTMB.Rmd vignettes/formula-grammar.Rmd vignettes/location-scale.Rmd vignettes/source-map.Rmd vignettes/which-scale.Rmd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/drmTMB.Rd` and `man/corpairs.Rd`.
- `Rscript -e "devtools::test()"`: passed with 1903 expectations.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `rg -n 'Only random intercepts|residual-scale random slopes are planned|residual-scale random slopes in sigma|sigma random intercepts only|random intercepts in residual scale|residual-scale covariance.*planned|corpairs.*ordinary univariate Gaussian mu random-effect correlations|eta_cor_sigma|scale-slope|corpars\$sigma' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man pkgdown-site`:
  found the intended new `eta_cor_sigma`, `scale-slope`, and `corpars$sigma`
  references plus unrelated existing malformed-input checks.
- `rg -n 'rho ~|meta_gaussian|tau ~|meta_known_V\([^V]|planned.*implemented|implemented.*planned' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man pkgdown-site _pkgdown.yml`:
  found only intentional guardrails, planned-feature wording, and generated
  pkgdown copies.

## Tests Of The Tests

The new deterministic simulations check:

- independent residual-scale random slopes recover a positive finite
  `sdpars$sigma` slope term;
- correlated residual-scale intercept-slope blocks recover finite SDs and the
  sign of the simulated scale-slope correlation;
- `corpairs()` returns a `scale-slope` row with response label `y`;
- `profile_targets()` maps `cor:sigma:cor((Intercept),z | id)` to
  `eta_cor_sigma`;
- labelled residual-scale random slopes fail clearly instead of silently using
  the new unlabelled path.

## Consistency Audit

README, NEWS, roadmap, formula grammar, likelihood math, random-effects docs,
correlation-pair docs, known limitations, and user tutorials now say the same
thing: ordinary unlabelled `sigma` random slopes are implemented, while
labelled cross-formula `mu`/`sigma` random slopes, bivariate residual-scale
random effects, and structured covariance layers remain planned.

## What Did Not Go Smoothly

The work resumed after context compaction, so the first step was to verify
partial edits rather than trust memory. An early broad patch attempt for
`eta_cor_sigma` did not apply before compaction; the final implementation was
done with smaller, checked patches. One stale-wording scan also needed cleaner
quoting because shell backticks in a pattern tried to execute `sigma`.

## Team Learning

- Ada kept the stage small: ordinary unlabelled `sigma` slopes, not the full
  four-effect labelled covariance block.
- Gauss and Noether kept the correlation transform parallel to `mu`:
  standardized latent effects, positive SDs on log scales, and bounded
  correlations through `tanh()`.
- Pat and Darwin needed the docs to say what biological question the model
  answers: group-to-group differences in residual variability and in how a
  predictor changes residual variability.
- Rose found the main risk: stale "sigma random intercepts only" wording after
  the code moved forward.

## Known Limitations

- Labelled residual-scale random slopes such as
  `sigma ~ z + (1 + z | p | id)` remain planned.
- The full univariate labelled four-effect block
  `bf(y ~ x + (1 + x | p | id), sigma ~ z + (1 + z | p | id))` remains
  planned.
- Bivariate `sigma1`/`sigma2` random effects and structured phylogenetic or
  spatial residual-scale covariance remain planned.
- Routine tests check deterministic recovery and plumbing, not a long
  simulation study of profile-interval coverage for `eta_cor_sigma`.

## Next Actions

1. Add the labelled univariate four-effect block only after the covariance
   parameterization and extractor rows are designed explicitly.
2. Add diagnostics for weak residual-scale random slopes, especially when the
   slope SD approaches zero and `rho_sigma` becomes weakly identified.
3. Consider a small comparator or independent likelihood check for
   intercept-only and intercept-slope residual-scale blocks if a suitable
   external overlap becomes available.
