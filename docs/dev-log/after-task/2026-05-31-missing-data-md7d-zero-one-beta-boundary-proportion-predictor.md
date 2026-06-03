# After Task: Missing Data MD7d Zero-One Beta Boundary-Proportion Predictor

## Goal

Extend the non-Gaussian missing-predictor lane to boundary-proportion
predictors that can have exact zero and exact one values.

## Implemented

MD7d adds `zero_one_beta()` as a predictor-model family for one
boundary-proportion `mi()` predictor in `[0, 1]` in a univariate Gaussian
location model:

```r
drmTMB(
  bf(y ~ z + mi(cover), sigma ~ 1),
  data = dat,
  impute = list(
    cover = impute_model(cover ~ z, family = zero_one_beta())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is fixed-effect only. Observed predictor values must be
finite numeric values in `[0, 1]`, with at least one observed interior value.
The first slice uses the impute formula for the interior beta mean, estimates
constant predictor-model `sigma`, `zoi`, and `coi`, and integrates missing
values over exact zero mass, deterministic interior beta quadrature, and exact
one mass.

## Mathematical Contract

For the missing predictor,

```text
m_xi = inv_logit(W_i alpha)
phi_x = 1 / sigma_x^2
zoi_x = inv_logit(gamma_zoi)
coi_x = inv_logit(gamma_coi)
```

The predictor likelihood is

```text
P(x_i = 0) = zoi_x * (1 - coi_x)
P(x_i = 1) = zoi_x * coi_x
p(0 < x_i < 1) = (1 - zoi_x) * Beta(x_i | m_xi, phi_x)
```

Observed predictor rows contribute the corresponding zero-one beta density.
Missing predictor rows use deterministic quadrature:

```text
log L_i =
  log sum_q
    w_q p_zero_one_beta(x_q | m_xi, sigma_x, zoi_x, coi_x)
    p(y_i | mu_i(x_q), sigma_i) ^ observed_y_i
