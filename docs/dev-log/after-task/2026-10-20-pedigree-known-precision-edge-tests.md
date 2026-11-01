# After Task: pedigree and known-precision edge tests

## 1. Goal

Pin edge behavior in the pedigree and known-precision helpers directly, without
running model fits, so future changes cannot silently alter these contracts.

## 2. Implemented

The existing test-only change adds direct tests for pedigree standardization,
parent normalization and ordering, Quaas precision construction, covariance to
precision conversion, and relatedness-matrix validation. The asymmetry cases
distinguish the internal, prevalidated covariance-to-precision conversion
helper, which symmetrizes from the upper triangle. The model-facing
`drm_known_relatedness_precision()` path rejects asymmetric input before
conversion. No package behavior or public API changed.

## 3a. Decisions and Rejected Alternatives

For the small pedigrees, the sparse Quaas precision is compared with the dense
inverse of the additive relationship matrix. The full-sib mating case has
inbreeding coefficient 0.25; outbred and half-known-parent cases check the
corresponding Mendelian variances. For the positive-definite matrix fixture,
the covariance and precision multiply to identity and their log determinants
agree.

Assumptions without asking: none.

## 4. Files Touched

- `tests/testthat/test-pedigree-known-precision-edges.R` (preserved from the
  PR).
- `docs/dev-log/check-log.d/2026-10-22-pr1599-pedigree-known-precision-edge-tests.md`
  (per-slice validation record).
- This after-task report (expanded to the project template).

## 5. Checks Run

- On the updated local candidate (focused test rerun before this report-only
  refresh),
  `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-pedigree-known-precision-edges.R")'`:
  PASS, 67 expectations, 0 failures, 0 warnings, 0 skips.
- `python3 tools/capability_ledger.py --check`: PASS, 31 generated outputs.
- `python3 tools/capability_ledger.py --check-c14-receipt-equivalence`: PASS,
  3 eligible and 7 source-different retained receipts.
- `python3 -m unittest tools.tests.test_capability_ledger`: PASS, 81 tests.
- `git diff --check`: PASS.
- After-task structure check: PASS. The closeout wrapper reaches the global
  Brain acceptance ledger and stops on nine unrelated unmet gates; those gates
  were left untouched. The earlier prose check reported 0 findings on the
  previous wording; manual source review for this update caught and corrected
  the overbroad asymmetry statement. No automated prose checker was available
  for this revision.
- The full package suite and current-candidate `R CMD check` were not run.

## 6. Tests of the Tests

The file checks boundary and malformed-input paths, including self-parenting,
cycles, unknown parents, duplicate IDs, malformed matrix names, non-finite
values, singular covariance, and non-positive-definite covariance and precision
matrices. The Quaas result is checked against the dense inverse obtained by
`solve(A)` from the helper-generated relationship matrix. This oracle checks
the dense inverse calculation; relationship-matrix construction remains outside
its scope. The non-positive-definite precision path emits a CHOLMOD warning;
the test suppresses that expected warning while asserting the helper's error.
The asymmetry tests now preserve the boundary: the internal
`drm_covariance_to_known_precision()` helper uses the upper triangle under its
prevalidated-input contract, while `drm_known_relatedness_precision()` rejects
asymmetry on the model-facing path.

## 8. Consistency Audit

The exercised helpers remain in `R/phylo-utils.R`; there is no change to their
implementation, formula syntax, examples, vignettes, NEWS, or pkgdown
navigation. `drm_covariance_to_known_precision()` applies
`forceSymmetric(uplo = "U")` and assumes its input has already been validated;
it is not the model-facing validation route. `drm_known_relatedness_precision()`
first calls `drm_standardize_relatedness_matrix()` and then rejects asymmetry
before dispatching to that conversion helper. The paired tests pin both
behaviors. No status inventory update is needed for this tests-only change.

## 7a. Issue Ledger

The PR has no linked issue. This pass did not search the issue tracker, so issue
status remains unchecked. No issue was opened, commented on, or closed.

## 9. What Did Not Go Smoothly

The initial PR head at preparation was
`ef3bc4690f27644458aa48cdc212fa8061481f15`; its merge base was
`f9bff01b5f3bbbc424402b73d67084dd446d9ff8`. I merged the exact current-main
candidate `2fb93b768977330fc9939d86375c37329a539277` into a new local worktree
without conflicts. The initial merge candidate was
`d7f9d1775ed79a29f3d03ec744290682bf68fb8d`. The PR's diff against that main
contains only the test, this report, and the per-slice check-log. No remote
branch was changed. The prior exact-PR-head workflow run `39856569302` was
cancelled; three of four Linux shards and the source-tree job passed, but the
remaining shard's R CMD check did not complete. The PR remains a draft.

## 10. Known Residuals

The tests characterize existing behavior and do not demonstrate that all
pedigree or precision inputs are scientifically appropriate. The internal
prevalidated conversion helper symmetrizes from the upper triangle; the
model-facing `drm_known_relatedness_precision()` path rejects asymmetric
matrices. The precision Cholesky failure can emit a warning before the intended
error. Those behaviors remain unchanged.

## 11. Team Learning

Tests-only PRs still need the repository's required check-log record and a
complete after-task report. Keep the existing test and its warning note, and
describe the focused validation separately from package-wide checks.

Memory receipt: loaded the `drmTMB` LOAD-FIRST manifest through `route.py`,
plus the `r-package-engineer` and `validation-harness` skills.

Golden Set: `memory_regression.py --selftest` passed all detector checks. This
task changed no hub or memory entries.

## 12. Cross-Product Coverage

This R-only test does NOT cover DRModels.jl or the R-to-Julia bridge. It adds no
cross-cutting flags and makes no cross-product parity claim.

## Next Actions

The local candidate includes exact current main
`2fb93b768977330fc9939d86375c37329a539277` and is ready for review. It has not
been pushed, marked ready, reviewed, or merged. Before any remote update, run
fresh checks on this exact candidate; do not treat the cancelled run or the
focused local test as a full package pass.
