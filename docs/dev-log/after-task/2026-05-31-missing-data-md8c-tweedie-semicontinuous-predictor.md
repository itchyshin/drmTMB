# After Task: Missing Data MD8c Tweedie Semi-Continuous Predictor

## Goal

Extend the non-Gaussian missing-predictor lane to semi-continuous predictors
that can have exact zeros.

## Implemented

MD8c adds `tweedie()` as a predictor-model family for one non-negative
semi-continuous `mi()` predictor in a univariate Gaussian location model:

```r
drmTMB(
  bf(y ~ z + mi(biomass), sigma ~ 1),
  data = dat,
  impute = list(
    biomass = impute_model(biomass ~ z, family = tweedie())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is fixed-effect only. Observed predictor values must be
finite and greater than or equal to zero, with at least one observed positive
value. The first slice estimates the predictor mean and scale, fixes
predictor-model Tweedie power at 1.5, and integrates missing values over exact
zero mass plus deterministic positive-support quadrature.

## Mathematical Contract

For the missing predictor,

```text
mu_xi = exp(W_i alpha)
phi_x = sigma_x^2
power_x = 1.5
x_i ~ Tweedie(mu_xi, phi_x, power_x)
```

Observed predictor rows contribute the Tweedie predictor likelihood:

```text
log TweedieDensity(x_i | mu_xi, phi_x, power_x)
```

Missing predictor rows sum over a zero-plus-positive quadrature support:

```text
log L_i =
  log sum_q
    w_q p_tweedie(x_q | mu_xi, phi_x, power_x)
    p(y_i | mu_i(x_q), sigma_i) ^ observed_y_i
```

The zero node has weight one and represents the exact Tweedie mass at zero.
Rows where both the response and predictor are missing contribute zero direct
likelihood but remain in the original-row accounting.

## Files Changed

- `R/missing-data.R`: accepts `family = tweedie()` in `impute_model()`, builds
  the fixed-effect Tweedie predictor model, validates non-negative observed
  values, creates zero-plus-positive quadrature support, maps the family to
  TMB `mi_family = 9`, and finalizes `imputed()` metadata with conditional
  quadrature means and normalized quadrature probabilities.
- `R/drmTMB.R`: updates public argument documentation, missing-data version
  labelling, missing-predictor scale-parameter mapping, and `sigma_mi_*`
  coefficient extraction for Tweedie predictor models.
- `src/drmTMB.cpp`: adds the MD8c Tweedie missing-predictor likelihood branch
  using TMB's `dtweedie()` density.
- `tests/testthat/test-missing-predictor-tweedie.R`: adds likelihood,
  response-mask, imputed-summary, and boundary tests.
- `vignettes/missing-data.Rmd` and `pkgdown-site/articles/missing-data.html`:
  add the semi-continuous missing-predictor example.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: record the syntax, likelihood, and
  implementation-slice boundary.
- `NEWS.md`, `man/drmTMB.Rd`, `man/miss_control.Rd`, `man/impute_model.Rd`,
  and `man/imputed.Rd`: update public release and reference documentation.

## Checks Run

```sh
air format R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-tweedie.R
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-tweedie.R')"
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing-predictor')"
Rscript -e "devtools::load_all(); rmarkdown::render('vignettes/missing-data.Rmd', output_dir = 'pkgdown-site/articles', output_file = 'missing-data.html', quiet = FALSE)"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-tweedie-location-scale.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
rg -n "[ \t]+$" R/missing-data.R R/drmTMB.R src/drmTMB.cpp tests/testthat/test-missing-predictor-tweedie.R vignettes/missing-data.Rmd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md man/drmTMB.Rd man/miss_control.Rd man/impute_model.Rd man/imputed.Rd
air format --check R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-tweedie.R
```

Results:

- Focused `test-missing-predictor-tweedie.R`: 24 expectations, no failures,
  warnings, or skips.
- Combined `devtools::test(filter = 'missing-predictor')`: 303 expectations,
  no failures, warnings, or skips.
- `test-tweedie-location-scale.R`: 86 expectations, no failures; one
  `glmmTMB`/TMB package-version warning in the comparator skip check.
- `test-gaussian-location-scale.R`: 71 expectations, no failures or warnings;
  one CRAN-gated skip.
- `rmarkdown::render()` rebuilt `pkgdown-site/articles/missing-data.html` with
  the MD8c semi-continuous predictor section.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`, the explicit trailing-whitespace scan, and
  `air format --check` passed.

The full package test suite was not rerun after MD8c. The most recent full
suite in this missing-data lane remains the MD7b run with 8,917 expectations,
no failures, warnings, or skips.

## Tests Of The Tests

The Tweedie predictor test independently recomputes `logLik(fit)` from the
observed Tweedie predictor density, the Gaussian response likelihood, and
zero-plus-positive quadrature for missing predictor values. A second test
repeats that likelihood check with missing responses included. Boundary tests
reject negative observed values, non-numeric predictors, and grouped Tweedie
predictor models.

## Consistency Audit

```sh
rg -n "Semi-continuous missing predictors|family = tweedie\\(\\)|MD8c|Tweedie predictor models, transformed|Tweedie positive-continuous predictor models|Use a later Tweedie" vignettes/missing-data.Rmd pkgdown-site/articles/missing-data.html man/impute_model.Rd man/miss_control.Rd man/imputed.Rd man/drmTMB.Rd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md R/missing-data.R R/drmTMB.R src/drmTMB.cpp tests/testthat/test-missing-predictor-tweedie.R
```

The positive scan confirmed current Tweedie syntax, rendered article text,
generated Rd text, implementation-slice labels, C++/R family mapping, and fixed
predictor-model power wording. It did not find stale current docs claiming that
Tweedie missing predictors remain unimplemented. Historical MD8a and MD8b
claim blocks in `docs/design/149-missing-data-design.md` still mention Tweedie
as planned because they describe earlier checkpoints.

## GitHub Issue Maintenance

```sh
gh issue list --repo itchyshin/drmTMB --search "Tweedie missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "semi-continuous missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing predictor positive continuous" --limit 20
```

All three searches returned no issue rows, so no issue was commented on,
closed, or opened for MD8c in this pass.

## What Did Not Go Smoothly

The main design choice was whether to estimate Tweedie power immediately.
MD8c keeps power fixed at 1.5 so it can reuse the existing `beta_mi` and
`log_sigma_mi` parameter path without introducing a weakly identified extra
shape parameter. That boundary is now explicit in the docs.

## Team Learning

Positive continuous and semi-continuous predictors need separate user guidance.
Lognormal and Gamma are right for strictly positive predictors; Tweedie is the
first route when exact zeros are part of the predictor process.

## Known Limitations

MD8c is one fixed-effect Tweedie missing predictor in a univariate Gaussian
location model. Estimated or predictor-dependent Tweedie power, exact 0/1
boundary-proportion models, grouped or structured semi-continuous predictor
models, multiple missing predictors, transformed or interacted `mi()` terms,
EM/profile engines, REML, simulation-based imputed summaries, response
imputation, measurement-error models, and pigauto interoperability remain
planned.

## Next Actions

- Add zero-one beta or denominator-aware boundary-proportion predictor models if
  users need proportions with exact 0/1 values.
- Add grouped or structured non-Gaussian predictor models after choosing a
  family-specific random-effect contract.
- Keep multiple missing predictors separate until the joint predictor model and
  any conditional-independence assumptions are explicit.
