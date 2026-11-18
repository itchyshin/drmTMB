# After Task: Native Bernoulli SD Regression Evidence and Guide

## 1. Goal

Verify the in-progress native Bernoulli predictor-dependent random-effect SD slice and align its reader-facing scope with the current implementation evidence.

## 2. Implemented

The worktree contains native Bernoulli SD regression for ordinary random intercepts, independent slopes, and correlated two-coefficient blocks. This slice verified those paths with focused tests and updated the guide to distinguish tested ordinary effects from unverified structured-provider, Julia, and repeated-sampling calibration support. The implementation source was already modified in the active goal worktree; this slice changed the vignette, not the core likelihood.

## 3a. Decisions and Rejected Alternatives

The Bernoulli random-effect SD is interpreted on the response link scale. Correlated blocks use coefficient-specific marginal scales and their existing correlation parameter. The guide keeps its compact intercept examples, then shows separate selectors for the intercept and slope in a correlated block. I did not broaden the example into a structured effect or describe mock Julia bridge tests as Julia-engine parity.

## 4. Files Touched

- Updated `vignettes/predictor-dependent-random-sd.Rmd` with tested native Bernoulli slope and correlated-block scope, a selector example, and explicit calibration and parity limits.
- Updated `docs/dev-log/check-log.md` with the executed test and render evidence.
- Added this report.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-(sd|correlated)", reporter = "summary")'` completed with `DONE` and no test failures reported. It exercised correlated Bernoulli blocks, integration, profiles, simulation, target selectors, and target workflows; five live Julia-dependent tests were skipped because neither `DRM_JL_PATH` nor `DRMODELS_JL_PATH` was configured. The regex also selected beta-binomial SD tests and a Julia NB2 test, which completed or skipped as shown by the runner.
- Rendered `vignettes/predictor-dependent-random-sd.Rmd` using the development package; both Bernoulli and Poisson example fits rendered successfully.
- `git diff --check` on the vignette passed.
- `slop_check.py` on the design and report passed with `FINDINGS: 0`.
- Confirmed `_pkgdown.yml` already includes the article in navigation.

## 6. Tests of the Tests

The Bernoulli integration tests include parameter recovery for intercept and slope SDs, a direct Laplace likelihood calculation, and constant-SD equivalence. Correlated-block tests check coefficient-axis identity, the requested marginal covariance, and fit/predict/simulate/refit behavior. These checks test distinct aspects of the route rather than only object construction.

## 7a. Issue Ledger

No GitHub issue was changed. The tests and guide belong to the active internal feature programme, and no open issue was identified as the owner of this slice.

## 8. Consistency Audit

The guide now says that its runnable examples use Bernoulli and Poisson random intercepts, while the broader native Bernoulli test slice covers independent slopes and correlated q=2 ordinary blocks. It retains the group-constant requirement for SD predictors. The site already links the article. No response-family inventory or release note was changed because the feature remains in progress and calibration is unverified.

## 9. What Did Not Go Smoothly

The focused integration test took about 6 to 7 minutes, slightly beyond its 5-minute estimate. I widened the estimate for the broader native Bernoulli test suite to 15 to 25 minutes. NotebookLM's local cookie check still failed its live token fetch, the notebook list returned a signed-out response, and credential refresh failed with a DNS resolution error. Its methods review remains incomplete.

## 10. Known Residuals

These tests establish implementation and recovery behavior for tested native ordinary Bernoulli cases only. They do not establish calibrated interval coverage, structured Bernoulli SD regression, all-distribution parity, or live Julia parity. The Julia fit tests remain skipped until the paired engine path is available. Totoro is occupied by the paired DRM.jl calibration campaign, so no Totoro or DRAC work was started here.

## 11. Team Learning

Treat a test suite's `DONE` plus explicit skip list as separate evidence: native routes passed, while a missing engine path leaves live parity untested. Keep the user-facing scope tied to that distinction.

## 12. Cross-Product Coverage

This slice does NOT cover structured-effect SD regression, every supported response family, live Julia fitting, or calibrated uncertainty. It covers native Bernoulli ordinary intercepts, independent slopes, and correlated q=2 blocks at the focused test level, plus the two rendered random-intercept examples. Save/reload, prediction, simulation, profile, and bootstrap-refit paths are covered only where the named tests exercise them.
