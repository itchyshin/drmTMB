# After Task: Poisson Julia Slope Bridge Check

## Goal

Verify a predictor-dependent Poisson random-slope SD fit through `drmTMB(engine = "julia")` and compare it with native TMB on the same generated data.

## Implemented

The R-facing test fits one independent numeric slope in Julia and native TMB. It checks convergence, log-SD coefficients, and rowwise Julia SD prediction against the fitted group values. The comparison uses a fixed 0.25 tolerance for both log-SD coefficients.

## Mathematical Contract

The test uses `log(s_g) = z_g' alpha` and `log(lambda_ig) = x_ig' beta + x_ig b_g`, where `b_g ~ Normal(0, s_g^2)`. The group predictor `z` is constant within group.

## Files Changed

`tests/testthat/test-julia-poisson-sd.R`, `docs/design/01-formula-grammar.md`, `docs/design/18-random-effect-scale-models.md`, `docs/dev-log/known-limitations.md`, and this report plus its check-log shard. The Julia implementation, tests, guide, NEWS, and package report are in the nested DRM.jl worktree.

## Checks Run

`devtools::test(filter = "julia-poisson-sd")` passed 22 assertions with two live Julia fits and one non-fatal JuliaCall dependency-install warning. The focused Julia package test passed 35 assertions, including the slope's independent quadrature oracle. `pkgdown::check_pkgdown()` reported no problems; `git diff --check` passed in both worktrees.

## Tests of the Tests

The Julia slope test first failed at its intercept-only guard. The bridge test uses the same generated data for both engines and keeps its 0.25 comparison tolerance fixed. It also checks Julia's public SD prediction mapping to groups.

## Consistency Audit

R formula documentation now lists Poisson intercept and independent-slope SD routes in both engines. Calibration and broad cross-engine agreement remain unclaimed.

## GitHub Issue Maintenance

No issue was inspected or changed; the larger capability programme remains active.

## What Did Not Go Smoothly

JuliaCall printed a non-fatal `LogExpFunctionsInverseFunctionsExt` startup error for an undefined `loglogistic`, then the bridge tests passed.

## Team Learning

A same-data bridge test gives a more direct parity check than comparing two independent recovery datasets.

## Known Limitations

This is one seeded comparison for the Poisson ordinary independent-slope route. It does not establish calibration, structured-effect support, or parity across a design grid.

## Next Actions

Continue the family/effect matrix, with NB2 slope SD support and calibration still open. All programme gates remain open.
