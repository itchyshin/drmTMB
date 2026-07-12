library(testthat)
library(drmTMB)

# Phase 18 is the package's exhaustive simulation/reporting harness, and the
# structured-conversion contract is a generated 22,000-assertion audit. Keep
# both in repository CI, but do not rerun them during routine CRAN checks.
not_cran <- isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false")))
if (not_cran) {
  test_check("drmTMB")
} else {
  test_check(
    "drmTMB",
    filter = "phase18|structured-re-conversion-contracts",
    invert = TRUE
  )
}
