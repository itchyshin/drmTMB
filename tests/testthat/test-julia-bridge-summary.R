# Issue #1081 option 1: a green test run must state its own boundary when the
# Julia bridge glue was never exercised (NOT_CRAN / DRMTMB_JULIA_TESTS /
# DRM_JL_PATH all unset). These tests exercise the counter/reporter
# functions in helper-julia-bridge-path.R directly.

test_that("summary reports skip count and says UNTESTED when nothing ran", {
  drm_julia_bridge_summary_reset()
  drm_julia_bridge_summary_record_skip()
  drm_julia_bridge_summary_record_skip()
  drm_julia_bridge_summary_record_skip()

  msg <- drm_julia_bridge_summary_line()

  expect_true(grepl("3", msg, fixed = TRUE))
  expect_true(grepl("skipped", msg, fixed = TRUE))
  expect_true(grepl("UNTESTED", msg, fixed = TRUE))
  drm_julia_bridge_summary_reset()
})

test_that("summary does not claim UNTESTED when live tests ran", {
  drm_julia_bridge_summary_reset()
  drm_julia_bridge_summary_record_live()
  drm_julia_bridge_summary_record_live()

  msg <- drm_julia_bridge_summary_line()

  expect_true(grepl("2", msg, fixed = TRUE))
  expect_true(grepl("ran", msg, fixed = TRUE))
  expect_false(grepl("UNTESTED", msg, fixed = TRUE))
  drm_julia_bridge_summary_reset()
})

test_that("summary reports both counts and stays accurate when mixed", {
  drm_julia_bridge_summary_reset()
  drm_julia_bridge_summary_record_live()
  drm_julia_bridge_summary_record_skip()
  drm_julia_bridge_summary_record_skip()

  msg <- drm_julia_bridge_summary_line()

  expect_true(grepl("1", msg, fixed = TRUE))
  expect_true(grepl("2", msg, fixed = TRUE))
  expect_true(grepl("ran", msg, fixed = TRUE))
  expect_true(grepl("skipped", msg, fixed = TRUE))
  expect_false(grepl("UNTESTED", msg, fixed = TRUE))
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
