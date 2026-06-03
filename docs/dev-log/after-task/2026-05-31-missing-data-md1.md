# After Task: Missing Data MD0 and MD1

## Goal

Start the missing-data lane without opening the later predictor-imputation or
bivariate-partial-pair work. The implemented claim is narrow: `drmTMB()` now
accepts `missing = miss_control(response = "include")` for univariate Gaussian
models with complete predictors, keeps missing-response rows in the fitted
object, and masks their Gaussian response likelihood contribution.

## Implemented

`miss_control()` is exported. Its default `response = "drop"` keeps the
existing complete-case behaviour. `response = "include"` is implemented only for
univariate Gaussian models. `predictor = "model"`, `engine = "em"`, and
`engine = "profile"` are reserved and error clearly.

The Gaussian builder now separates response missingness from model-input
missingness. It builds the response model frame with `na.pass` for MD1, stores
`observed_y`, replaces missing responses with an internal finite sentinel only
after that mask exists, and passes `observed_y` to TMB. The independent
Gaussian likelihood skips rows where `observed_y = 0`.

Gaussian fits now carry `fit$missing_data` with MD1 version, response policy,
predictor policy, engine, `original_row`, `model_row`, `observed_y`, counts, and
sentinel metadata. `nobs()` remains the likelihood-contributing count.
`fitted()` can return retained rows, and response/Pearson residuals are `NA` for
masked responses.

## Mathematical Contract

For the independent univariate Gaussian row likelihood, MD1 evaluates:

```text
nll = sum_i observed_y_i w_i {-log Normal(y_i | mu_i, V_i + sigma_i^2)}
```

Rows with `observed_y_i = 0` contribute zero direct response likelihood. Dense
known sampling covariance is not included because a dense `meta_V(V = V)` route
is one joint multivariate block and needs component-level slicing before partial
rows are safe.

## Files Changed

- `R/missing-data.R`
- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-missing-data-control.R`
- `tests/testthat/test-missing-response-gaussian.R`
- `tests/testthat/test-phylo-utils.R`
- `docs/design/149-missing-data-design.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `NEWS.md`
- `_pkgdown.yml`
- `man/miss_control.Rd`
- `man/drmTMB.Rd`
- `NAMESPACE`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript --vanilla -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-gaussian.R')"
Rscript --vanilla -e "devtools::load_all(); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"
Rscript --vanilla -e "devtools::test()"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

Outcomes:

- `devtools::document()` completed and generated `man/miss_control.Rd`.
- `test-missing-data-control.R` passed with 11 expectations.
- `test-missing-response-gaussian.R` passed with 32 expectations.
- `test-gaussian-location-scale.R` passed with 79 expectations and one CRAN
  skip.
- `devtools::test()` passed on the final tree with 8,654 expectations.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` passed.

## Tests Of The Tests

The new tests check both the positive and negative boundaries. They verify
default no-op complete-case behaviour, reserved `miss_control()` options,
non-Gaussian rejection, original-row accounting, residual masking, missing
predictor rejection under `predictor = "fail"`, and equality with an explicit
complete-case Gaussian fit for the observed rows.

The sentinel test runs the same masked fit with sentinel values `0` and `1e6`.
It checks invariant log-likelihoods, coefficients, gradients, and observed-row
fitted values. The same sentinel test also includes an ordinary Gaussian random
intercept, so it exercises the initialization and AD paths that could otherwise
accidentally read the sentinel.

## Consistency Audit

The status scan was:

```sh
rg -n "miss_control|response = \"include\"|observed_y|missing response|missing-data|mi\\(|predict_missing|imputed\\(|measurement error|engine = \"em\"|engine = \"profile\"" README.md ROADMAP.md NEWS.md docs vignettes R man tests _pkgdown.yml
```

The scan found the new implementation, tests, design notes, generated manual
pages, NEWS entry, and pkgdown reference entry. It also found historical
after-task notes that correctly described the earlier design-only state; those
were left as history rather than rewritten.

## GitHub Issue Maintenance

I searched for overlapping open issues:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "missing data miss_control mi impute complete-case" --limit 20
```

No matching open issue was returned, so I did not comment on or close an issue
from this implementation pass.

## What Did Not Go Smoothly

Adding an argument named `missing` exposed a real R footgun: the previous
`missing(weights)` call would resolve against the new argument name. The fix is
explicit `base::missing(weights)`.

The C++ template now requires `observed_y` for every direct TMB data list. Most
fit paths receive it through the normal TMB data builder; the isolated
phylogenetic-prior test helper also needed a dummy `observed_y = 1L`.

## Team Learning

Claude's sentinel warning was the right one. The test should not only compare
log-likelihoods after a fixed-effect fit; it should also cover gradients and a
neighbouring random-effect path so initialization and AD branches cannot read
the sentinel accidentally.

## Known Limitations

MD1 does not implement missing predictors, `mi()`, `predict_missing()`,
`imputed()`, EM, REML, bivariate partial response pairs, dense known-`V`
partial-row slicing, or measurement-error models. `nobs()` intentionally reports
the likelihood-contributing response count, not the retained row count.

## Next Actions

The next missing-data slice should be MD2: bivariate Gaussian response patterns
with row-pattern counts, both-responses-missing rows retained with zero response
likelihood, and a warning when complete pairs are too scarce to identify
`rho12`. Missing predictors should wait for the MD3a fixed-only `mi()` slice,
then MD3b grouped covariate models.
