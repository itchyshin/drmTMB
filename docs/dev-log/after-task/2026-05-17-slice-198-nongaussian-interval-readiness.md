# Slice 198 Non-Gaussian Interval Readiness

## Goal

Check the interval surfaces that fitted non-Gaussian paths already expose before
the comprehensive simulation phase. The target was not to add a new confidence
interval algorithm, but to make sure `summary()`, `confint()`, and
`profile_targets()` fail honestly and keep their interval-status columns stable.

## What Changed

- Made `drm_summary_coefficients()` return a valid empty coefficient table when
  a fitted model has no fixed-effect coefficients to summarize.
- Made `drm_wald_confint()` return a valid empty Wald interval table when no
  fixed-effect interval targets exist.
- Made `drm_summary_add_coefficient_ci()` and
  `drm_summary_add_parameter_ci()` create zero-row interval columns safely.
- Added ordinal regression coverage showing that
  `summary(fit, conf.int = TRUE)` works for cumulative-logit fits with a
  fixed-effect coefficient and for intercept-only ordinal fits whose coefficient
  and parameter tables are both empty.
- Updated the roadmap, validation-debt register, and NEWS so the non-Gaussian
  interval gate records the fixed bug without claiming a new profile or
  bootstrap interval method.

## Validation

- `Rscript -e "devtools::test(filter = 'summary', reporter = 'summary')"`:
  passed.
- Final focused and pkgdown checks are recorded in
  `docs/dev-log/check-log.md` for this slice.

## Role Notes

- Ada kept Slice 198 scoped to interval readiness rather than a broad inference
  rewrite.
- Fisher identified the important statistical boundary: fixed-effect Wald
  intervals can be present even when no response-scale summary parameter row
  should receive an interval.
- Curie converted the discovered ordinal crash into a regression test.
- Emmy kept the fix inside the existing summary/confint table helpers.
- Grace required the summary, profile-target, prediction-table, and pkgdown
  checks to stay together before merge.
- Pat and Darwin should treat this as a reader-safety fix: ordinal users now see
  an empty but well-formed interval table instead of an internal data-frame
  error.
- Rose notes that this slice does not change random-effect support, profile
  algorithms, bootstrap intervals, or ordinal mixed-model status.

## Remaining Boundary

Fitted non-Gaussian fixed-effect paths still rely on Wald intervals for ordinary
coefficient summaries and profile targets only where the target maps directly to
an optimized TMB parameter. Bootstrap intervals, nonlinear derived intervals,
and ordinal random-effect intervals remain planned work.
