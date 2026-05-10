# After Task: Cumulative-Logit Ordinal Family

## Goal

Implement the first ordinal response family in `drmTMB`: a fixed-effect,
univariate cumulative-logit location model for one ordered response.

## Implemented

`cumulative_logit()` now fits ordered responses with a `mu` location formula,
ordered cutpoints, and a fixed latent logistic scale. The R builder validates
ordered factors or integer category scores `1, ..., K`, rejects unsupported
scale, random-effect, known-covariance, denominator, and bivariate syntax, drops
the location intercept for identifiability, and stores fitted cutpoints on the
model object. The TMB branch uses a new `model_type = 13` route, estimates
cutpoints through unconstrained first-cutpoint plus log-spacing parameters, and
reports interpretable cutpoints.

The fitted-object methods now treat `mu` as a latent ordinal location.
`fitted()` returns the expected ordered-category score, `residuals()` subtracts
that score from the observed category score, Pearson residuals use the fitted
category-score variance, `sigma()` returns a fixed unit vector, `simulate()`
returns ordered factors with fitted labels, and `summary()` prints ordinal
cutpoints.

## Mathematical Contract

The implemented model is:

```text
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
mu_i = X_mu[i, ] beta_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

For category probabilities, the likelihood evaluates:

```text
Pr(y_i = 1) = F(theta_1 - mu_i)
Pr(y_i = k) = F(theta_k - mu_i) - F(theta_{k-1} - mu_i), 1 < k < K
Pr(y_i = K) = 1 - F(theta_{K-1} - mu_i)
```

where `F(a) = logit^{-1}(a)`. Middle-category probabilities are computed on
the log-CDF scale with a `log(1 - exp(x))` helper to reduce cancellation when
cutpoints are close.

## Files Changed

- `R/family.R`
- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-cumulative-logit.R`
- `tests/testthat/test-phylo-utils.R`
- `DESCRIPTION`
- `NAMESPACE`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `_pkgdown.yml`
- `man/cumulative_logit.Rd`
- updated generated Rd files for touched methods
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/11-reference-programme.md`
- `docs/design/19-family-link-contract.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-cumulative-logit.R')"
Rscript -e "devtools::document()"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::build_site()"
Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
rg -n "cumulative_logit\\(\\).*Planned|cumulative-logit.*planned|ordinal.*planned|No ordinal likelihood was added|not implemented.*cumulative_logit|not implemented.*ordinal|ordered logit/probit|rho ~|meta_gaussian|tau ~" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man _pkgdown.yml
Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
```

Outcomes:

- focused cumulative-logit tests after the final audit patch: 61 passed,
  0 failed;
- final `devtools::test()`: 1325 passed, 0 failed;
- `devtools::document()`: passed;
- `pkgdown::build_site()`: passed;
- `pkgdown::check_pkgdown()`: no problems found;
- `git diff --check`: clean;
- final `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

The stale-wording search found expected text only: ordinal scale or
discrimination formulas remain planned, unsupported ordinal routes report
explicit errors, ordered logit/probit remains a broader roadmap item, and
existing meta-analysis guardrails still mention `meta_gaussian` and `tau ~`.

## Tests Of The Tests

The new test file checks parameter recovery from simulated ordinal data,
compares the fitted log-likelihood to an independent category-probability
calculation, exercises both three-category and four-category responses, checks
missing-row filtering and sparse nonempty categories, verifies close-cutpoint
probability stability, confirms deterministic simulation with a seed, and
asserts malformed-input errors for unordered factors, invalid numeric codes,
empty categories, unsupported `sigma`, random-effect, `meta_known_V()`,
`mvbind()`, and `cbind()` syntax.

The final audit added the four-category test because the initial helper and
simulation tests covered only two cutpoints even though the implementation is
generic for `K >= 3`.

## Consistency Audit

The implementation, symbolic equations, R syntax, generated Rd files, README,
NEWS, ROADMAP, design notes, vignettes, known limitations, and pkgdown
navigation now describe the same first ordinal scope: one ordered response,
fixed effects, latent `mu`, ordered cutpoints, expected category-score
`fitted()`, and fixed latent logistic scale. Status tables now mark
`cumulative_logit()` as implemented while keeping ordinal scale,
discrimination, random-effect, known-covariance, phylogenetic, bivariate, and
mixed-response ordinal features planned.

## What Did Not Go Smoothly

The resumed change set was broad enough that the first pass looked complete,
but the test helper quietly assumed exactly two cutpoints. The after-task audit
caught that mismatch between the generic implementation claim and the tests,
and the final patch made the helper generic and added a four-category
simulation check.

## Team Learning

For new family work, test the smallest supported shape and at least one larger
shape whenever the likelihood claims generic dimension support. Here, `K = 3`
was necessary but not sufficient evidence for the ordered-cutpoint machinery.

## Known Limitations

- `cumulative_logit()` supports only fixed-effect univariate ordinal location
  models.
- The latent logistic scale is fixed; ordinal `sigma` or discrimination
  formulas remain planned.
- Random effects, known sampling covariance, phylogenetic terms, non-logit
  ordinal links, bivariate ordinal models, and mixed-response ordinal models
  are not implemented.
- `fitted()` returns an expected category score for plotting and summaries; it
  should not be interpreted as a measured continuous response.

## Next Actions

1. Decide whether the next ordinal extension exposes public `sigma`, a native
   discrimination parameter, or both `sigma` plus a reporting alias.
2. Add an ecology/evolution ordinal vignette after that scale or
   discrimination decision is settled.
3. Keep denominator-aware beta-binomial and zero-one-inflated beta work separate
   from ordinal extensions so their response contracts do not blur.
