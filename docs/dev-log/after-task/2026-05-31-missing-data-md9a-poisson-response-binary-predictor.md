# After Task: Missing Data MD9a Poisson Response Binary Predictor

## Goal

Open the first non-Gaussian response missing-predictor route without claiming a
general missing-data system.

## Implemented

MD9a supports one fixed-effect binary missing predictor inside an ordinary
Poisson response model:

```r
drmTMB(
  bf(count ~ z + mi(treatment)),
  family = poisson(),
  data = dat,
  impute = list(
    treatment = impute_model(treatment ~ z, family = binomial())
  ),
  missing = miss_control(predictor = "model")
)
```

The route requires complete count responses. It rejects zero-inflated Poisson
formulas, Poisson response random effects, structured Poisson response terms,
non-binary missing predictor families, and ordinary missing predictors outside
the explicit `mi()` term.

## Mathematical Contract

For the binary missing predictor,

```text
pi_i = logit^-1(W_i alpha)
x_i ~ Bernoulli(pi_i)
eta_yi(x) = o_i + eta_without_x_i + beta_x x
mu_yi(x) = exp(eta_yi(x))
```

Observed binary predictor rows contribute:

```text
log L_i = log p(x_i | pi_i) + log Poisson(y_i | mu_yi(x_i))
```

Missing binary predictor rows sum over the two states:

```text
log L_i =
  logspace_add(
    log(1 - pi_i) + log Poisson(y_i | mu_yi(0)),
    log(pi_i)     + log Poisson(y_i | mu_yi(1))
  )
```

This is likelihood-based integration over a discrete predictor state, not a
preprocessing fill-in and not EM.

## Files Changed

- `R/drmTMB.R`: routes `impute` and `missing` into Poisson model building,
  validates the MD9a boundary, starts `beta_mi`, extracts `mi_*` coefficients for
  Poisson fits, and records `fit$missing_data$version = "MD9a"`.
- `src/drmTMB.cpp`: adds the Poisson-response Bernoulli `mi()` finite-sum
  likelihood branch.
- `R/missing-data.R`: makes binary `imputed()` probabilities condition on the
  Poisson response likelihood when the response model is Poisson.
- `tests/testthat/test-missing-predictor-poisson-response.R`: adds independent
  log-likelihood and malformed-input checks.
- `tests/testthat/test-missing-data-control.R`: updates the boundary test so
  Poisson `predictor = "model"` reaches the new binary-only error rather than
  the old Gaussian-only guard.
- `vignettes/missing-data.Rmd`: adds the Poisson-response binary missing
  predictor example and updates the current-boundary table.
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: record the syntax, likelihood, test
  contract, and remaining boundaries.
- `NEWS.md`, `man/drmTMB.Rd`, `man/miss_control.Rd`, and `man/impute_model.Rd`:
  update public documentation.

## Checks Run

```sh
air format R/drmTMB.R R/missing-data.R tests/testthat/test-missing-data-control.R tests/testthat/test-missing-predictor-poisson-response.R
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-poisson-response.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-poisson-mean.R')"
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing-predictor')"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE, quiet = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::load_all(); pkgdown::build_reference()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::test()"
git diff --check
```

Results:

- Focused MD9a test: 13 expectations, no failures, warnings, or skips.
- Missing-data control test: 13 expectations, no failures, warnings, or skips.
- Ordinary Poisson regression test: 138 expectations, no failures, warnings, or
  skips.
- Missing-predictor test suite: 389 expectations, no failures, warnings, or
  skips.
- Full package test suite: 9,090 expectations, no failures, warnings, or skips.
- `devtools::document()`, `pkgdown::build_article("missing-data")`,
  `pkgdown::build_reference()`, `pkgdown::check_pkgdown()`, and
  `git diff --check` passed.

## Tests Of The Tests

The MD9a test independently recomputes the fitted log likelihood from the
Bernoulli predictor density and the Poisson response density. It checks the
finite two-state sum for missing predictors rather than only checking that the
fit converges. Boundary tests reject non-binary Poisson-response missing
predictor families, zero-inflated Poisson formulas, and missing ordinary
predictors outside `mi()`.

## Consistency Audit

Positive scan:

```sh
rg -n "MD9a|Poisson responses with binary missing predictors|Poisson response with one missing binary predictor|first non-Gaussian response route|Poisson-response plus binary|family = poisson\\(\\).*mi\\(treatment\\)" vignettes/missing-data.Rmd pkgdown-site/articles/missing-data.html R/drmTMB.R R/missing-data.R man/drmTMB.Rd man/miss_control.Rd man/impute_model.Rd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md tests/testthat/test-missing-predictor-poisson-response.R
```

Stale scan:

```sh
rg -n 'only with a univariate Gaussian formula|implemented only for one `mi\(\)` missing predictor in a univariate Gaussian|Poisson count predictors belong to the later|non-Gaussian response route.*planned|Poisson-response.*not implemented' vignettes/missing-data.Rmd pkgdown-site/articles/missing-data.html pkgdown-site/reference/drmTMB.html pkgdown-site/reference/miss_control.html pkgdown-site/reference/impute_model.html R/drmTMB.R R/missing-data.R man/drmTMB.Rd man/miss_control.Rd man/impute_model.Rd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/149-missing-data-design.md NEWS.md
```

The positive scan found the MD9a route in source docs, generated Rd, rendered
article HTML, design docs, NEWS, and tests. The stale scan found only intentional
boundary wording for zero-inflated Poisson `mi()` and unsupported
Poisson-response extensions.

Local `gllvmTMB` was checked because the missing-data vocabulary is shared, but
it is not a drop-in source for this scalar route. Its current local branch
contains `mi()` setup code for missing predictors, while its README still marks
missing predictors as out. Installed `glmmTMB` 1.1.11 documents ordinary
`na.action` row dropping; it does not provide the in-likelihood `mi()` predictor
mechanism used here.

## GitHub Issue Maintenance

No issue was changed in this pass. The branch is already a broad dirty
multi-lane working tree, and the durable handoff for the next agent is this
after-task report plus the check-log entry.

## What Did Not Go Smoothly

Two command-shape mistakes were corrected. The ordinary Poisson test file is
`tests/testthat/test-poisson-mean.R`, not `test-poisson.R`. This installed
`pkgdown::build_reference()` does not accept `new_process` or `quiet`, so it was
rerun with no extra arguments.

## Team Learning

The phrase "missing predictor module" is now too broad unless the response
family is stated. The public wording should distinguish the broad Gaussian
response family-coverage lane from narrow non-Gaussian response openings such as
MD9a.

## Known Limitations

MD9a is one fixed-effect binary missing predictor inside an ordinary
fixed-effect Poisson response mean model with complete count responses. Missing
Poisson responses, zero-inflated Poisson response models with `mi()`, Poisson
response random or structured effects with `mi()`, non-binary missing predictors
in Poisson response models, multiple missing predictors, grouped or structured
non-Gaussian predictor models, transformed or interacted `mi()` terms,
EM/profile/REML engines, simulated imputation summaries, measurement-error
models, and pigauto interoperability remain planned.

## Next Actions

The next missing-data slice should choose one explicit axis. Reasonable choices
are Poisson response plus continuous Gaussian `mi()`, Poisson response plus
ordered/categorical `mi()`, NB2 response plus binary `mi()`, or multiple
missing predictors. Each needs its own likelihood check because the response
family changes the conditional imputation probabilities.
