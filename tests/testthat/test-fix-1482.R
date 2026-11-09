# Issue #1482: gaussian(link != "identity") must not silently fit identity-scale mu.

test_that("drm_family_type accepts gaussian() with the default identity link", {
  expect_identical(drmTMB:::drm_family_type(stats::gaussian()), "gaussian")
  expect_identical(
    drmTMB:::drm_family_type(stats::gaussian(link = "identity")),
    "gaussian"
  )
})

test_that("drm_family_type rejects unsupported gaussian links", {
  expect_error(
    drmTMB:::drm_family_type(stats::gaussian(link = "log")),
    "Gaussian models currently require"
  )
  expect_error(
    drmTMB:::drm_family_type(stats::gaussian(link = "inverse")),
    "Gaussian models currently require"
  )
})

test_that("drmTMB rejects unsupported gaussian links before fitting", {
  set.seed(1)
  d <- data.frame(y = stats::rnorm(30, 10), x = stats::rnorm(30))

  expect_error(
    drmTMB(bf(mu = y ~ x, sigma ~ 1), data = d, family = stats::gaussian(link = "log")),
    "Gaussian models currently require"
  )
  expect_error(
    drmTMB(
      bf(mu = y ~ x, sigma ~ 1),
      data = d,
      family = stats::gaussian(link = "inverse")
    ),
    "Gaussian models currently require"
  )

  expect_silent(
    drmTMB(bf(mu = y ~ x, sigma ~ 1), data = d, family = stats::gaussian())
  )
})
