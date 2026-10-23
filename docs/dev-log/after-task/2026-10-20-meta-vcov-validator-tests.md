# After Task: `meta_vcov_bivariate()` validator tests

## 1. Goal

Characterise the current input checks and covariance construction in the internal validators behind `meta_vcov_bivariate()`. This is a test-only change; package behaviour is unchanged.

## 2. Implemented

The added test file calls `validate_meta_variance_vector()`, `validate_meta_pair_vector()`, and `meta_vcov_bivariate()` directly. It covers numeric-vector requirements, finite non-negative variances, length and recycling rules, conversion from `cor12`, row-paired block layout, and positive-definite and positive-semidefinite boundary cases.

## 3a. Decisions and Rejected Alternatives

The PR originally appended its evidence to the shared root `docs/dev-log/check-log.md`. Current `main` had independent updates to that same file, so I kept the root log exactly as it appears on `main` and moved this slice's record to `docs/dev-log/check-log.d/2026-10-22-meta-vcov-validator-tests.md`. The test and this report remain in the PR. No test or implementation change was dropped to resolve the conflict.

## Mathematical Contract

For study `i`, the sampling block is `[[v1[i], cov12[i]], [cov12[i], v2[i]]]`. When supplied, `cov12[i] = cor12[i] * sqrt(v1[i] * v2[i])`. The implementation accepts finite non-negative marginal variances, requires positive-definite blocks when both marginal variances are positive, and permits a zero variance only when the resulting covariance is zero. No likelihood or estimator changed.

## 4. Files Touched

- `tests/testthat/test-meta-vcov-validators.R`: new characterization tests.
- `docs/dev-log/check-log.d/2026-10-22-meta-vcov-validator-tests.md`: per-slice check record.
- `docs/dev-log/after-task/2026-10-20-meta-vcov-validator-tests.md`: this closeout record.

## 5. Checks Run

- The candidate includes merge commit `cf067c380f977fccd326f33bb29f3c5fe1c665d4`, which joins the earlier PR head `753230efab6f22b5fa047d924f466f8f51fd7b84` to exact `main` commit `2fb93b768977330fc9939d86375c37329a539277`. At the time of run `39887324310`, PR head `ef77e158ae485075b93c7e7423d5064fe54a909c` changed only this report and the per-slice check-log relative to `cf067c3`. The test and package source were unchanged. The PR branch now includes merge commit `37ef40ad0309bf913056816b25d939394986e2a4`, which joins evidence commit `18451c06a1bf7be83f684edafb06f614fd5ea0b1` to current `main` `12ec50f82d7bff1459756d79005321423f0c4e35`; the merge completed without conflicts.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "meta-vcov")'`: 94 passed, 0 failed, 0 warnings, 0 skips. This runs both `test-meta-vcov-validators.R` and `test-meta-vcov.R` on the merged candidate.
- `python3 tools/capability_ledger.py --check`: passed (31 generated outputs).
- `python3 -m unittest tools.tests.test_capability_ledger`: 81 tests passed; C14 receipt equivalence passed (3 eligible, 7 source-different receipts retained).
- `git diff --check review/main...HEAD` and `git diff --check`: passed.
- GitHub run `39887324310` completed successfully on exact PR head `ef77e158ae485075b93c7e7423d5064fe54a909c`: the OS matrix, source-tree test, and all four Ubuntu release shards passed. The focused local test was rerun on this tree: 94 passed, 0 failed, 0 warnings, 0 skips.
- Full package tests and a fresh `R CMD check` were not run locally. Julia tests are outside this R helper-test change.

## 6. Tests of the Tests

The assertions cover valid outputs and malformed input or invalid covariance errors. They pass on unchanged implementation code, as expected for characterization tests; a red-before-green result is not applicable. The new tests and the existing neighboring `meta-vcov` tests both ran in the focused test command above.

## 7a. Issue Ledger

The PR has no linked issue. The prior PR record says the author reviewed #710 as a related older item and made no issue comment, opened no issue, or closed an issue. No issue action was needed for this rebase.

## 8. Consistency Audit

The assertions match `R/meta-vcov.R`: variance inputs must be numeric vectors with finite non-negative values; pair inputs recycle only from length one or `n`; covariance is converted from correlation with `sqrt(v1 * v2)`; and the returned dense matrix uses row-paired study blocks. No roxygen, user documentation, examples, or package code changed, so documentation regeneration and pkgdown checks were not needed.

## 9. What Did Not Go Smoothly

At initial reconciliation, the PR branch was 30 commits behind `main` at `2fb93b7`; merging that exact base into the isolated candidate produced no conflicts. Main later advanced to `12ec50f`, and that exact current main also merged without conflicts. The earlier shared root check-log conflict had already been resolved by retaining this slice's record under `check-log.d`. Focused local checks pass on the implementation tree.

