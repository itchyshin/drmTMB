# Slice 234 Meta-V Standard Errors

## Goal

Expose standard errors in the `meta_V(V = V)` Phase 18 pilot summary without
treating known sampling covariance `V` as an estimated target.

## What Changed

- Updated `phase18_summarise_meta_v_fit()` to add a `std.error` column.
- The summariser reads `summary(fit)$coefficients$std_error` for estimated `mu`
  fixed effects and `summary(fit)$parameters$std_error` for response-scale
  fitted residual `sigma`.
- Extended the `meta_V(V = V)` pilot test to require finite positive standard
  errors for vector and dense known-covariance smoke fits.

## Checks

- `air format inst/sim/fit/sim_summarise_meta_v.R tests/testthat/test-phase18-meta-v-dgp.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-234-meta-v-se-summary.md`
- `Rscript -e "devtools::test(filter = 'phase18-meta-v-dgp', reporter = 'summary')"`
- `git diff --check`

## Limitations

This slice adds standard errors only. It does not yet attach `meta_V(V = V)`
Wald intervals or coverage summaries.

## Standing Roles

Fisher kept known sampling covariance `V` outside interval targets. Noether
separated `mu` coefficient standard errors from response-scale `sigma` standard
errors. Curie extended vector and dense known-covariance tests. Grace kept
missing-standard-error behavior non-fatal. Ada kept this as the `meta_V` sibling
to Slice 232.
