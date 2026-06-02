# After Task: Missing Data MD7c Negative-Binomial Count Predictor

## Goal

Extend the count missing-predictor lane from Poisson counts to overdispersed
counts by adding a fixed-effect NB2 predictor model.

## Implemented

MD7c adds `nbinom2()` as a predictor-model family for one non-negative integer
`mi()` predictor in a univariate Gaussian location model:

```r
drmTMB(
  bf(y ~ z + mi(abundance), sigma ~ 1),
  data = dat,
  impute = list(
    abundance = impute_model(abundance ~ z, family = nbinom2())
  ),
  missing = miss_control(predictor = "model")
)
```

The predictor model is fixed-effect only. Observed predictor values must be
finite non-negative integer counts. Missing counts are integrated by
deterministic finite summation under the fitted NB2 predictor model.

## Mathematical Contract

For the missing predictor,

```text
log(mu_xi) = W_i alpha
sigma_x > 0
Var(x_i | mu_xi, sigma_x) = mu_xi + sigma_x^2 mu_xi^2
```

Observed count rows contribute the NB2 predictor likelihood:

```text
log NB2(x_i | mu_xi, sigma_x)
```

Missing count rows sum over a deterministic count support `k = 0, ..., K`:

```text
log L_i =
  log sum_k
    p_nb2(k | mu_xi, sigma_x)
    p(y_i | mu_i(k), sigma_i) ^ observed_y_i
```

Rows where both the response and the count predictor are missing contribute
zero direct likelihood but are retained for original-row accounting.

## Files Changed

- `R/missing-data.R`: accepts `family = nbinom2()` in `impute_model()`, builds
  the fixed-effect NB2 predictor model, validates non-negative integer observed
  counts, creates bounded finite count support, maps the family to TMB
  `mi_family = 8`, and finalizes `imputed()` metadata with conditional expected
  counts and count-state probabilities.
- `R/drmTMB.R`: updates public argument documentation, dense known-`V` guards,
  missing-data version labelling, missing-predictor scale-parameter mapping,
  and `sigma_mi_*` coefficient extraction. The scale mapping now also frees the
  existing lognormal and Gamma missing-predictor scale parameters.
- `src/drmTMB.cpp`: adds the MD7c NB2 missing-predictor likelihood branch using
  the existing AD-stable NB2 count kernel.
- `tests/testthat/test-missing-predictor-nbinom2.R`: adds likelihood,
  response-mask, and boundary tests.
- `tests/testthat/test-missing-predictor-binary.R`: moves the unsupported-family
  boundary sentinel from `nbinom2()` to `truncated_nbinom2()`.
- `vignettes/missing-data.Rmd` and `pkgdown-site/articles/missing-data.html`:
  add the NB2 count missing-predictor example.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: record the syntax, likelihood, and
  implementation-slice boundary.
- `NEWS.md`, `man/drmTMB.Rd`, `man/miss_control.Rd`, `man/impute_model.Rd`,
  and `man/imputed.Rd`: update public release and reference documentation.

## Checks Run

```sh
air format R/missing-data.R R/drmTMB.R tests/testthat/test-missing-predictor-nbinom2.R tests/testthat/test-missing-predictor-binary.R
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-nbinom2.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-binary.R')"
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing-predictor')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
```

Results:

- Focused `test-missing-predictor-nbinom2.R`: 20 expectations, no failures,
  warnings, or skips.
- Adjusted `test-missing-predictor-binary.R`: 21 expectations, no failures,
  warnings, or skips.
- Combined `devtools::test(filter = 'missing-predictor')`: 279 expectations,
  no failures, warnings, or skips.
- `test-gaussian-location-scale.R`: 71 expectations, no failures or warnings;
  one CRAN-gated skip.
- `pkgdown::build_article('missing-data', new_process = FALSE)` rebuilt
  `pkgdown-site/articles/missing-data.html`.
- `pkgdown::check_pkgdown()`: no problems found.

The full package test suite was not rerun after MD7c. The most recent full
suite in this lane remains the MD7b run with 8,917 expectations, no failures,
warnings, or skips.

## Tests Of The Tests

The NB2 predictor test independently recomputes `logLik(fit)` from the
observed NB2 predictor likelihood, the Gaussian response likelihood, and
deterministic finite summation over missing count states. A second test repeats
that likelihood check with missing responses included. Boundary tests reject
negative observed counts, fractional observed counts, and grouped NB2 predictor
models.

## Consistency Audit

```sh
rg -n 'nbinom2\(\)|MD7c|NB2 predictor|negative-binomial count|sigma_mi_abundance|conditional expected counts for count predictors' pkgdown-site/articles/missing-data.html vignettes/missing-data.Rmd man/impute_model.Rd man/drmTMB.Rd man/imputed.Rd man/miss_control.Rd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md R/missing-data.R R/drmTMB.R src/drmTMB.cpp tests/testthat/test-missing-predictor-nbinom2.R
rg -n 'negative-binomial count predictors|Negative-binomial count predictors|conditional expected counts for Poisson|Poisson count predictors, Tweedie|MD7b/MD8a|MD7b/MD8b' vignettes/missing-data.Rmd man/impute_model.Rd man/drmTMB.Rd man/imputed.Rd man/miss_control.Rd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md pkgdown-site/articles/missing-data.html
```

The positive scan confirmed current NB2 syntax, rendered article text,
generated Rd text, implementation-slice labels, TMB family mapping, and
`sigma_mi_abundance` extraction. The stale scan returned only current
positive wording in `NEWS.md`; it did not find old generated or article text
claiming that NB2 missing predictors remain unimplemented.

## GitHub Issue Maintenance

```sh
gh issue list --repo itchyshin/drmTMB --search "nbinom2 missing predictor impute_model" --limit 20
gh issue list --repo itchyshin/drmTMB --search "negative binomial missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing predictor count" --limit 20
```

The exact NB2 and negative-binomial searches returned no issue rows. The broad
count search returned only #436, the four-week Phase 6c random-slope and
digital-twin exchange sprint, so no missing-data-specific issue comment or
closure was made.

## What Did Not Go Smoothly

The implementation exposed a small earlier mapping gap: lognormal and Gamma
missing-predictor scale parameters were present in metadata and coefficient
extraction but were still mapped as fixed parameters. MD7c fixed the common
`has_sigma_mi` gate so NB2, lognormal, and Gamma missing-predictor scale
parameters are all estimable.

## Team Learning

Count predictors should not be treated as one Poisson bucket. Poisson is the
right first model for mean-variance equality, while NB2 is the first
overdispersion-aware count model with the same finite-sum integration contract.

## Known Limitations

MD7c is one fixed-effect NB2 missing predictor in a univariate Gaussian
location model. Zero-truncated or hurdle count predictor models, grouped or
structured count predictor models, multiple missing predictors, transformed or
interacted `mi()` terms, EM/profile engines, REML, simulation-based imputed
summaries, response imputation, measurement-error models, and pigauto
interoperability remain planned.

## Next Actions

- Add Tweedie or exact-zero semi-continuous positive predictors if users need a
  positive-continuous route with genuine zeros.
- Add grouped or structured non-Gaussian predictor models after choosing a
  family-specific random-effect contract.
- Keep multiple missing predictors separate until the joint predictor model and
  any conditional-independence assumption are explicit.
