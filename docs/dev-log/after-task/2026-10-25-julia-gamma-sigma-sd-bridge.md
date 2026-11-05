# After Task: Gamma sigma SD regression through the Julia bridge

## 1. Goal

Exercise one Gamma `sigma` random-intercept SD-regression route through the R-to-Julia bridge, preserve the public target label, and record a same-data comparison with native TMB. Interval coverage remains deferred.

## 2. Implemented

The bridge now admits complete-response Gamma models with fixed-effect-only `mu`, one ordinary `sigma ~ 1 + (1 | id)` term, and its matching `sd(id, dpar = "sigma") ~ w` formula. The payload uses the canonical `sd` block and does not add the ordinary `resd` block for this predictor-dependent scale route. The route guard rejects a mismatched group, a random slope on `sigma`, and a random effect on `mu`.

The test generates Gamma responses with `sigma` as the coefficient of variation. A random intercept is additive on `log(sigma)`, so conditional Gamma shape is `1 / sigma^2`. The SD predictor controls the log-SD of that intercept. One same-data TMB/Julia fit checks convergence, signed SD-coefficient recovery, target names, group-SD output, prediction mapping, finite conditional `sigma`, and coefficient agreement within a smoke tolerance.

## 3a. Decisions and Rejected Alternatives

The bridge exception remains restricted to one ordinary `sigma` intercept, fixed `mu`, complete responses, and one matching SD formula. It does not admit a random slope or structured `sigma` effect. The independent Julia integration oracle is recorded in the paired DRM.jl report.

## 3. Mathematical Contract

For observation `i` in group `g`, `log(mu_i) = x_i' beta`, `log(sigma_ig) = gamma_0 + b_g`, `b_g ~ Normal(0, tau_g^2)`, and `log(tau_g) = alpha_0 + alpha_1 w_g`. Conditional on `b_g`, `y_ig ~ Gamma(shape = sigma_ig^(-2), scale = mu_i * sigma_ig^2)`. TMB and Julia use different integration approximations here, so the coefficient comparison is only a point-estimate smoke check.

## 4. Files Touched

- `R/julia-bridge.R`: narrow Gamma admission predicate and canonical SD-label mapping.
- `tests/testthat/test-julia-gamma-sigma-sd-bridge.R`: live synthetic same-data bridge fixture and route-refusal checks.
- `README.md`, `NEWS.md`, `docs/design/02-family-registry.md`, `docs/dev-log/known-limitations.md`, and `docs/dev-log/general-sd-regression/inventory.md`: current capability and evidence boundary.
- `docs/dev-log/after-task/2026-10-25-julia-gamma-sigma-sd-bridge.md` and `docs/dev-log/check-log.md`.
- Paired Julia implementation, family guide, capability table, NEWS, and its after-task report are in the paired DRM.jl candidate worktree.

## 5. Checks Run

- `TMPDIR=/private/tmp DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRM_JL_JULIA_HOME='/Users/z3437171/.juliaup/bin' JULIA_DEPOT_PATH='/private/tmp/julia-depot:/Users/z3437171/.julia' OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-gamma-sigma-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'`: passed; one live Julia bridge test ran. The test reports 11 expectations after adding three route refusals and the positive admission assertion.
- Direct Julia Gamma sigma SD test in the paired candidate: passed 14/14 assertions in 26 seconds, including the independent scalar-integration oracle and refusal of unused covariance inputs.
- `pkgdown::check_pkgdown()`: no problems found; existing Pandoc `--mathml` deprecation warnings were printed.
- Full package tests, documentation rendering, and full `devtools::check()` were not run for this slice.

## 6. Tests of the Tests

The live fixture exercises the coefficient-label payload, the public `sd(id, dpar = "sigma")` target, and the Julia fitter together. The explicit negative cases verify that this bridge exception does not admit another group, a sigma random slope, or a random effect on `mu`. The paired Julia unit test separately checks an independently integrated likelihood.

## 8. Consistency Audit

The bridge route, synthetic generator, Julia implementation, Gamma family row, and capability inventory all use Gamma `sigma` as CV and `sd()` as the SD of the latent log-CV intercept. Documentation labels the Julia bridge as a development candidate and limits the comparison to one point-estimate fixture. No coverage claim or broad parity claim is made.

## 7a. Issue Ledger

No issue was created, changed, or closed in this local implementation slice.

## 9. What Did Not Go Smoothly

The first bridge run showed that Julia returned the SD coefficient block under a hashed internal label instead of `sd`; this was corrected by mapping only the exact admitted Gamma route. JuliaCall also needs the paired candidate path and Julia home set explicitly in this environment. No other lane edits were reverted.

## 11. Team Learning

When an R bridge admits a family-specific SD formula, check the serialized coefficient labels and public target extraction in a live fit. Formula admission alone does not guarantee that `sdpars` or `predict()` will retain the intended target identity.

## 10. Known Residuals

This is one complete-response ordinary Gamma `sigma` intercept with fixed `mu`. The coefficient comparison uses a smoke tolerance because TMB and Julia use different integration approximations. It does not establish broad numerical parity, calibrated intervals, other random-effect shapes, structured `sigma` effects, or the full family/effect/backend scope. The overall predictor-dependent random-effect SD programme remains active.

## 12. Cross-Product Coverage

This slice covers one ordinary Gamma `sigma` random intercept through direct Julia and one same-data R/TMB-versus-Julia bridge fixture. It does NOT cover broad numerical parity, interval calibration, random slopes or structured `sigma` effects, or the remaining distribution-family, random-effect, provider, and layout combinations. The overall predictor-dependent SD programme remains active; coverage calibration stays deferred.
