# After Task: Zero-Inflated Poisson

## Goal

Implement fixed-effect zero-inflated Poisson models as an extension of the
ordinary Poisson route, using `zi ~ predictors` rather than a new
`zi_poisson()` family constructor.

## Implemented

- `drmTMB(drm_formula(count ~ x, zi ~ z), family = poisson(link = "log"))`
  now fits a univariate fixed-effect zero-inflated Poisson model.
- The TMB template has a new `model_type = 8` branch with conditional
  `mu = exp(X_mu beta_mu)` and structural-zero probability
  `zi = logit^{-1}(X_zi beta_zi)`.
- `predict(dpar = "mu")` returns the conditional Poisson mean.
- `predict(dpar = "zi")` returns the structural-zero probability.
- `fitted()` returns the unconditional response mean `(1 - zi) * mu`.
- `simulate()`, `residuals()`, `sigma()`, link helpers, `coef()`, and print
  output now handle the zero-inflated Poisson path.
- Unsupported offsets are rejected instead of silently ignored.
- `zi ~ 0` is rejected because it would create a zero-column parameter block.

## Mathematical Contract

For observation `i`:

```text
y_i | mu_i, zi_i ~ ZIP(mu_i, zi_i)
log(mu_i) = X_mu[i, ] beta_mu
logit(zi_i) = X_zi[i, ] beta_zi

Pr(y_i = 0) = zi_i + (1 - zi_i) exp(-mu_i)
Pr(y_i = y > 0) = (1 - zi_i) Poisson(y | mu_i)
E[y_i] = (1 - zi_i) mu_i
Var[y_i] = (1 - zi_i) mu_i (1 + zi_i mu_i)
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat, zi ~ survey_method),
  family = poisson(link = "log"),
  data = dat
)
```

The implementation, equations, tests, README, and vignettes all use this same
contract.

## Files Changed

- `src/drmTMB.cpp`
- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-zi-poisson.R`
- `tests/testthat/test-poisson-mean.R`
- `tests/testthat/test-family-link-contract.R`
- `tests/testthat/test-phylo-utils.R`
- `man/fitted.drmTMB.Rd`
- `man/residuals.drmTMB.Rd`
- `man/sigma.drmTMB.Rd`
- `man/simulate.drmTMB.Rd`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`

## Checks Run

```sh
R -q -e 'devtools::load_all(recompile = TRUE)'
R -q -e 'devtools::test(filter = "zi-poisson|family-link-contract")'
R -q -e 'devtools::test(filter = "zi-poisson|poisson-mean|family-link-contract")'
R -q -e 'devtools::document()'
R -q -e 'devtools::test()'
R -q -e 'pkgdown::check_pkgdown()'
R -q -e 'pkgdown::build_site()'
R -q -e 'devtools::check()'
git diff --check
```

Results:

- targeted ZIP/link tests: 78 passed before review additions;
- targeted count/link tests after review additions: 120 passed;
- full `devtools::test()`: 912 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

## Tests Of The Tests

- The recovery test simulates known `mu` and `zi` coefficients and checks both
  blocks.
- The likelihood test compares the TMB log-likelihood to an independent ZIP
  calculation.
- Boundary tests check `zi -> 0` against a Poisson likelihood and `zi -> 1`
  with stable log-space mixture algebra.
- Method tests verify `predict()`, `fitted()`, `residuals()`, `sigma()`,
  `simulate()`, and `newdata` prediction.
- Failure-path tests cover duplicate `zi`, two-sided `zi`, unsupported random
  terms inside both `mu` and `zi`, offsets, `zi ~ 0`, `meta_known_V()`,
  `sd(id)`, `mvbind()`, and non-integer counts.

## Consistency Audit

Stale-wording searches:

```sh
rg -n 'zi_poisson\(\)|Poisson.*zero inflation.*later|mu-only|Only `mu`|No overdispersion, zero inflation|no zero inflation' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes man pkgdown-site --glob '!pkgdown-site/search.json'
```

The remaining `zi_poisson()` hits are intentional statements that no public
constructor exists. Remaining "zero inflation later" hits refer to NB2 or
historical after-task/check-log entries, not current Poisson documentation.

## What Did Not Go Smoothly

- The first high-`zi` boundary test used a naive probability-scale comparator
  and failed by about 0.002 because of precision loss near `zi = 1`. The test
  was changed to use the same log-space mixture algebra as the likelihood.
- The first full test run failed because the hidden phylogenetic TMB parity
  helper did not supply the new dummy `X_zi` data field. The second run then
  failed because the same helper also needed a dummy `beta_zi` parameter.
- Poincare caught that offsets were accepted but ignored. This is now a general
  Phase 1 formula rejection until offset handling is deliberately implemented.

## Team Learning

- New global TMB data or parameter declarations must be propagated to all
  direct `MakeADFun()` helpers, not just ordinary model builders.
- Reviewers should explicitly look for base-R formula features that disappear
  during `model.matrix()` construction.
- Mixture-family tests should include both boundary directions and use
  numerically stable comparator algebra.

## Known Limitations

- The zero-inflated Poisson path is fixed-effect and univariate only.
- No random effects, overdispersion, hurdle component, known sampling
  covariance, phylogenetic/spatial structured effects, bivariate count model,
  or mixed composed count model is implemented for this route.
- Offsets are rejected rather than supported.

## Next Actions

- Add zero-inflated NB2 using the same `zi ~ predictors` grammar.
- Decide whether count offsets should be implemented across Poisson, ZIP, NB2,
  and future COM-Poisson families.
- Add external comparator checks against `glmmTMB` for ZIP and NB2 when the
  dependency strategy is settled.
