# Pedigree and known-precision edge tests (#1599)

Replayed the test-only change onto current main `f9bff01b5f3bbbc424402b73d67084dd446d9ff8`. The root `check-log.md` was preserved because current main already contains concurrent append-only records.

`Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-pedigree-known-precision-edges.R")'`: PASS, 66 expectations, 0 failures, 0 warnings, 0 skips. `git diff --check`: PASS. The focused check exercises pedigree ordering and normalization, sparse Quaas precision against dense `solve(A)`, covariance/precision consistency, and malformed-input errors.

This is focused test evidence only. The full test suite, `R CMD check`, and exact-PR-head CI were not run on this local candidate. No package implementation or public API changed.
