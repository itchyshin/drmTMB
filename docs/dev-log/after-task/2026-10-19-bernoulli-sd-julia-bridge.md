## 1. Goal

Exercise the live Julia bridge for the Bernoulli predictor-dependent random-effect SD candidate, using the paired local drmTMB and DRM.jl worktrees.

## 2. Implemented

No model code changed in this slice. The dedicated live Bernoulli SD bridge tests ran against the paired candidate worktrees. I updated the candidate capability inventory and Julia output contract to record the exact test boundary and Hessian diagnostics.

## 3a. Decisions and Rejected Alternatives

The active Julia candidate belongs to the same Codex SD lane as the R/TMB candidate. The test run used its paired dirty worktrees without modifying source. A general parity claim is not warranted: the live test covers four Bernoulli SD cases, while q2 same-data parity and interval calibration remain open.

The native current-source first look is separate. Its staged decision remains look2_required, and this test does not change that decision or authorize a second look.

## 4. Files Touched

- docs/dev-log/after-task/2026-10-19-bernoulli-sd-julia-bridge.md
- docs/dev-log/check-log.md
- docs/dev-log/general-sd-regression/inventory.md
- docs/dev-log/general-sd-regression/julia-output-contract.md
- docs/dev-log/general-sd-regression/stage-two-execution-design.md
- docs/dev-log/general-sd-regression/first-look-inference-review.md
- docs/dev-log/general-sd-regression/calibration-final-review.md

No production R, TMB, or Julia source changed in this slice.

## 5. Checks Run

- The dedicated command was devtools::test(filter = "julia-binomial-sd") with DRMTMB_JULIA_TESTS=true, NOT_CRAN=true, DRM_JL_PATH and DRMODELS_JL_PATH set to the paired candidate, Julia 1.10.0, Julia limited to four threads, and BLAS/OpenMP/MKL limited to one thread.
- Result: 95 assertions passed; zero failures, testthat warnings, or skips. Four live Julia tests ran.
- The tests exercised correlated q2 save/reload, public Bernoulli SD outputs, one independent random-slope comparison with TMB, and separate SD targets.
- Julia printed two singular-Hessian diagnostics for q2-related fits. These are material warnings about uncertainty at those fits, not test failures.
- The exact R source/test hashes were: R/drmTMB.R e2f4c357edc5d04052a029506b809eaace8ff11055a6202bf3d7de46b84c0535; R/julia-bridge.R 94c759f51ea8d4f9614be26d41fbb796d008ec4dea81cf4ce43489b91009deeb; tests/testthat/test-julia-binomial-sd.R 8d3cad087ba018144ea758539ca4a235abf8fb2266df0581a459b5d69357c92a; tests/testthat/helper-julia-bridge-path.R be788198cabc6624e6ce8e37d6d45db9bae963cc5adb1ce244e80edc5f29e093.
- The paired Julia source hashes were: src/binomial.jl 7bfa5fc5c4fca1bf578830f7d4d6dd524b5c0624f791eae7f827f219e45c3e09; src/binomial_sd_regression.jl 498704bbc8027581079212c14f831d29d1ccfa645297f4081a0e290ff53825f8; src/bridge.jl 4c5c0f520ae5ee4d8eecaf2c3c9e26655f86cd0af2763c27b24c111e125a5e5a; src/inference.jl 1f09f0c3605f55f93286477e414fb8dcbd6887180a7f51c95cebe88a35f98e09; test/test_binomial_sd_regression.jl 0ba3407b132c349ca84e0e9863389c82820bbc556de4f42bb7569dbceb1c4013; Project.toml 36b9455e8fcb093e848fe1286432b0ce1c6b9e4e4cafc64e5f460b3818ce1ef9.
- The R/TMB and Julia candidates were dirty development worktrees at HEADs 425bee81572c625a634b2b083050c5c57c1dc1f1 and 70dbf564eb670144c63c08f61ea099084d95add2, respectively.
- The general julia-bridge filter passed 218 assertions with two warnings, but its live tests were sigma-side tests and are not counted as Bernoulli SD evidence.
- The first Julia attempt stopped at a sandbox permission error writing /Users/z3437171/.julia/logs/manifest_usage.toml.pid. A retry in a fresh R process with a task-specific writable JULIA_DEPOT_PATH passed. The initial test also showed a secondary JuliaCall active-project error after the failed startup.
- After-task structure validation, prose check, and git diff --check passed.

## 6. Tests of the Tests

I checked the test file and verified that the four drm_skip_live_julia calls are in the dedicated Bernoulli SD test file. The generic bridge filter runs unrelated sigma-side tests; its 218 passing assertions were deliberately excluded from the Bernoulli SD evidence count. The dedicated filter ran all four live cases and reported zero skipped live tests.

## 7a. Issue Ledger

- The Julia Bernoulli SD route remains a dirty local development candidate, unavailable from the shared/released DRM.jl companion.
- Same-data comparisons cover only narrow intercept/slope fixtures. General R/TMB versus Julia parity is unestablished.
- Correlated q2 same-data parity remains unestablished, and q2-related singular-Hessian diagnostics mean standard errors from those fits are not reliable.
- No Julia interval-calibration evidence exists.
- Native first-look calibration remains unqualified, with the staged decision look2_required.

## 8. Consistency Audit

The candidate inventory now records the 3,000-fit native first-look decision and the four-live-test Julia result. The Julia output contract distinguishes two narrow same-data comparisons from general parity. The related DRM.jl CMR lane is in separate CJS source paths; it has no confirmed file overlap with this SD lane.

## 9. What Did Not Go Smoothly

The first focused filter selected generic bridge tests, not Bernoulli SD tests. After checking the file list, I ran the dedicated filter. JuliaCall first attempted to write under the protected home depot and stopped; the clean retry used a writable temporary depot before the existing depot. Both setup failures are retained in the execution history and were not treated as model failures.

## 10. Known Residuals

This slice does not establish calibration, broad family support, bivariate support, structured random-effect support, or general cross-engine parity. The paired worktrees contain other in-flight programme changes, so these hashes describe only this test snapshot and are not clean release pins. Two singular-Hessian diagnostics require follow-up before relying on q2 uncertainty.

## 11. Team Learning

A broad test filename filter can report a live Julia pass while exercising a different model parameter. Count live bridge evidence only after checking the exact tests selected and their response/family/effect targets. Isolate Julia's writable depot when the sandbox denies its default lock-file path.

Style assessment: 2/10, medium confidence. The report names the candidate paths, test filter, warnings, and limits. Scientific and factual checks passed against the live test output and source hashes. References are not applicable because this is an internal test record.

## 12. Cross-Product Coverage

Covers four live Bernoulli random-effect SD tests through the R-to-Julia bridge on the paired dirty candidate worktrees. Does NOT cover a clean or released source pair, broad same-data parity, q2 parity, calibrated uncertainty, other distributions or effect types, structured providers, or the full package check.
