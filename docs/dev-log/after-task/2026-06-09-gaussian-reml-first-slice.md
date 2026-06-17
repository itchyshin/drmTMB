# After Task: Gaussian REML First Slice

## Goal

Implement the first useful `drmTMB(..., REML = TRUE)` route for Gaussian mixed
models without overclaiming broader REML support.

## Implemented

`drmTMB()` now accepts a top-level `REML` argument. When `REML = TRUE`, the
first supported surface is univariate `family = gaussian()` with dense
full-rank `mu` fixed effects, ordinary `mu` random intercepts or slopes,
intercept-only `sigma`, complete responses, and unit likelihood weights.

The fit records `fit$estimator = "REML"`, `fit$REML = TRUE`, and
`fit$model$tmb_random_names`, while keeping the original
`fit$model$random_names` as the model's latent-effect names. `logLik()` carries
`df`, `nobs`, `estimator`, and `REML` attributes.

## Mathematical Contract

The C++ Gaussian joint likelihood is unchanged. The REML path passes
`random = c(spec$random_names, "beta_mu")` to `TMB::MakeADFun()`, integrating
the location fixed-effect vector together with the ordinary latent `mu` random
effects. This produces the restricted Gaussian likelihood for the fitted mean
design. Since `beta_mu` is integrated, `vcov.drmTMB()` uses the full
`sdreport` covariance matrix for REML coefficient covariance rows.

## Files Changed

- `R/drmTMB.R`: `REML` argument, estimator guards, TMB random-set switch, df
  accounting.
- `R/methods.R`: print/logLik/summary metadata and REML coefficient covariance.
- `tests/testthat/test-comparators.R`: REML `lme4` comparator tests and
  unsupported-neighbour checks.
- `man/drmTMB.Rd`: regenerated roxygen documentation.
- `vignettes/model-selection.Rmd`: ML-first model-selection example followed
  by a REML variance-component refit and optional `lme4` restricted-likelihood
  comparison.
- `docs/design/168-gaussian-reml-first-slice.md`: new implementation contract.
- `docs/design/03-likelihoods.md`, `docs/design/05-testing-strategy.md`,
  `docs/design/149-missing-data-design.md`, `docs/design/01-formula-grammar.md`,
  `README.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, and
  `vignettes/model-selection.Rmd`: synchronized public/status wording.

## Checks Run

- Direct TMB/lme4 REML probe: restricted log-likelihood matched
  `lme4::lmer(..., REML = TRUE)` to less than `1e-8`.
- `devtools::test(filter = "comparators")`: 84 passed, 0 failed, 0 warnings,
  0 skipped.
- `devtools::test(filter = "comparators|control|gaussian-location-scale|gaussian-random-intercepts")`:
  729 passed, 0 failed, 0 warnings, 0 skipped.
- `devtools::test()`: 10,189 passed, 0 failed, 0 warnings, 0 skipped.
- `devtools::document()`: wrote `man/drmTMB.Rd`.
- `tools::checkRd()` file-by-file over 54 Rd files: passed.
- `pkgdown::check_pkgdown()`: no problems found.
- Direct render of `vignettes/model-selection.Rmd`: passed.
- `devtools::check(document = FALSE, args = c("--as-cran"))`: 0 errors,
  0 warnings, 1 note. The note was `unable to verify current time`.
- `pkgdown::build_article("model-selection", new_process = FALSE)`: passed
  after `devtools::load_all(quiet = TRUE)` so pkgdown used the local REML
  implementation rather than an older installed package.
- `git diff --check`: passed.

## Tests Of The Tests

The new comparator tests check two positive REML paths against an independent
implementation: a random-intercept model and a correlated random-slope model in
`lme4`. They compare fixed effects, residual sigma, random-effect SDs,
correlation where present, restricted log-likelihood, and log-likelihood df.
The negative test checks non-Gaussian families, predictor-dependent `sigma`,
known sampling covariance, and direct `sd()` scale formulae.

## Consistency Audit

The stale-wording scan used:

```sh
rg -n "REML can be considered later|EM/profile/REML|EM/REML|REML engines|REML.*planned|REML" README.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes/model-selection.Rmd man/drmTMB.Rd --glob '!docs/dev-log/check-log.md'
```

Remaining REML mentions either describe the implemented first slice, explain
that ML is required for AIC/BIC comparisons across different fixed-effect
formulas, or explicitly scope planned work to missing-data routes and
unsupported Gaussian neighbours.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --search 'REML OR restricted maximum likelihood OR Gaussian mixed model' --limit 20 --json number,title,state,url,labels`
returned broad open issues #60 and #491, but no dedicated REML implementation
issue. No issue comment was added in this branch.

## What Did Not Go Smoothly

`air format .` reformatted unrelated simulation and test-helper files. Those
mechanical changes were removed before closing the branch. `tools::checkRd()`
also needed to be run file-by-file rather than on the package directory or a
vector of files. A first `pkgdown::build_article("model-selection")` attempt
ran in a new process against an older installed `drmTMB`, so it failed at the
new `REML` argument; rerunning after `devtools::load_all()` with
`new_process = FALSE` rendered the article successfully.

## Team Learning

For Gaussian REML in TMB, first check whether adding `beta_mu` to the random
integration set matches an independent comparator before writing a new C++
likelihood branch. Also check `sdreport` layout: integrated fixed effects move
out of `cov.fixed`, so extractor code must use the full reported covariance.

## Known Limitations

`REML = TRUE` still rejects non-Gaussian and bivariate models,
predictor-dependent `sigma`, known sampling covariance, row aggregation, sparse
fixed-effect matrices, structured effects, missing-data routes, direct `sd()`
scale formulae, `sigma` random effects, and q > 2 labelled covariance blocks.
ML remains the default and remains the correct estimator for AIC/BIC comparisons
across different fixed-effect formulas.

## Next Actions

The immediate merge-readiness gate is satisfied except for any optional final
manual/PDF CRAN rehearsal. The next REML slices should be evidence-led: either
add a comparator-backed `meta_V(V = V)` REML route against `metafor`, or extend
ordinary Gaussian REML to direct random-effect scale formulae only after a
matching `lme4` or independent restricted-likelihood check is in place.
