# 2026-10-21: reject structured SD formulas in three incomplete family builders

- Added a common builder guard for Student-t, skew-normal, and zero-one beta. These builders previously classified structured SD formulas but did not include them in the returned model specification.
- Before the fix, the Student regression test failed because the phylogenetic SD formula did not raise an error. New animal-SD tests for skew-normal and zero-one beta also failed before the guard.
- After the fix, `NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet=TRUE); for (p in c("tests/testthat/test-student-sd-regression.R", "tests/testthat/test-skew-normal-sd-regression.R", "tests/testthat/test-zero-one-beta-sd-regression.R")) testthat::test_file(p, reporter="summary")'` passed all three focused test files.
- These checks cover builder assembly and explicit rejection only. They do not add structured SD fitting, Julia parity, or interval calibration.
