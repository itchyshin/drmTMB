# After Task: Zero-Inflated NB2 Distributional Parameter

## Goal

Add fixed-effect zero-inflated negative-binomial 2 models without adding a new
public family constructor.

## Implemented

- `family = nbinom2()` now supports `zi ~ predictors`.
- The model type is internal: `zi_nbinom2`.
- The TMB routing integer is `model_type = 9`.
- `predict(fit, dpar = "mu")` returns the conditional NB2 count mean.
- `sigma(fit)` returns the conditional NB2 overdispersion scale.
- `predict(fit, dpar = "zi")` returns the structural-zero probability.
- `fitted(fit)` returns the unconditional response mean `(1 - zi) * mu`.
- `simulate()` and `residuals()` have zero-inflated NB2 branches.

## Mathematical Contract

For observation `i`:

```text
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
logit(zi_i) = X_zi[i, ] beta_zi
size_i = 1 / sigma_i^2
```

The count component is:

```text
Y_i | count component ~ NB2(mu_i, size_i)
E[Y_i | count component] = mu_i
Var[Y_i | count component] = mu_i + sigma_i^2 * mu_i^2
```

The zero-inflated mixture is:

```text
Pr(Y_i = 0) = zi_i + (1 - zi_i) * NB2(0 | mu_i, sigma_i)
Pr(Y_i = y > 0) = (1 - zi_i) * NB2(y | mu_i, sigma_i)
E[Y_i] = (1 - zi_i) * mu_i
```

The implementation evaluates the zero case with `logspace_add()` rather than
probability-scale addition.

## Files Changed

- `src/drmTMB.cpp`
- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-zi-nbinom2.R`
- `tests/testthat/test-family-link-contract.R`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`
- generated Rd files from `devtools::document()`

## Checks Run

- `air format .` failed because `air` is not installed locally.
- `R -q -e 'devtools::document()'`
- `R -q -e 'devtools::test(filter = "zi-nbinom2|nbinom2|family-link-contract")'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `git diff --check`

Results:

- targeted tests: 135 passed, 0 failed, 0 warnings, 0 skips;
- full tests: 966 passed, 0 failed, 0 warnings, 0 skips;
- pkgdown check: no problems found;
- pkgdown site build: successful;
- R CMD check: 0 errors, 0 warnings, 0 notes;
- whitespace check: clean.

## Tests Of The Tests

- Parameter recovery simulates known `mu`, `sigma`, and `zi` coefficients with
  continuous and factor predictors.
- The objective is compared against an independent zero-inflated NB2
  likelihood based on `stats::dnbinom()`.
- Boundary tests verify `zi -> 0` convergence to plain NB2 and `zi -> 1`
  log-space stability.
- Complete-case filtering is checked for predictors unique to the `zi`
  formula.
- Malformed-input tests cover duplicate `zi`, two-sided `zi`, random terms,
  offsets, `zi ~ 0`, `meta_known_V()`, `sd(id)`, `mvbind()`, and non-integer
  counts.

## Consistency Audit

Stale-wording searches:

```sh
rg -n "zero inflation.*NB2|zero inflation.*negative|zero-inflated NB2.*planned|NB2.*zero inflation.*not|zero-inflated negative|zi_nbinom2\(\)" README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'
rg -n "model_type = 8|model_type = 9|zi_nbinom2|zi_poisson|X_zi|beta_zi" R src tests docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'
```

The active docs now state that zero-inflated NB2 is implemented through
`family = nbinom2()` plus `zi ~ predictors`. Remaining `zi_nbinom2()` hits are
intentional statements that no public constructor exists. Historical after-task
notes were not edited when they were true at the time they were written.

## What Did Not Go Smoothly

- The first implementation was code-complete before public roxygen and
  source-map pages were fully synchronized. Copernicus caught this before
  closeout.
- The local `r-package-development` skill asks for `air format .`, but `air`
  is not installed in this environment.
- The recovery test needed a larger sample size than the plain NB2 test because
  `mu`, `sigma`, and `zi` share information about zeros.

## Team Learning

- For count-mixture families, the minimum reliable test bundle is simulation
  recovery, independent likelihood comparison, both mixture-boundary checks,
  complete-case filtering, and malformed-input tests.
- API consistency is clearer when zero inflation is expressed as an added
  distributional parameter rather than a new family constructor.
- Rose's audit should explicitly search generated pkgdown pages after every
  family-route change.

## Known Limitations

- Fixed-effect and univariate only.
- No random effects, hurdle component, known sampling covariance,
  phylogenetic/spatial structured effects, bivariate count model, or mixed
  composed count model yet.
- Offsets are rejected rather than implemented.

## Next Actions

- Monitor GitHub Actions after push.
- Decide whether the next count-family slice should be COM-Poisson,
  hurdle/truncated counts, or count-family comparator documentation.
- Consider adding a lightweight formatter availability note to the local
  R-package skill or project setup docs.
