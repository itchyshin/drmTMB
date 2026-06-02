# Missing Data MD3a After-Task Report

Date: 2026-05-31

## Task

Open the first missing-predictor route after MD1/MD2 without broadening the
missing-data API beyond the accepted plan. The fitted slice is one numeric
missing predictor in a univariate Gaussian location formula:

```r
drmTMB(
  bf(y ~ z + mi(x), sigma ~ 1),
  data = dat,
  impute = list(x = x ~ z),
  missing = miss_control(predictor = "model")
)
```

## What Changed

- Added the public `mi()` formula marker and `impute` argument to `drmTMB()`.
- Allowed `miss_control(predictor = "model")` for the univariate Gaussian
  MD3a route while keeping EM/profile engines reserved.
- Added R-side validation for exactly one additive bare numeric `mi(x)` term, a
  matching one-element `impute` list, complete ordinary predictors, complete
  `impute` predictors, no response variable in the predictor model, no `.` RHS,
  no sparse fixed-effect matrices, and no Gaussian aggregation.
- Added TMB data and parameters for the fixed-effect Gaussian predictor model:
  `beta_mi`, `log_sigma_mi`, and random `x_miss` modes. Missing `x` values are
  integrated by TMB/Laplace; observed `x` values contribute their predictor
  density.
- Extended `fit$missing_data` to version `MD3a` with predictor metadata,
  including model rows, original rows, observed/missing counts, formula text,
  and coefficient names.
- Added generated documentation for `mi()`, updated `drmTMB()` and
  `miss_control()` docs, and added `mi` to the pkgdown reference index.

## Likelihood Review

Gauss/Noether check: positive predictor scale is represented as
`log_sigma_mi`, and the C++ branch transforms it with `exp()`. The predictor
likelihood includes the Gaussian normalizing constant through `dnorm(...,
true)`. The response mean subtracts the placeholder `X_mu[, mi_col]` and adds
the observed or latent `x_i`, so the placeholder used for R's model matrix is
not the statistical predictor. `TMB::sdreport()` completed on a small MD3a fit
with `fit$uncertainty$status == "ok"`.

Fisher/Curie check: deterministic tests now cover row retention, metadata,
response-mask combination, invalid syntax, missing ordinary predictors, missing
imputation predictors, non-Gaussian runtime guards, direct TMB scaffold
synchronization, and full-suite regression. A broader simulation-recovery
battery remains needed before making a recovery-accuracy claim for missing
predictor slopes or conditional modes.

## Documentation Review

Pat/Rose check: the docs now call this a joint observed-data likelihood, not
multiple imputation. `docs/design/149-missing-data-design.md` and
`docs/design/03-likelihoods.md` state that `imputed()` summaries, grouped
covariate random effects, structured covariate models, multiple missing
predictors, and measurement-error models remain planned.

## Verification

Commands run:

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-biv-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-biv-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-phylo-utils.R')"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Final results:

- `test-missing-data-control.R`: 13 expectations, no failures.
- `test-missing-predictor-gaussian.R`: 35 expectations, no failures.
- `test-missing-response-gaussian.R`: 32 expectations, no failures.
- `test-gaussian-location-scale.R`: 71 expectations plus the existing CRAN
  skip, no failures.
- `test-missing-response-biv-gaussian.R`: 45 expectations, no failures.
- `test-biv-gaussian.R`: 718 expectations, no failures.
- `test-phylo-utils.R`: 79 expectations, no failures after adding the dummy
  MD3a TMB data/parameter fields to direct TMB probe objects.
- Final `devtools::test()`: 8,736 expectations, no failures, warnings, or
  skips.
- `pkgdown::check_pkgdown()`: no problems found after indexing `mi`.
- `git diff --check`: passed.

## Remaining Work

MD3b should add one grouped Gaussian covariate model, for example
`impute = list(x = x ~ 1 + z + (1 | group))`. MD4 should add explicit
structured covariate models such as `phylo()` or `spatial()` only after their
own validation. MD5 should add `imputed()` summaries with likelihood-based
conditional modes and standard errors, without posterior terminology. Dense
known-`V` partial-response slicing, EM/profile engines, REML,
measurement-error models, multiple missing predictors, factor or non-Gaussian
predictor models, transformed/interacted `mi()` terms, and pigauto
interoperability remain out of scope.
