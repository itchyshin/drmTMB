library(testthat)
library(drmTMB)

# Phase 18 is the package's exhaustive simulation/reporting harness, and the
# structured-conversion contract is a generated 22,000-assertion audit. Keep
# both in repository CI, but do not rerun them during routine CRAN checks.
#
# The second group is a CRAN check-time budget. Measured on 2026-08-10 (receipts
# in docs/dev-log/release/0.7.0-cran-gate/test-timings.csv): the CRAN lane ran
# 1160 s locally and 29-30 min of `checking tests` on win-builder, far above
# CRAN's ~10-minute incoming guidance. Seventeen files carried 747 s of that
# 1160 s; excluding them leaves 413 s locally (~6.9 min), projecting to ~10 min
# on Windows at the measured 1.50x local->win-builder factor.
#
# These are statistical-validation suites -- bivariate association sandwiches,
# the G4/G5 missing-response foundation, zero-one-beta, bivariate Gaussian, and
# the profile-target matrix -- not "does the package install and work" tests.
# They still run in full in repository CI, where NOT_CRAN=true. Nothing is
# deleted and no test is weakened; this only changes which lane runs them.
#
# The patterns are ANCHORED on purpose. An unanchored "zero-one-beta" also
# matches test-missing-predictor-zero-one-beta.R, and an unanchored
# "biv-gaussian" also matches test-missing-response-biv-gaussian.R -- neither is
# intended, and both must keep running on the CRAN lane.
#
# `^julia` excludes every test-julia-*.R file. Ligges win-builder R-release
# and R-oldrelease (2026-08-16) hung inside JuliaCall::julia_setup() for
# 105-149 minutes. JuliaCall is Suggests, so skip_if_not_installed() does
# not skip when those hosts have Julia 1.11.3. Cheap R-only tests in
# test-xfam-bridge.R stay on the CRAN lane; live JuliaCall tests there use
# drm_skip_live_julia(). The full suite still runs when NOT_CRAN=true.
not_cran <- isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false")))
if (not_cran) {
  test_check("drmTMB")
} else {
  test_check(
    "drmTMB",
    filter = paste(
      "phase18|structured-re-conversion-contracts",
      "^associate-pairs",
      "^missing-response-g4g5-foundation$",
      "^zero-one-beta$",
      "^biv-gaussian$",
      "^profile-targets$",
      "^julia",
      sep = "|"
    ),
    invert = TRUE
  )
}
