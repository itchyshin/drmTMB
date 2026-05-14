# After Task: Map Slice 24 Bivariate sd_phylo Implementation

## Goal

Implement the fitted Family B bivariate phylogenetic direct-SD path without
mixing it with q=4 phylogenetic location-scale covariance or residual
`rho12`.

## Implemented

- Added fitted bivariate syntax
  `sd_phylo1(species) ~ z_species` and
  `sd_phylo2(species) ~ z_species` for matching `mu1` and `mu2`
  phylogenetic location effects.
- Generalized the direct phylogenetic SD structure so one or both response
  endpoints can replace their scalar phylogenetic SD with a species-level
  surface.
- Added TMB data, start/map plumbing, likelihood scaling, reports, coefficient
  splitting, `predict()`, `sdpars`, random-effect transforms, `summary()`, and
  `profile_targets()` support.
- Kept `rho12` residual-only and the latent phylogenetic `mu1`/`mu2`
  correlation constant.
- Kept q=4 Family A and direct-SD Family B separated by a pre-optimization
  error.

## Mathematical Contract

For matching bivariate phylogenetic location effects:

```text
mu1_i = X1_i beta1 + a1_species[i]
mu2_i = X2_i beta2 + a2_species[i]
tau1_l = exp(W1_l alpha1)
tau2_l = exp(W2_l alpha2)
a1_l = tau1_l v1_tip,l
a2_l = tau2_l v2_tip,l
Cov(a1_l, a2_m) = rho_phylo tau1_l A_lm tau2_m
```

The TMB prior is on the unit tree effects `v1` and `v2` with one constant
latent correlation. Observed tip contributions are scaled by the fitted
species SD surface. When only one direct-SD formula is supplied, the other
endpoint keeps its scalar `log_sd_phylo` parameter.

## Files Changed

- `NEWS.md`
- `R/drmTMB.R`
- `R/methods.R`
- `R/parse-formula.R`
- `R/profile.R`
- `ROADMAP.md`
- `src/drmTMB.cpp`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-phylo-gaussian.R`
- `tests/testthat/test-profile-targets.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`

## Checks Run

- `air format R/drmTMB.R R/parse-formula.R R/methods.R R/profile.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-biv-gaussian.R tests/testthat/test-profile-targets.R src/drmTMB.cpp docs/design/01-formula-grammar.md docs/design/16-phylo-spatial-common-math.md docs/design/18-random-effect-scale-models.md`: passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|profile-targets|summary|biv-gaussian", reporter = "summary")'`: passed after fixing summary/profile routing.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n 'beta_sd_phylo1|beta_sd_phylo2|sd_phylo1\(species\).*planned|sd_phylo2\(species\).*planned|sd_phylo1\(species\).*not implemented|sd_phylo2\(species\).*not implemented' R tests docs NEWS.md ROADMAP.md vignettes`: no hits.
- `git diff --check`: passed.

## Tests Of The Tests

- The main positive test fits both `sd_phylo1()` and `sd_phylo2()`, checks
  positive predicted species SD surfaces, broad correlation with simulated
  truth, finite latent phylogenetic correlation, random-effect contribution
  accounting in `predict(mu1)` / `predict(mu2)`, median-SD covariance-summary
  reporting, and `corpairs(level = "phylogenetic")`.
- A one-sided test fits `sd_phylo1()` alone and `sd_phylo2()` alone so the
  mixed direct-SD plus scalar-`log_sd_phylo` path is exercised.
- The q=4 boundary test checks that direct-SD formulas are rejected when the
  all-four phylogenetic location-scale block is present.
- The profile-target test checks that direct-SD coefficients map to
  `beta_sd_mu`, while species SD surfaces remain derived targets.

## Consistency Audit

The formula grammar, likelihood notes, random-effect scale design, shared
phylogenetic math, NEWS, roadmap, and known limitations now agree that
`sd_phylo1()` / `sd_phylo2()` are implemented only for bivariate phylogenetic
location effects. Spatial direct-SD names remain planned. Old after-task notes
that described the names as planned are historical and were left unchanged.

## What Did Not Go Smoothly

Franklin's sidecar review caught two reporting bugs after the first focused
test run: `summary()$covariance` still looked for scalar SDs under
`sdpars$mu`, and `profile_targets()` routed `sd_phylo1()` /
`sd_phylo2()` coefficients to non-existent `beta_sd_phylo*` internals. Both
were fixed before the full test suite.

The start vector also carried an old dummy `beta_sd_mu` value when direct
`sd_phylo()` was the only random-effect SD model. The fitted tests were still
able to optimize, but the parameter vector was unnecessarily untidy, so the
start builder now keeps the dummy only when no random-effect SD model is
present.

## Team Learning

- Ada: sidecar review should happen before the check-log, not after; it caught
  user-visible reporting drift while the code was still easy to fix.
- Boole: the bivariate names are now real grammar, so planned-feature error
  hints must mention them as implemented alongside univariate `sd_phylo()`.
- Gauss: the likelihood is cleanest when direct-SD endpoints map out their
  scalar `log_sd_phylo` parameters and the prior stays on unit tree effects.
- Noether: summary covariance is not literally scalar under direct-SD surfaces;
  median endpoint SDs are a compact reporting convention, not the full
  species-pair covariance object.
- Curie: one-sided direct-SD tests are necessary because they exercise the
  mixed direct-surface plus scalar endpoint map.
- Fisher: profile likelihood can handle direct-SD fixed effects now, but
  derived species SD surfaces and median covariance summaries should remain
  marked as derived rather than directly profiled.
- Darwin: examples for this path should use species-level predictors such as
  habitat variability, not observation-level assay context.
- Pat: user-facing prose must keep saying that `rho12` is residual and
  `rho_phylo` is latent phylogenetic correlation.
- Emmy: coefficient packing through `beta_sd_mu` is shared across ordinary and
  phylogenetic direct-SD models; future additions should use helpers rather
  than inventing new internal parameter names.
- Grace: full tests and pkgdown both passed after the reporting fixes; the next
  risk gate is bivariate direct-SD diagnostics and broader recovery.
- Rose: old historical notes can say "planned", but current status tables and
  scans must exclude stale planned/not-implemented claims in live docs.

## Known Limitations

- No bivariate `check_drm()` direct-SD diagnostic row was added in this slice.
- Recovery evidence is broad but still small; Slice 25 should expand the
  diagnostics and documentation around weak SD surfaces and low species counts.
- `sd_spatial()`, `sd_spatial1()`, and `sd_spatial2()` remain planned.
- Predictor-dependent latent `corpair()` fitting remains deferred.

## Next Actions

- Slice 25: add bivariate `sd_phylo1()` / `sd_phylo2()` diagnostics, recovery
  documentation, and any pkgdown example text needed to make the feature
  usable.
- Then move to the spatial sibling lane after the phylogenetic Family B path is
  documented and audited.
