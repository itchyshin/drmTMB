# After Task: Fixed-Effect Zero-Truncated NB2 Family

## Goal

Add the first positive-count family, `truncated_nbinom2()`, without confusing
zero-truncated regression with the later hurdle model grammar.

## Implemented

- Exported `truncated_nbinom2()` with public distributional parameters `mu`
  and `sigma`.
- Added a fixed-effect univariate R builder for positive integer responses,
  default `sigma ~ 1`, complete-case filtering before response validation, and
  clear unsupported-feature errors.
- Added TMB `model_type = 11` for zero-truncated NB2 likelihoods.
- Added method support for `predict()`, `fitted()`, `sigma()`, `simulate()`,
  `residuals()`, and printed family labels.
- Added tests for recovery, independent likelihood, positive-count summaries,
  missingness, Poisson-limit behaviour, factors, scale extremes, and invalid
  or unsupported inputs.

## Mathematical Contract

The implemented model is:

```text
y_i | y_i > 0, mu_i, sigma_i ~ NB2(mu_i, size_i) truncated at zero
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
size_i = 1 / sigma_i^2
Pr(y_i = k | y_i > 0) = Pr_NB2(y_i = k) / (1 - Pr_NB2(0))
E[y_i | y_i > 0] = mu_i / (1 - Pr_NB2(0))
```

Matching R syntax:

```r
fit <- drmTMB(
  drm_formula(count ~ habitat, sigma ~ treatment),
  family = truncated_nbinom2(),
  data = dat
)
```

`predict(fit, dpar = "mu")` returns the untruncated NB2 component mean.
`sigma(fit)` returns the untruncated NB2 overdispersion scale. `fitted(fit)`
returns the expected observed positive count.

## Files Changed

- `R/family.R`
- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-truncated-nbinom2-location-scale.R`
- `tests/testthat/test-family-link-contract.R`
- `README.md`, `DESCRIPTION`, `NEWS.md`, `ROADMAP.md`, `_pkgdown.yml`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`
- `vignettes/testing-likelihoods.Rmd`
- generated `man/*.Rd` files and `NAMESPACE`

## Checks Run

- `Rscript -e "devtools::load_all()"`: passed.
- `Rscript -e "devtools::document()"`: first run warned because the new Rd
  topic did not yet exist; rerun passed cleanly.
- `Rscript -e "devtools::test(filter = 'truncated-nbinom2|family-link-contract')"`:
  109 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "devtools::test(filter = 'nbinom2|zi-nbinom2')"`: 148 passed,
  0 failed, 0 warnings, 0 skips.
- `air format .`: failed because `air` is not installed locally.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- `Rscript -e "devtools::test()"`: 1104 passed, 0 failed, 0 warnings, 0
  skips.
- `Rscript -e "pkgdown::build_site()"`: passed and generated
  `reference/truncated_nbinom2.html`.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "devtools::check()"`: 0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

- The independent likelihood test uses `stats::dnbinom()` and subtracts
  `log(1 - Pr_NB2(0))`, so it is independent of the TMB objective.
- The Poisson-limit test checks the zero-truncated NB2 objective against a
  hand-coded zero-truncated Poisson likelihood when `sigma` is almost zero.
- Complete-case tests verify that rows with missing predictors are removed
  before invalid positive-count responses are checked.
- Rejection tests cover unsupported `nu`, `zi`, planned `hu`, duplicate
  `sigma`, missing response, invalid count values, random effects,
  `meta_known_V()`, `sd(id)`, `mvbind()`, and `cbind()`.

## Consistency Audit

- Source docs now classify `truncated_nbinom2()` as implemented in the README,
  roadmap, family registry, likelihood design, formula grammar, testing
  strategy, family-link contract, source map, response-family vignette, and
  known-limitations file.
- `hu ~ predictors` remains planned and is described as the later hurdle
  extension, not as part of the implemented zero-truncated family.
- pkgdown includes `reference/truncated_nbinom2.html`, updated article pages,
  updated news, and updated roadmap text.
- The broad stale scan found no active source docs still presenting
  `truncated_nbinom2()` as planned. A generated pkgdown meta-description was
  a false-positive hit because it correctly says zero-truncated count models
  are implemented while hurdle and skewness models are staged later.

## What Did Not Go Smoothly

- The first roxygen run warned about the new self-link before the Rd topic had
  been generated. A second `devtools::document()` run was clean.
- `air format .` is still unavailable on this machine.
- Broad stale-wording regexes can overmatch compact generated meta
  descriptions. The audit should record these as false positives when the
  prose is correct.

## Team Learning

- Zero-truncated and hurdle wording needs disciplined separation because the
  later hurdle likelihood will reuse the positive-count kernel but introduce a
  different zero-generating process.
- Any new family where `predict(mu)` and `fitted()` differ needs method tests
  and explicit documentation before it is treated as implemented.
- Rose's after-task audit should continue checking generated pkgdown pages as
  well as source docs; the site is where users first notice stale status.

## Known Limitations

- `truncated_nbinom2()` is fixed-effect and univariate only.
- Random effects, known sampling covariance, phylogenetic/spatial terms,
  bivariate count models, mixed composed count families, and `hu` hurdle
  models are not implemented for this path.
- Responses must be positive integers after missing-row filtering.

## Next Actions

- Decide whether the next count-family task should be hurdle NB2 with
  `hu ~ predictors` or the first univariate ordinal family.
- When implementing `hu`, keep `predict(dpar = "mu")` and `fitted()` semantics
  explicit: `mu` remains the positive-count component target, while `fitted()`
  should become the unconditional response mean.
