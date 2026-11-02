# After Task: Zero-Inflated NB2 SD Route Verification

## 1. Goal

Determine whether the visible `sd(id) ~ w` zero-inflated NB2 route is exercised by the package-loaded native test suite.

## 2. Implemented

The existing test file passes through `devtools::test()`, providing local native evidence for the tested zero-inflated NB2 random-intercept SD route. No model source, test source, or public support claim changed.

## 3a. Decisions and Rejected Alternatives

The test checks a group-level SD regression for the NB2 count-side random intercept while `sigma` and `zi` remain fixed. No broader identifiability or calibration claim is made.

## 4. Files Touched

- Added this after-task report.
- Added `docs/dev-log/check-log.d/2026-10-19-zi-nbinom2-sd-route-verification.md`.
- Updated `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md` to add the verified route and its limits.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zi-nbinom2-sd-regression", reporter = "summary")'`: passed; 29 expectations reported as dots, no failures.
- `git diff --check -- docs/dev-log/after-task/2026-10-19-zi-nbinom2-sd-route-verification.md docs/dev-log/check-log.d/2026-10-19-zi-nbinom2-sd-route-verification.md`: passed.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <absolute report path>`: section structure passed; full closeout returned nonzero because nine programme gates remain unmet (`GATES.md`, binomial selectors, lognormal intercept, native binomial, native calibration, ordinary targets, Poisson label, Poisson ordinary, and Poisson slope).
- `python3 ~/shinichi-brain/tools/slop_check.py <absolute report path>`: 0 findings; the first relative-path invocation resolved against the brain repository instead of this worktree.

## 6. Tests of the Tests

The test file includes construction and target-validation checks, missing-data rejection, a fitted SD-regression case, and a constant-SD comparison. A preliminary `testthat::test_file()` invocation failed because it did not load the package; that invocation was discarded and the package-loaded `devtools::test()` run passed.

## 7a. Issue Ledger

Searched open issues in `itchyshin/drmTMB` for random-effect SD and zero-inflated NB2 terms. The connected issue search returned no matches; no issue was changed.

## 8. Consistency Audit

No runtime behavior or public user documentation changed. The internal native-family map now records the zero-inflated NB2 route and its evidence. The family registry, roadmap, random-effect-scale design, and known-limitations page describe an intercept-only direct-SD route. The formula-grammar vignette still says zero-inflated NB2 random effects beyond a spatial diagnostic route are planned, which conflicts with this tested ordinary-intercept slice. Per-file preflight found 46 refs with work on `vignettes/formula-grammar.Rmd` and an active direct-to-main lane. I reviewed the `origin/main` and `origin/claude/lane-g-docs-reference` diffs: they change nearby entries but leave this claim unchanged. I left the vignette untouched pending its owner handoff. The status-inventory search used this exact pattern: `zero.inflated.*(NB2|negative binomial)|zi_nbinom2|sd\(group\)` across README, internal roadmap, NEWS, known limitations, formula grammar, family registry, distribution roadmap, random-effect-scale design, the formula and SD vignettes, and `_pkgdown.yml`.

## 9. What Did Not Go Smoothly

The first test command bypassed package loading and produced missing-function errors. The correct `devtools::test()` entry point passed.

## 10. Known Residuals

Evidence covers one local test file. Simulation-recovery calibration, an independent likelihood oracle, calibrated uncertainty, Julia parity, and release support remain open. The stale formula-grammar row requires owner handoff before correction. Programme gates remain open.

## 11. Team Learning

Use the package test runner for test files that rely on the package namespace; `testthat::test_file()` alone is not an equivalent invocation here.

## 12. Cross-Product Coverage

Covers: one complete-data native TMB zero-inflated NB2 `mu` random intercept with fixed `sigma` and `zi`, a group-constant SD predictor, synthetic point recovery, an independent groupwise Laplace oracle, target validation, constant-SD comparison, prediction, simulation, and save/reload.

This slice does NOT cover random slopes, structured or provider effects, random effects on `sigma` or `zi`, missing-response fits, correlated blocks, Julia execution or bridge parity, interval calibration, or programme completion. The next action is to reconcile this route's exact row in the family capability ledger and continue the broader family, effect, and engine audit.

## Prose Assessment

Style: 3/10, medium confidence; the report uses concrete file names, test results, and scope limits. Genre and coverage: technical after-task report, all sections reviewed. Evidence and repair: sections 5 and 10 tie claims to exact checks and residual gates; no further prose change needed. Gates: scientific claims not applicable; factual claims pass against the test output, current documentation, preflight, and branch diffs; references not applicable because the report cites local evidence only. Provenance: self-review, version 2, 2026-10-19; source outputs and earlier report controls were seen.
