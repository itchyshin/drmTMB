# After Task: Missing Data MD6a Binary Predictor

Date: 2026-05-31

## Goal

Add the first non-Gaussian missing-predictor route without opening the broader
categorical, proportion, count, EM, REML, measurement-error, or multiple
missing-predictor surface.

## Implemented

`drmTMB` now supports one binary missing predictor in a univariate Gaussian
location model:

```r
drmTMB(
  bf(y ~ z + mi(treatment), sigma ~ 1),
  data = dat,
  impute = list(
    treatment = impute_model(treatment ~ z, family = binomial())
  ),
  missing = miss_control(predictor = "model")
)
```

`impute_model()` is the family-explicit predictor-model wrapper. Bare
`impute = list(x = x ~ z)` remains the Gaussian shortcut. For binary
predictors, observed logical values, numeric 0/1 values, two-level character
vectors, and two-level factors are accepted. `fit$missing_data$version` records
`"MD6a"`, and `imputed()` reports fitted conditional probabilities for missing
binary predictor rows.

## Mathematical Contract

The binary predictor model is:

```text
treatment_i ~ Bernoulli(pi_i)
logit(pi_i) = W_i alpha
mu_i(x) = eta_without_x_i + beta_x x
```

For observed binary predictors, the row contributes:

```text
log p(x_i | pi_i) + observed_y_i log p(y_i | mu_i(x_i), sigma_i)
```

For missing binary predictors, TMB sums exactly over the two states:

```text
logspace_add(
  log(1 - pi_i) + observed_y_i log p(y_i | mu_i(0), sigma_i),
  log(pi_i)     + observed_y_i log p(y_i | mu_i(1), sigma_i)
)
```

This is finite-state integration, not a continuous latent Gaussian imputation,
not posterior multiple imputation, and not EM. If the response is also missing,
the response likelihood term is zero and the Bernoulli states sum to one.

## Files Changed

- `R/missing-data.R`: `impute_model()`, family validation, binary predictor
  model construction, binary metadata, and `imputed()` binary summaries.
- `R/drmTMB.R`: binary `mi()` routing, TMB data/parameter handling, dense known
  covariance guard, and MD6a fitted-object versioning.
- `src/drmTMB.cpp`: `mi_family` switch and exact two-state Bernoulli/logit
  contribution for missing binary predictors.
- `tests/testthat/test-missing-predictor-binary.R`: independent likelihood,
  response-mask composition, metadata, `imputed()`, and boundary tests.
- `tests/testthat/test-missing-predictor-gaussian.R` and
  `tests/testthat/test-phylo-utils.R`: adjusted boundary wording and direct TMB
  dummy data for the new `mi_family` field.
- `vignettes/missing-data.Rmd` and `pkgdown-site/articles/missing-data.html`:
  article section for binary missing predictors and the `impute_model()` family
  pattern.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: MD6a syntax, likelihood, and slice
  boundary.
- `NEWS.md`, `_pkgdown.yml`, generated `man/*.Rd`, and `NAMESPACE`: public
  documentation and reference navigation.

## Checks Run

```sh
air format R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-binary.R tests/testthat/test-phylo-utils.R
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-binary.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-phylo-utils.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-gaussian.R')"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript -e "devtools::test()"
```

Final results:

- `test-missing-predictor-binary.R`: 21 expectations, no failures.
- `test-missing-predictor-gaussian.R`: 109 expectations, no failures.
- `test-missing-data-control.R`: 13 expectations, no failures.
- `test-phylo-utils.R`: 79 expectations, no failures.
- `test-missing-response-gaussian.R`: 32 expectations, no failures.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: no whitespace errors.
- Full `devtools::test()`: 8,831 expectations, no failures, warnings, or skips.
  Duration was 665.7 seconds.

## Tests Of The Tests

The new binary test independently recomputes the fitted log likelihood from
the fitted coefficients, observed Bernoulli contributions, Gaussian response
densities, and exact two-state `logspace_add` terms for missing binary rows.
It also combines `predictor = "model"` with `response = "include"` and checks
that residuals are masked when responses are missing. Boundary tests reject an
unsupported predictor family, grouped binary predictor models, and more-than-two
category predictors.

## Consistency Audit

The status-inventory scan was:

```sh
rg -n "missing data|miss_control|mi\\(|impute_model|imputed|missing predictor|non-Gaussian predictor|categorical predictor|proportion predictor|binary predictor|multiple missing" README.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml NEWS.md pkgdown-site/articles/missing-data.html
```

It confirmed that NEWS, formula grammar, pkgdown navigation, and the generated
missing-data article expose `impute_model()` and the binary route while keeping
unsupported families explicit.

The stale-wording scan was:

```sh
rg -n "numeric continuous variable|missing categorical predictors|Factor, non-Gaussian|factor or non-Gaussian predictor models|non-Gaussian predictor models remain planned|imputed\\(fit\\).*MD3a/MD3b/MD4|current MD5 slice" R man NEWS.md README.md ROADMAP.md docs/design vignettes docs/dev-log/known-limitations.md pkgdown-site/articles/missing-data.html
```

It found only intentionally historical MD3/MD5 design wording and the current
MD3a/MD3b/MD4/MD6a extractor row. No current user-facing article or generated
help page still says all categorical or non-Gaussian missing predictors are
unsupported.

## GitHub Issue Maintenance

These searches returned no matching open issues, so no issue comment or closure
was made:

```sh
gh issue list --repo itchyshin/drmTMB --search "binary missing predictor mi impute_model" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing data non-Gaussian predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "categorical missing predictor" --limit 20
```

## What Did Not Go Smoothly

The first Gaussian missing-predictor test run caught stale test wording. The
public validation message changed from "bare numeric predictor" to "bare
predictor" because `mi()` now accepts numeric Gaussian and binary Bernoulli
routes. The test expectation was updated and the Gaussian test passed on rerun.

## Team Learning

Boole's API check is that `impute` entries should contain predictor formulas,
not full `drm_formula()` objects. The family-explicit wrapper is the right
extension point: `impute_model(x ~ z, family = binomial())` works today, and
future family-specific slices can add beta/proportion, lognormal, ordered, and
multinomial predictor likelihoods without changing the top-level `mi()` marker.

Fisher's inference check is that binary missing predictors should be integrated
by exact finite summation, not approximated as Gaussian latent values. Pat's
article check is that the user sees what to do next when their predictor is
ordered, multinomial, proportion, count, grouped binary, or structured binary:
those are planned family-specific slices, not silently accepted models.

## Known Limitations

At the MD6a checkpoint, only the first fixed-effect binary missing-predictor
route was implemented. Later MD6b, MD6c, and MD7a added ordered categorical,
unordered categorical, and strict beta/proportion predictors. Positive
lognormal predictor models, count predictor models, grouped or structured
non-Gaussian predictor models, multiple missing predictors, transformed or
interacted `mi()` terms, splines inside `mi()`, dense known-covariance
partial-response slicing, EM/profile engines, REML, simulated imputed
summaries, response imputation, measurement-error models, and pigauto
interoperability remain planned.

## Next Actions

The later ordered, unordered, and strict beta/proportion slices followed this
rule: each new predictor family needed its own likelihood equation,
failure-path tests, and `imputed()` interpretation before it became public
fitted support.
