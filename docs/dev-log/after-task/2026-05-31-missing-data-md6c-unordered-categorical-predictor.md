# After Task: Missing Data MD6c Unordered Categorical Predictor

## Goal

Extend the missing-predictor lane beyond Gaussian, binary, and ordered
predictors by fitting one unordered categorical `mi()` predictor in a
univariate Gaussian location model.

## Implemented

MD6c adds `categorical()` as a predictor-model family for `impute_model()`.
The fitted public syntax is:

```r
drmTMB(
  bf(y ~ z + mi(habitat), sigma ~ 1),
  data = dat,
  impute = list(
    habitat = impute_model(habitat ~ z, family = categorical())
  ),
  missing = miss_control(predictor = "model")
)
```

The route accepts unordered factors, character predictors, and numeric or
integer category scores with at least three observed levels. It rejects ordered
factors, two-level predictors sent to `categorical()`, missing imputation-model
covariates, grouped or structured unordered predictor models, and categories
with no observed values.

## Mathematical Contract

For unordered states \(s = 1,\ldots,K\), the first level is the baseline:

\[
\eta_{i1} = 0,\qquad \eta_{is} = W_i \alpha_s \quad s > 1,
\]

\[
\Pr(x_i = s) =
  \frac{\exp(\eta_{is})}{\sum_{r = 1}^K \exp(\eta_{ir})}.
\]

Observed predictor rows add `log Pr(x_i = observed state)` and the Gaussian
response density. Missing predictor rows use exact summation:

\[
\log \sum_{s=1}^K
  \Pr(x_i = s)\,
  p(y_i \mid \mu_i(x_i = s), \sigma_i),
\]

with the response density omitted when the response is also missing.

## Files Changed

- `R/missing-data.R`: `categorical()`, model building, finite-state design
  handling, finalization, and `imputed()` metadata for unordered categorical
  missing predictors.
- `R/drmTMB.R`: public argument documentation and MD6c version tagging.
- `src/drmTMB.cpp`: `mi_family == 3` baseline-softmax likelihood branch.
- `tests/testthat/test-missing-predictor-categorical.R`: independent
  likelihood, response-mask combination, and boundary tests.
- `vignettes/missing-data.Rmd`, `NEWS.md`, `_pkgdown.yml`,
  `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: public and design docs.
- `man/*.Rd`, `NAMESPACE`: roxygen outputs.

## Checks Run

```sh
Rscript -e "devtools::document()"
air format --check R/missing-data.R tests/testthat/test-missing-predictor-categorical.R
air format R/missing-data.R tests/testthat/test-missing-predictor-categorical.R
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-categorical.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-binary.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-ordered.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gaussian.R')"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-phylo-utils.R')"
Rscript -e "devtools::test()"
```

Results:

- `test-missing-predictor-categorical.R`: 24 expectations, no failures,
  warnings, or skips.
- `test-missing-predictor-binary.R`: 21 expectations, no failures, warnings,
  or skips.
- `test-missing-predictor-ordered.R`: 23 expectations, no failures, warnings,
  or skips.
- `test-missing-predictor-gaussian.R`: 109 expectations, no failures,
  warnings, or skips.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: no whitespace errors.
- `test-phylo-utils.R`: 79 expectations, no failures, warnings, or skips.
- Full `devtools::test()`: 8,878 expectations, no failures, warnings, or
  skips in 631.7 seconds.

## Tests Of The Tests

The categorical test independently recomputes the fitted log-likelihood from
the softmax predictor model and Gaussian response model. It includes exact
`logsumexp` over all missing unordered states, rows where the response is also
missing, and boundary tests for ordered factors, grouped categorical models,
unobserved levels, and two-level categorical inputs.

## Consistency Audit

Stale wording scans:

```sh
rg -n "unordered categorical predictors|unordered multinomial|unordered.*planned|categorical.*planned|MD6c|categorical\\(\\)|conditional modal" NEWS.md README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes _pkgdown.yml R man
rg -n "binary slice|binary predictor slice|ordered or unordered|unordered categorical with more than two levels|wait for the unordered|non-Gaussian predictor models remain planned|binary predictors may use|finite-state predictor models" R man NEWS.md README.md ROADMAP.md docs/design vignettes docs/dev-log/known-limitations.md
rg -n "One missing unordered predictor|categorical\\(\\)|baseline-category softmax|beta/proportion|count predictors|positive-continuous" pkgdown-site/articles/missing-data.html
```

The scans found one stale public-doc sentence that mentioned only binary
finite-state predictors; it now names binary, ordered categorical, and
unordered categorical predictor models. The MD6a design boundary now points
readers to MD6c for unordered predictors with more than two levels.

## GitHub Issue Maintenance

Issue searches:

```sh
gh issue list --repo itchyshin/drmTMB --search "unordered categorical missing predictor categorical impute_model" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing predictor categorical" --limit 20
gh issue list --repo itchyshin/drmTMB --search "proportion missing predictor" --limit 20
```

All three searches returned no open issue rows, so no issue comment or closure
was made.

## What Did Not Go Smoothly

The first categorical coefficient-name pass needed alignment with the
category-major `beta_mi` vector used in TMB. The independent likelihood test
caught the vectorization contract directly. `air format --check` also caught
formatting drift in the new missing-data file before the final test run.

## Team Learning

For finite-state predictors, the binding contract should be an independent
likelihood recomputation rather than only extractor or coefficient checks. The
binary, ordered, and unordered routes now share that pattern.

## Known Limitations

MD6c is one fixed-effect unordered categorical predictor in a univariate
Gaussian location model. Later MD7a added the first strict beta/proportion
predictor slice. Grouped or structured unordered predictor models, multiple
missing predictors, transformed or interacted `mi()` terms, count predictors,
positive-continuous non-Gaussian predictor models, EM/profile engines, REML,
simulation-based imputed summaries, response imputation, measurement-error
models, and pigauto interoperability remain planned.

## Next Actions

The next non-Gaussian predictor slice should be beta/proportion. It needs a
separate design decision about whether to integrate missing continuous
bounded predictors by Laplace on an unconstrained logit scale or by deterministic
quadrature for the first fixed-effect slice.
