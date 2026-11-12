# After Task: bivariate Gaussian non-finite values (#1709)

## Goal

Stop `Inf` in a bivariate Gaussian response or fixed-effect design from
reaching `lm.fit` or `nlminb` as a backend error.

## Implemented

Observed `y1` and `y2` are checked with `is.finite()` after the missingness
mask is applied. The five fixed-effect design matrices are checked with the
existing `drm_abort_if_nonfinite_fit_design()`. The univariate Gaussian
wording and call sites are untouched.

## Mathematical Contract

No bivariate density, link, or `rho12` definition changed. A non-finite
response or design entry is not a parameter of the fitted likelihood.
`docs/design/03-likelihoods.md` was not edited.

## Files Changed

- `R/drmTMB.R`: two response checks and five design checks in
  `drm_build_biv_gaussian_spec()`.
- `tests/testthat/test-fix-1709-biv-gaussian-nonfinite.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-12-fix-1709-biv-gaussian-nonfinite.md`

## Checks Run

See the check-log shard. The new file passes. The univariate Gaussian
#1697 file still passes.

## Tests Of The Tests

On `R/drmTMB.R` at `98717b68c`, `Inf` in `y1`, `y2`, and a mean predictor
were `simpleError`s from `lm.fit`, and `Inf` in a `sigma1` predictor was
the three-preset `nlminb` abort. Those tests require `rlang_error` plus the
finite-value wording, so they fail on main. `NA` and `NaN` in `y1` already
dropped to `nobs` 19 and still do.

## Consistency Audit

The response sentence reuses "Gaussian models require finite observed
response values." The design sentence is the existing Gaussian design
abort, with `dpar` set to `mu1`, `mu2`, `sigma1`, `sigma2`, or `rho12`.
No README, vignette, pkgdown, or roxygen change.

## GitHub Issue Maintenance

Closes #1709. Bivariate lognormal and bivariate Student-t go through this
Gaussian builder for the shared location-scale matrices, so an `Inf` in
those shared designs is caught here too. A non-finite bivariate Student-t
`nu` design is not checked in this change.

## What Did Not Go Smoothly

`Inf` in `y` or in a mean design dies in `lm.fit`. `Inf` in `sigma1` gets
through the start and dies only after three optimizer presets. The checks
have to sit before both.

## Team Learning

The #1697 guard was univariate. A follow-up issue for the bivariate builder
was the right split, and the same helper covers the design half without a
new message.

## Known Limitations

Bivariate Student-t `nu` is built after this spec and is not covered.
`NA` and `NaN` responses remain complete-case drops, including when only
one response is missing.

## Next Actions

Draft pull request for #1709.
