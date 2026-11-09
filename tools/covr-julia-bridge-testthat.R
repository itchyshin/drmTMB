library(testthat)
library(drmTMB)

# Julia bridge coverage lane: run only live-Julia test files (stems matching
# ^julia after testthat strips the test- prefix). Repository CI sets this driver
# by planting it over the installed tests/testthat.R; the source tree keeps the
# sharded driver in tests/testthat.R.

not_cran <- isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false")))
if (!not_cran) {
  stop("Julia bridge coverage requires NOT_CRAN=true", call. = FALSE)
}
if (!identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true")) {
  stop("Julia bridge coverage requires DRMTMB_JULIA_TESTS=true", call. = FALSE)
}

julia_filter <- Sys.getenv("DRMTMB_COVERAGE_JULIA_FILTER", "^julia")
if (!nzchar(julia_filter)) {
  stop("DRMTMB_COVERAGE_JULIA_FILTER must be non-empty", call. = FALSE)
}

test_check("drmTMB", filter = julia_filter)
