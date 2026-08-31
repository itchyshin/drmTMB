# Batch Julia startup must be distinguished from an R CMD check process.  A
# bare Rscript is a normal user-facing batch workflow; `_R_CHECK_PACKAGE_NAME_`
# is set by tools:::.check_packages() while checking a package.

test_that("Julia startup blocks an actual check lane but admits ordinary batch R", {
  ordinary_batch <- c(
    NOT_CRAN = "false",
    DRMTMB_JULIA_TESTS = "",
    `_R_CHECK_PACKAGE_NAME_` = ""
  )
  expect_false(drmTMB:::drm_julia_cran_lane_blocked(
    is_interactive = FALSE,
    environ = ordinary_batch
  ))
  expect_false(drmTMB:::drm_julia_cran_lane_blocked(
    is_interactive = FALSE,
    environ = c(ordinary_batch, `_R_CHECK_FORCE_SUGGESTS_` = "false")
  ))

  check_lane <- ordinary_batch
  check_lane[["_R_CHECK_PACKAGE_NAME_"]] <- "drmTMB"
  expect_true(drmTMB:::drm_julia_cran_lane_blocked(
    is_interactive = FALSE,
    environ = check_lane
  ))

  # Existing repository-live-test overrides stay explicit and continue to win.
  opted_in <- check_lane
  opted_in[["DRMTMB_JULIA_TESTS"]] <- "true"
  expect_false(drmTMB:::drm_julia_cran_lane_blocked(
    is_interactive = FALSE,
    environ = opted_in
  ))

  not_cran <- check_lane
  not_cran[["NOT_CRAN"]] <- "true"
  expect_false(drmTMB:::drm_julia_cran_lane_blocked(
    is_interactive = FALSE,
    environ = not_cran
  ))
})

test_that("Julia batch-startup gate does not infer a check lane from interactivity", {
  env <- c(
    NOT_CRAN = "false",
    DRMTMB_JULIA_TESTS = "",
    `_R_CHECK_PACKAGE_NAME_` = ""
  )
  expect_false(drmTMB:::drm_julia_cran_lane_blocked(
    is_interactive = TRUE,
    environ = env
  ))

  env[["_R_CHECK_PACKAGE_NAME_"]] <- "drmTMB"
  expect_false(drmTMB:::drm_julia_cran_lane_blocked(
    is_interactive = TRUE,
    environ = env
  ))
})
