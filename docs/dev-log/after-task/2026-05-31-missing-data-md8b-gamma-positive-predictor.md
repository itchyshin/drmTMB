# After Task: Missing Data MD8b Gamma Positive Predictor

## Goal

Extend the positive continuous missing-predictor lane beyond the MD8a
lognormal route by adding a Gamma mean-CV predictor model for skewed positive
covariates.

## Implemented

MD8b adds `Gamma(link = "log")` as a predictor-model family for one positive
continuous `mi()` predictor in a univariate Gaussian location model:

```r
drmTMB(
  bf(y ~ z + mi(biomass), sigma ~ 1),
  data = dat,
  impute = list(
    biomass = impute_model(biomass ~ z, family = Gamma(link = "log"))
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is fixed-effect only. Observed predictor values must be
finite and greater than zero. Missing positive values are integrated by
deterministic Gauss-Laguerre quadrature under the fitted Gamma mean-CV model.

## Mathematical Contract

For the missing predictor,

```text
x_i ~ Gamma(shape = 1 / sigma_x^2, scale = mu_xi sigma_x^2)
log(mu_xi) = W_i alpha
mu_i(x) = eta_without_x_i + beta_x x
```

Observed positive predictor rows contribute the Gamma predictor likelihood:

```text
log Gamma(x_i | shape = 1 / sigma_x^2, scale = mu_xi sigma_x^2)
```

Missing predictor rows use Gauss-Laguerre nodes `t_k` and weights `w_k` for
the `exp(-t)` weight:

```text
x_ik = scale_i t_k

log L_i =
  log sum_k
    w_k t_k^(shape - 1) / Gamma(shape)
    p(y_i | mu_i(x_ik), sigma_i) ^ observed_y_i
```

Rows where both the response and the Gamma predictor are missing contribute
zero direct likelihood but are retained for original-row accounting.

## Files Changed

- `R/missing-data.R`: accepts `family = Gamma(link = "log")` in
  `impute_model()`, builds the fixed-effect Gamma predictor model, validates
  positive observed values, creates Gauss-Laguerre quadrature nodes and
  weights, maps the family to TMB `mi_family = 7`, and finalizes `imputed()`
  metadata with conditional quadrature means and probabilities.
- `R/drmTMB.R`: updates public argument documentation, dense known-`V` guards,
  missing-data version labelling, and `sigma_mi_*` coefficient extraction.
- `src/drmTMB.cpp`: adds the MD8b Gamma missing-predictor likelihood branch.
- `tests/testthat/test-missing-predictor-gamma.R`: adds likelihood,
  response-mask, and boundary tests.
- `vignettes/missing-data.Rmd` and `pkgdown-site/articles/missing-data.html`:
  add the Gamma positive continuous missing-predictor example.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: record the syntax, likelihood, and
  implementation-slice boundary.
- `NEWS.md`, `man/drmTMB.Rd`, `man/miss_control.Rd`, `man/impute_model.Rd`,
  and `man/imputed.Rd`: update public release and reference documentation.

## Checks Run

```sh
air format R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-gamma.R
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gamma.R')"
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing-predictor')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Results:

- Focused `test-missing-predictor-gamma.R`: 22 expectations, no failures,
  warnings, or skips.
- Combined `devtools::test(filter = 'missing-predictor')`: 259 expectations,
  no failures, warnings, or skips.
- `test-gaussian-location-scale.R`: 71 expectations, no failures or warnings;
  one CRAN-gated skip.
- `pkgdown::build_article('missing-data', new_process = FALSE)` rebuilt
  `pkgdown-site/articles/missing-data.html`.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: no whitespace errors.

The full package test suite was not rerun after MD8b. The most recent full
suite in this lane was the MD7b run with 8,917 expectations, no failures,
warnings, or skips.

## Tests Of The Tests

The Gamma predictor test independently recomputes `logLik(fit)` from the
observed Gamma predictor likelihood, the Gaussian response likelihood, and the
same Gauss-Laguerre quadrature used for missing positive predictor values. A
second test repeats that likelihood check with missing responses included.
Boundary tests reject zero observed values, non-numeric predictors, non-log
Gamma links, and grouped Gamma predictor models.

## Consistency Audit

```sh
rg -n "Gamma positive|Gamma\\(link = &quot;log&quot;\\)|Gamma\\(link = \\\"log\\\"\\)|MD8b|Tweedie positive|positive-continuous predictor models|Gamma and Tweedie" pkgdown-site/articles/missing-data.html vignettes/missing-data.Rmd man/impute_model.Rd man/drmTMB.Rd man/imputed.Rd man/miss_control.Rd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-gamma.R
```

The scan confirmed current MD8b syntax, rendered article text, generated Rd
text, implementation-slice labels, C++/R family mapping, and remaining Tweedie
or grouped positive-continuous boundaries. Historical MD8a claim blocks in
`docs/design/149-missing-data-design.md` still mention Gamma and Tweedie as
planned because they describe the earlier MD8a checkpoint.

## GitHub Issue Maintenance

```sh
gh issue list --repo itchyshin/drmTMB --search "Gamma positive missing predictor impute_model" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing predictor positive continuous" --limit 20
gh issue list --repo itchyshin/drmTMB --search "Tweedie missing predictor" --limit 20
```

All three searches returned no issue rows, so no issue was commented on,
closed, or opened for MD8b in this pass.

## What Did Not Go Smoothly

The Gamma route needed a different quadrature transformation from MD8a. The
final implementation uses Gauss-Laguerre quadrature on `t = x / scale`, which
keeps the predictor-density weight explicit enough for an independent
likelihood test.

## Team Learning

Positive continuous predictors need more than one family. `lognormal()` is a
good model when log-scale noise is natural; `Gamma(link = "log")` is a good
mean-CV model when response-scale skew and variance proportional to the square
of the mean are the better data story.

## Known Limitations

MD8b is one fixed-effect Gamma missing predictor in a univariate Gaussian
location model. Tweedie predictor models, exact-zero semi-continuous
predictors, negative-binomial count predictors, grouped or structured
non-Gaussian predictor models, multiple missing predictors, transformed or
interacted `mi()` terms, EM/profile engines, REML, simulation-based imputed
summaries, response imputation, measurement-error models, and pigauto
interoperability remain planned.

## Next Actions

- Add negative-binomial count predictors if overdispersed count covariates are
  the next highest-value family.
- Add Tweedie or exact-zero semi-continuous positive predictors if users need a
  positive-continuous route with genuine zeros.
- Keep multiple missing predictors separate until the joint predictor model and
  any conditional-independence assumption are explicit.
