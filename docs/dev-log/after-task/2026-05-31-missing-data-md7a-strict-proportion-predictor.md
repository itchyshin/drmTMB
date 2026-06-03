# After Task: Missing Data MD7a Strict Proportion Predictor

## Goal

Extend the missing-predictor lane from finite-state predictors to one strict
proportion predictor in a univariate Gaussian location model.

## Implemented

MD7a adds `beta()` as a predictor-model family for `impute_model()` when the
first `mi()` predictor is numeric and strictly inside `(0, 1)`. The fitted
public syntax is:

```r
drmTMB(
  bf(y ~ z + mi(cover), sigma ~ 1),
  data = dat,
  impute = list(
    cover = impute_model(cover ~ z, family = beta())
  ),
  missing = miss_control(predictor = "model")
)
```

The route accepts one fixed-effect beta predictor model with complete
imputation-model covariates. It rejects observed predictor values at 0 or 1,
non-numeric predictors, missing imputation-model covariates, grouped or
structured beta predictor models, multiple `mi()` predictors, and transformed
or interacted `mi()` terms.

## Mathematical Contract

For observed strict proportions \(x_i \in (0, 1)\), the predictor model is:

\[
\operatorname{logit}(\mu_{x,i}) = W_i \alpha,\qquad
\phi_x = \exp(-2\log\sigma_x).
\]

Observed predictor rows add the beta predictor density and the Gaussian
response density:

\[
\log f_\beta(x_i; \mu_{x,i}, \phi_x)
  + \log f_N(y_i; \mu_i(x_i), \sigma_i).
\]

Missing predictor rows with observed responses use deterministic
Gauss-Legendre quadrature over \(x \in (0, 1)\):

\[
\log \sum_q w_q
  f_\beta(x_q; \mu_{x,i}, \phi_x)
  f_N(y_i; \mu_i(x_q), \sigma_i).
\]

Rows where both the response and the proportion predictor are missing are
retained for row accounting but contribute no observed-data likelihood.

## Files Changed

- `R/missing-data.R`: beta predictor model building, quadrature nodes and
  weights, beta density helpers, TMB data plumbing, and `imputed()` conditional
  quadrature means.
- `R/drmTMB.R`: public argument documentation, MD7a version tagging, and
  sigma-mi parameter reporting for beta predictor models.
- `src/drmTMB.cpp`: `mi_family == 4` beta/quadrature likelihood branch.
- `tests/testthat/test-missing-predictor-beta.R`: independent likelihood,
  response-mask combination, and boundary tests.
- `tests/testthat/test-phylo-utils.R`: direct TMB fixture now supplies dummy
  missing-predictor quadrature vectors.
