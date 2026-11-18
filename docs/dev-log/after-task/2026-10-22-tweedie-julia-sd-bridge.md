# After Task: Tweedie Julia SD-Regression Bridge

## 1. Goal

Admit and test a narrowly scoped Tweedie random-effect SD route through the Julia bridge, matching native TMB for ordinary intercept and independent slope targets.

## 2. Implemented

The Julia bridge now admits one ordinary `mu` random intercept or one independent numeric `mu` slope with exactly one matching `sd()` target, a fixed-effect `sigma` formula (predictors are allowed), and intercept-only `nu`. Random effects on `sigma` or `nu` remain excluded. When data are available, the bridge rejects categorical slope variables. Formula-only checks retain refusal for unmatched targets, correlated or multiple terms, structured effects, and random effects inside the SD formula. NEWS now describes the exact candidate boundary.

## 3a. Decisions and Rejected Alternatives

The bridge exception is limited to the Tweedie capability already implemented in the paired Julia candidate. It does not admit structured or correlated effects, multiple random terms, or predictor-dependent `nu`; no likelihood or covariance parameterization changed. Assumption: the checked paired Julia worktree is the intended development candidate for this branch; a different DRM.jl source pin would require rerunning the live parity test.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-tweedie-sd-regression.R`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-22-tweedie-julia-sd-bridge.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `.unlazy/general-sd-regression/GATES.md`
- `.unlazy/general-sd-regression/gates/tweedie-julia-ordinary-sd.md`
- `docs/dev-log/after-task/2026-10-22-tweedie-julia-sd-bridge.md`

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 NOT_CRAN=true Rscript -e 'devtools::test(filter = "tweedie-sd-integration", reporter = "summary")'`: passed, 27 expectations; no live Julia tests were part of this command.
- Julia-enabled `devtools::test(filter = "julia-tweedie-sd-regression", reporter = "summary")` against paired Julia candidate `general-sd-julia` HEAD `70dbf564e`, with `JULIA_NUM_THREADS=2` and single-threaded BLAS: rerun passed with 37 expectations and two live parity tests for ordinary intercept and independent slope; the categorical-slope refusal check also passed. The drmTMB worktree was at HEAD `425bee815`; both candidate worktrees are dirty, so this is candidate-worktree evidence rather than a sealed source receipt.
- `git diff --check` on the six changed source, test, NEWS, and log/report files: passed. The whole-worktree check reports trailing blank lines at EOF in the existing `LOOP/lanes/general-sd-regression/checkpoint.md` and `tests/testthat/test-binomial-sd-integration.R`; these unrelated lines were left untouched.
- JuliaCall's dependency bootstrap first failed under the restricted shell (`install_dependency.jl` exited 1) before either live fit ran. The network-authorized retry completed setup and passed both live tests. An earlier bootstrap attempt for this slice also required the same retry.
- The repository `route.py` lookup found no LOAD-FIRST manifest for this worktree; project instructions and local design/docs were used as technical truth. The `closeout.py` generator is rooted at the Shinichi brain checkout, so it was invoked with an absolute report path; the first relative-path attempt targeted the wrong root and wrote nothing.

## 6. Tests of the Tests

The first red run failed because `drm_julia_tweedie_scalar_sd_route_admitted()` did not exist. The admission test covers both permitted shapes and negative controls for absent SD formulas, mismatched group/coefficient targets, correlated and multiple random terms, categorical slopes, random `sigma`/`nu`, predictor-dependent `nu`, random effects in the SD right-hand side, and structured effects. Live same-data fits compare coefficient names, the SD trend direction, group-level predictions, and their alignment for both intercept and slope routes.

## 7a. Issue Ledger

The read-only search found open issue #1230 about stale Tweedie family wording. In this checkout, the detailed article paragraph already states that ordinary `mu` intercepts and independent numeric slopes are available. The issue concerns the broader article/man-page consistency audit, so this bridge slice did not edit that high-reference shared vignette or alter the issue. No issue comment, creation, or closure was made.

## 8. Consistency Audit

The bridge guard is specific to the Tweedie family and reuses the existing formula parser and family-specific Julia implementation. The native Tweedie integration filter passed after the bridge change. NEWS and the check log state the same constraints as the bridge and test. The older parity-matrix entry records the result at its 2026-09-05 source pin and was left intact as a historical receipt; it does not describe this newer paired development candidate. The family article currently states that ordinary Tweedie `mu` intercepts and independent numeric slopes are available. No exported API or pkgdown navigation changed.

## 9. What Did Not Go Smoothly

The initial live Julia attempt stalled in JuliaCall's temporary-project dependency bootstrap. A later restricted-shell rerun reached both live tests but failed because `install_dependency.jl` exited 1 before fitting. Retrying with network access completed setup and both live tests in under one minute. These setup failures were not model-test failures. The closeout helper's relative paths are rooted at the brain repository rather than this linked worktree, so the report had to use an absolute output path.

## 10. Known Residuals

This is one family-specific bridge slice. It does not establish Tweedie Julia support for structured or correlated effects, other distributional endpoints, predictor-dependent `nu`, interval calibration, or all output/refit surfaces. It does not establish broader family, effect-type, provider, or engine parity. The full general-SD goal remains active; coverage validation remains deferred by the user's later scope decision.

## 11. Team Learning

When testing a JuliaCall bridge in a restricted shell, distinguish JuliaCall's temporary dependency bootstrap from model fitting. The dependency setup can fail or stall before the package's model code runs; report that boundary and retry only with the needed setup permission.

Memory receipt: searched the local Shinichi brain for the SD-regression decision context and read D-93; it confirms that implementation evidence does not imply release readiness. `route.py` reported no LOAD-FIRST manifest for this worktree. Golden Set: not checked; no known-mistake class was being changed.

## 12. Cross-Product Coverage

The changed family fence covers the Julia bridge admission decision for this Tweedie ordinary `mu` route; the paired candidate fit was tested against native TMB for one ordinary intercept and one independent slope. It does NOT cover structured/correlated effects, other families, other parameter endpoints, calibrated intervals, the full public prediction/refit surface, or shared/released DRM.jl parity.
