# After Task: Missing Data MD3b

Date: 2026-05-31

## Goal

Extend the first univariate Gaussian missing-predictor route from a fixed-effect
covariate model to one grouped random-intercept covariate model without opening
structured imputation, random slopes, multiple missing predictors, or public
imputation summaries.

The fitted syntax is:

```r
drmTMB(
  bf(y ~ z + mi(x), sigma ~ 1),
  data = dat,
  impute = list(x = x ~ z + (1 | group)),
  missing = miss_control(predictor = "model")
)
```

## Implemented

MD3b supports one numeric `mi(x)` term in a univariate Gaussian location formula
and one additive random-intercept term in the Gaussian covariate model for
`x`. Missing `x` values remain latent TMB random effects. The grouped covariate
intercepts are a separate standard-normal latent block scaled by
`sd_mi_group_x`; they are integrated by the same Laplace fit as response-model
random effects.

The parser rejects random slopes, multiple covariate random-effect terms,
non-additive random-effect expressions, transformed or nested grouping
variables, missing group values, and grouping variables with fewer than two
levels. Ordinary predictors, impute-model predictors, response masks, grouping
variables, and offsets still have to be explicit and complete unless a fitted
missing-data slice says otherwise.

## Mathematical Contract

For observed and latent values of the missing predictor, MD3b fits:

```text
x_i | alpha, a_g, sigma_x ~ Normal(W_i alpha + a_{g_i}, sigma_x^2)
a_g = sd_x_group * u_g
u_g ~ Normal(0, 1)
sigma_x = exp(log_sigma_mi)
sd_x_group = exp(log_sd_mi_group)
```

The response model uses the observed or latent `x_i` in place of the finite
placeholder required by R's model matrix. The predictor likelihood includes the
Gaussian normalizing constant through `dnorm(..., true)`. Positive covariate
scales stay on unconstrained log scales in TMB and are reported on the response
scale as `sigma_mi_x` and `sd_mi_group_x`.

## Files Changed

- `R/missing-data.R`: grouped `impute` parsing, validation, metadata, and TMB
  missing-predictor data fields.
- `R/drmTMB.R`: `impute` variable collection, MD3b version selection, grouped
  starts/maps, random-parameter routing, and coefficient extraction.
- `src/drmTMB.cpp`: grouped covariate random-intercept data, parameters,
  likelihood contribution, and reports.
- `R/formula-markers.R`, `man/mi.Rd`, `man/miss_control.Rd`, and
  `man/drmTMB.Rd`: public missing-predictor wording.
- `docs/design/149-missing-data-design.md`, `docs/design/03-likelihoods.md`,
  `docs/design/01-formula-grammar.md`, and `NEWS.md`: design and release
  wording for the fitted MD3b boundary.
- `tests/testthat/test-missing-predictor-gaussian.R` and
  `tests/testthat/test-phylo-utils.R`: grouped MD3b tests and direct TMB
  scaffold synchronization.

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-phylo-utils.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-biv-gaussian.R')"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
```

Final results:

- `test-missing-data-control.R`: 13 expectations, no failures.
- `test-missing-predictor-gaussian.R`: 55 expectations, no failures.
- `test-missing-response-gaussian.R`: 32 expectations, no failures.
- `test-phylo-utils.R`: 79 expectations, no failures.
- `test-gaussian-location-scale.R`: 71 expectations plus the existing CRAN
  skip, no failures.
- `test-biv-gaussian.R`: 718 expectations, no failures.
- `devtools::test()`: 8,756 expectations, no failures, warnings, or skips.
- `pkgdown::check_pkgdown()`: no problems found.

## Tests Of The Tests

The new tests exercise both successful and malformed MD3b paths. They check
retained-row accounting, grouped metadata, finite `sd_mi_group_x`, finite
optimizer gradients, response masks combined with grouped `mi()`, random-slope
rejection, multiple-random-effect rejection, and missing grouping-variable
rejection. The direct TMB probe tests guard the shared data/parameter contract
for code paths that bypass the R builder.

## Consistency Audit

The implementation, equations, R syntax, and docs now describe the same fitted
model: one numeric `mi(x)` term with a fixed-effect or one random-intercept
Gaussian covariate model. The stale-wording scan:

```sh
rg -n "MD3b|grouped covariate random effects|one random-intercept|random-intercept covariate|impute = list\\(x = x ~ z \\+ \\(1|impute = list\\(x = x ~ 1 \\+ z \\+ \\(1|covariate random slopes|multiple missing predictors|structured covariate|imputed\\(\\)|measurement-error|measurement error" R man NEWS.md README.md ROADMAP.md docs/design vignettes docs/dev-log/known-limitations.md
```

found current MD3b implementation wording, intentional MD3a historical slice
boundaries, and current deferred-scope wording. No current public doc claims
covariate random slopes, structured covariate models, multiple missing
predictors, `imputed()` summaries, EM/profile engines, REML, or
measurement-error models are implemented.

## GitHub Issue Maintenance

These searches returned no matching open issues, so no issue comment or closure
was made:

```sh
gh issue list --repo itchyshin/drmTMB --search "missing data mi grouped random intercept impute" --limit 20
gh issue list --repo itchyshin/drmTMB --search "miss_control mi impute missing predictor" --limit 20
```

## What Did Not Go Smoothly

The first grouped parameter pass exposed the same direct-TMB-scaffold risk seen
in MD3a: tests that call `TMB::MakeADFun()` directly need dummy values for each
new global data and parameter field. Keeping the grouped fields mapped out for
non-MD3b fits avoided changing ordinary fits, but the direct scaffolds still
had to be synchronized explicitly.

## Team Learning

Gauss and Noether's main check is that MD3b is a covariate model, not a
response-model random-effect shortcut. The group effect enters the predictor
model for `x`; the response model then uses the observed or latent `x_i`.
Curie's useful guardrail is that every future missing-data slice should include
at least one direct TMB scaffold check if the global TMB data contract changes.

## Known Limitations

MD3b does not implement covariate random slopes, multiple covariate
random-effect terms, structured covariate models, multiple missing predictors,
factor or non-Gaussian predictor models, transformed or interacted `mi()` terms,
dense known-`V` partial-response slicing, EM/profile engines, REML,
measurement-error models, public `imputed()` summaries, or pigauto
interoperability.

## Next Actions

The next missing-data slices are MD4 for explicitly designed structured
covariate models and MD5 for `imputed()` summaries using likelihood-based
conditional modes and standard errors. Before either slice, keep the parser
strict and add the shared failure-path tests first.
