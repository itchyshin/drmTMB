# After Task: Likelihood Row Weights

## Goal

Implement `weights =` as a top-level fitting argument for ordinary
log-likelihood row multipliers, while keeping known sampling variance and
covariance in `meta_known_V(V = V)`.

## Implemented

- Added `weights = NULL` to `drmTMB()`.
- Evaluated weights in the model-fitting environment and filtered them to the
  modelled rows.
- Stored processed weights in `fit$model$weights`.
- Added `weights.drmTMB()` so `weights(fit)` returns the processed vector.
- Passed weights to the TMB template as `DATA_VECTOR(weights)`.
- Multiplied independent-row likelihood contributions by `weights(i)`.
- Used one complete-row weight per bivariate Gaussian response pair.
- Rejected non-unit weights with full dense known-covariance
  `meta_known_V(V = V)` paths because those paths are joint MVN likelihoods,
  not sums of independent row contributions.

## Mathematical Contract

For independent univariate rows:

```text
nll = sum_i w_i {-log f(y_i | theta_i)}
```

For bivariate Gaussian rows without full known sampling covariance:

```text
nll = sum_i w_i {-log f([y1_i, y2_i]' | theta_i)}
```

Here `w_i` is a non-negative likelihood multiplier. It is not a known sampling
variance. Known sampling variance or covariance remains:

```r
meta_known_V(V = V)
```

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-gaussian-location-scale.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-phylo-utils.R`
- `man/drmTMB.Rd`
- `man/weights.drmTMB.Rd`
- `NAMESPACE`
- `README.md`
- `NEWS.md`
- `_pkgdown.yml`
- `vignettes/source-map.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/11-reference-programme.md`
- `docs/design/22-likelihood-weights.md`
- `docs/design/23-large-data-memory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `ROADMAP.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|phylo-utils')"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n "S3method\\(weights|weights.drmTMB|@param weights|weights =" NAMESPACE man R tests docs/design vignettes/source-map.Rmd README.md NEWS.md _pkgdown.yml`
- `rg -n 'weights.*not yet|does not yet have.*weights|planned.*weights|weights.*planned|Status: planned' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man _pkgdown.yml pkgdown-site --glob '!docs/dev-log/after-task/**'`
- `rg -n 'David \\[surname|Buerkner|Bürkner|Hadfield|Amari|Gelman|Fletcher' README.md ROADMAP.md NEWS.md docs/design docs/dev-log vignettes R tests man _pkgdown.yml`

Current results:

- Gaussian location-scale targeted tests: 67 passed.
- Bivariate Gaussian targeted tests: 101 passed.
- Phylo-utils targeted tests: 45 passed.
- Combined targeted rerun after namespace repair: 213 passed.
- Full `devtools::test()`: 1215 passed.
- Source-map vignette rendered.
- `devtools::document()` completed.
- `pkgdown::check_pkgdown()` found no problems before and after site build.
- `pkgdown::build_site()` completed.
- `tools/fix-pkgdown-favicon-mime.R` completed on the generated site.
- First `devtools::check()` attempt exposed a missing `stats::weights` import.
- Final `devtools::check()` completed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check` is clean.

## Tests Of The Tests

- Constant weights of 2 keep Gaussian estimates stable and double `logLik`.
- Integer weights match explicit row duplication, including zero weights.
- Malformed weights test wrong length, negative values, missing values,
  all-zero values, and matrix input.
- Bivariate Gaussian constant weights of 2 keep estimates stable and double
  the complete-row likelihood.
- A full dense known-covariance test rejects non-unit weights, protecting the
  distinction between likelihood weighting and `meta_known_V(V = V)`.

## Consistency Audit

- `README.md` now states that `weights =` are row log-likelihood multipliers.
- `NEWS.md` records the user-facing change.
- `_pkgdown.yml` includes `weights.drmTMB`.
- `docs/design/01-formula-grammar.md` marks top-level `weights =` as
  implemented and outside formula grammar.
- `docs/design/03-likelihoods.md` contains the matching likelihood equations.
- `docs/design/22-likelihood-weights.md` now describes implemented status.
- `docs/design/23-large-data-memory.md` keeps aggregation separate from
  ordinary likelihood weights.
- `vignettes/source-map.Rmd` maps the implementation, tests, and docs.

## What Did Not Go Smoothly

Adding a new TMB data vector required updating the direct hidden
`model_type = 99` phylogenetic prior test helper. This is a useful reminder
that direct `MakeADFun()` tests must be searched whenever the TMB data
contract changes.

The first `devtools::check()` attempt also caught a namespace issue: the new
`weights.drmTMB()` S3 method needed `@importFrom stats weights`. The fix was
small, but it belongs in the implementation checklist for future S3 methods.

The first implementation routes weights through all independent-row families,
but the deepest tests are Gaussian and bivariate Gaussian. That is acceptable
for this phase because Gaussian is the main location-scale path and bivariate
complete-row weighting is the tricky naming/interpretation case.

## Team Learning

- Ada should continue using small implementation phases with full consistency
  audits before moving on.
- Boole and Emmy should keep top-level fitting options separate from
  distributional formula grammar.
- Fisher should require independent likelihood or comparator checks before
  making strong claims about frequency-weight equivalence in random-effect,
  structured, or known-covariance settings.
- Grace should treat dense covariance plus weights as a future design problem,
  not something to silently approximate.
- Rose should search for stale `weights planned` wording after the pkgdown
  build.

## Known Limitations

- `weights =` does not reduce memory use by itself.
- Dense full known-covariance `meta_known_V(V = V)` cannot yet be combined with
  non-unit weights.
- Response-specific bivariate weights are not implemented.
- Sufficient-statistic aggregation for very large Gaussian data remains a
  separate scaling feature.

## Next Actions

1. Push the completed phase and watch GitHub Actions for both R-CMD-check and
   pkgdown.
2. Add a future tutorial paragraph explaining when to use `weights =`,
   `meta_known_V(V = V)`, `sigma ~ x`, and `sd(group) ~ x`.
3. Consider a focused follow-up test for one non-Gaussian independent family,
   probably Poisson, to prove the shared TMB weighting path beyond Gaussian.
