# After Task: Student-t and skew-normal non-finite designs (#1710)

## Goal

Make `Inf` in a Student-t or skew-normal fixed-effect design abort in
drmTMB, with the column name, instead of leaking `lm.fit` or an
`nlminb` preset failure.

## Implemented

`drm_abort_if_nonfinite_fit_design()` gained a `family` argument. The
default is `"Gaussian"`, and the Gaussian sentence is unchanged. The
Student-t and skew-normal builders call it for `mu`, `sigma`, and `nu`
after `model.matrix()` and before starting values.

## Mathematical Contract

No density, link, or coefficient definition changed. A non-finite design
entry is still not a parameter of the Student-t or skew-normal likelihood.
`docs/design/03-likelihoods.md` was not edited.

## Files Changed

- `R/methods.R`: `family` argument, default `"Gaussian"`.
- `R/drmTMB.R`: three calls in `drm_build_student_ls_spec()` and three in
  `drm_build_skew_normal_ls_spec()`.
- `tests/testthat/test-fix-1710-student-skew-nonfinite.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-12-fix-1710-student-skew-nonfinite.md`

## Checks Run

See the check-log shard. The new file passes. The Gaussian #1697 file
passes, and the Gaussian abort sentence is unchanged.

## Tests Of The Tests

The new file was run on `R/drmTMB.R` at `98717b68c` before the calls were
added. The six `Inf` tests failed. The two `NA` tests passed before and
after, so complete-case dropping of a missing predictor was not turned
into an abort.

## Consistency Audit

The Gaussian message string is still produced by the default `family`.
No README, vignette, or pkgdown change. No roxygen change.

## GitHub Issue Maintenance

Closes #1710. Other families that still reach `lm.fit` or the optimizer
preset abort on `Inf` in a design are not this issue. They are listed in
the sweep report for Shinichi to file.

## What Did Not Go Smoothly

`Inf` in `mu` dies in `lm.fit` during starting values. `Inf` in `sigma`
or `nu` gets past starting values and dies as `NA/NaN gradient evaluation`
after three `nlminb` presets. One check after `model.matrix()` covers
both.

## Team Learning

A finite-design guard has to sit before both the least-squares start and
the optimizer. Guarding only the response, which #1697 already did for
Student-t `y`, leaves the design path open.

## Known Limitations

Lognormal, Gamma, Tweedie, beta, Poisson, NB2, binomial, beta-binomial,
and bivariate Gaussian designs are not covered here. `NA` and `NaN` in a
response stay on the existing missingness path.

## Next Actions

Draft pull request for #1710. Bivariate Gaussian `Inf` in `y` or a design
is #1709 and is a separate branch.
