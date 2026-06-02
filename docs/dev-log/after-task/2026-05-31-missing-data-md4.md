# After Task: Missing Data MD4 Structured Predictors

## Goal

Fit the first structured missing-predictor route without widening the missing
data surface beyond one univariate Gaussian `mi()` predictor.

## Implemented

MD4 now supports one explicit intercept-only structured Gaussian covariate
model for a missing numeric predictor:

```r
drmTMB(
  bf(y ~ z + mi(x), sigma ~ 1),
  data = dat,
  impute = list(x = x ~ z + relmat(1 | line, Q = Q)),
  missing = miss_control(predictor = "model")
)
```

The same route can use one of `phylo()`, coordinate `spatial()`, `animal()`, or
`relmat()` in the `impute` formula. The structured covariate model is explicit;
it is not inherited from the response model.

## Mathematical Contract

For MD4, the covariate model is:

```text
u_x ~ Normal(0, sd_x_struct^2 Q_x^-1)
x_i ~ Normal(W_i alpha + a_i u_x[node_i], sigma_x^2)
```

`Q_x` is built by the explicit structured covariate marker. The fitted slice is
intercept-only, so `a_i = 1` in public syntax. Missing `x_i` values and the
structured covariate field are TMB random effects integrated by the Laplace
approximation. The C++ implementation mirrors the existing centered structured
field parameterization: `u_x` enters the predictor directly, while `sd_x_struct`
scales the precision-prior contribution.

## Files Changed

- `R/missing-data.R`: parses one structured `impute` marker, builds the
  structured covariate field, exports TMB data, and records structured metadata
  under `fit$missing_data$predictors`.
- `R/drmTMB.R`: includes structured imputation variables in missing-data
  completeness checks, initializes/maps `u_mi_struct` and
  `log_sd_mi_struct`, adds `u_mi_struct` to random parameters, labels the
  fitted slice as `MD4`, and exposes `sd_mi_<marker>_<variable>` coefficients.
- `src/drmTMB.cpp`: adds the structured missing-predictor data, prior, reports,
  and ADREPORTs.
- `tests/testthat/test-missing-predictor-gaussian.R`: adds focused MD4
  support, response-mask composition, and malformed-input tests.
- `tests/testthat/test-phylo-utils.R`: updates direct TMB scaffolds for the new
  mapped-off parameters and data fields.
- `docs/design/149-missing-data-design.md`,
  `docs/design/03-likelihoods.md`, `docs/design/01-formula-grammar.md`,
  `R/formula-markers.R`, `R/drmTMB.R`, `NEWS.md`, and generated Rd files now
  describe MD4 as fitted and keep the remaining boundaries explicit.

## Checks Run

```sh
air format R/missing-data.R R/formula-markers.R R/drmTMB.R tests/testthat/test-missing-predictor-gaussian.R tests/testthat/test-phylo-utils.R
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-phylo-utils.R')"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Results:

- `test-missing-predictor-gaussian.R`: 109 expectations, no failures.
- `test-phylo-utils.R`: 79 expectations, no failures.
- `devtools::test()`: 8,810 expectations, no failures, warnings, or skips.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: no whitespace errors.

## Tests Of The Tests

The new MD4 tests exercise a fitted `relmat(1 | line, Q = Q)` covariate model,
the combination with `response = "include"`, and four boundary errors:
structured covariate slopes, simultaneous grouped and structured covariate
effects, `phylo_interaction()` in `impute`, and missing structured grouping
values outside the explicit `mi()` predictor.

## Consistency Audit

Stale wording scan:

```sh
rg -n "structured covariate models remain planned|structured covariate models|MD3a/MD3b missing-predictor|fitted MD3a/MD3b|public imputation summaries remain|imputation summaries remain planned|one random-intercept Gaussian predictor model|fixed-effect or one random-intercept" R man NEWS.md README.md ROADMAP.md docs/design vignettes docs/dev-log/known-limitations.md
```

The remaining hits are intended MD4 boundary errors, historical MD5/MD4
headings, and current wording that says simulation-based imputation summaries
remain planned. Current public docs no longer say structured covariate models
remain wholly planned.

GitHub issue audit:

```sh
gh issue list --repo itchyshin/drmTMB --search "missing data structured mi impute relmat" --limit 20
gh issue list --repo itchyshin/drmTMB --search "miss_control mi impute structured" --limit 20
gh issue list --repo itchyshin/drmTMB --search "MD4 missing predictor" --limit 20
```

All three searches returned no matching open issues, so no issue comment or
closure was made.

## What Did Not Go Smoothly

The first C++ draft multiplied the structured field by `sd_mi_struct` in the
linear predictor while also scaling the precision prior by `sd_mi_struct`. That
would have double-counted the scale. The implementation now matches the
existing centered structured-effect parameterization: the latent field enters
the predictor directly and the SD appears in the prior.

## Team Learning

Gauss/Noether review should explicitly compare new structured latent fields to
the existing `u_phylo` parameterization before tests are added. The same
symbolic contract now appears in `docs/design/03-likelihoods.md`.

## Known Limitations

MD4 does not support structured covariate slopes, more than one structured
covariate model, grouped-plus-structured covariate effects,
`phylo_interaction()` covariate models, automatic inheritance from the response
model, joint response-covariate structured correlations, dense known-`V`
partial-response slicing, multiple missing predictors, factor or non-Gaussian
predictor models, EM/profile engines, REML, measurement-error models, simulated
imputations, or multiple-imputation pooling.

## Next Actions

The next missing-data implementation choices should be a small simulation
recovery battery for MD3a/MD3b/MD4, or a separate design gate for dense known
`V` partial-response slicing. Measurement-error models should remain a later
lane because they need a different observation-error contract for covariates.
