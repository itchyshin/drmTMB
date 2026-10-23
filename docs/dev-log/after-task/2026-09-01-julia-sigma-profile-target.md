## 1. Goal

Repair the `engine = "julia"` profile route for an asymmetric Gaussian location-scale model whose phylogenetic SD is on the sigma axis.

## 2. Implemented

The R bridge now preserves the selected SD parameter block when it invokes `DRM.drm_bridge_inference()`. The target inventory admits `sd:sigma:phylo(...)`; unprefixed asymmetric sigma storage maps to Julia `resd_sigma`, while legacy unprefixed mean-only storage remains `resd`. Documentation and targeted tests cover the supported target.

## 3a. Decisions and Rejected Alternatives

Use the existing DRM.jl `:resd_sigma` profile implementation and correct the R target contract. Do not relabel the Julia block to `resd`, and do not coerce an unbounded profile endpoint into a finite interval.

## 4. Files Touched

R/julia-bridge.R; man/confint.drmTMB_julia.Rd; man/summary.drmTMB_julia.Rd; tests/testthat/test-julia-bridge.R; tests/testthat/test-julia-inference.R; this report; and the matching check-log.

## 5. Checks Run

Focused `test-julia-inference.R` and `test-julia-bridge.R` pass. A test-first regression initially failed because an unprefixed sigma axis was mapped to `resd`; it passes after the repair. A live local 8-tip Gaussian REML bridge fit invoked `confint(..., parm = "sd:sigma:phylo(1 | species)", method = "profile")` and returned one `resd_sigma` row. The row records lower 0.8137304, upper Inf, and `profile.boundary = TRUE`; this small probe does not claim a finite upper endpoint.

## 6. Tests of the Tests

Before the production mapping change, the new unprefixed-sigma regression failed with actual `resd` and expected `resd_sigma`. The same focused files pass after the minimal mapping change.

## 7a. Issue Ledger

PR #1105 contains this repair. Parent Julia-R parity gates, including broad profile/bootstrap parity, remain open. No release, registration, collaborator reply, or destructive worktree cleanup occurred.

## 8. Consistency Audit

Inspected both prefixed coupled storage and unprefixed asymmetric storage. The former already maps to `resd_mu`/`resd_sigma`; the latter required the correction. Legacy unprefixed mean-only storage retains its `resd` mapping. The bivariate q=4 route remains separate and passes no explicit SD parameter to its existing multi-axis primitive.

## 9. What Did Not Go Smoothly

The first live run exposed the target mismatch. JuliaCall also logs a `LogExpFunctionsInverseFunctionsExt` precompile error in this local Julia 1.10 depot, although DRM.jl loads and the bridge call proceeds. That environment issue is not repaired in this PR.

## 10. Known Residuals

This does NOT cover universal profile endpoint finiteness, broad bootstrap parity, all families, missing-response paths, performance, or a clean JuliaCall environment. The tiny live probe has an unbounded upper profile endpoint and reports it honestly.

## 11. Team Learning

Memory receipt: the bridge optionality/control-surface guard shaped the work; it required the exact R target to reach the same Julia parameter block rather than merely expose a label. Golden Set: legacy mean `resd`, prefixed coupled mean/sigma blocks, unprefixed asymmetric sigma block, and bivariate q=4 no-parm routing. The durable lesson is that public axis labels alone are insufficient: R target inventory must preserve the fitted Julia parameter block.

## 12. Cross-Product Coverage

This does NOT cover native-R/direct-Julia numerical parity, fixed-effect profile targets, bootstrap refits, threaded inference, non-Gaussian families, bivariate q=4 interval calibration, missing-data composition, documentation rendering, full-package checks, CI success, or programme completion. It covers the univariate Gaussian phylogenetic sigma-axis profile target contract through focused R tests and one local live bridge probe.
