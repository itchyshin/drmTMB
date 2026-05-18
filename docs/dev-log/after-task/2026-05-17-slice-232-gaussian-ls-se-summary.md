# Slice 232 Gaussian Location-Scale Standard Errors

## Goal

Expose fixed-effect standard errors in the Gaussian location-scale Phase 18
pilot summary.

## What Changed

- Updated `phase18_summarise_gaussian_ls_fit()` to add a `std.error` column.
- The summariser reads `summary(fit)$coefficients$std_error` when available and
  aligns rows by parameter names such as `mu:x` and `sigma:z`.
- Missing or unavailable standard errors remain `NA_real_`.
- Extended the Gaussian location-scale pilot test to require finite positive
  standard errors for the fitted smoke model.

## Checks

- `air format inst/sim/fit/sim_summarise_gaussian_ls.R tests/testthat/test-phase18-gaussian-ls-pilot.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-232-gaussian-ls-se-summary.md`
- `Rscript -e "devtools::test(filter = 'phase18-gaussian-ls-pilot', reporter = 'summary')"`
- `git diff --check`

## Limitations

This slice only adds standard errors to the Gaussian location-scale pilot
summary. It does not yet attach Wald intervals or coverage summaries to the
surface.

## Standing Roles

Noether kept row alignment tied to explicit parameter names. Fisher framed this
as standard-error extraction only, not a completed interval method. Curie added
the finite positive standard-error check. Grace kept missing-standard-error
behavior non-fatal. Ada limited the change to one surface.
