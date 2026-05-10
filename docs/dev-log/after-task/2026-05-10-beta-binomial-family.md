# After Task: Beta-Binomial Mean-Overdispersion Family

## Goal

Implement the first denominator-aware response family:
`beta_binomial()` for fixed-effect univariate success counts with known trial
totals.

## Implemented

`beta_binomial()` now fits `cbind(successes, failures)` responses. The model
uses `mu` for success probability and public `sigma` for extra-binomial
variation, with internal precision `phi = 1 / sigma^2`. The builder validates
integer non-negative successes and failures, positive row totals, supported
distributional parameters, complete-case filtering, and unsupported syntax. The
TMB branch uses `model_type = 14`.

Methods now return probability-scale summaries where appropriate:
`fitted()` returns fitted success probabilities, `sigma()` returns
extra-binomial `sigma`, residuals compare observed success proportions with
fitted probabilities, Pearson residuals use the beta-binomial proportion
variance, and `simulate()` returns success counts bounded by the observed trial
totals.

## Mathematical Contract

```text
p_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
y_i | p_i, n_i ~ Binomial(n_i, p_i)
logit(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
phi_i = 1 / sigma_i^2
n_i = successes_i + failures_i
```

Matching R syntax:

```r
drmTMB(
  bf(cbind(successes, failures) ~ habitat, sigma ~ treatment),
  family = beta_binomial(),
  data = dat
)
```

Use `cbind(successes, failures)`, not `cbind(successes, trials)`.
`fitted()` returns the fitted success probability; multiply by the row trial
total for an expected number of successes.

## Files Changed

- `R/family.R`
- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-beta-binomial.R`
- `tests/testthat/test-phylo-utils.R`
- `DESCRIPTION`
- `NAMESPACE`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `_pkgdown.yml`
- `man/beta_binomial.Rd`
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

## Checks Run

```sh
air --version
air format R/drmTMB.R R/family.R R/methods.R tests/testthat/test-beta-binomial.R tests/testthat/test-cumulative-logit.R tests/testthat/test-phylo-utils.R
Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-phylo-utils.R'); testthat::test_file('tests/testthat/test-beta-binomial.R'); testthat::test_file('tests/testthat/test-cumulative-logit.R')"
Rscript -e "devtools::document()"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::build_site()"
Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
rg -n "beta_binomial\\(\\).*planned|planned.*beta_binomial|not implemented.*beta_binomial|cumulative_logit\\(\\).*planned|planned.*cumulative_logit|not implemented.*cumulative_logit|No ordinal likelihood was added|denominator syntax.*not settled|successes, trials|log variance; drmTMB|factor of two|dispersion model is on log variance" README.md ROADMAP.md NEWS.md DESCRIPTION docs/design docs/dev-log/known-limitations.md docs/dev-log/after-task/2026-05-10-location-scale-paper-phase-map.md vignettes R tests man _pkgdown.yml --glob '!docs/dev-log/check-log.md'
rg -n 'beta_binomial|cumulative_logit|sigma\\^2|log-variance|log-`sigma`|variance summaries' pkgdown-site/reference/index.html pkgdown-site/reference/beta_binomial.html pkgdown-site/articles/distribution-families.html pkgdown-site/articles/source-map.html pkgdown-site/articles/which-scale.html pkgdown-site/articles/location-scale.html pkgdown-site/ROADMAP.html pkgdown-site/AGENTS.html
Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
```

Outcomes:

- `air` 0.9.0 is installed and formatting passed.
- focused phylo, beta-binomial, and cumulative-logit tests passed:
  45, 43, and 71 tests respectively.
- `devtools::document()` passed and generated `man/beta_binomial.Rd`.
- final full `devtools::test()` after Air formatting: 1378 passed, 0 failed,
  0 warnings, 0 skips.
- `pkgdown::build_site()` passed and generated
  `pkgdown-site/reference/beta_binomial.html`.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: clean.
- stale-wording scans found expected text only: explicit unsupported-feature
  errors for beta-binomial/cumulative-logit extensions, ordinal-scale
  future-work notes, and the intentional warning not to pass
  `cbind(successes, trials)`.
- `devtools::check(...)`: first rerun found one note from a temporary `tmp`
  directory created for PDF rendering; after removing that directory, the final
  rerun reported 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

- Parameter-recovery tests compare fitted `mu` and `sigma` coefficients with
  simulated truth.
- Independent likelihood tests compare `logLik()` with a direct
  beta-binomial calculation at fitted coefficients.
- Weighted likelihood tests verify that observation weights multiply the
  beta-binomial log-likelihood contribution.
- Method tests check `predict()`, `fitted()`, `sigma()`, response residuals,
  Pearson residuals, `newdata`, and deterministic `simulate()` output.
- Boundary-count tests fit all-failure/all-success patterns and require finite
  likelihood, link predictions, probability predictions, and `sigma`.
- Malformed-input tests reject ordinary proportion responses, unsupported
  `phi`, random effects, random-effect scale formulas, `meta_known_V(V = V)`,
  non-integer counts, and zero-trial rows.

## Consistency Audit

Source docs, generated Rd, README, NEWS, ROADMAP, design notes, vignettes,
known limitations, and source map now describe the same first beta-binomial
scope: one response, fixed effects, `cbind(successes, failures)` syntax, known
row trial totals, `mu` as success probability, and public extra-binomial
`sigma`.

The response contract deliberately keeps denominator-aware counts separate from
strict continuous proportions: use `beta()` for values strictly between 0 and
1, and use `beta_binomial()` for counted successes out of known trials.

## What Did Not Go Smoothly

- The first resumed documentation pass missed stale tutorial wording that still
  described beta-binomial as planned. Pat and Rose flagged that gap.
- Air was initially missing from the local environment. It was installed with
  Homebrew and then used on the touched R and test files.
- A scale-language slip in the location-scale paper phase map overgeneralized
  software parameterizations. The corrected note now requires every comparator
  harness to record package-native parameter, drmTMB parameter, and
  paper-facing variance interpretation separately.

## Team Learning

- Pat should keep checking examples from the user's perspective: `cbind(successes,
  failures)` versus `cbind(successes, trials)` is a small wording issue with a
  large practical cost.
- Gauss and Noether should keep asking whether scale-like parameters are SD,
  variance, precision, shape, or family-specific dispersion before comparator
  claims are made.
- Rose should require generated-site and stale-status checks before a family is
  called closed.

## Known Limitations

- `beta_binomial()` currently supports fixed-effect univariate models only.
- Random effects, known sampling covariance, phylogenetic or spatial terms,
  bivariate or mixed beta-binomial models, and a successes/trials response alias
  remain planned.
- `sigma` is extra-binomial variation via `phi = 1 / sigma^2`; it is not a
  residual SD.

## Next Actions

1. Build and check pkgdown after this after-task report is in place.
2. Add a real or transparent simulated ecology/evolution beta-binomial example
   after the current Phase 9 check loop closes.
3. Keep zero-one-inflated beta work separate from counted-trial beta-binomial
   work.