```

The support contains exact nodes at 0 and 1 plus deterministic interior beta
quadrature nodes. Rows where both the response and boundary-proportion
predictor are missing contribute zero direct likelihood but remain in the
original-row accounting.

## Files Changed

- `R/missing-data.R`: accepts `family = zero_one_beta()` in `impute_model()`,
  builds the fixed-effect zero-one beta predictor model, validates bounded
  observed values and interior support, creates exact-boundary plus interior
  quadrature support, maps the family to TMB `mi_family = 10`, and finalizes
  `imputed()` metadata with conditional quadrature means and normalized
  quadrature probabilities.
- `R/drmTMB.R`: updates public argument documentation, dense known-`V` guards,
  missing-data version labelling, missing-predictor scale and boundary
  parameter mapping, and `sigma_mi_*`, `zoi_mi_*`, and `coi_mi_*` coefficient
  extraction.
- `src/drmTMB.cpp`: adds the MD7d zero-one beta missing-predictor likelihood
  branch with stable log-boundary probabilities.
- `tests/testthat/test-missing-predictor-zero-one-beta.R`: adds likelihood,
  response-mask, imputed-summary, and boundary tests.
- `vignettes/missing-data.Rmd` and `pkgdown-site/articles/missing-data.html`:
  add the boundary-proportion missing-predictor example.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: record the syntax, likelihood, and
  implementation-slice boundary.
- `NEWS.md`, `man/drmTMB.Rd`, `man/miss_control.Rd`, `man/impute_model.Rd`,
  and `man/imputed.Rd`: update public release and reference documentation.

## Checks Run

```sh
air format R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-zero-one-beta.R
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-zero-one-beta.R')"
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing-predictor')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-zero-one-beta.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-beta-location-scale.R')"
Rscript -e "devtools::load_all(); rmarkdown::render('vignettes/missing-data.Rmd', output_dir = 'pkgdown-site/articles', output_file = 'missing-data.html', quiet = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
air format --check R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-zero-one-beta.R
git diff --check
```

Results:

- Focused `test-missing-predictor-zero-one-beta.R`: 25 expectations, no
  failures, warnings, or skips.
- Combined `devtools::test(filter = 'missing-predictor')`: 328 expectations,
  no failures, warnings, or skips.
- `test-zero-one-beta.R`: 56 expectations, no failures, warnings, or skips.
- `test-beta-location-scale.R`: 85 expectations, no failures, warnings, or
  skips.
- `rmarkdown::render()` rebuilt `pkgdown-site/articles/missing-data.html` with
  the MD7d boundary-proportion predictor section.
- `pkgdown::check_pkgdown()`: no problems found.
- `air format --check` and `git diff --check` passed.

The full package test suite was not rerun after MD7d. The most recent full
suite in this missing-data lane remains the MD7b run with 8,917 expectations,
no failures, warnings, or skips.

## Tests Of The Tests

The zero-one beta predictor test independently recomputes `logLik(fit)` from
the observed zero-one beta predictor density, the Gaussian response likelihood,
and exact-boundary plus interior quadrature support for missing predictor
values. A second test repeats that likelihood check with missing responses
included. Boundary tests reject out-of-range observed values, predictors
without an observed interior value, non-numeric predictors, and grouped
zero-one beta predictor models.

## Consistency Audit

```sh
rg -n "zero-one beta|zero_one_beta|MD7d|boundary proportion|boundary-proportion|exact 0/1 proportions|exact 0/1 boundary proportions|Boundary proportion" R/missing-data.R R/drmTMB.R src/drmTMB.cpp tests/testthat/test-missing-predictor-zero-one-beta.R vignettes/missing-data.Rmd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md man/drmTMB.Rd man/miss_control.Rd man/impute_model.Rd man/imputed.Rd
rg -n "exact 0/1 proportions|exact 0/1 boundary|boundary-proportion.*planned|zero-one beta.*planned|zero_one_beta.*later|Use .*later.*zero|Boundary-proportion predictor models need" R man NEWS.md docs/design vignettes pkgdown-site/articles/missing-data.html
```

The positive scan confirmed current MD7d wording in the implementation,
generated Rd files, design docs, article source, rendered article, tests, and
`NEWS.md`. The stale scan returned current implemented missing-data wording
and unrelated older response-family or simulation-plan boundaries. It did not
find current missing-data docs claiming that zero-one beta missing predictors
remain unimplemented.

## GitHub Issue Maintenance

```sh
gh issue list --repo itchyshin/drmTMB --search "zero-one beta missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "boundary proportion missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing predictor proportion" --limit 20
```

All three searches returned no issue rows, so no issue was commented on,
closed, or opened for MD7d in this pass.

## What Did Not Go Smoothly

The main mechanical trap was parameter mapping. A Gaussian response model does
not otherwise need `beta_zoi` or `beta_coi`, so the covariance-probe mapping
had to free those boundary parameters only when a zero-one beta missing
predictor is present.

## Team Learning

Proportion predictors need two separate routes. Use `beta()` only for strict
interior proportions in `(0, 1)`. Use `zero_one_beta()` when exact zeros or
ones are part of the predictor-generating process.

## Known Limitations

MD7d is one fixed-effect zero-one beta missing predictor in a univariate
Gaussian location model. Denominator-aware beta-binomial predictor models,
grouped or structured non-Gaussian predictor models, multiple missing
predictors, transformed or interacted `mi()` terms, zero-truncated or hurdle
count predictor models, EM/profile engines, REML, simulation-based imputed
summaries, response imputation, measurement-error models, and pigauto
interoperability remain planned.

## Next Actions

- Add denominator-aware beta-binomial missing predictors for proportions that
  are observed as successes out of known trials.
- Add grouped or structured non-Gaussian predictor models after choosing a
  family-specific random-effect contract.
- Keep multiple missing predictors separate until the joint predictor model and
  any conditional-independence assumptions are explicit.
