# After Task: Map Slice 23 Bivariate sd_phylo Design

## Goal

Define the bivariate `sd_phylo1()` / `sd_phylo2()` Family B contract before
adding code, so the next implementation slice does not drift into q=4
location-scale covariance or residual-scale SD modelling.

## Implemented

- Documented the planned public syntax
  `sd_phylo1(species) ~ z1` / `sd_phylo2(species) ~ z2`.
- Defined `sd_phylo1()` as the direct SD model for the `mu1` phylogenetic
  location effect and `sd_phylo2()` as the direct SD model for the `mu2`
  phylogenetic location effect.
- Recorded the intended bivariate covariance algebra with one constant latent
  phylogenetic location-location correlation.
- Clarified that residual `rho12` remains a separate within-observation
  coscale parameter.
- Clarified that `sd_phylo1()` / `sd_phylo2()` must be rejected beside all-four
  q=4 phylogenetic location-scale blocks for the same species level.
- Updated the planned-syntax error hint so it mentions implemented univariate
  `sd_phylo(species)`.

## Mathematical Contract

For matching bivariate phylogenetic location effects:

```text
mu1_i = X1_i beta1 + a1_species[i]
mu2_i = X2_i beta2 + a2_species[i]
tau1_l = exp(W1_l alpha1)
tau2_l = exp(W2_l alpha2)
a1_l = tau1_l v1_tip,l
a2_l = tau2_l v2_tip,l
Cov(a1_l, a1_m) = tau1_l A_lm tau1_m
Cov(a2_l, a2_m) = tau2_l A_lm tau2_m
Cov(a1_l, a2_m) = rho_phylo tau1_l A_lm tau2_m
```

The design preserves a constant latent phylogenetic location-location
correlation `rho_phylo`, reported by `corpairs()`. It does not introduce
location-scale or scale-scale phylogenetic correlations.

## Files Changed

- `R/parse-formula.R`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/parse-formula.R ROADMAP.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/16-phylo-spatial-common-math.md docs/design/18-random-effect-scale-models.md docs/dev-log/known-limitations.md`: passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|phylo-gaussian|package-skeleton", reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n 'sd_phylo1\(species\).*Implemented|sd_phylo2\(species\).*Implemented|sd_phylo1\(species\).*fits|sd_phylo2\(species\).*fits|bivariate `sd_phylo1\(\)`.*implemented|bivariate `sd_phylo2\(\)`.*implemented' README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site/articles/phylogenetic-spatial.html R tests`: no hits.
- `git diff --check`: passed.

## Tests Of The Tests

This is a design-only slice. The focused `biv-gaussian`, `phylo-gaussian`, and
`package-skeleton` tests confirm that existing bivariate, phylogenetic, and
reserved-syntax checks still pass after the documentation and parser-hint
change. Implementation tests are deferred to Slice 24.

## Consistency Audit

The formula grammar, likelihood design, shared structured-effect math,
random-effect scale design, roadmap, and known limitations now describe the same
planned model:

- response-specific location-only direct-SD syntax;
- one shared tree and constant latent phylogenetic location-location
  correlation;
- residual `rho12` separate;
- no mixing with all-four q=4 phylogenetic location-scale blocks.

## What Did Not Go Smoothly

No implementation failure occurred. The main risk was wording drift: older
phrasing said only that `sd_phylo1()` / `sd_phylo2()` were planned, without
specifying whether the bivariate model would keep a constant phylogenetic
correlation or try to model location-scale correlations. This slice closes that
ambiguity before code starts.

## Team Learning

- Ada: design slices are useful only when they constrain the next code slice;
  this one names exact allowed and rejected combinations.
- Boole: public names should keep response roles visible:
  `sd_phylo1()` means `mu1` location SD, not a generic first SD.
- Gauss: the TMB implementation can reuse the bivariate phylogenetic base
  correlation while replacing endpoint SD scalars with species-level surfaces.
- Noether: the cross-covariance formula
  `rho_phylo tau1_l A_lm tau2_m` is the anchor for checking storage order.
- Curie: Slice 24 tests should include one-or-both direct-SD formulas, group
  mismatch errors, q=4 conflict errors, and a small recovery smoke test.
- Fisher: the first fitted slice should treat `rho_phylo` as constant; predictor
  dependent latent `corpair()` remains a later inference problem.
- Darwin: examples should use species-level ecological predictors, not
  observation-level assay covariates, for `sd_phylo1()` / `sd_phylo2()`.
- Pat: tutorials must say in plain words that residual `rho12` is not the same
  as the latent phylogenetic mean-mean correlation.
- Emmy: the object model should mirror ordinary `sd1()` / `sd2()` where
  possible, but store phylogenetic direct-SD metadata separately from ordinary
  group effects.
- Grace: keeping this design-only avoids pushing an untested likelihood change
  while Actions are still running for the previous slice.
- Rose: continue naming "planned" versus "implemented" explicitly in every
  status table.

## Known Limitations

- No bivariate `sd_phylo1()` / `sd_phylo2()` fitting code was added.
- No new recovery test was added for the planned bivariate direct-SD model.
- Spatial direct-SD siblings remain planned after the phylogenetic path.

## Next Actions

- Slice 24: implement bivariate `sd_phylo1()` / `sd_phylo2()` for matching
  bivariate phylogenetic location effects.
- Slice 25: add recovery tests, summaries, docs, and diagnostics for the fitted
  bivariate direct-SD path.
