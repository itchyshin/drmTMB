# After Task: Native Tweedie independent-slope SD regression

## 1. Goal

Extend native Tweedie direct-SD regression from an ordinary location intercept to one independent numeric location slope, using a bounded, complete-response route with fixed `sigma` and `nu`.

## 2. Implemented

The Tweedie builder now admits one ordinary `mu` intercept or one independent numeric slope as the SD target. A slope target uses `sd(group, coef = "x") ~ w` alongside `(0 + x | group)`. Target identity, SD design rows, and the TMB random-effect-to-SD map are checked. A seeded synthetic fit recovers the log-SD trend, returns finite coefficient uncertainty, predicts increasing group SDs, simulates and survives save/reload prediction. A constant SD formula agrees with the existing random-slope model.

## 3a. Decisions and Rejected Alternatives

Reused the existing Tweedie model-type 16 likelihood path, which already maps group SDs to all ordinary `mu` terms. Changed only the R admission and target selection to allow the independent slope case. Structured effects, correlated blocks, multiple targets, and random effects on `sigma` or `nu` remain outside this slice. Assumptions made without asking: none.

## 4. Files Touched

- ` R/drmTMB.R `
- ` tests/testthat/test-tweedie-sd-regression.R `
- ` tests/testthat/test-tweedie-sd-integration.R `
- ` README.md `
- ` NEWS.md `
- ` docs/design/01-formula-grammar.md `
- ` docs/design/03-likelihoods.md `
- ` docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md `
- ` docs/dev-log/known-limitations.md `
- ` vignettes/formula-grammar.Rmd `
- ` vignettes/model-map.Rmd `
- ` docs/dev-log/check-log.d/2026-10-20-tweedie-sd-slope.md `

## 5. Checks Run

- Before the builder change, the focused regression test failed because the Tweedie builder rejected the independent slope SD target.
- ` Rscript -e "devtools::test(filter = '^tweedie-sd-regression$', reporter = 'summary')" ` passed.
- ` Rscript -e "devtools::test(filter = '^tweedie-sd-integration$', reporter = 'summary')" ` passed, including seeded slope recovery and constant-SD equivalence.
- ` git diff --check ` passed for the changed implementation, tests, and documentation.
- The source-bound test did not run the Julia engine; Julia parity is not established by this slice.

## 6. Tests of the Tests

The new admission test failed before the code change at the intended unsupported-target error. The integration test combines SD regression with an existing independent random slope and checks recovery, predictions, simulation, save/reload, and constant-SD equivalence.

## 7a. Issue Ledger

No GitHub issue was opened or changed. This was a narrow continuation of the existing general SD-regression programme; no matching issue was identified for this exact Tweedie admission slice.

## 8. Consistency Audit

The public model map, formula guide, NEWS, README status row, known-limitations note, likelihood registry, and native family adapter map now describe the Tweedie slope route and its boundary consistently. The exact search was `rg -n -i `random-slope SDs outside.*Tweedie|Tweedie.*random slopes remain excluded|coefficient-specific targets.*rejected|until random-slope SD regression` README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd --glob `!**/evidence/**``; it found no remaining claim that Tweedie predictor-dependent slope SDs are excluded. The likelihood implementation itself was not changed. The task does NOT establish independent Tweedie likelihood-oracle evidence, Julia support, structured or correlated support, interval-coverage calibration, or general family parity.

## 9. What Did Not Go Smoothly

The repository-wide lane census is busy and reports 31 live lanes. The exact source and documentation paths were claimed under the current lane lease after reviewing the targeted source diff. A broad recursive stale-wording search initially traversed archived evidence capsules and produced excessive output; the final inventory search was restricted to current documentation paths. A repository-wide whitespace check also surfaced an unrelated extra blank line at EOF in another test file, which was not modified.

## 10. Known Residuals

The supported scope is complete responses, one ordinary `mu` target, fixed-effect `sigma` and `nu`, and either an intercept or one independent numeric slope. The independent likelihood oracle and confidence-interval coverage validation remain open. No Julia edit was made because DRM.jl ownership has not been handed off. The overall general predictor-dependent random-effect SD goal remains active.

## 11. Team Learning

When the likelihood already applies group-specific SD rows across all random-effect terms, audit builder admission and target resolution before changing TMB code. Narrow tests can expose support that is blocked only at the formula adapter.

## 12. Cross-Product Coverage

Native R/TMB fitting, recovery, extraction/prediction, simulation, and save/reload checks cover this slice. This task does NOT cover Julia, other distributions, structured or correlated effects, interval calibration, or programme completion.
