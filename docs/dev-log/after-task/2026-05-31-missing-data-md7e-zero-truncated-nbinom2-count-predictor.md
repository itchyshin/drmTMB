# After Task: Missing Data MD7e Zero-Truncated NB2 Count Predictor

## Goal

Extend the non-Gaussian missing-predictor lane to positive integer count
predictors where zero is structurally impossible.

## Implemented

MD7e adds `truncated_nbinom2()` as a predictor-model family for one positive
integer `mi()` predictor in a univariate Gaussian location model:

```r
drmTMB(
  bf(y ~ z + mi(abundance), sigma ~ 1),
  data = dat,
  impute = list(
    abundance = impute_model(abundance ~ z, family = truncated_nbinom2())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is fixed-effect only. Observed predictor values must be
finite positive integer counts. The first slice estimates the untruncated NB2
mean model and one predictor-model overdispersion scale, then conditions the
predictor likelihood on positive support.

## Mathematical Contract

For the missing predictor,

```text
log(mu_xi) = W_i alpha
sigma_x > 0
p_+(mu_xi, sigma_x) = 1 - p_nb2(0 | mu_xi, sigma_x)
p_zt(k | mu_xi, sigma_x) = p_nb2(k | mu_xi, sigma_x) / p_+
  for k = 1, 2, ...
```

Observed positive-count rows contribute the zero-truncated NB2 predictor
likelihood:

```text
log p_zt(x_i | mu_xi, sigma_x)
```

Missing positive-count rows sum over a deterministic positive count support:

```text
log L_i =
  log sum_k
    p_zt(k | mu_xi, sigma_x)
    p(y_i | mu_i(k), sigma_i) ^ observed_y_i
