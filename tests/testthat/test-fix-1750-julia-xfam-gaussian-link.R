test_that("xfam tag #1750: non-identity Gaussian link returns NULL like Poisson", {
  expect_null(drmTMB:::drm_julia_xfam_family_tag(stats::gaussian(link = "log")))
  expect_equal(
    drmTMB:::drm_julia_xfam_family_tag(stats::gaussian()),
    "gaussian"
  )
  expect_null(drmTMB:::drm_julia_xfam_family_tag(stats::poisson(link = "identity")))
  expect_equal(drmTMB:::drm_julia_xfam_family_tag(stats::poisson()), "poisson")
})

test_that("xfam tag #1750: mixed pair with log-link Gaussian is not cross-family", {
  skip_if_not_installed("JuliaCall")
  expect_false(drmTMB:::drm_julia_is_cross_family(c(
    stats::gaussian(link = "log"),
    stats::poisson()
  )))
})