## 10. Known Residuals

These tests characterize current validators; they do not establish a validation-policy change. GitHub run `39887324310` completed successfully on exact prior head `ef77e158...`, with all six jobs passing. The current PR head `4b5b365e...` includes a conflict-free merge of live `main` `12ec50f...`. Run `39894191617` is queued on that head for the OS matrix and source-tree tests; it has not completed. No full package check is recorded on this main-synced candidate. The PR remains draft; no merge or release claim is made.

## 11. Team Learning

For test-only characterization PRs, keep the evidence trail explicit: distinguish a reported result from a fresh rerun, state that unchanged code is expected to pass, and record the exact test command and result. Use `check-log.d` for a PR-scoped entry when several lanes may append to the shared root log.

## 12. Cross-Product Coverage

This change covers the native R `meta-vcov` tests and validators. It does NOT cover `DRModels.jl`, the R-to-Julia bridge, other model APIs, shared numerical code, or Julia parity. No cross-product claim is made.

## Next Actions

The isolated candidate is on local branch `codex/refresh-pr1600`; the current remote PR head is `4b5b365e1c30262cbb471ed3aba1e5ca41216d08`. It includes merge commit `37ef40ad0309bf913056816b25d939394986e2a4`, which joined evidence commit `18451c06...` to live `main` `12ec50f...` without conflicts. Run `39887324310` passed all six jobs on prior exact head `ef77e158...`. Run `39894191617` is queued on current head `4b5b365e...`; wait for those jobs before considering merge.

## Earlier current-head follow-up (2026-10-23, 08:12 UTC; historical)

The earlier sections above preserve the receipts and next actions recorded for their then-current PR heads. At 2026-10-23 08:12 UTC, the live PR head was `f76fe80ad17c7c130206f35fe69a188df7a9dae5`. The PR still targeted `main` at base SHA `12ec50f82d7bff1459756d79005321423f0c4e35`; live `main` was `8f550660ba011db5f880588d1e1976cc345d682f`. The head was 18 commits behind `main`. The PR's three changed paths did not overlap paths changed on `main`, `git merge-tree --write-tree origin/main refs/remotes/origin/pr1600-head` returned clean tree `2ac2968f70b05fe0de42c822ca2c5b9316e191d1`, and GitHub reported the PR mergeable. No sync commit was pushed.

I reran the focused tests from an isolated checkout at exact head `f76fe80ad17c7c130206f35fe69a188df7a9dae5` with `R_PROFILE_USER=/dev/null` and `--no-init-file`, using `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "meta-vcov")'`. The output was 94 passed, 0 failures, 0 warnings, and 0 skips. The console transcript is `/private/tmp/drmtmb-pr1600-meta-vcov-20261023.log`, SHA-256 `609d8457177394d66f07f4bde174c4f160e6f8e91a2932f8dee70a9b71887b20`. The output also states that no live Julia bridge tests ran. The run covered the focused validator tests. No full package test or `R CMD check` ran.

At 08:12 UTC, exact-head GitHub Actions run #3573 (`39896251857`) was still queued. It has not passed in the evidence recorded here. Scope: validator characterization only. Recovery, interval availability, interval calibration, and coverage remain untested. The PR remained open and draft; no merge or readiness claim is made. The current record edits pass `git diff --check`, the after-task structure check, the one-row check-log parser, and the prose checker (0 findings).


## Current-head follow-up (2026-10-23, 14:10 UTC)

The refreshed PR candidate is exact head `7a5802db34316e2987eb42aaca9f40633f499195`, based on current `main` `16647cdc2a426e669faa4c750abaddd5a0935d89`. The focused test was run against this source with `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "meta-vcov")'`: 94 passed, 0 failed, 0 warnings, and 0 skips. The transcript is `/private/tmp/drmtmb-pr1600-current-main-focused.log`, SHA-256 `cd9c51fb95cd25682a4b5a1f1d629ee632185e71184656c4afdd195e116b0a3a`. The output reports that no live Julia bridge tests ran.

Exact-head GitHub Actions run #3578 (`39966079139`) was queued at the latest check; it is pending, not passed. The earlier run #3575 (`39923323372`) was queued for prior head `0164c0800aec807d94be5dc7636e429b994b0e7d` and does not certify this candidate. The current focused test does not establish a full package test or `R CMD check`; no recovery, interval availability, calibration, or coverage claim is made. The record-only follow-up requires fresh checks on the resulting commit as well. The PR body was not updated because the GitHub connector returned 403 for an authorized PR-body update and alternate routes were explicitly disallowed. The PR remains open and unmerged.