```

Rows where both the response and the positive-count predictor are missing
contribute zero direct likelihood but remain in the original-row accounting.

## Files Changed

- `R/missing-data.R`: accepts `family = truncated_nbinom2()` in
  `impute_model()`, builds the fixed-effect zero-truncated NB2 predictor
  model, validates positive integer observed values, creates positive count
  support, maps the family to TMB `mi_family = 11`, and finalizes `imputed()`
  metadata with conditional expected positive counts and count-state
  probabilities.
- `R/drmTMB.R`: updates public argument documentation, dense known-`V` guards,
  missing-data version labelling, missing-predictor scale-parameter mapping,
  and `sigma_mi_*` coefficient extraction for zero-truncated NB2 predictor
  models.
- `src/drmTMB.cpp`: adds the MD7e zero-truncated NB2 missing-predictor
  likelihood branch using the existing AD-stable NB2 count kernels and
  `drm_log1mexp()`.
- `tests/testthat/test-missing-predictor-truncated-nbinom2.R`: adds
  likelihood, response-mask, imputed-summary, and boundary tests.
- `tests/testthat/test-missing-predictor-binary.R`: moves the unsupported
  family sentinel from `truncated_nbinom2()` to `student()`.
- `vignettes/missing-data.Rmd` and `pkgdown-site/articles/missing-data.html`:
  add the zero-truncated count missing-predictor example.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: record the syntax, likelihood, and
  implementation-slice boundary.
- `NEWS.md`, `man/drmTMB.Rd`, `man/miss_control.Rd`, `man/impute_model.Rd`,
  and `man/imputed.Rd`: update public release and reference documentation.

## Checks Run

```sh
air format R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-truncated-nbinom2.R tests/testthat/test-missing-predictor-binary.R
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-truncated-nbinom2.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-binary.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-truncated-nbinom2-location-scale.R')"
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing-predictor')"
Rscript -e "devtools::load_all(); rmarkdown::render('vignettes/missing-data.Rmd', output_dir = 'pkgdown-site/articles', output_file = 'missing-data.html', quiet = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
air format --check R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-truncated-nbinom2.R tests/testthat/test-missing-predictor-binary.R
git diff --check
```

Results:

- Focused `test-missing-predictor-truncated-nbinom2.R`: 21 expectations, no
  failures, warnings, or skips.
- Adjusted `test-missing-predictor-binary.R`: 21 expectations, no failures,
  warnings, or skips.
- `test-truncated-nbinom2-location-scale.R`: 75 expectations, no failures,
  warnings, or skips.
- Combined `devtools::test(filter = 'missing-predictor')`: 349 expectations,
  no failures, warnings, or skips.
- `rmarkdown::render()` rebuilt `pkgdown-site/articles/missing-data.html` with
  the MD7e zero-truncated count predictor section.
- `pkgdown::check_pkgdown()`: no problems found.
- `air format --check` and `git diff --check` passed.

The full package test suite was not rerun after MD7e. The most recent full
suite in this missing-data lane remains the MD7b run with 8,917 expectations,
no failures, warnings, or skips.

## Tests Of The Tests

The zero-truncated NB2 predictor test independently recomputes `logLik(fit)`
from the observed zero-truncated NB2 predictor density, the Gaussian response
likelihood, and deterministic positive-count summation for missing predictor
values. A second test repeats that likelihood check with missing responses
included. Boundary tests reject zero observed counts, fractional observed
counts, and grouped zero-truncated NB2 predictor models.

## Consistency Audit

```sh
rg -n "truncated_nbinom2|zero-truncated|MD7e|positive-count|positive count" R/missing-data.R R/drmTMB.R src/drmTMB.cpp tests/testthat/test-missing-predictor-truncated-nbinom2.R tests/testthat/test-missing-predictor-binary.R vignettes/missing-data.Rmd pkgdown-site/articles/missing-data.html docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md man/drmTMB.Rd man/miss_control.Rd man/impute_model.Rd man/imputed.Rd
rg -n "zero-truncated or hurdle count predictor|Zero-truncated or hurdle count predictor|zero-truncated.*planned|truncated_nbinom2.*Unsupported missing-predictor|truncated_nbinom2.*not implemented|positive-count.*planned" R man NEWS.md docs/design vignettes pkgdown-site/articles/missing-data.html tests/testthat/test-missing-predictor-binary.R
```

The positive scan confirmed current MD7e wording in the implementation,
generated Rd files, design docs, article source, rendered article, tests, and
`NEWS.md`. The stale scan returned current implemented missing-data wording
and unrelated response-family or Phase 18 planning boundaries. It did not find
current missing-data docs claiming that zero-truncated NB2 missing predictors
remain unimplemented.

## GitHub Issue Maintenance

```sh
gh issue list --repo itchyshin/drmTMB --search "zero-truncated missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "truncated nbinom2 missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "positive count missing predictor" --limit 20
```

The first two searches returned no issue rows. The broad positive-count search
returned only #436, the four-week Phase 6c random-slope and digital-twin
exchange sprint, so no missing-data-specific issue comment or closure was made.

## What Did Not Go Smoothly

The first local hygiene command exposed a malformed test file while the test
was being drafted. That was corrected before any test run was counted as
evidence. I also briefly tried the non-existent file
`tests/testthat/test-truncated-nbinom2.R`; the real response-family test is
`tests/testthat/test-truncated-nbinom2-location-scale.R`.

## Team Learning

Count predictors should keep support constraints explicit. `poisson()` and
`nbinom2()` are for non-negative counts that can include zero, while
`truncated_nbinom2()` is for positive counts where zero is not possible by
design.

## Known Limitations

MD7e is one fixed-effect zero-truncated NB2 missing predictor in a univariate
Gaussian location model. Hurdle count predictor models, denominator-aware
beta-binomial predictor models, grouped or structured non-Gaussian predictor
models, multiple missing predictors, transformed or interacted `mi()` terms,
EM/profile engines, REML, simulation-based imputed summaries, response
imputation, measurement-error models, and pigauto interoperability remain
planned.

## Next Actions

- Decide the denominator-aware beta-binomial missing-predictor grammar before
  implementing success/trial proportion predictors.
- Add grouped or structured non-Gaussian predictor models after choosing a
  family-specific random-effect contract.
- Keep hurdle count predictors separate because the impute formula needs a way
  to declare the hurdle-zero model.
