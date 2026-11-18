# After Task: Native Bernoulli related-matrix q2 simulation and bootstrap

## 1. Goal

Complete marginal simulation and a bounded bootstrap refit workflow for the native Bernoulli logit related-matrix route with an intercept and one numeric slope, each with its own predictor-dependent SD.

## 2. Implemented

`simulate()` now draws independent fresh intercept and slope fields, applying each coefficient's fitted group-specific SD to its related-matrix covariance. `bootstrap_refit_one()` omits an internally stored all-one weight vector when it represents an unweighted fit. Actual non-unit weights remain explicit.

## 3a. Decisions and Rejected Alternatives

The covariance for coefficient field `j` remains `D_j K D_j`, where `D_j` contains that field's fitted group SDs. This slice retains the existing kernel scale and independent-field assumption. The bootstrap check covers refit execution and selected-target retention. It does not establish interval calibration.

## 4. Files Touched

- `R/methods.R`, `R/profile.R`, `man/simulate.drmTMB.Rd`
- `tests/testthat/test-binomial-relmat-q2-sd.R`
- `tools/general-sd-regression/bernoulli-relmat-q2/PLAN.md`, `make-capsule.py`, `source-manifest.json`, `source-capsule.tar.gz`, `check-fragment.md`, and `checkpoint.md`
- `docs/dev-log/general-sd-regression/bernoulli-relmat-q2-report.md`
- `docs/dev-log/after-task/2026-10-28-native-bernoulli-relmat-q2-marginal-bootstrap.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- The focused recovery/workflow block passed 31 assertions in 49.6 seconds. The complete q2 test file and neighboring target-workflow file passed after loading the package.
- `tools::checkRd("man/simulate.drmTMB.Rd")` passed. `pkgdown::check_pkgdown()` found no problems and reported existing Pandoc `--mathml` deprecation warnings.
- Scoped `git diff --check` passed. All 15 source-capsule member hashes matched the manifest; capsule SHA-256: `b59cb690ac400ca13c7844e9a09c46c765d6a5de7a6a602b62bac4cbc24d9acf`.
- The after-task structure check initially found missing numbered headings. The final structure check passed. It reports the broader acceptance ledger as UNKNOWN because its runner is absent.
- The full package suite, `R CMD check`, coverage calibration, and Julia q2 parity were not run.

## 6. Tests of the Tests

Before the bootstrap fix, both refits failed because the q2 route requires unweighted Bernoulli responses. The fitted object had stored implicit weights as ones, and the generic refitter passed them as explicit weights. After the fix, both seeded refits succeeded and retained the requested SD target. Existing negative tests continue to reject non-unit weights and unsupported q2 targets.

## 7a. Issue Ledger

The issue search returned package-wide test-sweep tracker #1464. That tracker does not identify this related-matrix q2 slice. No issue was opened, changed, or closed.

## 8. Consistency Audit

The simulator uses the same coefficient-specific scales as the fitted covariance and follows the existing `relmat()` formula. The roxygen description and `man/simulate.drmTMB.Rd` describe the admitted q2 marginal draw. The likelihood and formula parser were unchanged. Public capability maps were not promoted while q2 profile behavior and broader support remain open.

## 9. What Did Not Go Smoothly

Calling `test_file()` without `devtools::load_all()` failed during setup because package functions were unavailable. Loading the package before the focused test resolved that setup issue. A 64-group profile diagnostic returned unavailable endpoints. Profiling the frozen 160-group fixture exceeded the three-minute stop rule, so that run was interrupted.

## 10. Known Residuals

The 64-group fixture had a fitted SD slope near -3.9 and unavailable profile endpoints, consistent with weak information in that diagnostic. The high-information profile run has no result. This slice does not verify q2 profile intervals, outer-Hessian identifiability, interval coverage, or Julia parity. Other families, links, providers, and public workflow combinations remain open in the larger goal.

## 11. Team Learning

Fitted model objects can store all-one weights for unweighted fits. Generic refit code must preserve the distinction between implicit and explicit weights when a family route checks the input form. Structured q2 profile runtime needs its own bounded diagnostic before the interval workflow is advertised.

## 12. Cross-Product Coverage

This slice covers native TMB Bernoulli logit `mu`, one unlabelled related-matrix block with an intercept and one independent numeric slope, separate predictor-dependent SD formulas, marginal simulation, and two bootstrap refits. It does NOT cover Julia parity, profile interval availability, coverage calibration, or other families and providers.
