# Coverage for R/associate-pairs.R small internal helpers.

test_that("drm_pair_validate_kernel() requires latent_normal()", {
  expect_error(drmTMB:::drm_pair_validate_kernel(list()), "latent_normal")
  expect_error(
    drmTMB:::drm_pair_validate_kernel(structure(list(name = "other"), class = "drm_pair_kernel")),
    "latent_normal"
  )
  expect_invisible(drmTMB:::drm_pair_validate_kernel(latent_normal()))
})

test_that("drm_pair_descriptor() refuses unknown pair classes", {
  expect_error(
    drmTMB:::drm_pair_descriptor("gaussian_gaussian"),
    "Unsupported"
  )
})

test_that("drm_pair_logdiffexp() implements stable log-difference", {
  f <- drmTMB:::drm_pair_logdiffexp
  expect_equal(f(0, log(0.5)), log(0.5))
  expect_equal(f(log(0.2), 0), -Inf)
  expect_equal(f(-2, -1), -Inf)
  expect_equal(f(0, -30), 0, tolerance = 1e-12)
})

test_that("latent_normal() constructs the Arc 6 kernel marker", {
  k <- latent_normal()
  expect_s3_class(k, "drm_pair_kernel")
  expect_identical(k$name, "latent_normal")
})