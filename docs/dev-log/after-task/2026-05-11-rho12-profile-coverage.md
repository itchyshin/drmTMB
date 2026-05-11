# After Task: Residual Rho12 Profile Coverage

## Goal

Add explicit test coverage for residual `rho12` profile intervals so the package
does not blur a residual-correlation coefficient interval with a response-scale
row correlation interval.

## Implemented

- Added a focused bivariate Gaussian test for
  `confint(fit, parm = "fixef:rho12:w", method = "profile")`.
- The test verifies that the target maps to the second `beta_rho12` parameter.
- The test compares the public `confint()` result against a manual
  `TMB::tmbprofile()` call with the same one-hot linear combination.
- The expected scale remains `link` with transformation `linear_predictor`.

## Mathematical Contract

For `rho12 = ~ w`, the fitted coefficient `fixef:rho12:w` is an unconstrained
linear-predictor coefficient. Profiling that coefficient gives an interval for
`beta_rho12[2]`, not a row-specific residual correlation. A response-scale
residual correlation for row `i` is still
`0.99999999 * tanh(X_rho12[i, ] beta_rho12)`, which is a derived quantity when
the row has more than an intercept.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-rho12-profile-coverage.md`

## Checks Run

- `air format tests/testthat/test-profile-targets.R`
- `Rscript -e "devtools::test(filter = 'profile-targets')"`
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `LC_ALL=C rg -n "[^\x00-\x7F]" tests/testthat/test-profile-targets.R`

The focused profile-target suite passed with 98 expectations, no failures, no
warnings, and no skips. The full package test suite passed with 1578
expectations, no failures, no warnings, and no skips. `git diff --check` passed,
and the touched test file had no non-ASCII characters.

## Tests Of The Tests

The test is not only a smoke test. It independently constructs the one-hot
linear combination for `beta_rho12[2]`, profiles that target with
`TMB::tmbprofile()`, and checks that `confint.drmTMB()` returns the same lower
and upper endpoints to numerical tolerance.

## Consistency Audit

- No user-facing documentation changed because the profile design note already
  states that `beta_rho12` profiles are on the atanh linear-predictor scale
  unless a separate interpretable response-scale contrast is requested.
- No likelihood, formula grammar, or C++ parameterization changed.
- The test reinforces the Phase 6 boundary: direct `rho12` coefficients are
  covered, while response-scale residual-correlation intervals remain planned.

## What Did Not Go Smoothly

The first exploratory R snippet loaded the installed package and therefore did
not see the newly exported `profile_targets()` helper. Rerunning with
`devtools::load_all()` confirmed the current worktree behaviour. This is a
small reminder to use the development load path when testing code that has just
been added but not installed.

## Team Learning

Noether's lens is the key one here: the symbolic residual correlation
`rho12_i` and the fitted coefficient `beta_rho12` are related but not the same
profile target. Fisher's lens says response-scale residual-correlation
intervals need a separate derived-target design, especially when `rho12` has
predictors.

## Known Limitations

- No response-scale residual `rho12_i` interval is implemented.
- No profile interval is implemented for a contrast such as residual
  correlation at a named predictor value.
- Bivariate group-level, phylogenetic, and non-phylogenetic correlation
  intervals remain planned structured-covariance work.

## Next Actions

1. Decide whether the first response-scale residual `rho12` interval should be
   an intercept-only shortcut or a named `newdata` contrast.
2. Add a phylogenetic SD profile test before claiming that direct target.
3. Keep structured phylogenetic and non-phylogenetic correlations on the
   double-hierarchical roadmap, separate from residual `rho12`.
