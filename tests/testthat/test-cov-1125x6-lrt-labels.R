# Extra likelihood-ratio helpers in R/model-comparison.R.

test_that("drm_lrtest_vc_labels() flattens sdpars and corpars", {
  fit <- list(
    sdpars = list(mu = c(`sd(g)` = 0.1)),
    corpars = list(mu = c(rho = 0.2))
  )
  labs <- drmTMB:::drm_lrtest_vc_labels(fit)
  expect_true(all(c("mu:sd(g)", "mu:rho") %in% labs))
  expect_length(labs, 2L)
})

test_that("drm_lrtest_map_guard() refuses MAP estimator fits", {
  map <- list(estimator = "MAP")
  ml <- list(estimator = "ML")
  expect_error(drmTMB:::drm_lrtest_map_guard(map, ml), class = "drmTMB_lrtest_map_error")
  expect_invisible(drmTMB:::drm_lrtest_map_guard(ml, ml))
})

test_that("drm_lrtest_boundary_warn() is silent when vc labels match", {
  reduced <- list(sdpars = list(mu = c(`sd(g)` = 0.1)), corpars = list())
  full <- reduced
  expect_invisible(drmTMB:::drm_lrtest_boundary_warn(reduced, full, df = 1L))
})

test_that("drm_lrtest_mean_structure() lists mean coefficients", {
  fit <- list(coefficients = list(mu = c("(Intercept)" = 1, x = 2), mu2 = c(y = 3)))
  ms <- drmTMB:::drm_lrtest_mean_structure(fit)
  expect_length(ms, 3L)
  expect_true("mu (Intercept)" %in% ms)
  expect_true("mu2 y" %in% ms)
  expect_false("sigma (Intercept)" %in% ms)
})