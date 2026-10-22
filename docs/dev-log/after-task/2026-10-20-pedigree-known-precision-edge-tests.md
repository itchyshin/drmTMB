# After Task: pedigree and known-precision edge tests

## 1. Goal

Pin edge behavior in the pedigree and known-precision helpers directly, without
running model fits, so future changes cannot silently alter these contracts.

## 2. Implemented

The existing test-only change adds direct tests for pedigree standardization,
parent normalization and ordering, Quaas precision construction, covariance to
precision conversion, and relatedness-matrix validation. No package behavior or
public API changed.

## 3a. Decisions and Rejected Alternatives

For the small pedigrees, the sparse Quaas precision is compared with the dense
inverse of the additive relationship matrix. The full-sib mating case has
inbreeding coefficient 0.25; outbred and half-known-parent cases check the
corresponding Mendelian variances. For the positive-definite matrix fixture,
the covariance and precision multiply to identity and their log determinants
agree.

## 4. Files Touched

- `tests/testthat/test-pedigree-known-precision-edges.R` (preserved from the
  PR).
- `docs/dev-log/check-log.d/2026-10-22-pr1599-pedigree-known-precision-edge-tests.md`
  (per-slice validation record).
- This after-task report (expanded to the project template).

## 5. Checks Run

- `Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-pedigree-known-precision-edges.R")'`:
  PASS, 66 expectations, 0 failures, 0 warnings, 0 skips.
- `git diff --check`: PASS.
- Prose style check: PASS, 0 findings.
- This focused result does not certify the full package suite or `R CMD check`.

## 6. Tests of the Tests

The file checks boundary and malformed-input paths, including self-parenting,
cycles, unknown parents, duplicate IDs, malformed matrix names, non-finite
values, singular covariance, and non-positive-definite covariance and precision
matrices. The Quaas result is checked against an independently formed dense
relationship matrix and `solve(A)`, rather than another copy of the sparse
algorithm. The non-positive-definite precision path emits a CHOLMOD warning;
the test suppresses that expected warning while asserting the helper's error.

## 8. Consistency Audit

The exercised helpers remain in `R/phylo-utils.R`; there is no change to their
implementation, formula syntax, examples, vignettes, NEWS, or pkgdown
navigation. The asymmetry test deliberately records current behavior: the
helpers symmetrize from the upper triangle and do not reject an asymmetric
matrix. This is a characterization test; the input contract remains unchanged. No
status inventory update is needed for a tests-only change.

## 7a. Issue Ledger

The PR has no linked issue. This pass did not search the issue tracker, so issue
status remains unchecked. No issue was opened, commented on, or closed.

## 9. What Did Not Go Smoothly

The isolated clone fetched the exact live PR head
`4629c116ada05a9af7f8f8df0473d181606fb491` and current main
`f9bff01b5f3bbbc424402b73d67084dd446d9ff8`. The focused test passed after the
test-only change was replayed onto current main. Main already had its own recent
append in `docs/dev-log/check-log.md`, so that file was preserved and this
change records its result under `docs/dev-log/check-log.d/`. The refreshed
candidate remains local; no push or exact-head CI run occurred.

## 10. Known Residuals

The tests characterize existing behavior and do not demonstrate that all
pedigree or precision inputs are scientifically appropriate. In particular,
asymmetric matrices are currently symmetrized from their upper triangle, and
the precision Cholesky failure can emit a warning before the intended error.
Those behaviors remain unchanged.

## 11. Team Learning

Tests-only PRs still need the repository's required check-log record and a
complete after-task report. Keep the existing test and its warning note, and
describe the focused validation separately from package-wide checks.

## 12. Cross-Product Coverage

This R-only test does NOT cover DRModels.jl or the R-to-Julia bridge. It adds no
cross-cutting flags and makes no cross-product parity claim.

## Next Actions

The local candidate is based on current main
`f9bff01b5f3bbbc424402b73d67084dd446d9ff8`. Before updating the PR branch,
verify that its remote head is still
`4629c116ada05a9af7f8f8df0473d181606fb491`; then use an expected-head update
and wait for checks on the exact new head. Do not mark ready or merge as part
of this closeout.
