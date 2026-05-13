# After Task: Bivariate Same-Response Mu/Sigma Covariance

## Goal

Finish the third ordinary grouped covariance slice: one same-response bivariate
mean-scale random-intercept covariance block, such as matching `(1 | p | id)`
in `mu1` and `sigma1`, without claiming the full labelled block across `mu1`,
`mu2`, `sigma1`, and `sigma2`.

## Implemented

`drmTMB()` now accepts one labelled same-response bivariate `mu`/`sigma`
random-intercept pair. The fitted correlation is reported in
`corpars$mu_sigma`, `corpairs()` as a `mean-scale` row, `profile_targets()` as
an `eta_cor_mu_sigma` target, and `check_drm()` as
`biv_mu_sigma_random_effect_covariance`.

The TMB data list now passes `mu_re_dpar`, `sigma_re_dpar`,
`n_sigma_re_cors`, `sigma_re_cor_id`, and `sigma_re_pair_index` separately from
the `sigma_re_cross_*` fields used for `mu`/`sigma` covariance. This keeps
same-parameter `sigma1`/`sigma2` covariance and same-response `mu`/`sigma`
covariance in separate channels.

## Mathematical Contract

For response 1, the implemented slice is:

```text
mu1_ij = X_mu1[ij, ] beta_mu1 + sd_mu1 b_j
log(sigma1_ij) = X_sigma1[ij, ] beta_sigma1 + sd_sigma1 a_j
[b_j, a_j]' ~ Normal(0, [[1, rho_mu_sigma], [rho_mu_sigma, 1]])
```

The same pattern is allowed for response 2. Residual `rho12` remains the
within-observation response-response correlation after `mu1`, `mu2`, `sigma1`,
and `sigma2` have been modelled.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `R/check.R`
- `R/methods.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-phylo-utils.R`
- `NEWS.md`, `README.md`, `ROADMAP.md`
- `docs/design/01-formula-grammar.md`,
  `docs/design/03-likelihoods.md`,
  `docs/design/12-profile-likelihood-cis.md`,
  `docs/design/17-correlated-random-effect-blocks.md`,
  `docs/design/20-coscale-correlation-pairs.md`,
  `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/known-limitations.md`, `docs/dev-log/check-log.md`
- `vignettes/distribution-families.Rmd`, `vignettes/formula-grammar.Rmd`,
  `vignettes/model-map.Rmd`, `vignettes/source-map.Rmd`,
  `vignettes/which-scale.Rmd`
- `man/drmTMB.Rd`, `man/corpairs.Rd`

## Checks Run

- `air format R/drmTMB.R R/check.R R/methods.R tests/testthat/test-biv-gaussian.R`: passed.
- `air format tests/testthat/test-gaussian-random-intercepts.R tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e "devtools::document()"`: passed; regenerated `man/drmTMB.Rd` and `man/corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|check-drm')"`: passed with 369 expectations.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|phylo-utils|biv-gaussian|check-drm')"`: passed with 639 expectations.
- `Rscript -e "devtools::test()"`: passed with 2052 expectations.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

`devtools::check()` was not run for this slice.

## Tests Of The Tests

The new bivariate regression checks the fitted model, TMB data fields,
independent R-side transformation of `u_sigma` from `u_mu`, `corpairs()` row
semantics, `profile_targets()` mapping, and the new `check_drm()` diagnostic.
The unsupported-syntax block also checks that a `mu1` label paired with
`sigma2` fails as cross-response covariance.

The full-suite rerun first failed because old tests still expected the previous
unsupported bivariate random-effect message, and because a hand-built phylo TMB
fixture lacked the new random-effect metadata fields. Updating those fixtures
confirmed that the new C++ data contract is package-wide, not only bivariate.

## Consistency Audit

The active stale-wording scan found no broad planned-only wording after the
edits:

```sh
rg -n 'bivariate random slopes, cross-parameter|cross-parameter covariance blocks, and `rho12`|cross-parameter bivariate covariance blocks remain planned|double-hierarchical cross-parameter covariance|bivariate `sigma1`/`sigma2` and cross-parameter' README.md ROADMAP.md NEWS.md docs vignettes --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**'
```

The positive status scan checked that code, tests, and docs separate the
implemented pairwise bridge from the full planned block:

```sh
rg -n 'same-response|full cross-parameter|biv_mu_sigma_random_effect_covariance|corpars\$mu_sigma|eta_cor_mu_sigma' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R tests/testthat/test-check-drm.R
```

The syntax guardrail scan found only intentional meta-analysis and `rho12`
guardrails:

```sh
rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\([^V]' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R
```

## What Did Not Go Smoothly

The crash left a large partial diff in `R/drmTMB.R` and `src/drmTMB.cpp`. The
first targeted test run was useful: it showed that the branch compiled and that
the remaining failures were metadata names and stale expectations, not a broken
likelihood.

## Team Learning

Ada kept this as slice 3 rather than drifting into a full Cholesky block.
Noether's main lesson is that same-parameter and cross-parameter correlations
need separate data fields. Curie's lesson is that the test must inspect both
the fitted object and the TMB data contract, because a green fit alone would not
catch fixture drift. Rose's lesson is that status prose must say
same-response pairwise bridge, not full double-hierarchical covariance.

## Known Limitations

Only one same-response bivariate `mu`/`sigma` random-intercept pair is
implemented. The all-four-formula same-label pattern is still rejected.
Bivariate random slopes, `rho12` random effects, bivariate random effects with
`meta_known_V(V = V)`, phylogenetic or spatial bivariate covariance, and a true
full labelled covariance block remain planned.

## Next Actions

Close this slice with a recovery checkpoint. The next coding slice is the
Cholesky-labelled block design, but it should start as a plan and source-map
pass before code: identify the minimal labelled block object, decide how to
name `corpairs()` rows, and only then add simulation recovery.
