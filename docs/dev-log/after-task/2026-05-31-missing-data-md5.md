# After Task: Missing Data MD5

Date: 2026-05-31

## Goal

Expose fitted missing-predictor summaries for the already implemented MD3a and
MD3b likelihoods without opening response imputation, simulated imputations,
posterior terminology, EM, REML, measurement-error models, or structured
covariate models.

## Implemented

`imputed()` is now an exported S3 generic with a `drmTMB` method. For a fitted
univariate Gaussian `mi(x)` model, it returns the retained-row identity,
original-row identity, observed/missing indicator, fitted estimate, optional
standard error, source label, and uncertainty status.

For missing predictor rows, `estimate` is the conditional mode of the TMB
`x_miss` random effect. When `TMB::sdreport()` is available, `std_error` is the
likelihood-based conditional standard error from `diag.cov.random`. For
observed predictor rows returned by `rows = "all"`, `estimate` is the observed
predictor value and `std_error` is `NA`.

The fitted object now stores `value` and `conditional_mode` inside
`fit$missing_data$predictors[[x]]`. This lets `imputed()` report fitted
conditional modes even when `drm_control(keep_tmb_object = FALSE)` drops the
TMB object after fitting. If `sdreport()` was skipped or failed, `std_error` is
`NA` and `uncertainty_status` records the fitted uncertainty state.

## Mathematical Contract

MD5 does not change the likelihood. It reads the optimized conditional modes
from the existing MD3a/MD3b joint likelihood:

```text
L(theta) =
  integral p(y_obs | x_obs, x_mis, theta_y)
           p(x_obs, x_mis | theta_x)
           d x_mis
```

For MD3b, the grouped covariate random intercepts are already part of
`theta_x` and the Laplace approximation. `imputed()` reports the fitted
conditional mode of each missing `x_i`; it does not report posterior means,
credible intervals, simulated draws, or multiple-imputation pooled estimates.

## Files Changed

- `R/missing-data.R`: `imputed()` generic/method, conditional-mode finalization,
  and random-effect standard-error extraction.
- `R/drmTMB.R`: finalizes `fit$missing_data` after optimization so fitted
  missing-predictor modes are stored in the fit object.
- `tests/testthat/test-missing-predictor-gaussian.R`: MD5 extractor tests for
  fixed-effect MD3a, grouped MD3b, all-row output, no retained TMB object, and
  unsupported response-only or unknown-variable calls.
- `man/imputed.Rd`, `NAMESPACE`, and `_pkgdown.yml`: generated docs and
  reference-index entry.
- `docs/design/149-missing-data-design.md`, `docs/design/03-likelihoods.md`,
  `docs/design/01-formula-grammar.md`, and `NEWS.md`: fitted MD5 boundary.

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-biv-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-package-skeleton.R')"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
```

Final results:

- `test-missing-predictor-gaussian.R`: 85 expectations, no failures.
- `test-missing-data-control.R`: 13 expectations, no failures.
- `test-missing-response-gaussian.R`: 32 expectations, no failures.
- `test-missing-response-biv-gaussian.R`: 45 expectations, no failures.
- `test-package-skeleton.R`: 100 expectations, no failures.
- `devtools::test()`: 8,786 expectations, no failures, warnings, or skips.
- `pkgdown::check_pkgdown()`: no problems found.

## Tests Of The Tests

The MD5 tests compare `imputed(fit)$estimate` directly with
`fit$obj$env$parList(fit$opt$par)$x_miss`, so the extractor is tied to the TMB
conditional modes rather than to starts or model-frame placeholders. The tests
also confirm finite `sdreport()` standard errors, `NA` standard errors when
`sdreport()` is skipped, and unchanged estimates when the TMB object is dropped
from the fitted object.

## Consistency Audit

The public and design wording now says `imputed()` is implemented only for
fitted MD3a/MD3b `mi()` predictors. The stale-wording scan:

```sh
rg -n "imputation summaries remain planned|imputed\\(\\).*planned|MD5|posterior|credible intervals|multiple-imputation|simulation-based imputed|response imputation|conditional modes|likelihood-based conditional" R man NEWS.md README.md ROADMAP.md docs/design vignettes docs/dev-log/known-limitations.md
```

found current MD5 implementation wording, intentional non-Bayesian boundary
wording, and unrelated posterior/interval cautions outside the missing-data
lane. No current missing-data doc claims response imputation, simulated
imputations, multiple-imputation pooling, or posterior summaries are
implemented.

## GitHub Issue Maintenance

These searches returned no matching open issues, so no issue comment or closure
was made:

```sh
gh issue list --repo itchyshin/drmTMB --search "imputed missing predictor imputation summaries" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing data imputed conditional modes" --limit 20
```

## What Did Not Go Smoothly

The main design choice was whether `imputed()` should require a retained TMB
object. Storing fitted missing-predictor modes in `fit$missing_data` is the
better extractor contract: users can reduce object size with
`keep_tmb_object = FALSE` and still inspect fitted missing values. Standard
errors still depend on `sdreport()`, so skipped or failed uncertainty stays
visible as `NA` rather than being silently invented.

## Team Learning

Emmy's architecture check is that missing-data summaries belong in
`fit$missing_data`, not only in `fit$obj`, because object-storage controls can
drop the TMB object. Fisher's inference check is that the column names and docs
say `conditional_mode` and `std_error`; they do not imply posterior draws,
credible intervals, or multiple imputation.

## Known Limitations

MD5 does not implement structured `mi()` covariate models, dense known-`V`
partial-response slicing, covariate random slopes, multiple covariate
random-effect terms, multiple missing predictors, factor or non-Gaussian
predictor models, transformed or interacted `mi()` terms, response imputation
summaries, simulated imputations, EM/profile engines, REML, measurement-error
models, or pigauto interoperability.

## Next Actions

The remaining named missing-data implementation slice is MD4: explicit
structured covariate models for `mi()` using `phylo()`, `spatial()`,
`animal()`, or `relmat()` when the missing predictor lives at that level. That
slice should start with one tiny structured route and its malformed-input tests,
not automatic inheritance from response-model structure.
