# After Task: Slice 26 Phylogenetic `corpair()` Design Gate

## Goal

Clarify the planned `corpair(species, level = "phylogenetic", ...) ~ w`
route before implementation, so the package does not imply that
predictor-dependent residual `rho12` regression or ordinary grouped
`corpair()` regression can be copied directly to a tree-coupled latent layer.

## Implemented

- Added a level-specific guard for unsupported `corpair()` regressions.
- Made `level = "phylogenetic"` fail with a design-gate message that points
  users to currently fitted constant phylogenetic correlations:
  `corpairs(fit, level = "phylogenetic")`.
- Made `level = "spatial"` fail with a spatial-specific planned-feature
  message rather than the older generic ordinary-only message.
- Added a bivariate Gaussian failure-path test for the reserved phylogenetic
  syntax.
- Updated formula grammar, the correlation-pair design note, known limitations,
  NEWS, ROADMAP, the formula-grammar article, the phylogenetic-spatial article,
  and the `corpair()` reference page.

## Mathematical Contract

The first ordinary q=2 `corpair()` model is valid because each group has an
independent 2 by 2 latent covariance matrix:

```r
corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ w
```

The planned phylogenetic analogue is not that simple:

```r
corpair(species, level = "phylogenetic", block = "p",
        from = "mu1", to = "mu2") ~ ecology
```

Phylogenetic latent effects are coupled across species by the tree-derived
matrix `A`. A predictor-dependent phylogenetic correlation must therefore define
one positive-definite covariance matrix for all species in the block, not
independent per-species `tanh()` correlations. Slice 26 records this as a design
gate rather than a fitted likelihood.

## Files Changed

- `R/drmTMB.R`
- `R/formula-markers.R`
- `man/corpair.Rd`
- `tests/testthat/test-biv-gaussian.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `NEWS.md`
- `ROADMAP.md`
- generated pkgdown articles and reference pages

## Checks Run

- `/opt/homebrew/bin/air format R/drmTMB.R R/formula-markers.R tests/testthat/test-biv-gaussian.R docs/design/20-coscale-correlation-pairs.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/phylogenetic-spatial.Rmd docs/dev-log/known-limitations.md ROADMAP.md NEWS.md`:
  passed.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::document()'`:
  passed and refreshed `man/corpair.Rd`.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); devtools::test(filter = "biv-gaussian", reporter = "summary")'`:
  passed.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); devtools::test(filter = "package-skeleton", reporter = "summary")'`:
  passed.
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE); pkgdown::build_article("formula-grammar", new_process = FALSE, quiet = TRUE); pkgdown::build_reference()'`:
  passed.
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'pkgdown::build_site()'`:
  passed and refreshed the local articles, reference pages, NEWS, and ROADMAP.
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'pkgdown::check_pkgdown()'`:
  passed.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::test(reporter = "summary")'`:
  passed.
- `rg -n "Only ordinary group-level .*corpair|phylogenetic and spatial latent correlation regressions are later slices|clade-level|copy.*ordinary|planned design gate|positive-definite covariance contract|tree-coupled" R man docs vignettes pkgdown-site NEWS.md ROADMAP.md tests --glob '!pkgdown-site/search.json'`:
  returned only intentional guardrail, documentation, and generated-site hits.
- `git diff --check`: passed.

## Tests Of The Tests

The new test exercises the exact unsupported public formula:

```r
corpair(species, level = "phylogenetic", block = "p",
        from = "mu1", to = "mu2") ~ ecology
```

It checks that the error is an `rlang_error`, says the feature is planned but
not fitted, points to `corpairs(fit, level = "phylogenetic")`, and names the
positive-definite design requirement. This is a failure-path test by design:
the slice does not add a likelihood.

## Consistency Audit

Rose checked the formula grammar, correlation-pair design note, known
limitations, ROADMAP, NEWS, formula-grammar article, phylogenetic-spatial
article, and generated `corpair()` reference page. The implemented-versus-
planned boundary is consistent: constant phylogenetic correlations are fitted
and extracted with `corpairs()`, while predictor-dependent phylogenetic
`corpair()` regression remains planned.

## What Did Not Go Smoothly

The first instinct was to treat phylogenetic `corpair()` like ordinary
group-level `corpair()`. Gauss and Noether caught the real issue: the tree
couples all species, so the model needs a positive-definite full covariance
construction before a species-level predictor can vary the latent correlation.

## Team Learning

- Ada should keep stopping at mathematical design gates before implementation
  pressure turns a reserved syntax into a false claim.
- Boole should keep `corpair()` / `corpairs()` naming stable, but make unsupported
  formulas tell users exactly what fitted route to use today.
- Gauss should design the next likelihood around a full positive-definite
  tree-coupled covariance, not a per-tip residual-correlation analogy.
- Noether should write the next contract as equations before any TMB parameter
  vector is added.
- Darwin should help decide whether the first predictor-dependent phylogenetic
  correlation target is biologically a species-level surface, a clade-level
  contrast, or a smaller globally valid covariance model.
- Fisher should review profile-likelihood and identifiability implications once
  the covariance contract is chosen.
- Pat should check that article readers can distinguish residual `rho12`,
  constant phylogenetic `corpairs()`, and planned phylogenetic `corpair()`.
- Grace should keep pkgdown and full test gates in the loop for user-facing
  grammar changes.
- Rose should watch for stale wording that says phylogenetic `corpair()` is only
  "later" without explaining why it has a positive-definite design gate.

## Known Limitations

- No phylogenetic `corpair()` likelihood was added in this slice.
- No `corpair(..., level = "phylogenetic")` profile interval exists because
  there is no fitted predictor-dependent target yet.
- Spatial `corpair()` remains behind the constant spatial covariance block.

## Next Actions

Choose the first positive-definite covariance contract for
`corpair(species, level = "phylogenetic", from = "mu1", to = "mu2") ~ w`, then
implement the q=2 phylogenetic location-location slice with simulation recovery
and profile-target planning. If that decision needs literature support, Jason
and Fisher should scout multivariate nonstationary phylogenetic covariance
models before Gauss starts TMB work.