- `vignettes/missing-data.Rmd`, `NEWS.md`, `_pkgdown.yml`,
  `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and
  `docs/design/149-missing-data-design.md`: public and design docs.
- `man/*.Rd`, `NAMESPACE`: roxygen outputs.

## Checks Run

```sh
Rscript -e "devtools::load_all()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-beta.R')"
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-beta.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-categorical.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-ordered.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-binary.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-predictor-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-beta-location-scale.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-gaussian.R')"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE)"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-phylo-utils.R')"
Rscript -e "devtools::load_all(); devtools::test()"
git diff --check
```

Results:

- Initial `test-missing-predictor-beta.R`: 20 expectations, no failures,
  warnings, or skips.
- Post-document `test-missing-predictor-beta.R`: 20 expectations, no failures,
  warnings, or skips.
- `test-missing-predictor-categorical.R`: 24 expectations, no failures,
  warnings, or skips.
- `test-missing-predictor-ordered.R`: 23 expectations, no failures, warnings,
  or skips.
- `test-missing-predictor-binary.R`: 21 expectations, no failures, warnings,
  or skips.
- `test-missing-predictor-gaussian.R`: 109 expectations, no failures,
  warnings, or skips.
- `test-beta-location-scale.R`: 85 expectations, no failures, warnings, or
  skips.
- `test-missing-data-control.R`: 13 expectations, no failures, warnings, or
  skips.
- `test-missing-response-gaussian.R`: 32 expectations, no failures, warnings,
  or skips.
- `pkgdown::build_article('missing-data', new_process = FALSE)` rebuilt
  `pkgdown-site/articles/missing-data.html`; the rendered article contains the
  strict proportion example, beta-family imputation syntax, and conditional
  quadrature-mean wording.
- `pkgdown::check_pkgdown()`: no problems found.
- The first full `devtools::test()` run reached the end with 8,886 passing
  expectations and three direct-TMB fixture errors in `test-phylo-utils.R`;
  those hand-built data fixtures lacked the new dummy `mi_quad_nodes` and
  `mi_quad_weights` values.
- After patching the direct-TMB fixture, `test-phylo-utils.R`: 79
  expectations, no failures, warnings, or skips.
- Final full-suite result after the fixture patch: 8,898 expectations, no
  failures, warnings, or skips in 625.3 seconds.
- `git diff --check`: no whitespace errors.

## Tests Of The Tests

The beta predictor test independently recomputes `logLik(fit)` from the beta
predictor likelihood and Gaussian response likelihood. For missing predictor
rows it recomputes the same deterministic quadrature sum used by TMB, including
the case where the response is also missing and therefore contributes no
observed-data likelihood.

Boundary tests reject exact 0/1 observed predictor values, factor predictors,
and grouped beta predictor models.

## Consistency Audit

Stale wording scans:

```sh
rg -n "beta/proportion predictors|proportion predictors.*not implemented|beta/proportion.*remain planned|strict proportion.*planned|family = beta\\(\\).*planned" docs/design/149-missing-data-design.md docs/design/03-likelihoods.md docs/design/01-formula-grammar.md vignettes/missing-data.Rmd NEWS.md R man README.md ROADMAP.md docs/dev-log/known-limitations.md
rg -n "Strict proportion missing predictors|impute = list\\(cover = impute_model\\(cover ~ z, family = beta\\(\\)\\)\\)|conditional quadrature means|count predictors|positive-continuous" pkgdown-site/articles/missing-data.html
```

The scans found current implementation wording for strict beta/proportion
predictors and remaining-boundary wording for count predictors,
positive-continuous non-Gaussian predictor models, exact 0/1 proportions, and
denominator-aware beta-binomial predictor models.

## GitHub Issue Maintenance

Issue searches:

```sh
gh issue list --repo itchyshin/drmTMB --search "beta proportion missing predictor impute_model" --limit 20
gh issue list --repo itchyshin/drmTMB --search "strict proportion missing predictor" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing predictor beta" --limit 20
```

All three searches returned no open issue rows, so no issue comment or closure
was made.

## What Did Not Go Smoothly

Adding new top-level `DATA_VECTOR` entries for quadrature exposed a direct-TMB
test-fixture contract in `test-phylo-utils.R`. Normal `drmTMB()` fits already
received dummy quadrature data through `drm_tmb_missing_predictor_data()`, but
tests that call `TMB::MakeADFun()` directly also need to supply every TMB data
object. The full test suite caught this; the shared phylo fixture now supplies
`mi_quad_nodes = 0` and `mi_quad_weights = 1`.

## Team Learning

Every new top-level TMB `DATA_*` object should trigger a scan for direct
`TMB::MakeADFun()` tests, not just package-level model fits. The phylo utility
tests are a standing fixture to remember.

## Known Limitations

MD7a is one fixed-effect strict proportion predictor in a univariate Gaussian
location model. It does not handle exact 0/1 proportions, beta-binomial
denominators, grouped or structured beta predictor models, multiple missing
predictors, transformed or interacted `mi()` terms, count predictors,
positive-continuous non-Gaussian predictor models, EM/profile engines, REML,
simulation-based imputed summaries, response imputation, measurement-error
models, or pigauto interoperability.

## Next Actions

The next missing-predictor slice should either add count predictors
(Poisson/negative-binomial fixed-effect imputation models with exact finite or
truncated summation) or positive-continuous predictors (lognormal/Gamma fixed
effect models, likely with quadrature or a carefully reviewed Laplace
parameterization). gllvmTMB should mirror the public contract but keep any
higher-dimensional latent-variable missingness in its own package lane.
