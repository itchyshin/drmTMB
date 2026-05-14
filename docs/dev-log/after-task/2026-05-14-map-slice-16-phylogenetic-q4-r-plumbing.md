# After Task: 35-Map Slice 16 Phylogenetic q4 R Plumbing

## Goal

Add R-side parser and boundary plumbing for the planned bivariate
phylogenetic q=4 location-scale block before exposing a fitted all-four
likelihood.

## Implemented

The formula parser now preserves optional structured covariance-block labels
in syntax such as `phylo(1 | p | species, tree = tree)`. Matching labelled
terms in bivariate `mu1` and `mu2` fit through the existing phylogenetic
mean-mean path, and the label is propagated into `sdpars`, `corpars`,
`corpairs()`, and `profile_targets()`.

Bivariate formulas that put `phylo()` in `sigma1` or `sigma2` now fail before
model-frame construction with q4-specific messages. The guard distinguishes
partial location-scale blocks, unlabelled all-four blocks, mismatched
block/group/tree definitions, structured slopes, and the matched but not yet
implemented all-four q=4 endpoint.

## Mathematical Contract

This slice does not add a new likelihood contribution. It enforces the public
R contract needed before the Slice 15 matrix-normal TMB probe can become a
fitted q=4 model:

```text
mu1, mu2, sigma1, sigma2 must share one explicit phylogenetic block label,
one species grouping variable, and one tree.
rho12 remains a residual within-observation coscale parameter.
```

## Files Changed

- `R/parse-formula.R`
- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-package-skeleton.R`
- `tests/testthat/test-phylo-gaussian.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-14-map-slice-16-phylogenetic-q4-r-plumbing.md`

## Checks Run

- `air format R/parse-formula.R R/drmTMB.R R/methods.R tests/testthat/test-package-skeleton.R tests/testthat/test-phylo-gaussian.R docs/design/01-formula-grammar.md docs/design/16-phylo-spatial-common-math.md vignettes/formula-grammar.Rmd vignettes/phylogenetic-spatial.Rmd NEWS.md`:
  passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `Rscript -e 'devtools::test(filter = "package-skeleton|phylo-gaussian", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|corpairs|profile-targets|phylo-gaussian|package-skeleton", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::build_article("phylogenetic-spatial", quiet = TRUE); pkgdown::build_article("formula-grammar", quiet = TRUE)'`:
  passed and refreshed the local HTML pages.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The new parser test checks that the structured term stores
`covariance_label = "p"` and a stable label string. The new bivariate
phylogenetic boundary test exercises the malformed paths that should fail
before optimization: matched all-four q4 syntax, partial `sigma1` use,
unlabelled all-four syntax, and mismatched `mu1`/`mu2` labels.

The existing bivariate phylogenetic fit test was moved to labelled `phylo()`
syntax, so it now verifies that a fitted mean-mean phylogenetic correlation can
carry a user block label without changing the dense marginal-likelihood
comparison.

## Consistency Audit

The formula grammar, structured-effect design note, formula-grammar article,
phylogenetic/spatial article, and NEWS now agree on the boundary:
labelled bivariate phylogenetic `mu1`/`mu2` terms are implemented as metadata,
while any phylogenetic scale endpoint is still a guarded planned q4 path.
The rebuilt local pkgdown pages contain the same status wording.

## What Did Not Go Smoothly

An initial malformed-input test used escaped quotes inside formula code, which
made `air` fail before the test suite could run. Curie caught it at the format
gate, and the test now uses ordinary formula syntax.

## Team Learning

- Ada: keep Slice 16 as a boundary/plumbing slice, not a hidden likelihood
  extension.
- Boole: structured labels need the same validation rules as ordinary
  covariance-block labels.
- Gauss: no new TMB contribution should be inferred from R-side label
  propagation.
- Noether: the R boundary now matches the Slice 14 endpoint contract and keeps
  `rho12` outside the latent phylogenetic covariance matrix.
- Curie: malformed-input tests should include both partial and matched-but-
  not-implemented q4 paths.
- Fisher: label support is not identifiability evidence; recovery waits for
  the fitted q4 likelihood.
- Darwin: article wording now tells ecological users which phylogenetic
  correlation is real today and which remains the PLSM target.
- Pat: error messages now say what to fit now versus what is reserved for q4.
- Emmy: the fitted object stores the phylogenetic block label once and routes
  it through extractors.
- Grace: rebuilding the touched articles is enough for this docs-facing slice;
  full site build waits for a larger productization slice.
- Rose: keep reporting "guarded planned" distinct from "implemented" in both
  design docs and pkgdown.

## Known Limitations

This still does not fit q=4 phylogenetic location-scale models. There are no
four phylogenetic endpoint SDs, no six phylogenetic q4 `corpairs()` rows, no
simulation recovery, and no tutorial example for the all-four fitted model.

## Next Actions

Slice 17 should move from boundary plumbing to fitted q4 reporting only after
the R-side q4 data/start/map path is ready. If the next implementation slice is
instead treated as Slice 17 reporting, Ada should first split out the missing
fit-plumbing work so the roadmap does not overclaim.
