# After Task: Bivariate Gaussian Known Sampling Covariance Likelihood

## Goal

Implement bivariate Gaussian meta-analysis with a known sampling covariance
matrix while keeping `rho12` as the residual or between-study correlation.

## Implemented

- `drmTMB()` now accepts one `meta_known_V(V = V)` marker in a bivariate
  Gaussian location formula.
- `V` must be a dense row-paired `2n` by `2n` matrix using
  `[y1_1, y2_1, y1_2, y2_2, ...]` ordering.
- The TMB likelihood adds `V` to the fitted residual covariance from
  `sigma1`, `sigma2`, and `rho12`.
- Bivariate `simulate()` and Pearson residuals use the same full observation
  covariance when known `V` is present.
- Duplicate `meta_known_V()` markers across `mu1` and `mu2` are rejected.

## Mathematical Contract

For complete bivariate rows:

```text
y_i = [y1_i, y2_i]'
mu_i = [mu1_i, mu2_i]'

y_stack ~ MVN(mu_stack, V + Omega_stack)

Omega_i =
  [sigma1_i^2,                 rho12_i sigma1_i sigma2_i;
   rho12_i sigma1_i sigma2_i,  sigma2_i^2]

log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
atanh(rho12_i) = X_rho12[i, ] beta_rho12
```

The fitted `rho12_i` is not the known within-study sampling correlation. It is
the residual or between-study correlation after `V` has already been included.

Matching R syntax:

```r
fit <- drmTMB(
  drm_formula(
    mu1 = y1 ~ x1 + meta_known_V(V = V),
    mu2 = y2 ~ x1,
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ x1
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

## Files Changed

- `src/drmTMB.cpp`
- `R/drmTMB.R`
- `R/methods.R`
- `R/meta-vcov.R`
- `tests/testthat/test-biv-gaussian.R`
- `README.md`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/08-meta-analysis.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/meta-analysis.Rmd`
- `man/meta_vcov_bivariate.Rd`
- `man/simulate.drmTMB.Rd`
- `man/residuals.drmTMB.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: 84 passed, 0 failed.
- `Rscript -e "devtools::test()"`: 602 passed, 0 failed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: site rebuilt successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.
- Stale-wording scans found no active bivariate known-`V` docs still calling
  the likelihood planned.

## Tests Of The Tests

- The likelihood test compares `logLik(fit)` to an independent base-R
  multivariate normal calculation using `chol()`.
- The recovery test simulates a positive within-study sampling correlation and
  a negative residual `rho12`, then checks that the estimate targets the
  residual correlation rather than the sampling correlation.
- The missing-row test removes a paired observation and checks that the same
  paired rows and columns are removed from `V`.
- The malformed-input tests reject vector `V` in bivariate syntax and duplicate
  `meta_known_V()` markers.

## Consistency Audit

- Formula grammar now says bivariate known `V` uses a complete-row row-paired
  matrix.
- The likelihood design now records the implemented dense known-`V` path and
  keeps bivariate random effects as future work.
- The meta-analysis vignette now shows bivariate fitting syntax instead of only
  the covariance helper.
- README and NEWS now state that bivariate known-`V` fitting is implemented.
- `simulate()` and `residuals()` documentation now mention `V + Omega`, not
  only residual covariance.
- Generated pkgdown pages were rebuilt after roxygen changes.

## What Did Not Go Smoothly

The first documentation pass updated the meta-analysis vignette but missed the
`simulate()` and `residuals()` reference pages. That was caught by the stale
reference-page audit and fixed before the final package checks.

The targeted bivariate test file now takes about 20 seconds because the dense
known-`V` path evaluates a full multivariate normal density. This is acceptable
for the current CRAN-safe test size, but sparse storage should be introduced
before larger bivariate meta-analysis examples become routine.

## Team Learning

Rose's after-task audit should explicitly include method documentation, not
only vignettes and design files. Gauss and Fisher's checks should continue to
ask whether `rho12` is being tested against a known sampling correlation, not
just whether it recovers a simulated residual correlation in isolation.

## Known Limitations

- Bivariate known-`V` fitting currently requires complete bivariate rows.
- Sparse known sampling covariance is not implemented.
- Bivariate random effects and structured phylogenetic or spatial bivariate
  covariance are still future work.
- Unknown within-study sampling correlations still need sensitivity-analysis
  helpers.

## Next Actions

1. Add sensitivity helpers for unknown bivariate within-study sampling
   correlations.
2. Decide how missing single outcomes should be represented in row-paired
   bivariate meta-analysis.
3. Start the sparse known-`V` design before scaling to large phylogenetic or
   spatial meta-analysis examples.
