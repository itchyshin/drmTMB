# After task: nobs() ignores zero-weight rows (#1699)

Reader: a maintainer checking that the Schwarz penalty uses the same sample size as the likelihood.

## Task goal

`nobs()` and the `logLik` `"nobs"` attribute should count rows with a positive likelihood weight among the rows that enter the likelihood. `BIC()` should then match a fit that drops those zero-weight rows. `fitted()`, `residuals()`, and `weights()` lengths, the log-likelihood value, and `AIC()` stay as they were.

## Files changed

- `R/methods.R`: `drm_likelihood_nobs()`, `nobs.drmTMB()`, `logLik.drmTMB()`, `df.residual.drmTMB()`, `BIC()` via `drm_ic_nobs()`, and the printed observation count.
- `R/model-comparison.R`: `aicc.drmTMB()` uses `nobs()` so it follows the same sample size as its documented formula.
- `man/model-fit-extractors.Rd` and the roxygen block above the methods.
- `tests/testthat/test-fix-1699-nobs-zero-weight.R`
- `NEWS.md`

## Checks

Before, against installed `nobs.drmTMB = object$nobs`: the new test file failed all 7 tests (33 expectations). The Gaussian example in #1699 gave `nobs` 20 vs 15 and `BIC` 48.36 vs 47.49.

After reinstall: the same file passed 7 tests, 0 failures, 73 expectations. Related files listed in `docs/dev-log/check-log.d/2026-11-10-nobs-zero-weight-1699.md` passed. No tolerance or existing expectation was loosened.

## Consistency audit

`glm()` uses `sum(prior.weights != 0)`. Stored weights are non-negative, so `sum(weights > 0)` is the same rule. A weight of 0.5 or 2 still counts as one row; the test locks that against both the dropped-row fit and `nobs(glm(...))`.

REML `df` does not read `nobs`. The REML test shows equal log-likelihood, equal `df`, and equal `nobs()` / `BIC()` once zero-weight rows are dropped.

Julia fits refuse `weights`, so their `nobs` methods were not edited.

`rg -n "fitted rows after complete-case|fitted-row count" R vignettes README.md man/model-fit-extractors.Rd` returned no hits. `vignettes/missing-data.Rmd` still says `nobs()` reports likelihood-contributing responses rather than retained rows; that sentence remains true.

## Tests of the tests

The new file failed on the pre-fix package and passed after the change. Expectations that log-likelihood, `AIC`, and extractor lengths match already passed before the fix, so those guards are not vacuous.

## What did not go smoothly

Running `test-model-comparison.R` and `test-poisson-mean.R` with `library(drmTMB)` cannot see unexported helpers (`drm_lrtest`, `drm_build_poisson_spec`). Reloading with `pkgload::load_all()` cleared those errors. They are not regressions from this change.

## Team learning

None recorded in `docs/dev-log/team-improvements.md`. The sample-size count belongs in `nobs()`, not in the stored row count that sizes fitted vectors.

## Design docs, pkgdown, issues

No formula, likelihood, or roadmap change. pkgdown navigation was not changed. #1699 is the only open issue on this sample-size bug. It stays open until the pull request merges. No new issue was filed.

## Known limitations

`fit$nobs` and `check_drm()` still report the likelihood-row count including zero-weight rows. That field is a row index for internal lengths, not the BIC sample size. Frequency weights greater than one still count as one observation, as in `glm()`, not as `sum(weights)`.
