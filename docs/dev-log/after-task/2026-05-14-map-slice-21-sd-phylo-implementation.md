# After Task: Map Slice 21 sd_phylo Implementation

## Goal

Implement univariate Family B `sd_phylo(species) ~ x_species` for Gaussian
phylogenetic location models, while keeping bivariate `sd_phylo1()` /
`sd_phylo2()` and spatial direct-SD models planned.

## Implemented

`drmTMB()` now fits:

```r
drm_formula(
  y ~ x + phylo(1 | species, tree = tree),
  sigma ~ w,
  sd_phylo(species) ~ z_species
)
```

The fitted SD surface is available through `coef(fit, "sd_phylo(species)")`,
`predict(fit, dpar = "sd_phylo(species)")`, `fit$sdpars`, `summary()`, and
`profile_targets()`. The bivariate direct-SD names remain planned and still
reject before fitting.

## Mathematical Contract

The implementation follows the Slice 20 contract:

```text
v_aug ~ MVN(0, A_aug)
tau_l = exp(W_l alpha_phylo)
a_l = tau_l v_tip,l
Cov(a_tip) = D_tip A_tip D_tip
```

The TMB branch uses `u_phylo` as the unit tree effect when an `sd_phylo()`
formula is present, maps out the scalar `log_sd_phylo`, and multiplies observed
tip contributions by the fitted species-level SD. Internal nodes remain
computational coordinates of the unit tree effect; they do not receive
user-facing SD predictors.

## Files Changed

- `R/parse-formula.R`
- `R/drmTMB.R`
- `R/methods.R`
- `R/profile.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-phylo-gaussian.R`
- `tests/testthat/test-phylo-utils.R`
- `tests/testthat/test-biv-gaussian.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/phylogenetic-spatial.Rmd`
- `man/drmTMB.Rd`
- `man/fixef.Rd`
- `pkgdown-site/articles/phylogenetic-spatial.html`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-14-map-slice-21-sd-phylo-implementation.md`

## Checks Run

- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `Rscript -e 'devtools::document()'`: passed and updated `man/drmTMB.Rd` and
  `man/fixef.Rd`.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|biv-gaussian|package-skeleton|profile-targets|summary", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(filter = "beta-binomial|beta-location-scale|phylo-gaussian|biv-gaussian|profile-targets", reporter = "summary")'`:
  passed after fixing the non-Gaussian coefficient-splitter guard.
- `Rscript -e 'devtools::test(filter = "phylo-utils|phylo-gaussian", reporter = "summary")'`:
  passed after adding the new dummy TMB data fields to direct phylo-prior
  probes.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE)'`:
  passed and refreshed the local article.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'sd_phylo\(species\).*Planned|sd_phylo\(species\).*remain planned|Fitting, recovery tests, and reporting for this syntax remain planned|tip/internal-node.*remain planned|sd_phylo\(species\).*not implemented|sd_phylo1\(.*Implemented|sd_phylo2\(.*Implemented' README.md ROADMAP.md docs vignettes man pkgdown-site/articles/phylogenetic-spatial.html`:
  no hits.
- `git diff --check`: passed.

## Tests Of The Tests

The intercept-only `sd_phylo(species) ~ 1` test compares the optimized
log-likelihood and fitted log-SD against the existing scalar `log_sd_phylo`
model on the same data. The predictor-dependent recovery test simulates
species-level SDs from `tau_l = exp(alpha_0 + alpha_1 z_l)` and checks the
fitted SD surface tracks the simulated `tau_l`. The bivariate negative test
keeps `sd_phylo1()` / `sd_phylo2()` outside the implemented surface.

## Consistency Audit

Formula grammar, likelihood notes, phylogenetic math, random-effect scale
design, known limitations, NEWS, roadmap, roxygen documentation, and the
phylogenetic-spatial article now agree: univariate `sd_phylo()` is implemented;
bivariate and spatial direct-SD variants remain planned.

## What Did Not Go Smoothly

The first full test run exposed a shared-extractor mistake: non-Gaussian specs
do not have `random_scale$phylo`, so `split_tmb_coef()` needed an explicit
guard. The hidden phylo-prior TMB probes also needed dummy `X_sd_phylo`,
`has_sd_phylo_model`, `sd_phylo_beta_offset`, and `phylo_mu_sd_row` fields
because they call `MakeADFun()` directly rather than using `make_tmb_data()`.

## Team Learning

- Ada: after adding a fitted dpar-like surface, always run the full suite
  because shared extractors reach every family.
- Boole: `sd_phylo()` is now a real univariate grammar target; bivariate names
  should stay explicitly planned until response-specific code exists.
- Gauss: non-centred scaling avoided parameter-dependent sparse precision
  algebra and kept the scalar-SD equivalence exact.
- Noether: the `sd_phylo() ~ 1` equivalence test is the cleanest invariant for
  this reparameterization.
- Curie: direct TMB probe tests need dummy fields whenever the template's data
  signature changes.
- Fisher: profile-ready rows are the fixed `beta_sd_mu` coefficients; fitted
  species SDs are derived group-scale targets.
- Darwin and Pat: user-facing examples should say species-level predictors
  model among-species phylogenetic effect SDs, not residual `sigma`.
- Grace: full tests and pkgdown checks passed after two narrow guard fixes.
- Rose: stale status scans must include generated pkgdown pages when a vignette
  status table changes.

## Known Limitations

`sd_phylo()` is univariate Gaussian only. It targets location phylogenetic
random-effect SDs and does not model residual `sigma`, q=4 Family A endpoint
SDs, bivariate response-specific SDs, random slopes, or spatial fields.

## Next Actions

1. Commit and push Slice 21.
2. Move to Slice 22 recovery/docs hardening for `sd_phylo()` if the PR checks
   are green.
