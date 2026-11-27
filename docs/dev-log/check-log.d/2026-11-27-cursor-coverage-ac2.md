# 2026-11-27 — cursor coverage ac2 (R/[a-c]* 0% files)

- Branch `cursor/1127cov-drmTMB-ac2`; CRAN-lane metrics via `covr::package_coverage(type = "tests")` with `tools/covr-source-tree-layout.sh` planted install path (`NOT_CRAN=false`).
- Added `tests/testthat/test-covr-ac2-topup.R` and `covr-ac2-topup` to `drm_cran_test_contexts()`.
- Local: `test_file("tests/testthat/test-covr-ac2-topup.R")` passed under `NOT_CRAN=false` (~25s) and `NOT_CRAN=true` (includes `drm_o3_fit` smoke).
- Issues filed: none.