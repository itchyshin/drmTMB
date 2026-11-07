# After Task: Julia Gamma random-effect SD smoke

## 1. Goal

Recheck the existing Gamma random-effect SD tests through the live Julia bridge against the current source. This smoke covers fitting, public outputs, and recovery checks. Interval coverage was not tested.

## 2. Implemented

No package code or test code changed. The existing Julia Gamma SD test file was run unchanged. It covers an ordinary random-intercept SD formula and an independent random-slope SD formula, both with a fixed group-level predictor on the SD formula.

## 3a. Decisions and Rejected Alternatives

The goal's current finish line requires implementation, light numerical and equivalence checks, small fixed-seed recovery checks, public-output consistency, and documentation. Ninety-five-percent interval coverage calibration is deferred to a later validation phase. The two Hessian warnings recorded in the earlier Bernoulli bridge run remain a limitation for those fits and do not affect this Gamma smoke.

## 4. Files Touched

- `docs/dev-log/after-task/2026-10-20-julia-gamma-sd-smoke.md`
- `docs/dev-log/check-log.d/2026-10-20-julia-gamma-sd-smoke.md`
- `docs/dev-log/general-sd-regression/evidence/julia-gamma-smoke-20261020/`

No production source or test file was edited.

## 5. Checks Run

The command was:

```sh
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
DRM_JULIA_TESTS=true NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
JULIA_NUM_THREADS=1 Rscript -e \
'devtools::test(filter = "^julia-gamma-sd$", reporter = "summary", stop_on_failure = TRUE)'
```

Result: two live Julia bridge tests passed, with no reported failures or skips. The tests execute four fits across TMB and Julia. The intercept case checks SD coefficient naming and sign, group-level and row-level predictions, parameter extraction, and save/reload. The slope case checks convergence, positive SD-predictor recovery against the fixed synthetic truth, cross-engine coefficient agreement, and row-level SD predictions. The complete console output is `docs/dev-log/general-sd-regression/evidence/julia-gamma-smoke-20261020/test-console.log`.

A before/after SHA-256 manifest covers 196 native R/TMB source files, relevant R test helpers and the focused test file, plus DRM.jl Julia source and project files. The manifests are byte-identical with SHA-256 `acec9acfc0b7f36006b6cc85f0d6b55460c0dc7b7a7e8dc20b8de805154d52d9`. The test log SHA-256 is `e7294f0019c703d75f956318b7fc1787f6554320d2116c643d3355fe412323da`.

## 6. Tests of the Tests

The synthetic intercept and slope designs encode positive SD-predictor effects. Assertions check the fitted direction and, for the slope, a tolerance against the predeclared coefficient and native-engine fit. Output assertions verify that extracted and predicted group SDs map back to the fitted target. This run did not add malformed-input controls or compare against an independent likelihood oracle.

## 7a. Issue Ledger

No issue was changed. This smoke only rechecks an existing, focused test route and does not resolve an issue or capability row by itself.

## 8. Consistency Audit

The run made no source, public API, formula grammar, likelihood, or documentation changes. The after-task report and check-log shard describe only the tested Gamma intercept and independent-slope Julia bridge routes. Other Gamma providers, covariance blocks, endpoints, and operations remain outside this receipt.

## 9. What Did Not Go Smoothly

Nothing failed in this run. JuliaCall started from the configured local DRM.jl checkout, and both bridge tests completed.

## 10. Known Residuals

This run gives no evidence about 95-percent interval coverage or calibrated Wald and profile inference. It covers two Gamma SD routes and does not establish full Gamma support or capability-wide R/Julia parity. The intercept test checks the direction and public outputs; its coefficient-recovery tolerance is broad. The slope test's convergence and recovery assertions leave broader recovery questions open. The goal remains open.

## 11. Team Learning

This bridge test binds a synthetic SD predictor with a known direction to engine comparisons and public target outputs. Its scope is limited to the two Gamma routes recorded here.

## 12. Cross-Product Coverage

This receipt covers Gamma `mu` SD formulas for one ordinary intercept and one independent random slope, using synthetic data, through native TMB and the Julia bridge. It does not cover structured providers, correlated or cross-parameter blocks, other distributional endpoints, other families, interval calibration, or all public refit workflows.
