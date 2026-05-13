# After Task: Bivariate Joint Mean-Scale Covariance Regression

## Goal

Prove that a bivariate Gaussian model can fit the first labelled `mu1`/`mu2`
and `sigma1`/`sigma2` random-intercept covariance blocks in the same model
while keeping residual `rho12` separate.

## Implemented

Added a deterministic simulation test with `(1 | pm | id)` in both location
formulas, `(1 | ps | id)` in both scale formulas, and predictor-dependent
`rho12 ~ x`. The test checks convergence, positive-definite Hessian,
fixed-effect recovery, group-level SD recovery, group-level correlation
recovery, `corpairs()` row classes, `summary()` rows, `profile_targets()` TMB
parameter names, and both `check_drm()` bivariate covariance diagnostics.

## Mathematical Contract

The test model has separate group-level blocks for individual differences in
average response and residual scale. The residual covariance remains
row-level: `Omega_i[1,2] = rho12_i * sigma1_i * sigma2_i`, with
`rho12_i = tanh(beta0 + beta1 * x_i)` on the response scale. The group-level
mean-mean and scale-scale correlations are not residual `rho12`.

## Files Changed

- `tests/testthat/test-biv-gaussian.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-bivariate-joint-mu-sigma-covariance.md`

## Checks Run

- `air format tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with
  227 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 2006 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

The new test combines a newly implemented neighbouring feature rather than
testing either covariance block alone. It would fail if the two group-level
correlations collapsed into one row, if residual `rho12 ~ x` was reported as a
group-level correlation, if `profile_targets()` reused the wrong TMB parameter,
or if `check_drm()` omitted either bivariate covariance diagnostic.

## Consistency Audit

I checked the current naming and scope surface with these scans:

```sh
rg -n "joint.*mu.*sigma|coexist|same model|mean-mean|scale-scale|biv_mu_random_effect_covariance|biv_sigma_random_effect_covariance|corpars\\$mu|corpars\\$sigma" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R
rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R
rg -n "rho12|sigma1|sigma2|sd\\(" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R
```

The roadmap and double-hierarchical endpoint note now say that the combined
labelled-intercept bivariate slice is covered, while bivariate random slopes,
cross-parameter bivariate covariance, structured effects, and random effects in
`rho12` remain planned.

## What Did Not Go Smoothly

The first local probe used constant residual `rho12`. The after-task audit
caught that the design plan names `rho12 ~ x`, so I strengthened the test to
cover predictor-dependent residual coscale in the same fitted model.

## Team Learning

Ada should keep converting roadmap wording into tests before marking slices
done. Rose's audit is useful here because status wording can be technically
true while still under-tested.

## Known Limitations

This is still an intercept-only bivariate group-level covariance slice. It does
not add bivariate random slopes, cross-parameter covariance among `mu1`, `mu2`,
`sigma1`, and `sigma2`, bivariate random effects in `rho12`, phylogenetic
blocks, spatial blocks, or bivariate known-`V` plus random effects.

## Next Actions

The next implementation slice should either add a missing malformed-syntax
guard for the combined bivariate block or move to the smallest cross-parameter
bivariate covariance design, depending on which gap is most valuable after CI
merges this regression slice.
