# After Task: Count Exposure Offsets

## Goal

Implement standard R exposure offsets for count models without changing the
meaning of `sigma`, `zi`, `hu`, `weights`, or `meta_known_V(V = V)`.

## Implemented

Poisson, zero-inflated Poisson, NB2, and zero-inflated NB2 now accept
`offset(log(exposure))` in the `mu` formula. The offset is extracted from the
model frame, validated as one finite value per modelled row, passed to TMB as
`offset_mu`, included in starting values, stored in `fit$model$offset$mu`, and
used by `predict()` for both training data and `newdata`.

Offsets remain rejected in downstream formulas such as `sigma ~`,
`zi ~`, and `hu ~`, and in model families where the likelihood contract has not
yet been designed for exposure offsets.

## Mathematical Contract

For an exposure or effort variable `e_i`, users write:

```r
drmTMB(
  drm_formula(count ~ habitat + offset(log(e_i))),
  family = poisson(link = "log"),
  data = dat
)
```

The implemented predictor is:

```text
eta_mu_i = log(e_i) + X_mu[i, ] beta_mu
mu_i = exp(eta_mu_i) = e_i * exp(X_mu[i, ] beta_mu)
```

For NB2, the offset changes only the conditional mean:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
log(mu_i) = log(e_i) + X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
size_i = 1 / sigma_i^2
Var(y_i) = mu_i + sigma_i^2 * mu_i^2
```

Zero-inflated variants use the same `mu_i`; the structural-zero probability is
still modelled separately by `zi ~ predictors`.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-poisson-mean.R`
- `tests/testthat/test-zi-poisson.R`
- `tests/testthat/test-nbinom2-location-scale.R`
- `tests/testthat/test-zi-nbinom2.R`
- `tests/testthat/test-phylo-utils.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/known-limitations.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`
- `man/drmTMB.Rd`

## Checks Run

- `Rscript -e "devtools::test(filter = 'poisson-mean|zi-poisson|nbinom2-location-scale|zi-nbinom2')"`: 264 passed.
- `Rscript -e "rmarkdown::render('vignettes/distribution-families.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/formula-grammar.Rmd', output_dir = tempdir(), quiet = TRUE)"`: passed.
- `Rscript -e "devtools::document()"`: regenerated `man/drmTMB.Rd`.
- First `Rscript -e "devtools::test()"`: failed because `tests/testthat/test-phylo-utils.R` created a direct TMB object without the new `offset_mu` data slot.
- `Rscript -e "devtools::test(filter = 'phylo-utils|poisson-mean|zi-poisson|nbinom2-location-scale|zi-nbinom2')"` after the fixture fix: 309 passed.
- Second `Rscript -e "devtools::test()"`: 1246 passed.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.

## Tests Of The Tests

The Poisson offset test compares `drmTMB` coefficients and log-likelihood
against `stats::glm()` with the same `offset(log(effort))`. The NB2,
zero-inflated Poisson, and zero-inflated NB2 tests compare fitted
log-likelihoods to independent pointwise likelihood calculations that include
the offset. Prediction tests check that new exposure values multiply the
response-scale mean. Invalid exposure values trigger the finite-offset error.

## Consistency Audit

The implementation, symbolic equations, R syntax, tests, README, NEWS,
formula grammar, family registry, likelihood design, family-link contract,
distribution roadmap, source map, known limitations, and pkgdown pages now use
the same rule: `offset(log(exposure))` is a standard count-model `mu` formula
term for Poisson and NB2 paths. Stale-wording scans found no current docs
claiming that count offsets are unimplemented; unrelated `offset` hits in
generated CSS, SVG gradients, and pkgdown JavaScript were ignored.

## What Did Not Go Smoothly

The first full test run failed in a hidden phylogenetic TMB parity test. That
test bypasses `make_tmb_data()` and constructs the C++ data list manually, so
it needed a dummy `offset_mu` entry after the C++ template gained the new
`DATA_VECTOR(offset_mu)` slot. The failure was useful because it protected
direct TMB fixtures from silently drifting away from the template contract.

## Team Learning

Respecting R convention gave us a better API than a new `exposure =` argument:
users can reuse `glm()` and `glmmTMB` habits, while `drmTMB` keeps
distributional formulas explicit. The next time we add a TMB data slot, Ada and
Grace should search for direct `TMB::MakeADFun()` test fixtures before the full
test run. Rose's inventory scan should continue to include source-map and
known-limitations pages, because they are easy to forget after code-focused
changes.

## Known Limitations

Offsets are not implemented for truncated NB2 or hurdle NB2 yet, even though
those are count models. That is intentional for this phase because their
observed mean contracts include truncation or hurdle normalisation. Offsets are
also not implemented for Gaussian, bivariate, meta-analysis, phylogenetic, or
spatial paths.

## Next Actions

Add a short tutorial example with actual fitted output for a rate model, such
as insect counts per trap night or detections per survey hour. Later, design
whether exposure offsets should extend to truncated and hurdle count models,
and whether bivariate or mixed count families need response-specific exposure
handling.
