# After Task: NB2 Independent-Slope SD Regression

## Goal

Add predictor-dependent SDs for one ordinary independent numeric NB2 location slope to the existing SD-regression interface in native TMB and Julia.

## Implemented

For `(0 + x | group)` with fixed `sigma ~ 1`, `sd(group, coef = "x") ~ z` now models the log SD of the latent slope coefficient. The observation contribution is `x * b_group`. The route requires complete data and group-constant SD predictors.

## Mathematical Contract

`b_g = exp(z_g' alpha) u_g`, where `u_g ~ Normal(0, 1)`, and `eta_ig = X_ig beta + x_ig b_g`. The NB2 response likelihood and dispersion parameterization are unchanged.

## Files Changed

Native R/TMB: `R/drmTMB.R`, `tests/testthat/test-nbinom2-sd-regression.R`, `tests/testthat/test-nbinom2-sd-integration.R`, `tests/testthat/helper-nbinom2-sd-regression.R`, `tests/testthat/test-julia-negbinomial-sd.R`, the NB2 alignment note, formula/family/scale design docs, known limitations, NEWS, vignette, and check-log shard. Julia: `src/negbinomial.jl`, `test/test_negbinomial_sd_regression.jl`, family/capability docs, and its check-log shard.

## Checks Run

The NB2-focused native assembly filter passed 67 assertions. The native integration file passed before and after the shared fixture extraction, including recovery, an independent slope-loading Laplace oracle, wrong-loading negative control, prediction, simulation, save/reload, profile target, and bootstrap refit. Julia's focused NB2 suite passed 53 assertions. The R-to-Julia bridge test passed 9 assertions with one live Julia fit. The new vignette fit ran against the edited checkout and returned coefficient and group-SD predictions. `pkgdown::check_pkgdown()` reported no problems. `pkgdown::build_site()` reached site initialization but stopped when it tried to contact `cloud.r-project.org` and DNS resolution failed; the edited vignette example was executed separately against the worktree. `git diff --check` passed in both worktrees. Julia docs rendering could not start because `Documenter` is absent from the docs environment.

## Tests Of The Tests

The Julia adapter test first failed at the prior intercept-only guard. The native builder test also failed before the slope admission was enabled. The integration oracle compares the fitted objective component with independent numerical integration using row-specific `x` loading, and a deliberately incorrect unit loading is rejected by the check.

## Consistency Audit

R and Julia capability documentation now lists the NB2 slope route and keeps interval calibration explicitly open. The R vignette states that the SD belongs to the latent coefficient. Correlated blocks, structured effects, offsets, `zi`/`hu`, missing responses, and non-fixed `sigma` remain outside this route. No navigation change was needed.

## GitHub Issue Maintenance

Open issues were searched with `"random-effect SD"`, `nbinom2 sd predictor`, and `NB2 random slope`. No issue specific to non-zero-inflated NB2 slope-SD regression matched. Issue #1451 concerns zero-inflated or hurdle count random intercepts, a separate scope, and was left unchanged.

## What Did Not Go Smoothly

The first vignette smoke command loaded an older installed package and correctly rejected the feature. Re-running with `devtools::load_all()` used the edited worktree. An initial extractor label omitted the coefficient selector; execution caught it, and the vignette now uses the full target identity. Julia documentation rendering is blocked by the missing `Documenter` dependency. The full R site build also needs network access for the CRAN link; neither dependency installation nor network changes were attempted.

## Team Learning

For selector-based targets, copy the exact public target string from the fitted object into vignette extractors. Run examples through the active worktree rather than relying on an installed package version.

## Known Limitations

The evidence establishes point recovery, a fixed-parameter slope-loading likelihood check, public output behavior, and one same-data engine comparison. It does not establish interval calibration or broad engine parity. JuliaCall emitted a non-fatal `LogExpFunctionsInverseFunctionsExt` warning during the bridge check.

## Next Actions

Continue the family and random-effect matrix. Calibrate the NB2 slope route before advertising uncertainty intervals; test broader designs only as separate validated slices. All programme gates remain open.
