# After Task: Native complete-data ZIP `mu` slope SD regression

## 1. Goal

Add a bounded predictor-dependent random-effect SD route for one independent numeric slope in the native complete-response zero-inflated Poisson model. Keep the zero-inflation parameter fixed and require the SD formula to select the same slope.

## 2. Implemented

The native ZIP builder now admits one independent `mu` slope when its coefficient-selected `sd()` formula identifies that slope. The fitted model estimates the group SD as a log-linear function of a group-constant predictor. The work adds a seeded slope-recovery case and an independent groupwise likelihood integral.

The mathematical contract is `b_g ~ N(0, s_g^2)`, `log(s_g) = gamma_0 + gamma_1 w_g`, and `log(mu_ig) = beta_0 + b_g x_ig`. The ZIP structural-zero probability remains fixed, and `w_g` must be constant within group. This route is complete-response only.

## 3a. Decisions and Rejected Alternatives

Kept the existing ZIP likelihood and target-resolution grammar. The builder change admits only one selected independent numeric `mu` slope with its matching SD formula. It does not admit a slope without the matching formula, `zi` random effects, other ZIP random-effect structures, or missing responses. Interval calibration is deferred under the implementation-first goal. No assumptions required user input.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-zi-poisson-sd-regression.R`
- `tests/testthat/test-zi-poisson-sd-integration.R`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `vignettes/formula-grammar.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/dev-log/known-limitations.md`
- `NEWS.md`
- `docs/dev-log/after-task/2026-10-21-native-zip-mu-slope-sd.md`
- `docs/dev-log/check-log.d/2026-10-21-native-zip-mu-slope-sd.md`

Several shared documentation files contain earlier programme edits. This report records only this ZIP slice and does not claim ownership of their full diffs.

## 5. Checks Run

- `test-zi-poisson-sd-regression`: passed, 25 assertions.
- `test-zi-poisson-sd-integration`: passed, 25 assertions in 68.5 seconds. It includes the seeded slope fit and recovery bound, SD predictions, independent groupwise integral, and reversed-group-index control.
- `git diff --check` on the implementation, focused tests, and updated documentation: passed.
- The after-task structure checker passed its required-section check. Its full acceptance-ledger reverify was interrupted while replaying the still-active programme gates; the broader goal remains open.
- The general predictor-dependent SD vignette was rendered after loading current source. The ZIP code chunks executed; the render emitted the existing Pandoc `--mathjax` deprecation warning. A final prose-only equation was added while that render was in progress, so that exact final prose was not inspected in the generated HTML.
- Full package checks, pkgdown checks, coverage calibration, and Julia parity were not run in this slice.

## 6. Tests of the Tests

The missing-SD-formula case must reject the selected ZIP slope, and reversing the group-to-SD index must worsen the independent integral. The recovery case retains a fixed seed and compares the fitted log-SD slope with its generating value using a predeclared standard-error bound. These controls catch target-routing and indexing errors in this fixture; they do not establish broad recovery or interval performance.

## 7a. Issue Ledger

An open-issue search found no matching issue, so no issue was opened, edited, or closed.

## 8. Consistency Audit

The code, tests, formula grammar, roadmap, limitations page, NEWS, and the two affected vignettes now agree that this is one native complete-response ZIP `mu` slope with fixed `zi`, conditional on a matching coefficient-selected SD formula. The status inventory search found no current README ZIP claim and no navigation change that would require `_pkgdown.yml` edits. The issue tracker was left unchanged because no open issue matched this work.

## 9. What Did Not Go Smoothly

The first assembly-test run assumed shorthand target names, while the resolver returns the selected formula target identity. The test was corrected to use that identity. The initial independent-integral oracle fixed the slope at its generating value, which did not represent the fitted marginal likelihood; the oracle now optimizes over the fixed slope before comparing the integral. A plain vignette render loaded an unrelated installed checkout; loading the current source resolved that mismatch.

## 10. Known Residuals

This slice establishes one native complete-response ZIP slope route with point-recovery and a fixture-specific independent integral. It does not establish interval calibration, general ZIP random-effect support, missing-response support, structured or correlated ZIP effects, random effects on `zi`, or Julia parity. The programme goal remains active.

## 11. Team Learning

For selected-coefficient SD routes, tests should assert the resolved target identity rather than infer a name from the user shorthand. An independent marginal-likelihood check should optimize shared fixed effects rather than condition on their generating values.

## 12. Cross-Product Coverage

Native R/TMB formula admission, fitting, coefficient extraction, SD prediction, and one independent per-group slope likelihood comparison were exercised. This slice does not cover profiles, bootstrap refitting for the slope, Julia execution, interval calibration, structured effects, or the overall general predictor-dependent random-effect SD goal.

## Prose assessment

The separate assessment record is `2026-10-21-native-zip-mu-slope-sd.assessment.json` and is bound to this exact report hash. It records a self-review of perceived style and separate science, facts, and reference gates. This is not independent review.
