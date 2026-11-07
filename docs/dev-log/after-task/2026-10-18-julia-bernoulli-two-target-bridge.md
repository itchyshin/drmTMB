# After Task: Bernoulli two-target Julia bridge verification

## 1. Goal

Reverify that the R-to-Julia bridge fits separate Bernoulli random-intercept and independent-slope SD regressions on one grouping variable after the selected-target identity changes.

## 2. Implemented

No additional fitting code was needed. The existing live bridge test now passes with two explicitly selected SD targets on the same group, including coefficient extraction, group SD prediction, profile-target identity, and bootstrap refit routing.

## 3a. Decisions and Rejected Alternatives

- Kept the two independent scalar coefficients as separate effects; this test does not imply a correlated intercept-slope covariance model.
- Treated the run as bridge regression evidence, not uncertainty calibration.
- Assumption: the existing deterministic synthetic fixture remains representative of this narrow higher-information cell; it does not establish behavior across seeds or designs.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-sd.R` (executed, unchanged in this slice)
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/check-log.d/2026-10-18-julia-bernoulli-two-target-bridge.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-18-julia-bernoulli-two-target-bridge.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

`DRMTMB_JULIA_TESTS=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" JULIA_DEPOT_PATH="/private/tmp/drm-julia-depot:$HOME/.julia" OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=2 Rscript -e 'devtools::test(filter = "julia-binomial-sd")'` passed 70 assertions across three live Julia bridge tests in 82.8 seconds. The testthat result had zero failures, warnings, or skips. Julia emitted Hessian boundary diagnostics during refit checks; those standard errors are not claimed as reliable. `git diff --check` passed. The read-only open-issue search for `Bernoulli separate SD Julia bridge` found no matching issue.

## 6. Tests of the Tests

The run includes both one-target baseline routes and a same-group two-target formula with explicit intercept and slope selectors. It checks both public coefficient blocks, group SD predictions, and refit target routing. The live test exercises R marshalling, Julia fitting, output translation, and refitting together, so a direct Julia-only pass would not substitute for it.

## 7a. Issue Ledger

No matching open issue was found in the read-only search. No issue was changed.

## 8. Consistency Audit

The R formula syntax, selected target labels, Julia target descriptors, and same-group Bernoulli implementation agree for separate independent scalar coefficients. The public R formula-grammar guide already states that Julia supports separate intercept and slope selectors for Bernoulli. The design table incorrectly said the Julia route allowed one term and one formula; it now records the tested same-group Bernoulli cell. The older after-task note and frozen check-log row remain historical snapshots. This does not establish correlated blocks or broaden other families.

## 9. What Did Not Go Smoothly

The Hessian checks reported numerical singularity at boundary coordinates during refit diagnostics. The fits and assertions completed, but those diagnostics reinforce that the run is not calibration evidence.

## 10. Known Residuals

This is one seeded synthetic same-group Bernoulli cell. It does not establish interval coverage, robust behavior across seeds, correlated intercept-slope covariance, structured effects, or multi-target parity for other families. The broader G0-G8 gates remain open.

## 11. Team Learning

After changing shared bridge target resolution, rerun the most information-dense live formula that uses multiple selected SD targets; single-target family checks cannot validate hash-key disambiguation for multiple targets. The route helper reported no LOAD-FIRST manifest for this checkout, so no routed brain notes were available; the Golden Set was not run because no known-mistake fixture was in scope.

## 12. Cross-Product Coverage

- Bernoulli independent intercept and numeric slope with separate selected SD formulas on one group: native R/TMB, Julia fitting, bridge extraction, prediction, and refit target identity are covered by the live test.
- Interval calibration and reliable uncertainty for this cell: does NOT cover these claims; Hessian boundary diagnostics remain visible.
- Correlated blocks, structured effects, other response families, and multi-target parity outside Bernoulli: does NOT cover these surfaces.
