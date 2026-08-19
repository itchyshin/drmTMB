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
not_cran <- isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false")))
if (not_cran) {
  test_check("drmTMB")
} else {
  source(file.path("testthat", "helper-cran-lane.R"), local = TRUE)
  test_check(
    "drmTMB",
    filter = drm_cran_test_filter()
  )
}
