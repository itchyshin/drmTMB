## 1. Goal

Verify that a predictor-dependent Bernoulli random-effect SD slope retains its canonical target through Julia profile and bootstrap refits, and record the evidence boundary.

## 2. Implemented

Extended the live Julia Bernoulli SD bridge test to exercise one profile interval and a three-refit parametric-bootstrap smoke check for the SD slope. Updated the random-effect SD design note, NEWS, and check log to distinguish target/refit routing from interval reliability and calibration.

## 3a. Decisions and Rejected Alternatives

Kept the existing coefficient-block route because the profile and bootstrap APIs already accept generic fixed-effect targets. Did not change Julia source or claim interval validation. Assumed a three-refit bootstrap is sufficient for a plumbing smoke test; if this assumption is wrong, the needed change is a larger, separately estimated calibration design, and makes no calibration claim.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-sd.R`
- `NEWS.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-17-julia-bernoulli-sd-inference-routing.md`

Other pre-existing changes in this worktree belong to the broader SD-regression goal and are not included in this bounded slice.

## 5. Checks Run

- `JULIA_DEPOT_PATH=/private/tmp/drm-julia-depot:/Users/z3437171/.julia DRM_JL_PATH=/private/tmp/drmtmb-julia-public-env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary")'`: PASS; live Julia fit, profile interval and three-refit bootstrap smoke completed.
- Same environment with `filter = "binomial-sd-|julia-binomial-sd"`: PASS before the recovery assertion was added; focused native Bernoulli SD and live Julia bridge tests completed.
- Final live Julia SD test at 300 groups passed with the ±0.25 recovery bound, profile routing, and three-refit bootstrap routing. Live Julia SD recovery at 120 groups initially failed that bound: slope estimate 0.20 versus truth 0.50. A same-seed 300-group diagnostic converged and estimated intercept -0.270 (truth -0.223; SE 0.082) and slope 0.512 (truth 0.500; SE 0.138). The final 300-group Julia test then passed with the original bound.
- `git diff --check`: PASS.
- `tools::checkRd("man/confint.drmTMB.Rd")`: PASS with existing MathML deprecation warnings.
- `pkgdown::check_pkgdown()`: PASS, no problems found.
- `slop_check.py` on the design note: 2 style hits/2186 words, 0.9 per 1000; findings 0.
- `slop_check.py` on full `NEWS.md`: existing whole-file hits; the changed paragraph has no em dash. The first attempt used paths relative to the hub and checked no repository files; the corrected run used absolute paths.

## 6. Tests of the Tests

The live test asserts the canonical `fixef:sd:w` target for both profile and bootstrap outputs. The separate adapter test already rejects a changed SD predictor within a group. No mutation was injected into the profile/bootstrap route, so this is a positive smoke check, not a demonstrated negative control.

## 7a. Issue Ledger

- Fixed: docs/check-log wording previously left profile and bootstrap routing untested; it now records the narrow live smoke result.
- Deferred: profile/bootstrap interval reliability, coverage, and calibrated uncertainty remain open.
- No code defect was found in the generic Julia fixed-effect inference route.

## 8. Consistency Audit

Checked the Julia Bernoulli test, the random-effect SD design note, NEWS, and the check log. Their claims now agree: live point outputs and coefficient target routing are checked; inference calibration and broader family/effect coverage are not. `pkgdown::check_pkgdown()` found no navigation/API issues.

## 9. What Did Not Go Smoothly

The repository does not contain the hub `tools/closeout.py` or its companion validators. Calling the hub script attempted to write into the read-only Shinichi repository, and was stopped by filesystem permissions. The report is therefore written directly in this repository using the required section structure. Julia startup also prints a non-fatal `LogExpFunctionsInverseFunctionsExt` precompile warning (`loglogistic` undefined); the live tests still completed successfully.

## 10. Known Residuals

The recovery smoke uses one 300-group synthetic fixture and only three bootstrap refits. The 120-group failure remains recorded in the check log. It cannot establish nominal coverage, bias, failure rates, or reliable interval behavior. The umbrella SD-regression gates G0-G8 remain unmet; Bernoulli calibration and the full family/effect/backend map are outstanding.

## 11. Team Learning

Memory receipt: loaded the routed drmTMB manifest and applied its symbolic-alignment, compute-gating, and capability-boundary guidance. Golden Set: not run; this slice did not touch a known Golden Set failure class. Future Julia SD coefficients should be checked through the public profile and bootstrap interfaces, while keeping routing evidence separate from calibration evidence.

## 12. Cross-Product Coverage

Covers: Julia-engine Bernoulli ordinary location random-intercept SD slope; canonical coefficient target through profile and three bootstrap refits; R-facing outputs and documentation.

Does NOT cover: interval calibration or coverage; native TMB inference routing in this slice; other response families; random slopes, correlated or structured effects; bivariate models; or the complete family/effect/backend capability universe.
