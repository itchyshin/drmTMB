# After-task: endpoint profile engine extended to fixed-effect coefficients

**Date:** 2026-06-20 · **Author:** Ada (autonomous, owner-directed) · **Gate:** TDD + targeted test suites
**Branch:** `shannon/overnight-audit-gaps-20260619`

## Task goal

Owner steer: manage and speed up profile-likelihood intervals ("profile is my
favorite"). The endpoint solver was ~3-5x faster than `TMB::tmbprofile()` but only
for direct scale/SD/correlation targets; fixed-effect coefficients fell back to the
slow full-grid route. Extend the endpoint engine to coefficients.

## Files changed

- `R/profile.R` — `profile_endpoint_target_supported()` now admits
  `target_class == "fixed-effect"` and `transformation == "linear_predictor"`;
  roxygen for `profile_engine` + the description updated; two stale error-message
  enumerations updated to include fixed-effect coefficients.
- `tests/testthat/test-profile-targets.R` — removed the obsolete "endpoint rejects
  coefficient" assertion; added "endpoint engine supports fixed-effect coefficient
  profiles and agrees with tmbprofile".
- `man/confint.drmTMB.Rd` — regenerated from roxygen (unrelated roxygen2-version
  `.Rd` drift reverted to keep the change surgical).
- `NEWS.md`, `docs/dev-log/check-log.md`, this report.

## Why it is small and safe

The endpoint solver (`profile_endpoint_evaluator`), the opt-position mapping, and
`profile_transform_interval` (which already had a `linear_predictor` identity branch)
were all general. Only the eligibility allow-list excluded coefficients. The `auto`
engine already falls back to `tmbprofile` when an endpoint solve errors, so the worst
case is the previous behaviour.

## Checks run and exact outcomes

- RED: `confint(parm="mu:x", profile_engine="endpoint")` errored before the change.
- GREEN: endpoint coefficient CI equals tmbprofile CI to max |diff| 4.4e-6; `auto`
  selects endpoint; 29.8 ms vs 117.1 ms (3.93x) on a Gaussian `mu:x`.
- `test-profile-targets.R`: FAIL 0, PASS 795. `test-biv-gaussian.R`: FAIL 0, PASS 945.
- `devtools::document()` ran; only `man/confint.drmTMB.Rd` kept.

## Consistency audit

- No status-matrix cell changed by the code edit itself; this is an engine/perf
  enhancement. It makes coefficient profiles ~3-5x faster by default and unblocks
  feasible profile calibration for RE / non-Gaussian models (previously too slow).
- The companion benchmark
  (`docs/dev-log/simulation-artifacts/2026-06-20-profile-engine-speed-benchmark/`)
  measured the 3-5x on scale/SD/correlation targets; this change brings the same to
  coefficients (3.93x measured on `mu:x`).

## Tests of the tests

- The new test pins both correctness (endpoint == tmbprofile within 1e-3) and the
  `auto`-selects-endpoint behaviour; the retained `newdata` and `ystep` assertions
  guard the genuinely-unsupported and controls-force-tmbprofile paths.

## Follow-ups (not done here)

- A full `devtools::check()` before any release (only targeted suites run here).
- Broaden profile/bootstrap CI calibration to random-slope and non-Gaussian rows
  (now feasible at speed).
- "maximized in Julia": an in-process direct DRM.jl profile/bootstrap loop.
