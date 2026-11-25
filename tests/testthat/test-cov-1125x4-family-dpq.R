# Small DPQ helpers in R/family-dpq.R.

test_that("drm_gamma_shape_scale() inverts mean-CV parameterization", {
  g <- drmTMB:::drm_gamma_shape_scale(mu = 2, sigma = 0.5)
  expect_equal(g$shape, 4, tolerance = 1e-12)
  expect_equal(g$scale, 0.5, tolerance = 1e-12)
})

test_that("drm_beta_shapes() returns complementary alpha and beta", {
  b <- drmTMB:::drm_beta_shapes(mu = 0.2, sigma = 0.25)
  expect_gt(b$shape1, 0)
  expect_gt(b$shape2, 0)
  expect_equal(b$shape1 / (b$shape1 + b$shape2), 0.2, tolerance = 1e-9)
})

test_that("drm_family_dpq_gamma() exposes reference closures", {
  gfd <- drmTMB:::drm_family_dpq_gamma()
  expect_identical(gfd$dpars, c("mu", "sigma"))
  d <- gfd$d(1, list(mu = 2, sigma = 0.5))
  expect_equal(d, stats::dgamma(1, shape = 4, scale = 0.5), tolerance = 1e-12)
})

test_that("drm_recycle_scalar_arg() recycles scalar y to nrow(params)", {
  params <- data.frame(mu = 1:4, sigma = rep(0.5, 4))
  out <- drmTMB:::drm_recycle_scalar_arg(2, params)
  expect_length(out, 4L)
  expect_true(all(out == 2))
  long <- drmTMB:::drm_recycle_scalar_arg(1:4, params)
  expect_identical(long, 1:4)
})

test_that("drm_nbinom2_size() maps sigma to size", {
  expect_equal(drmTMB:::drm_nbinom2_size(2), 0.25, tolerance = 1e-12)
})