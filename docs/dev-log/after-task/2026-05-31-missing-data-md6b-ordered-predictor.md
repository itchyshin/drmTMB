# After Task: Missing Data MD6b Ordered Predictor

## Goal

Implement the first ordered categorical missing-predictor route without
broadening the missing-data interface beyond one fixed-effect finite-state
predictor in a univariate Gaussian location model.

## Implemented

- `impute_model(score ~ z, family = cumulative_logit())` is now accepted for
  one ordered `mi(score)` predictor.
- Ordered missing predictors are integrated by exact finite-state summation in
  TMB rather than by treating category scores as Gaussian values.
- `fit$missing_data$version` records `"MD6b"` for the route.
- `imputed()` reports fitted conditional expected ordered-category scores, and
  `fit$missing_data$predictors[[name]]$conditional_probabilities` stores level
  probabilities for missing ordered predictor rows.

## Mathematical Contract

For an ordered missing predictor with predictor-design row `W_i`, the
predictor model is:

```text
Pr(x_i <= k) = logit^-1(c_k - W_i alpha)
c_1 < c_2 < ... < c_{K-1}
```

Observed ordered predictors contribute:

```text
log p_ord(x_i | W_i alpha, c)
  + observed_y_i log p(y_i | mu_i(x_i), sigma_i)
```

Missing ordered predictors contribute:

```text
logsumexp_k(
  log p_ord(k | W_i alpha, c)
  + observed_y_i log p(y_i | mu_i(k), sigma_i)
)
```

When both the response and ordered predictor are missing, the response term is
zero and the ordered probabilities sum to one; the row is retained for
accounting but adds no direct likelihood.

## Files Changed

- `R/missing-data.R`
- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-missing-predictor-ordered.R`
- `tests/testthat/test-phylo-utils.R`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/149-missing-data-design.md`
- `vignettes/missing-data.Rmd`
- `man/impute_model.Rd`
- `man/imputed.Rd`
- `man/miss_control.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-ordered.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-binary.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-phylo-utils.R')"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript -e "devtools::test()"
```

Results:

- Ordered targeted test: 23 expectations, no failures, warnings, or skips.
- Binary targeted test: 21 expectations, no failures, warnings, or skips.
- Gaussian missing-predictor targeted test: 109 expectations, no failures,
  warnings, or skips.
- Missing-data control targeted test: 13 expectations, no failures, warnings,
  or skips.
- `test-phylo-utils.R`: 79 expectations, no failures, warnings, or skips.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: no whitespace errors.
- Full `devtools::test()`: 8,854 expectations, no failures, warnings, or
  skips.

## Tests Of The Tests

- The ordered test independently recomputes the likelihood using
  cumulative-logit category probabilities and Gaussian response densities, then
  compares it to `logLik(fit)`.
- The same test combines ordered missing predictors with missing responses.
- Boundary tests cover unordered factor inputs, grouped cumulative-logit
  predictor models, and empty observed ordered categories.

## Consistency Audit

- The formula grammar table now has an explicit ordered `mi(score)` row using
  `impute_model(score ~ z, family = cumulative_logit())`.
- The likelihood design note now describes MD6b with equations, R syntax, and
  the `X_mi_state_mu` state-design reason.
- The missing-data design note now has an MD6b fitted slice and updated
  implementation table.
- The missing-data article now distinguishes binary and ordered finite-state
  predictor models from future unordered, proportion, count, and positive
  continuous families.
- The generated article was rebuilt at
  `pkgdown-site/articles/missing-data.html`.

## GitHub Issue Maintenance

Issue searches for ordered missing predictors and categorical missing
predictors returned no dedicated open issue. A broader non-Gaussian
missing-predictor search surfaced only #436, the broad Phase 6c sprint tracker,
so no issue comment or closure was made.

## What Did Not Go Smoothly

The dirty worktree includes many unrelated Phase 18, structured-effect, and
article changes. The MD6b audit therefore records focused files and commands
rather than treating `git status` as a clean task boundary.

## Team Learning

Family-aware `impute_model()` is the right extension point for non-Gaussian
missing predictors. The response formula names where the missing predictor is
used; the `impute` entry names the model for that predictor.

## Known Limitations

- Only one ordered missing predictor is supported.
- The ordered predictor model is fixed-effect cumulative logit only.
- The response model is univariate Gaussian location only.
- Unordered multinomial, beta/proportion, count, lognormal/Gamma positive
  continuous, grouped finite-state, structured finite-state, and multiple
  missing-predictor routes remain planned.
- `imputed()` reports fitted conditional summaries, not posterior draws,
  credible intervals, or multiple-imputation pools.

## Next Actions

- Decide whether unordered multinomial or proportion predictors should be MD6c.
- Keep family-specific slices small, with an independent likelihood
  recomputation test for each new missing-predictor family.
- Coordinate the same `impute_model(formula, family = ...)` contract with
  `gllvmTMB` before implementing parallel syntax there.
