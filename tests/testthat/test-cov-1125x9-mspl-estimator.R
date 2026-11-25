# Guards in R/mspl-estimator.R (distinct from R/mspl.R covered elsewhere).

test_that("drm_match_estimator() normalizes ML/MSPL spellings", {
  expect_identical(drmTMB:::drm_match_estimator("ML"), "ml")
  expect_identical(drmTMB:::drm_match_estimator("mspl"), "mspl")
  expect_error(drmTMB:::drm_match_estimator("reml"), "should be one of")
})

test_that("drm_is_mspl() detects estimator on objects and literals", {
  obj <- list(estimator = "MSPL", class = "drmTMB")
  class(obj) <- "drmTMB"
  expect_true(drmTMB:::drm_is_mspl(obj))
  expect_false(drmTMB:::drm_is_mspl(list(estimator = "ML", class = "drmTMB")))
  expect_true(drmTMB:::drm_is_mspl("mspl"))
  expect_false(drmTMB:::drm_is_mspl("ml"))
})

test_that("drm_mspl_filter_frequency_rows() keeps integer replicate weights", {
  dat <- data.frame(y = 0:3, x = 1:4)
  w <- c(1, 2, 3, 3)
  out <- drmTMB:::drm_mspl_filter_frequency_rows(dat, w, "mspl")
  expect_equal(nrow(out$data), 4L)
  expect_equal(out$weights, w)
  expect_error(
    drmTMB:::drm_mspl_filter_frequency_rows(dat, c(1, 0.5, 1, 1), "mspl"),
    "integer"
  )
})

test_that("drm_mspl_vcov_names() uniquifies duplicated beta_mu labels", {
  obj <- list(
    opt = list(par = c(beta_mu = 0.1, beta_mu = 0.2, re_sigma = 0.3)),
    class = "drmTMB"
  )
  class(obj) <- "drmTMB"
  nm <- drmTMB:::drm_mspl_vcov_names(obj)
  expect_length(nm, 3L)
  expect_equal(length(unique(nm)), length(nm))
})

test_that("drm_abort_mspl_inference() stops on MSPL objects only", {
  mspl <- structure(list(estimator = "MSPL"), class = "drmTMB")
  expect_error(
    drmTMB:::drm_abort_mspl_inference(mspl, "confint"),
    "not available"
  )
  ml <- structure(list(estimator = "ML"), class = "drmTMB")
  expect_invisible(drmTMB:::drm_abort_mspl_inference(ml, "confint"))
})