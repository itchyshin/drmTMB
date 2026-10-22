# After task: predict/marginal validator tests

## Task goal

Add direct, fit-free characterization tests for the argument validators and
plain-vector helpers used by `predict_parameters()` and
`marginal_parameters()`. Keep the tests separate from the fitted-model paths.

## Files created or changed

- `tests/testthat/test-predict-marginal-parameter-validators.R` adds the
  characterization tests. This file is unchanged by the documentation follow-up.
- `docs/dev-log/check-log.md` records the focused test result.
- This after-task report records scope, evidence, and remaining limits.

## Checks run and exact outcomes

- `Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-predict-marginal-parameter-validators.R")'`
  on merge commit `2afdfc0eb4298056dafb57472f4ed48d95d17a46` (PR source
  `5254d9f56bca18527f86b1f105a1f17958ed7f8b` plus current `main`
  `7820315cc904358edbf3635515ebd3a73dbb7f31`): **FAIL 0, WARN 0, SKIP 0,
  PASS 114**. `devtools::load_all()` rebuilt the debug library and clang emitted
  12 compiler warnings; testthat reported no warnings.
- The six CI checks reported on the original PR head `5254d9f56bca18527f86b1f105a1f17958ed7f8b`
  were all successful (`os-matrix`, `source-tree tests (blind spot)`, and
  Ubuntu release shards 1–4). They predate the merge with current `main`; the
  updated branch needs fresh exact-head CI after it is pushed.
- Full `devtools::test()`, `R CMD check`, and helpers requiring a fitted model
  were not run.

## Consistency audit

Compared the assertions with the current-main definitions in
`R/predict-parameters.R` and `R/marginal-parameters.R`. The expected validator
errors, reserved output-name prefixes, link/response averaging rules, clamp
band boundaries, row-wise standard errors, and unavailable-interval fields
match those definitions. The change does not alter package code, public API,
formula grammar, or user-facing capability claims, so the status inventory,
design docs, and pkgdown navigation do not need updates.

## Tests of the tests

The focused run exercised all 114 expectations and reported no failures,
warnings, or skips. The tests assert returned values and error messages as well
as helper output shape. `predict_parameters_clamp_bent()` uses a minimal
stand-in object; no model fit is constructed. The tests do not claim coverage
of helpers that require fitted objects.

## What did not go smoothly

The focused run rebuilt the debug library and emitted 12 compiler warnings
from existing C++ dependencies/source; none became testthat warnings. Merging
current `main` into the PR branch completed without conflicts.

## Team learning and process improvements

Small, pure helpers can be characterized without repeated model fits. Keep the
test report explicit about which helpers use stand-ins and which fitted-model
paths remain outside the test.

## Design-doc updates

None. This is a test-only change and does not change model or API design.

## pkgdown and documentation updates

No user-facing documentation or pkgdown navigation changed. The check log and
this report are the developer records for the test addition.

## GitHub issue maintenance

The PR has no linked issue. An open-issue search for
`predict_parameters marginal_parameters` returned no matches; the issue tracker
was left unchanged.

## Known limitations and next actions

The full test suite and `R CMD check` remain unrun, and fit-requiring helpers
remain uncovered here. Push this synchronized documentation-only update and
check the new exact-head CI before promoting the PR from draft or merging it.
