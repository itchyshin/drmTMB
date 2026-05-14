# After Task: Slice 27 Phylogenetic `corpair()` Loading Contract

## Goal

Choose the first positive-definite covariance contract for future
predictor-dependent phylogenetic `corpair()` regression before adding TMB
likelihood parameters.

## Implemented

- Selected a q=2 location-location loading contract for
  `corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ w`.
- Clarified that phylogenetic location-scale and scale-scale correlation
  regressions are deferred q=4 extensions, not part of the first selected q=2
  implementation.
- Added the contract to the correlation-pair design note, the common
  phylogenetic math note, likelihood design, formula grammar, known limitations,
  NEWS, ROADMAP, `corpair()` documentation, and the two user-facing articles.
- Added a `test-phylo-utils.R` algebra test that checks positive definiteness,
  local same-species correlation recovery, constant-correlation equivalence to
  the existing bivariate phylogenetic covariance, and the nonstationary effect
  when `rho_l` varies.

## Mathematical Contract

Let `A` be the standardized tree-derived species correlation matrix. Let `z1`
and `z2` be independent unit phylogenetic fields:

```text
z1 ~ MVN(0, A)
z2 ~ MVN(0, A).
```

For species `l`, the future `corpair()` linear predictor defines

```text
rho_l = tanh_guard(W_l alpha)
c_l = sqrt((1 + rho_l) / 2)
d_l = sqrt((1 - rho_l) / 2).
```

The q=2 location-location effects are

```text
a1_l = tau1 (c_l z1_l + d_l z2_l)
a2_l = tau2 (c_l z1_l - d_l z2_l).
```

This is positive definite because `[a1, a2]` is a linear transformation of two
independent Gaussian fields. When `rho_l` is constant, it reduces exactly to
the currently implemented constant bivariate phylogenetic covariance:

```text
Cov(a1, a2) = tau1 tau2 rho A.
```

When `rho_l` varies, the model is nonstationary. The same-species
phylogenetic correlation is `rho_l`, but between-species covariances are also
modulated by the species-specific loading vectors.

## Files Changed

- `R/formula-markers.R`
- `man/corpair.Rd`
- `tests/testthat/test-phylo-utils.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `NEWS.md`
- `ROADMAP.md`
- generated pkgdown pages

## Checks Run

- `/opt/homebrew/bin/air format R/formula-markers.R tests/testthat/test-phylo-utils.R docs/design/20-coscale-correlation-pairs.md docs/design/16-phylo-spatial-common-math.md docs/design/03-likelihoods.md docs/design/01-formula-grammar.md vignettes/phylogenetic-spatial.Rmd vignettes/formula-grammar.Rmd docs/dev-log/known-limitations.md ROADMAP.md NEWS.md`:
  passed.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::document()'`:
  passed and refreshed `man/corpair.Rd`.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); devtools::test(filter = "phylo-utils", reporter = "summary")'`:
  passed after fixing a dimname-only expectation in the new algebra test.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::test(reporter = "summary")'`:
  passed.
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'pkgdown::build_site()'`:
  passed and refreshed local docs.
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'pkgdown::check_pkgdown()'`:
  passed.
- `rg -n "selected q=2|two-field loading|nonstationary|positive-definite loading|rho_l|c_l|d_l|phylo.*corpair.*contract" docs/design vignettes pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/articles/formula-grammar.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html NEWS.md ROADMAP.md tests R man --glob '!pkgdown-site/search.json'`:
  returned expected design, test, generated-site, and documentation hits.
- `git diff --check`: passed.

## Tests Of The Tests

The new algebra test constructs the induced dense covariance from a small
ultrametric tree and checks four claims:

- the covariance is symmetric positive definite;
- the same-species correlations recover the supplied `rho_l`;
- a constant `rho_l` produces exactly the existing separable bivariate
  phylogenetic covariance;
- variable `rho_l` changes the within-trait off-diagonal covariance, naming the
  nonstationary implication explicitly.

## Consistency Audit

Rose checked the formula grammar, likelihood design, common math note,
correlation-pair design note, known limitations, NEWS, ROADMAP, generated
`corpair()` reference page, and the phylogenetic-spatial and formula-grammar
articles. The story is now consistent: the syntax is reserved, the first
positive-definite q=2 contract is selected, but fitting remains planned.

## What Did Not Go Smoothly

The algebra test first failed on dimnames when comparing the constant-correlation
covariance to the expected separable block matrix. Curie kept the comparison
numeric and reran the focused test. The larger lesson is that the mathematical
contract should be tested independently before TMB code is added.

## Team Learning

- Ada should split design-contract slices from implementation slices whenever
  positive definiteness is the central risk.
- Boole should keep the same `corpair()` grammar but explain that
  `level = "phylogenetic"` changes the covariance construction.
- Gauss should implement the next TMB slice using two independent unit
  phylogenetic fields and species-specific loadings, not per-species 2 by 2
  covariance matrices.
- Noether should preserve the constant-correlation equivalence test when TMB
  likelihood code is added.
- Darwin should help choose examples where nonstationary phylogenetic
  correlation is biologically interpretable, such as life-history trade-offs
  changing along an ecological axis.
- Fisher should review identifiability and profile-likelihood implications for
  the `alpha`, `tau1`, and `tau2` parameters before large simulations.
- Pat should check that users understand `rho_l` as a same-species
  phylogenetic latent correlation, not residual `rho12`.
- Grace should keep full package and pkgdown checks on these grammar-facing
  slices because generated docs are a first-class artifact.
- Rose should watch for future wording that says the phylogenetic `corpair()`
  model is merely "like residual `rho12`"; it is a nonstationary latent
  covariance model.

## Known Limitations

- No phylogenetic `corpair()` likelihood was fitted in this slice.
- The selected contract starts with q=2 location-location only.
- q=4 location-scale and scale-scale phylogenetic `corpair()` regression,
  direct-SD mixtures, random slopes, and spatial equivalents remain later work.

## Next Actions

Implement the q=2 phylogenetic location-location `corpair()` likelihood using
two unit tree fields, add simulation recovery and diagnostics, then expose fitted
modelled rows through `corpairs()` and profile-target planning.
