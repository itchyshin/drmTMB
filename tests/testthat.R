library(testthat)
library(drmTMB)

# The complete suite is an evidence programme as well as a package test suite:
# it includes simulation, recovery, coverage, numerical-oracle, comparator,
# generated-contract, and reader-render audits. Keep all of it in repository CI,
# but run a bounded installed-package smoke lane during routine CRAN checks.
#
# Candidate 6b45164b took 14 minutes in the Windows test stage even after the
# existing validation-suite exclusions. An explicit allowlist is fail-closed:
# a new evidence suite runs in full CI by default and enters the CRAN lane only
# after its runtime and purpose are reviewed.
#
# The retained contexts cover release identity, formula parsing, ordinary
# families, representative structured/missing/meta routes, public methods,
# MSPL, and reader/S3 compatibility. Nothing is deleted or weakened. Julia
# remains defense-in-depth blocked in the CRAN lane by drm_julia_setup() unless
# DRMTMB_JULIA_TESTS=true; its live suite remains repository-CI-only.
# Repository CI shards the full suite across parallel jobs via DRMTMB_TEST_SHARD
# ("k/N"); unset means run everything, so a local devtools::test() is unchanged.
# The helper lives under testthat/ so R CMD check does not execute it as a test
# file in its own right, and is sourced here the same way helper-cran-lane.R is
# below -- it is needed BEFORE test_check(), to build the filter argument.
# The CRAN lane is deliberately never sharded: it is already a bounded allowlist.
source(file.path("testthat", "helper-shard-util.R"), local = TRUE)
drm_shard <- drm_shard_filter()

not_cran <- isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false")))
if (not_cran) {
  if (is.null(drm_shard)) {
    test_check("drmTMB")
  } else {
    test_check("drmTMB", filter = drm_shard)
  }
} else {
  source(file.path("testthat", "helper-cran-lane.R"), local = TRUE)
  test_check(
    "drmTMB",
    filter = drm_cran_test_filter()
  )
}
