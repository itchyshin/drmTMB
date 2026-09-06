# Issue #1081 option 1: a green test run must state its own boundary when the
# LIVE Julia engine was never exercised (NOT_CRAN / DRMTMB_JULIA_TESTS /
# DRM_JL_PATH all unset) -- and must not over-claim "UNTESTED" over the
# mock-driven marshalling tests that do run there (issue #1081, leaf A1).
# These tests exercise the counter/reporter functions in
# helper-julia-bridge-path.R directly.

test_that("summary reports skip count and says the LIVE ENGINE was not exercised when nothing ran", {
  drm_julia_bridge_summary_reset()
  drm_julia_bridge_summary_record_skip()
  drm_julia_bridge_summary_record_skip()
  drm_julia_bridge_summary_record_skip()

  msg <- drm_julia_bridge_summary_line()

  expect_true(grepl("0 live tests ran, 3 skipped", msg, fixed = TRUE))
  expect_true(grepl("LIVE ENGINE was not exercised", msg, fixed = TRUE))
  # The old wording over-claimed (mock-driven marshalling tests DO run here).
  expect_false(grepl("UNTESTED", msg, fixed = TRUE))
  expect_false(grepl("bridge glue was exercised", msg, fixed = TRUE))
  drm_julia_bridge_summary_reset()
})

test_that("summary says the bridge glue was exercised when live tests ran", {
  drm_julia_bridge_summary_reset()
  drm_julia_bridge_summary_record_live()
  drm_julia_bridge_summary_record_live()

  msg <- drm_julia_bridge_summary_line()

  expect_true(grepl("2 live tests ran", msg, fixed = TRUE))
  expect_true(grepl("bridge glue was exercised", msg, fixed = TRUE))
  expect_false(grepl("not exercised", msg, fixed = TRUE))
  drm_julia_bridge_summary_reset()
})

test_that("summary reports both counts and stays accurate when mixed", {
  drm_julia_bridge_summary_reset()
  drm_julia_bridge_summary_record_live()
  drm_julia_bridge_summary_record_skip()
  drm_julia_bridge_summary_record_skip()

  msg <- drm_julia_bridge_summary_line()

  expect_true(grepl("1 live test ran, 2 skipped", msg, fixed = TRUE))
  expect_true(grepl("bridge glue was exercised", msg, fixed = TRUE))
  expect_false(grepl("not exercised", msg, fixed = TRUE))
  drm_julia_bridge_summary_reset()
})

test_that("drm_skip_live_julia() records a skip on the CRAN-lane branch", {
  drm_julia_bridge_summary_reset()
  withr::local_envvar(c(NOT_CRAN = "false", DRMTMB_JULIA_TESTS = "false"))
  testthat::local_mocked_bindings(interactive = function() FALSE, .package = "base")

  outcome <- tryCatch(
    drm_skip_live_julia(),
    skip = function(e) e
  )

  expect_s3_class(outcome, "skip")
  expect_equal(drm_julia_bridge_summary_env$skipped, 1L)
  expect_equal(drm_julia_bridge_summary_env$ran, 0L)
  drm_julia_bridge_summary_reset()
})

test_that("drm_skip_live_julia() records a live run when it proceeds", {
  drm_julia_bridge_summary_reset()
  withr::local_envvar(c(NOT_CRAN = "true"))

  result <- drm_skip_live_julia()

  expect_true(isTRUE(result))
  expect_equal(drm_julia_bridge_summary_env$ran, 1L)
  expect_equal(drm_julia_bridge_summary_env$skipped, 0L)
  drm_julia_bridge_summary_reset()
})
