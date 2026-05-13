# After Task: Fitted Bivariate Phylogenetic Location

## Goal

Fit the first bivariate Gaussian phylogenetic location slice for matching
intercept-only `phylo(1 | species, tree = tree)` terms in `mu1` and `mu2`.

## Implemented

`drm_build_biv_gaussian_spec()` now extracts matched `mu1`/`mu2` `phylo()`
terms, removes them before ordinary random-effect parsing, builds the shared
tree precision structure, and passes it to the bivariate Gaussian TMB branch.
The C++ likelihood adds one latent phylogenetic location vector for each
response, estimates two `log_sd_phylo` entries and one `eta_cor_phylo`, and
uses the shared sparse augmented tree precision in the matrix-normal prior.

The fitted object exposes the two phylogenetic location SDs in `sdpars$mu`, the
phylogenetic mean-mean correlation in `corpars$phylo`, and bivariate
`phylo_mu` random effects in `ranef()` / `random_effects`. Fitted-row
`predict(..., dpar = "mu1")` and `predict(..., dpar = "mu2")` include the
matching phylogenetic mean contribution; `newdata` predictions continue to
exclude conditional random effects.

## Mathematical Contract

For matching terms in `mu1` and `mu2`,

```text
[a_mu1, a_mu2] ~ MatrixNormal(0, Q_aug^{-1}, Sigma_phylo)
Sigma_phylo =
  [sd_phylo_mu1^2, rho_phylo * sd_phylo_mu1 * sd_phylo_mu2;
   rho_phylo * sd_phylo_mu1 * sd_phylo_mu2, sd_phylo_mu2^2]
rho_phylo = 0.999999 * tanh(eta_cor_phylo)

mu1_i = X_mu1[i, ] beta_mu1 + a_mu1[species_i]
mu2_i = X_mu2[i, ] beta_mu2 + a_mu2[species_i]
```

This `rho_phylo` is a phylogenetic mean-mean correlation. It is not residual
`rho12`, and it is not a phylogenetic scale or mean-scale correlation.

## Files Changed

- `R/drmTMB.R`, `src/drmTMB.cpp`
- `R/methods.R`, `R/profile.R`, `R/formula-markers.R`
- `tests/testthat/test-phylo-gaussian.R`,
  `tests/testthat/test-biv-gaussian.R`,
  `tests/testthat/test-gaussian-location-scale.R`,
  `tests/testthat/test-phylo-utils.R`
- `README.md`, `NEWS.md`, `ROADMAP.md`, `man/drmTMB.Rd`, `man/phylo.Rd`
- `docs/design/01-formula-grammar.md`,
  `docs/design/03-likelihoods.md`,
  `docs/design/09-phylogenetic-and-spatial-speed.md`,
  `docs/design/15-location-coscale-phylogenetic-extension.md`,
  `docs/design/16-phylo-spatial-common-math.md`,
  `docs/design/20-coscale-correlation-pairs.md`,
  `docs/design/28-double-hierarchical-endpoint.md`,
  `docs/design/29-mammal-location-coscale-route.md`
- `docs/dev-log/known-limitations.md`, `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-13-135745-codex-checkpoint.md`
- `vignettes/formula-grammar.Rmd`, `vignettes/model-map.Rmd`,
  `vignettes/phylogenetic-spatial.Rmd`, `vignettes/which-scale.Rmd`

## Checks Run

- `air format ...`: passed on touched R, test, markdown, and R Markdown files.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/drmTMB.Rd` and `man/phylo.Rd`.
- `Rscript -e 'devtools::test(filter = "phylo|biv-gaussian|profile-targets")'`:
  passed with 838 expectations.
- `Rscript -e 'devtools::test(filter = "gaussian-location-scale|phylo|biv-gaussian|profile-targets")'`:
  passed with 916 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,657 expectations, 0 failures,
  0 warnings, and 0 skips.
- Rendered `vignettes/formula-grammar.Rmd`, `vignettes/model-map.Rmd`,
  `vignettes/phylogenetic-spatial.Rmd`, and `vignettes/which-scale.Rmd` to
  temporary HTML files with `rmarkdown::render(...)`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

The new bivariate phylogenetic test compares the fitted Laplace objective to an
independent dense marginal likelihood built from the tip covariance, residual
`sigma1` / `sigma2`, residual `rho12`, two fitted phylogenetic SDs, and fitted
`corpars$phylo`. It also checks fitted parameter names, profile-target mapping,
conditional prediction contributions for both responses, and the current
`newdata` convention that excludes conditional random effects.

The existing unsupported-syntax tests still cover one-sided bivariate
`phylo()` terms and mismatched tree/group pairs. The updated stale expectation
now checks for the matched-term error rather than the previous planned-feature
message.

## Consistency Audit

The status wording was synchronized across README, NEWS, roadmap, formula
grammar, likelihood design, phylogenetic/spatial design notes, mammal route,
model map, which-scale, known limitations, and roxygen-generated Rd files.
The repeated guardrail is that only the bivariate `mu1`/`mu2` phylogenetic
location slice is fitted. The q=4 `mu1`, `mu2`, `sigma1`, `sigma2` endpoint,
phylogenetic scale effects, mean-scale phylogenetic correlations, structured
`rho12`, spatial effects, and `corpairs()` rows for phylogenetic correlations
remain planned.

## What Did Not Go Smoothly

The first full `devtools::test()` rerun exposed one stale test expectation from
the previous guard-only slice. That was useful: it confirmed the public failure
mode changed from "planned" to "must be matched" for one-sided bivariate
`phylo()` syntax.

The crash also left a stale recovery checkpoint from before the fitted
implementation. Repository state, not that checkpoint, was used as the source
of truth for this closeout, and a fresh checkpoint now records the current
working tree.

## Team Learning

Ada kept the slice narrow: bivariate phylogenetic location only. Gauss and
Noether got the independent dense-likelihood comparator they needed before the
TMB branch could be trusted. Curie pushed the test beyond convergence by
checking objective equality, prediction contributions, and profile-target
indices. Pat and Rose kept the public prose from implying that the complete
phylogenetic location-scale programme is finished.

## Known Limitations

`corpairs()` does not yet emit the fitted bivariate phylogenetic mean-mean
correlation. The value is available in `corpars$phylo`, but the correlation-pair
table still needs a deliberate phylogenetic row design.

The full q=4 phylogenetic endpoint across `mu1`, `mu2`, `sigma1`, and `sigma2`
is still planned. There are no phylogenetic scale effects, no phylogenetic
mean-scale correlations, no structured effects in `rho12`, and no spatial
likelihood in this slice.

## Next Actions

1. Add `corpairs()` rows for fitted phylogenetic mean-mean correlations with a
   stable `level = "phylogenetic"` contract.
2. Add `check_drm()` diagnostics for near-boundary `corpars$phylo` and weak
   bivariate phylogenetic SDs.
3. Only after those reporting surfaces are stable, consider the next
   phylogenetic location-scale slice.
