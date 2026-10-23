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

- The local candidate is merge commit `cf067c380f977fccd326f33bb29f3c5fe1c665d4`, with parents PR head `753230efab6f22b5fa047d924f466f8f51fd7b84` and exact `review/main` commit `2fb93b768977330fc9939d86375c37329a539277`. The merge completed without conflicts.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "meta-vcov")'`: 94 passed, 0 failed, 0 warnings, 0 skips. This runs both `test-meta-vcov-validators.R` and `test-meta-vcov.R` on the merged candidate.
- `python3 tools/capability_ledger.py --check`: passed (31 generated outputs).
- `python3 -m unittest tools.tests.test_capability_ledger`: 81 tests passed; C14 receipt equivalence passed (3 eligible, 7 source-different receipts retained).
- `git diff --check review/main...HEAD` and `git diff --check`: passed.
- GitHub run `39855947658` belongs to the old PR head `753230ef...`, not this local candidate. It completed as cancelled: release shards 3/4 and 4/4 succeeded; shards 1/4 and 2/4 and the source-tree job were cancelled. The combined commit status had no statuses. The local candidate has no GitHub CI result.
- Full package tests and a fresh `R CMD check` were not run locally. Julia tests are outside this R helper-test change.

## 6. Tests of the Tests

The assertions cover valid outputs and malformed input or invalid covariance errors. They pass on unchanged implementation code, as expected for characterization tests; a red-before-green result is not applicable. The new tests and the existing neighboring `meta-vcov` tests both ran in the focused test command above.

## 7a. Issue Ledger

The PR has no linked issue. The prior PR record says the author reviewed #710 as a related older item and made no issue comment, opened no issue, or closed an issue. No issue action was needed for this rebase.

## 8. Consistency Audit

The assertions match `R/meta-vcov.R`: variance inputs must be numeric vectors with finite non-negative values; pair inputs recycle only from length one or `n`; covariance is converted from correlation with `sqrt(v1 * v2)`; and the returned dense matrix uses row-paired study blocks. No roxygen, user documentation, examples, or package code changed, so documentation regeneration and pkgdown checks were not needed.

## 9. What Did Not Go Smoothly

The PR branch was 30 commits behind current `main`. Merging the exact reviewed `main` commit into the isolated candidate produced no conflicts. The earlier shared root check-log conflict had already been resolved by retaining this slice's record under `check-log.d`. All focused local checks pass on the merged candidate.

## 10. Known Residuals

These tests characterize current validators; they do not establish full-package health or change validation policy. The tested merge candidate `cf067c3` and the report-only closeout update remain local. The remote PR remains draft at head `753230ef...`; its only retrieved workflow run was cancelled and does not validate the local merge candidate. Full package tests, a fresh `R CMD check`, and exact-candidate GitHub CI remain outstanding.

## 11. Team Learning

For test-only characterization PRs, keep the evidence trail explicit: distinguish a reported result from a fresh rerun, state that unchanged code is expected to pass, and record the exact test command and result. Use `check-log.d` for a PR-scoped entry when several lanes may append to the shared root log.

## 12. Cross-Product Coverage

This change covers the native R `meta-vcov` tests and validators. It does NOT cover `DRModels.jl`, the R-to-Julia bridge, other model APIs, shared numerical code, or Julia parity. No cross-product claim is made.

## Next Actions

The isolated candidate is on local branch `codex/pr1600-main-sync-20261022`. Its tested implementation tree is merge commit `cf067c380f977fccd326f33bb29f3c5fe1c665d4`, followed only by these source-bound report and check-log updates. No push, ready-for-review transition, or PR merge was performed. Any next PR action requires review of this local candidate and green exact-head checks.
