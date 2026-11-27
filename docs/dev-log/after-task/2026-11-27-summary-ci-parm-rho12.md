# After-task: summary `ci_parm = "rho12"` (#1932)

## Problem

Bare `ci_parm = "rho12"` matched the direct response-scale profile target `rho12`, but coefficient rows join on `fixef:` names, so `rho12:(Intercept)` stayed `conf.status = not_requested` while the default `summary(conf.int = TRUE)` filled Wald bounds.

## Fix

`summary_wald_coefficient_confint()` augments the selected Wald table with fixed-effect targets for any bare distributional-parameter names in `ci_parm` that appear in `object$coefficients`, without widening the parameter-level selection.

## Verification

Regression test in `test-summary.R`; manual repro from issue #1932 passes under `pkgload::load_all()`.