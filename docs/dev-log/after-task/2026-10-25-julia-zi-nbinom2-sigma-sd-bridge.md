# After Task: Julia bridge admission for ZI-NB2 sigma SD

## 1. Goal

Align the R bridge's admission check with the existing Julia ZI-NB2 sigma-SD implementation: fixed `zi` is allowed; predictor-dependent or random-effect `zi` is refused.

## 2. Implemented

`drm_julia_negbin2_sigma_sd_route_admitted()` now permits only `mu`, `sigma`, the one matching SD endpoint, and optional `zi`. When `zi` is present, the existing intercept-only predicate must pass. The ordinary NB2 sigma intercept and slope routes retain their prior admission behavior.

## 3a. Decisions and Rejected Alternatives

- Kept this as a bridge validation correction; no likelihood, formula grammar, public API, or registry change was needed.
- Reused the existing fixed-intercept predicate rather than adding a second definition of fixed `zi`.
- The existing live ZI-NB2 test already checks a fixed-`zi` cross-engine fit, so this change adds fit-free boundary checks rather than duplicating that integration fit.
- Interval coverage remains deferred by the programme decision.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-zi-nbinom2-sigma-sd-bridge.R`
- `tests/testthat/test-zi-nbinom2-sigma-sd-workflows.R`
- `NEWS.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `docs/dev-log/internal-roadmap.md`
- `docs/dev-log/check-log.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/check-log.d/2026-10-25-julia-zi-nbinom2-sigma-sd-bridge.md`
- `docs/dev-log/after-task/2026-10-25-julia-zi-nbinom2-sigma-sd-bridge.md`

## 5. Checks Run

- Red test before the fix: fixed `zi` passed, while `zi ~ w` and `zi ~ 1 + (1 | id)` were incorrectly admitted.
- Focused NB2 sigma-SD bridge unit tests: passed, including ordinary intercept/slope label checks and all three ZI admission cases. Existing live tests skipped in this first run because no Julia checkout path was set.
- With `DRM_JL_PATH` set to the paired Julia worktree and JuliaCall environment configured, the existing live ZI-NB2 sigma-SD bridge test passed: one live test ran.
- The ordinary NB2 sigma-SD bridge test also passed with Julia enabled: one live test ran, covering intercept and numeric-slope fits.
- The native ZI-NB2 workflow smoke test passed 12 expectations: `profile_targets()` marks the SD slope as profile-ready, and two bootstrap refits retain the target with available diagnostics.
- A full profile confidence-interval attempt exceeded four minutes without returning output and was interrupted. It is recorded as unverified for this cell.
- Scoped `git diff --check` on the implementation and added boundary test: passed.
- Coverage calibration, full package tests, and full documentation build were not run.

## 6. Tests of the Tests

The boundary test failed before the predicate change for both unsupported `zi` forms and passed afterward. The fixed-`zi` positive case guards against rejecting the route Julia already implements. Existing NB2 tests guard the ordinary sigma intercept and slope admission behavior. The workflow test confirms bootstrap refits expose the original SD target; it does not assess interval coverage. The full profile attempt did not finish within the stated estimate.

## 7a. Issue Ledger

- Fixed: the R bridge could route unsupported varying or random `zi` formulas to the Julia NB2 sigma-SD path.
- Deferred: Julia support for varying or random `zi` alongside this SD route; no such support is claimed.
- Deferred: interval coverage and broader uncertainty validation. The full profile confidence interval for this particular ZI-NB2 SD slope remains unverified because the attempted run was stopped after exceeding four minutes.

## 8. Consistency Audit

The bridge predicate now matches the Julia implementation boundary recorded by its existing live fixture: `mu` and `zi` fixed, one ordinary sigma random intercept with a predictor-dependent SD. The standalone test exercises only formula admission. No TMB likelihood or formula grammar changed. The capability map, roadmap, and development NEWS now report this single same-data Julia fit and retain the broader parity and interval-calibration limits.

## 9. What Did Not Go Smoothly

The initial test run skipped live Julia because the local checkout path was not set. Re-running with the explicit paired worktree and Julia home exercised the live route successfully. The repository's lane-preflight helper remained slow in this environment; it was not used as evidence of ownership. I sent the active DRM parity lane this scoped change and its live-test result.

## 10. Known Residuals

This verifies one bridge admission correction, the existing fixed-`zi` fit route, and bootstrap target retention for the native ZI-NB2 SD slope. It does not validate interval coverage, a completed profile interval for this cell, alternative `zi` models, other distributions, or the broader programme. The checkout contains concurrent dirty work; no unrelated changes were reverted, and nothing was committed, merged, or pushed.

## 11. Team Learning

The existing ZI-NB2 live bridge fixture should be checked before adding a second end-to-end simulation test; a focused predicate test was sufficient for this gap. No durable memory note was added.

## 12. Cross-Product Coverage

Covers: R bridge admission and one existing live R-to-Julia ZI-NB2 sigma-intercept SD integration fit with fixed `zi`; native profile-target registration and two successful bootstrap refits for the sigma SD slope coefficient.

Does NOT cover: predictor-dependent or random `zi`, a completed profile interval for this ZI-NB2 cell, interval coverage, other families or random-effect types, full package checks, or programme completion.
