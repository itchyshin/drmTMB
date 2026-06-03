# After Task: Missing Data MD7b Poisson Count Predictor

## Goal

Extend the non-Gaussian missing-predictor lane to one count predictor, so the
missing-data API no longer treats counts as if they had to be Gaussian.

## Implemented

MD7b adds `poisson(link = "log")` as a predictor-model family for
`impute_model()` when the first `mi()` predictor is a non-negative integer
count. The fitted public syntax is:

```r
drmTMB(
  bf(y ~ z + mi(abundance), sigma ~ 1),
  data = dat,
  impute = list(
    abundance = impute_model(abundance ~ z, family = poisson())
  ),
  missing = miss_control(predictor = "model")
)
```

The route accepts one fixed-effect Poisson predictor model with complete
imputation-model covariates. It rejects negative counts, fractional counts,
non-finite counts, grouped or structured Poisson predictor models, multiple
`mi()` predictors, and transformed or interacted `mi()` terms.

## Mathematical Contract

For observed counts \(x_i \in \{0, 1, 2, \ldots\}\), the predictor model is:

\[
\log(\lambda_i) = W_i \alpha,\qquad x_i \sim \mathrm{Poisson}(\lambda_i).
\]

Observed predictor rows add the Poisson predictor density and the Gaussian
response density:

\[
\log f_\mathrm{Pois}(x_i; \lambda_i)
  + \log f_N(y_i; \mu_i(x_i), \sigma_i).
\]

Missing predictor rows with observed responses use deterministic finite
summation over \(k = 0,\ldots,K\):

\[
\log \sum_{k=0}^K
  f_\mathrm{Pois}(k; \lambda_i)
  f_N(y_i; \mu_i(k), \sigma_i).
\]

Rows where both the response and the count predictor are missing are retained
for row accounting but contribute no observed-data likelihood.

## Files Changed

- `R/missing-data.R`: Poisson family dispatch, count validation, finite count
  support construction, model building, TMB data plumbing, and `imputed()`
  conditional expected counts.
- `R/drmTMB.R`: public argument documentation, dense known-`V` guard, and MD7b
  version tagging.
- `src/drmTMB.cpp`: `mi_family == 5` Poisson finite-sum likelihood branch.
- `tests/testthat/test-missing-predictor-poisson.R`: independent likelihood,
  response-mask combination, and boundary tests.
- `tests/testthat/test-missing-predictor-binary.R`: old unsupported-family
  boundary now uses `nbinom2()` because `poisson()` is implemented.
- `vignettes/missing-data.Rmd`, `NEWS.md`, `docs/design/01-formula-grammar.md`,
  `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: public and design docs.
- `man/drmTMB.Rd`, `man/miss_control.Rd`, `man/impute_model.Rd`, and
  `man/imputed.Rd`: roxygen outputs.

## Checks Run

```sh
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-poisson.R')"
air format R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-poisson.R
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-poisson.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-beta.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-categorical.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-ordered.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-binary.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-gaussian.R')"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript -e "devtools::load_all(); devtools::test()"
```

Results:

- Initial `test-missing-predictor-poisson.R`: 19 expectations, no failures,
  warnings, or skips.
- Post-document `test-missing-predictor-poisson.R`: 19 expectations, no
  failures, warnings, or skips.
- `test-missing-predictor-beta.R`: 20 expectations, no failures, warnings, or
  skips.
- `test-missing-predictor-categorical.R`: 24 expectations, no failures,
  warnings, or skips.
- `test-missing-predictor-ordered.R`: 23 expectations, no failures, warnings,
  or skips.
- `test-missing-predictor-binary.R`: 21 expectations, no failures, warnings,
  or skips after updating the unsupported-family boundary from `poisson()` to
  `nbinom2()`.
- `test-missing-predictor-gaussian.R`: 109 expectations, no failures,
  warnings, or skips.
- `test-missing-data-control.R`: 13 expectations, no failures, warnings, or
  skips.
- `test-missing-response-gaussian.R`: 32 expectations, no failures, warnings,
  or skips.
- `pkgdown::build_article('missing-data', new_process = FALSE)` rebuilt
  `pkgdown-site/articles/missing-data.html`; the rendered page contains the
  count predictor example and conditional-expected-count wording.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: no whitespace errors.
- Full `devtools::test()`: 8,917 expectations, no failures, warnings, or
  skips; duration 717.9 seconds.

## Tests Of The Tests

The Poisson predictor test independently recomputes `logLik(fit)` from the
Poisson predictor likelihood and Gaussian response likelihood. For missing
predictor rows it recomputes the same deterministic finite count-state sum used
by TMB, including the case where the response is also missing and therefore
contributes no observed-data likelihood.

Boundary tests reject negative observed counts, fractional observed counts, and
grouped Poisson predictor models.

## Consistency Audit

Stale wording scans:

```sh
rg -n "Count predictors,|count predictors.*not implemented|count predictors remain planned|family = poisson\\(\\).*planned|MD7b|Poisson count missing predictors|conditional expected counts|Negative-" vignettes/missing-data.Rmd docs/design/149-missing-data-design.md docs/design/03-likelihoods.md docs/design/01-formula-grammar.md NEWS.md R man pkgdown-site/articles/missing-data.html
rg -n "Count missing predictors|impute_model\\(abundance ~ z, family = poisson\\(\\)\\)|conditional expected count|MD7b|negative-binomial" pkgdown-site/articles/missing-data.html
```

The scans found current implementation wording for Poisson count predictors,
historical MD6/MD7a boundary text that explicitly points to later MD7b, and
remaining-boundary wording for negative-binomial count predictors,
positive-continuous non-Gaussian predictor models, grouped/structured count
predictor models, and multiple missing predictors.

## GitHub Issue Maintenance

Issue searches:

```sh
gh issue list --repo itchyshin/drmTMB --search "poisson count missing predictor impute_model" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing predictor count" --limit 20
gh issue list --repo itchyshin/drmTMB --search "negative binomial missing predictor" --limit 20
```

The exact Poisson and negative-binomial searches returned no open issue rows.
The broad count search returned only #436, the four-week Phase 6c random-slope
and digital-twin exchange sprint, so no missing-data-specific issue comment or
closure was made.

## What Did Not Go Smoothly

The first neighbour-test run caught one stale assumption in the MD6a binary
test: it expected `impute_model(..., family = poisson())` to error. That was a
good drift catch rather than a product problem. The test now checks `nbinom2()`
as the unsupported count-family boundary.

## Team Learning

When a planned family becomes implemented, boundary tests in earlier slices
should be searched for that family name. Otherwise the old failure-path test
becomes a false regression signal.

## Known Limitations

MD7b is one fixed-effect Poisson count predictor in a univariate Gaussian
location model. It does not handle negative-binomial or overdispersed count
predictor models, grouped or structured count predictor models, multiple
missing predictors, transformed or interacted `mi()` terms, exact 0/1
proportions, denominator-aware beta-binomial predictor models, EM/profile
engines, REML, simulation-based imputed summaries, response imputation,
measurement-error models, or pigauto interoperability.

## Next Actions

The next missing-predictor slice should either add negative-binomial count
predictors, using the existing Poisson count-state machinery plus a dispersion
parameter, or positive-continuous predictors such as lognormal/Gamma, using a
carefully reviewed quadrature or Laplace route.
