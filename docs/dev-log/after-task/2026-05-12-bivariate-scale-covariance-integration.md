# After Task: Bivariate Scale Covariance Integration

## Goal

Finish the broken bivariate covariance lane by making matching labelled
`sigma1`/`sigma2` random-intercept covariance work in the same bivariate
Gaussian fit as the existing `mu1`/`mu2` group covariance and residual `rho12`.

## Implemented

The bivariate Gaussian builder now extracts matching labelled random-intercept
terms from `sigma1` and `sigma2` formulas. A model such as
`sigma1 = ~ z1 + (1 | q | id)` and `sigma2 = ~ z2 + (1 | q | id)` builds a
two-term residual-scale random-effect structure, passes `u_sigma`,
`log_sd_sigma`, and `eta_cor_sigma` to TMB, and applies the fitted group effects
to `log_sigma1` and `log_sigma2`.

The fitted scale random-intercept SDs are reported in `sdpars$sigma`. The
group-level scale-scale correlation is reported in `corpars$sigma`, listed by
`corpairs()` with class `scale-scale`, and exposed as direct `profile_targets()`
rows. Residual `rho12` stays a separate within-observation residual
correlation.

## Mathematical Contract

The implemented bivariate residual-scale block is

```text
log(sigma1_ij) = X_sigma1[ij, ] beta_sigma1 + a_1j
log(sigma2_ij) = X_sigma2[ij, ] beta_sigma2 + a_2j
[a_1j, a_2j]' ~ MVN(0, Sigma_sigma_ID)
```

`Sigma_sigma_ID` contains two positive SDs and one bounded correlation. The
TMB parameterization uses `log_sd_sigma` for the SDs and
`rho_sigma = 0.999999 * tanh(eta_cor_sigma)` for the correlation.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `R/methods.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `tests/testthat/test-phylo-utils.R`
- README, NEWS, roadmap, formula grammar, likelihood design, correlation-pair
  design, known limitations, bivariate tutorial, source map, and generated Rd
  files

## Checks Run

- `Rscript -e "devtools::load_all()"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: 144 passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|corpairs|profile-targets|biv-gaussian|phylo')"`:
  760 passed.
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`: 78 passed.
- `Rscript -e "devtools::test()"`: 1947 passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  0 errors, 0 warnings, 0 notes.
- `git diff --check`
- stale-wording scan for old claims that bivariate `sigma1`/`sigma2` random
  effects remained planned

## Tests Of The Tests

The new `test-biv-gaussian.R` case fits one model with matching `mu1`/`mu2`
random intercepts, matching `sigma1`/`sigma2` random intercepts, and residual
`rho12`. It checks convergence, finite fixed effects, SDs, correlations,
random-effect extraction, positive fitted scales, `corpairs()` classes, and
profile target names. This is the combined proof that the bivariate pieces
participate in one model rather than passing only as separate slices.

## Consistency Audit

Rose searched the source docs and generated help for stale claims that
bivariate `sigma1`/`sigma2` random intercepts were still planned. The remaining
planned boundaries now refer to bivariate random slopes, `rho12` random effects,
`meta_known_V(V = V)` plus random effects, and structured covariance layers.

Pat's reader-facing check was that the README and bivariate tutorial now tell an
applied user what to write next: use matching labelled intercepts in `mu1` and
`mu2` for mean-mean group covariance, matching labelled intercepts in `sigma1`
and `sigma2` for scale-scale group covariance, and `rho12` for residual
within-row coupling.

## What Did Not Go Smoothly

The branch already contained many earlier bivariate and tutorial edits, so the
first job was not implementation but proving which pieces were real. The full
test suite exposed stale rejection-test wording for one-sided bivariate
`phylo()` syntax; those tests now expect the more precise matching-term error.

## Team Learning

- Ada should preserve this branch rather than abandon it: the integrated
  bivariate stack now has full-suite evidence.
- Gauss should keep the scale covariance parameterization narrow:
  intercept-only, log SDs, and a bounded tanh correlation.
- Noether should keep residual `rho12` separate from group-level `mu` and
  `sigma` correlations in equations and labels.
- Curie should add longer recovery simulations before expanding to bivariate
  random slopes.
- Rose should keep searching stale planned-versus-implemented wording whenever
  a covariance slice moves from roadmap to code.

## Known Limitations

- Bivariate random slopes remain planned.
- `rho12` random effects remain planned.
- Bivariate random effects still cannot be combined with dense
  `meta_known_V(V = V)`.
- Bivariate phylogenetic covariance has partial plumbing on this branch but is
  not closed until simulation recovery, docs, examples, and `corpairs()` coverage
  are completed.
- `pkgdown::build_site()` was not rerun.

## Next Actions

1. Add bivariate random-slope design only after the intercept-only mean and
   scale blocks stay stable.
2. Add explicit `check_drm()` diagnostics for bivariate `sigma1`/`sigma2`
   scale covariance if weak-SD warnings prove useful in examples.
3. Decide whether bivariate phylogenetic covariance should be finished on this
   branch or split into a separate small PR with its own simulations.
