# After Task: Missing Data MD8a Lognormal Positive Predictor

## Goal

Extend the likelihood-based missing-predictor lane beyond finite-state,
strict-proportion, and count predictors by adding the first positive continuous
non-Gaussian predictor model.

## Implemented

MD8a adds `lognormal()` as a predictor-model family for one positive continuous
`mi()` predictor in a univariate Gaussian location model:

```r
drmTMB(
  bf(y ~ z + mi(biomass), sigma ~ 1),
  data = dat,
  impute = list(
    biomass = impute_model(biomass ~ z, family = lognormal())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is fixed-effect only. Observed predictor values must be
finite and greater than zero. Missing positive values are integrated by
deterministic quadrature over log-scale predictor states.

## Mathematical Contract

For the missing predictor,

```text
log(x_i) ~ Normal(W_i alpha, sigma_x^2)
mu_i(x) = eta_without_x_i + beta_x x
```

Observed positive predictor rows contribute the lognormal predictor likelihood:

```text
log Normal(log x_i | W_i alpha, sigma_x) - log x_i
```

Missing predictor rows use standard-normal quadrature nodes `q_k` and weights
`w_k`:

```text
x_ik = exp(W_i alpha + sigma_x q_k)

log L_i =
  log sum_k
    w_k p(y_i | mu_i(x_ik), sigma_i) ^ observed_y_i
```

Rows where both the response and the lognormal predictor are missing contribute
zero direct likelihood but are retained for row accounting.

## Files Changed

- `R/missing-data.R`: accepts `family = lognormal()` in `impute_model()`, builds
  the fixed-effect lognormal predictor model, provides Gauss-Hermite quadrature
  nodes and weights, maps the family to TMB `mi_family = 6`, and finalizes
  `imputed()` metadata with conditional quadrature means and probabilities.
- `R/drmTMB.R`: updates public argument documentation, dense known-`V` guards,
  missing-data version labelling, and `sigma_mi_*` coefficient extraction.
- `src/drmTMB.cpp`: adds the MD8a lognormal missing-predictor likelihood branch.
- `tests/testthat/test-missing-predictor-lognormal.R`: adds likelihood,
  response-mask, and boundary tests.
- `vignettes/missing-data.Rmd` and `pkgdown-site/articles/missing-data.html`:
  add the positive continuous missing-predictor section.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: record the syntax, likelihood, and
  implementation-slice boundary.
- `NEWS.md`, `man/drmTMB.Rd`, `man/miss_control.Rd`, `man/impute_model.Rd`, and
  `man/imputed.Rd`: update public release and reference documentation.

## Checks Run

```sh
air format R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-lognormal.R
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-lognormal.R')"
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing-predictor')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Results:

- First focused `test-missing-predictor-lognormal.R`: 21 expectations, no
  failures, warnings, or skips.
- Combined `devtools::test(filter = 'missing-predictor')`: 237 expectations, no
  failures, warnings, or skips.
- `test-gaussian-location-scale.R`: 71 expectations, no failures or warnings;
  one CRAN-gated skip.
- `pkgdown::build_article('missing-data', new_process = FALSE)` rebuilt
  `pkgdown-site/articles/missing-data.html`.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: no whitespace errors.

## Tests Of The Tests

The lognormal predictor test independently recomputes `logLik(fit)` from the
observed lognormal predictor likelihood, the Gaussian response likelihood, and
the same deterministic log-scale quadrature used for missing positive
predictor values. A second test repeats that likelihood check with missing
responses included. Boundary tests reject zero values, non-numeric predictors,
and grouped lognormal predictor models.

## Consistency Audit

```sh
rg -n "Positive continuous missing predictors|impute_model\\(biomass ~ z, family = lognormal\\(\\)\\)|conditional quadrature mean|MD8a|Gamma and Tweedie|positive-continuous" pkgdown-site/articles/missing-data.html vignettes/missing-data.Rmd man/impute_model.Rd man/drmTMB.Rd man/imputed.Rd man/miss_control.Rd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md
```

The scan confirmed current MD8a syntax, rendered article text, generated Rd
text, implementation-slice labels, and remaining Gamma/Tweedie or grouped
positive-continuous boundaries. Historical MD6 and MD7 claim blocks in
`docs/design/149-missing-data-design.md` still mention positive-continuous
predictors as planned because they describe earlier checkpoints.

## GitHub Issue Maintenance

No issue was opened or closed for MD8a in this pass. The prior MD7b audit found
no missing-data-specific count predictor issue, and this slice continues the
same local implementation lane.

## What Did Not Go Smoothly

The main numerical choice was whether to use a new continuous latent variable
or deterministic quadrature. Deterministic quadrature was the better first
slice because it keeps the likelihood test independently reproducible and
avoids reporting log-scale random-effect standard errors as original-scale
imputation uncertainty.

## Team Learning

For positive continuous missing predictors, the family belongs in
`impute_model()`, not inside the main response formula. The main formula states
how the response depends on `mi(x)`; the `impute` model states the data
generating model for the missing predictor.

## Known Limitations

MD8a is one fixed-effect lognormal missing predictor in a univariate Gaussian
location model. Gamma and Tweedie predictor models, exact-zero semi-continuous
predictors, grouped or structured positive-continuous predictor models,
multiple missing predictors, transformed or interacted `mi()` terms,
EM/profile engines, REML, simulation-based imputed summaries, response
imputation, measurement-error models, and pigauto interoperability remain
planned.

## Next Actions

- Add a Gamma positive-continuous predictor slice if mean-CV modelling is the
  next highest-value positive route.
- Add negative-binomial count predictors if overdispersed count covariates are
  more urgent than continuous positive covariates.
- Keep multiple missing predictors separate until the joint predictor model and
  any conditional-independence assumption are explicit.
