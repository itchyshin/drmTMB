# After Task: Slice 17 Phylogenetic q4 Fit and Reporting

## Goal

Fit the first constant labelled bivariate phylogenetic q=4 location-scale block
and report its point estimates without claiming recovery evidence or direct
profile intervals for the six derived correlations.

## Implemented

- Matching labelled `phylo(1 | p | species, tree = tree)` terms in `mu1`,
  `mu2`, `sigma1`, and `sigma2` now build one endpoint-major q=4 phylogenetic
  latent state.
- The public bivariate Gaussian path now activates four `log_sd_phylo`
  parameters and six `theta_phylo` unstructured-correlation parameters for that
  q=4 block.
- The TMB likelihood adds the q=4 matrix-normal prior against the sparse tree
  precision while preserving the existing two-endpoint `eta_cor_phylo` path for
  matching `mu1`/`mu2` models.
- `sdpars`, `corpars`, `ranef()`, `predict()`, `corpairs()`,
  `summary(fit)$covariance`, and `profile_targets()` now share the endpoint
  order `mu1`, `mu2`, `sigma1`, `sigma2`.
- `profile_targets()` marks q=4 phylogenetic correlations as derived
  `theta_phylo` targets with note `derived_unstructured_correlation`; it does
  not label them as direct profile-ready atanh targets.
- Formula grammar, likelihood notes, phylogenetic/spatial math, mammal route,
  roadmap, known limitations, NEWS, roxygen, and the touched article sources
  were synchronized with the new fitted status.

## Mathematical Contract

For each augmented tree node, the fitted latent vector is

```text
U_j = [U_mu1,j, U_mu2,j, U_sigma1,j, U_sigma2,j]'
```

with

```text
U ~ MatrixNormal(0, A_augmented, Sigma_phylo)
Sigma_phylo = D R(theta_phylo) D
```

The first two components enter `mu1` and `mu2`; the last two enter the
`log(sigma1)` and `log(sigma2)` linear predictors. Residual `rho12` remains the
within-observation bivariate Gaussian correlation and is not part of
`Sigma_phylo`.

## Files Changed

- `src/drmTMB.cpp`
- `R/drmTMB.R`
- `R/methods.R`
- `R/profile.R`
- `tests/testthat/test-phylo-gaussian.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/29-mammal-location-coscale-route.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `man/drmTMB.Rd`

## Checks Run

- `air format R/drmTMB.R R/methods.R R/profile.R tests/testthat/test-phylo-gaussian.R`:
  passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|corpairs|profile-targets|check-drm|biv-gaussian|covariance-block-registry", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::build_article("phylogenetic-spatial", quiet = TRUE); pkgdown::build_article("formula-grammar", quiet = TRUE); pkgdown::build_article("model-map", quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n 'phylogenetic q=4 blocks|q=4 location-scale endpoint is still planned|matched-but-not-yet|full q=4 endpoint remains planned|rejected before optimization until fitted|Guarded planned q4|phylogenetic scale and mean-scale correlations remain planned' NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes pkgdown-site/articles | head -n 120`:
  returned no stale current-status hits.
- `git diff --check`: passed.

## Tests Of The Tests

The new q=4 test replaces the former "matched all-four syntax errors" guard and
would have failed before this slice because the same model did not fit. It now
checks active `theta_phylo` parameters, four endpoint SD labels, six
phylogenetic `corpairs()` rows, q=4 `summary(fit)$covariance` rows, block/class
filters, scale-endpoint prediction, and derived profile-target status. The same
test still exercises malformed-input guards for partial, unlabelled, and
mismatched q=4 syntax.

## Consistency Audit

Rose checked current-status wording across NEWS, roadmap, design docs, known
limitations, article sources, and generated article HTML. Historical after-task
notes still say phylogenetic q=4 was planned because that was true when they
were written; the new check-log and after-task report supersede those notes.

## What Did Not Go Smoothly

- The first tiny q=4 smoke fit is intentionally used for reporting structure,
  not convergence evidence. The optimizer may hit singular or boundary behavior
  on tiny data, which is exactly why Slice 18 needs recovery simulations and
  q=4-specific diagnostics.
- The q=4 correlation profile story needed a pause. The local `gllvmTMB`
  profile-CI code shows a strong direct `TMB::tmbprofile()` pattern for single
  parameters and linear contrasts, but nonlinear derived correlations need a
  slower fix-and-refit design. This slice therefore marks q=4 correlations as
  derived rather than profile-ready.

## Team Learning

- Ada should keep one sentence at the top of each slice naming the implemented
  claim and the non-claim.
- Boole should preserve endpoint order in one helper and make parser rejection
  messages follow that same order.
- Gauss should keep q=2 and q=4 covariance parameterizations side by side until
  simulation recovery shows the q=4 branch is stable.
- Noether should continue checking that symbolic endpoint order, R names, and
  TMB storage order are identical.
- Fisher should design q=4 inference around direct profile targets first and
  derived fix-and-refit targets later.
- Curie should make Slice 18 a real simulation/recovery slice rather than
  expanding smoke tests.
- Pat and Darwin should check whether the q=4 article example teaches the
  biological meaning of location-location, location-scale, and scale-scale rows.
- Grace should keep pkgdown rebuilds targeted during slice work and reserve full
  checks for milestone gates.
- Rose should keep stale status scans focused on current docs and not rewrite
  historical notes that were true at the time.

## Known Limitations

- No q=4 simulation recovery evidence exists yet.
- `check_drm()` still uses the older bivariate phylogenetic covariance check
  wording and needs q=4-specific messages.
- Direct profile intervals are not implemented for the six derived q=4
  phylogenetic correlations.
- Spatial q=4 and `sd_phylo()` remain planned sibling/family lanes.

## Next Actions

1. Add Slice 18 recovery simulations and finite-gradient checks for
   phylogenetic q=4.
2. Add q=4-specific `check_drm()` diagnostics and wording.
3. Promote a real fitted q=4 example only after recovery evidence is green.
4. Keep Fisher's profile-CI design note for the later derived-correlation
   inference slice.
