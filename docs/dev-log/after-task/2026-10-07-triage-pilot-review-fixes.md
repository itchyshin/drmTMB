# After Task: Review fixes for silent-input PR #1501

## Goal

Answer the Code Reviewer BLOCKED notes on draft PR #1501 without
opening a new pull request. Applied users who set `contr.sum`, ask for
`gaussian(link = "log")` on a Julia mixed pair, or plot an incomplete
or at-boundary bootstrap interval should get the requested coding, a
loud refusal, or a visible interval.

## Implemented

`#1495` predict breakage. `drm_prepare_model_matrix_newdata()` now
copies the fitted factor's `contrasts` attribute onto the rebuilt
newdata factor. `drm_prediction_matrix()` also passes those contrasts
into `drm_fixed_effect_matrix()`, so `predict(fit, newdata =)` and the
emmeans basis keep `contr.sum` columns (`g1`/`g2`) instead of falling
back to treatment coding and aborting with "Could not align the mu
design matrix".

`#1458` at-boundary. Relabelling a percentile row to
`bootstrap_at_boundary` no longer hides dropped refits.
`warn_bootstrap_incomplete()` still fires when
`bootstrap.failed > 0` on that row.

`#1458` plots. `plot_parameter_surface()` and `plot_corpairs()` treat
`bootstrap_incomplete` and `bootstrap_at_boundary` as plottable. The
status column remains the marker.

`#1482` Julia mixed pair. `drm_julia_xfam_family_tag()` now runs
`drm_require_gaussian_identity_link()` before returning `"gaussian"`,
so `c(poisson(), gaussian(link = "log"))` with `engine = "julia"`
errors instead of fitting identity. The same error now names
`Gamma(link = "log")` as well as `lognormal()`.

## Mathematical Contract

No likelihood parameterization changed. Gaussian location remains
`mu = X_mu beta_mu` on the identity scale. Contrast coding changes only
the design-matrix columns used for prediction, so they must match the
fitted coefficients. Bootstrap percentiles are still the empirical
quantiles of retained refits.

## Files Changed

- `R/methods.R`, `R/sparse-fixed.R`: carry fitted contrasts into prediction.
- `R/profile.R`: incomplete warning on at-boundary rows.
- `R/plot-parameter-surface.R`, `R/plot-corpairs.R`: keep new statuses plottable.
- `R/julia-bridge.R`, `R/drmTMB.R`: Julia Gaussian link check; Gamma suggestion.
- `tests/testthat/test-silent-input-drops.R`,
  `tests/testthat/test-plot-parameter-surface.R`,
  `tests/testthat/test-plot-corpairs.R`.
- `NEWS.md`, `man/confint.drmTMB.Rd`, `docs/dev-log/check-log.md`, this report.
- C17 model-15 receipt to be rewired after `R/drmTMB.R` / `R/methods.R` moved.

## Checks Run

Targeted tests and C17 recertify are recorded in the follow-up commit
after this review-fix slice.

## Consistency Audit

`rg "meta_gaussian|tau ~|rho ~"` on the touched R, test, NEWS, and
after-task files found no new stale syntax. Terms stayed `sigma`,
`rho12`, `lognormal()`, and `Gamma(link = "log")`.

## Tests of the Tests

The new `#1495` test compares `predict(newdata)` to `lm()` on the same
`contr.sum` data. The Julia `#1482` test calls the tag helper and
cross-family detector only, so it does not need Julia. The `#1458`
plot tests feed helper filters, not ggplot. The at-boundary warning
test covers the helper and a mocked `confint()` path.

## What Did Not Go Smoothly

The review found a real predict regression from the first `#1495`
droplevels fix: restoring contrasts at fit time is not enough if
newdata rebuilds the factor without them. C17 `mc-0568` is a whole-file
blob pin, so any `R/drmTMB.R` message edit needs a recertify even when
model 15 is untouched.

## Team Learning

When a factor-coding fix changes the fitted design, add a
`predict(newdata)` test in the same change. When a new
`conf.status` is added, update plot availability filters in the same
change.

## Design-doc Updates

None. Likelihoods and formula grammar are unchanged.

## pkgdown/documentation Updates

NEWS and `?confint.drmTMB` mention the at-boundary incomplete warning
and the Gamma suggestion.

## GitHub Issue Maintenance

No new issues. Work stays on PR #1501 for #1495, #1482, and #1458.

## Known Limitations

Honouring `gaussian(link = "log")` as a fitted likelihood is still out
of scope. Unused-level contrast subsetting is still a warning, not a
rebuilt contrast matrix.
