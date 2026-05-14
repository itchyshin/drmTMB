# After Task: Slice 12 Ordinary q2 corpair Regression

## Goal

Fit the first predictor-dependent latent random-effect correlation model without
claiming q=4, phylogenetic, or spatial correlation regression.

## Implemented

Slice 12 adds one fitted `corpair()` route:

```r
corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ x_group
```

It is available for bivariate Gaussian fits with matching labelled ordinary
location random intercepts:

```r
mu1 = y1 ~ x + (1 | p | id)
mu2 = y2 ~ x + (1 | p | id)
```

The predictor must be constant within `id` after complete-case filtering.
Unsupported levels, endpoint pairs, q=4 blocks, mismatched groups or blocks,
and within-group-varying predictors error before optimization. `rho12` remains
the residual within-observation correlation model.

The fitted link-scale coefficients appear in `coef()`, `summary()`, `vcov()`,
and `profile_targets()`. `corpairs()` reports the response-scale mean, minimum,
maximum, and number of fitted group-level latent correlations.

## Mathematical Contract

For each group \(g\), the latent location random effects follow

\[
\begin{pmatrix}
u_{\mu_1,g} \\
u_{\mu_2,g}
\end{pmatrix}
\sim
\operatorname{MVN}\left(
\mathbf{0},
\begin{pmatrix}
\sigma_1^2 & \rho_g \sigma_1 \sigma_2 \\
\rho_g \sigma_1 \sigma_2 & \sigma_2^2
\end{pmatrix}
\right),
\qquad
\rho_g = 0.999999 \tanh(\mathbf{x}_g^\top \boldsymbol{\beta}_{cor}).
\]

Because this block is q=2, a single Fisher-z regression preserves positive
definiteness. q=4 correlation regression is still deferred because six
independent pairwise `tanh()` regressions would not guarantee a valid 4 by 4
correlation matrix.

## Files Changed

- `NEWS.md`
- `R/drmTMB.R`
- `R/formula-markers.R`
- `R/methods.R`
- `R/profile.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `man/corpair.Rd`
- `src/drmTMB.cpp`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-package-skeleton.R`
- `tests/testthat/test-phylo-utils.R`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `air format R/drmTMB.R R/methods.R R/profile.R src/drmTMB.cpp tests/testthat/test-biv-gaussian.R tests/testthat/test-package-skeleton.R NEWS.md docs/design/01-formula-grammar.md docs/design/20-coscale-correlation-pairs.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd vignettes/phylogenetic-spatial.Rmd`: passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `Rscript -e 'devtools::test(filter = "package-skeleton|biv-gaussian", reporter = "summary")'`: passed.
- `Rscript -e 'devtools::test(filter = "package-skeleton|biv-gaussian|gaussian-random-intercepts|gaussian-random-effect-scale|corpairs|comparators|check-drm", reporter = "summary")'`: passed after cross-family metadata fixes.
- `Rscript -e 'devtools::test(filter = "phylo-utils", reporter = "summary")'`: passed after manual TMB fixture sync.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("formula-grammar", new_process = FALSE, quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE); pkgdown::build_reference()'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The new positive test simulates group-level correlations from a known
Fisher-z regression and checks convergence, positive Hessian, positive fitted
correlation slope, correlation between fitted and true group-level correlations,
`corpairs()` modelled summaries, `corpairs(conf.int = TRUE)` interval status,
`profile_targets()` entries for `beta_cor_mu`, and finite standard errors in
`summary()`.

The failure tests cover mismatched covariance-block labels and predictors that
vary within group. Existing parser tests also cover unsupported endpoint pairs,
such as location-scale `mu1` to `sigma2`, so the fitted route remains bounded.

## Consistency Audit

NEWS, formula grammar, `corpair()` reference docs, known limitations, the
correlation-pair design note, the formula-grammar article, and the
phylogenetic-spatial article now agree on the status:

- ordinary q=2 `mu1`-`mu2` `corpair()` regression is implemented;
- phylogenetic and spatial `corpair()` regressions remain planned;
- q=4 correlation regression remains planned until a positive-definite
  parameterization is designed;
- `corpairs()` is the extractor, while `corpair()` is the formula marker;
- residual `rho12` is still separate from latent random-effect correlations.

## What Did Not Go Smoothly

The first focused tests passed, but the full test suite exposed that
`X_cor_mu` and `beta_cor_mu` were global TMB declarations. Non-bivariate data
lists and manual TMB algebra fixtures needed harmless defaults. The second full
run then exposed univariate Gaussian specs without `cor_model` metadata, so
`split_tmb_corpars()` now uses a guarded `has_modelled_mu_correlation()` helper.

One pkgdown call also used unsupported arguments for the installed
`pkgdown::build_reference()` API. Rerunning `pkgdown::build_reference()` without
those arguments refreshed the local reference pages.

## Team Learning

- Ada: run at least one full suite before pushing when a C++ template gains a
  global data or parameter field.
- Boole: endpoint-specific `corpair()` is now a fitted formula marker for one
  narrow route, so reference docs must no longer say all `corpair()` formulas
  are rejected.
- Gauss: q=2 Fisher-z regression is the correct first likelihood because it
  preserves positive definiteness without a new q=4 matrix model.
- Noether: the mathematical contract should state the group-specific
  covariance matrix, not only the formula syntax.
- Curie: tests must cover both the fitted q=2 route and malformed predictors
  that vary within group.
- Fisher: `profile_targets()` should expose link-scale coefficient profiles now;
  response-scale group-specific intervals need a future newdata-aware design.
- Pat: `corpairs()` output should show mean, range, and `n_values` so applied
  users see that the latent correlation is no longer one constant.
- Emmy: global TMB declarations require defaults in every data and parameter
  fixture, including manual algebra tests.
- Grace: full tests caught two regressions that focused tests missed; keep full
  suite gates for C++ template changes.
- Rose: stale wording scans need to include `man/` and `R/formula-markers.R`,
  not just vignettes and design docs.

## Known Limitations

- This slice fits only ordinary group-level q=2 `mu1`-`mu2` latent correlation
  regression.
- Location-scale, scale-scale, q=4, phylogenetic, and spatial
  predictor-dependent `corpair()` regressions remain planned.
- `corpairs(conf.int = TRUE)` marks the modelled group row as
  `newdata_required`; response-scale intervals for specified group-level
  covariate values are future work.

## Next Actions

Use this q=2 route as the ordinary stepping stone for future phylogenetic and
spatial correlation-regression designs. The next modelling step should not
expand to q=4 until the positive-definite correlation-regression
parameterization is explicit and testable.
