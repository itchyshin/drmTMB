# PR #1595 refresh against current main

Merged current `main` (`7820315cc904358edbf3635515ebd3a73dbb7f31`) into the
MI quadrature guard branch. The two generated-file conflicts were resolved by
running their repository generators: `tools/write-env-skip-census.R` regenerated
the skip census from the merged test tree, and `tools/recertify-c17.py`
reproduced all three C17 current-source cells. The historical receipt directories
remain in place. The new C17 receipt is
`docs/dev-log/implementation-recovery/2026-10-22-pr1595-main-refresh-c17c2-c14-final-source-compatibility/`
and records merge-source commit `3e282a88b991559369ad32daea12f0f5c3fe1489`.

Checks: focused `devtools::test(filter = "mi-quadrature-1476-1477|mi-weights-1459|env-skip-census")`
passed 243 expectations, with two existing labelled skips and no failures or
warnings. The regenerated census contains 902 skip call sites; the Beta
`skip_on_cran()` row is represented. `tools/capability_ledger.py --check` passed
(31 generated outputs); `--check-c14-receipt-equivalence` passed; the capability
ledger Python tests passed 81/81. Full package tests were not rerun. The PR remains
open pending exact-head CI.
