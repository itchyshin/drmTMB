# Gamma SD bridge evidence refresh

Date: 2026-10-22. Native worktree HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired Julia worktree HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`. Both worktrees were dirty; the exact source manifest records and verifies 198 relevant source files.

Ran three `testthat::test_file()` descriptions from `tests/testthat/test-julia-gamma-sd.R` with Julia 1.10.0 and a private offline depot: ordinary Gamma `mu` intercept, ordinary independent numeric slope, and phylogenetic `mu` intercept. All three passed, with 12 expectations each and one live Julia fit per test; each compares against native TMB.

`python3 tools/general-sd-regression/tests/test_reconcile_evidence.py` passed all 10 tests. `python3 tools/general-sd-regression/reconcile_evidence.py` passed: 19,118 candidate rows, 11 linked rows, 19,107 unlinked rows. Four superseded Gamma records were preserved in `evidence/gamma-phylo-point-parity-20261022/superseded-gamma-evidence.tsv`. The reconciliation is evidence bookkeeping only; it does not close a programme gate or validate interval coverage.

The after-task section-structure check passed, and `slop_check.py` reported zero findings for both notes. The integrated acceptance-ledger reverify was not run: this is a partial evidence slice, and the active programme gates remain open.
