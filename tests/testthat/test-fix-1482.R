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

biv_gaussian_link_test_data <- function() {
  set.seed(1482)
  x <- stats::rnorm(40)
  data.frame(
    y1 = 0.5 + 0.7 * x + stats::rnorm(40, sd = 0.3),
    y2 = -0.2 - 0.4 * x + stats::rnorm(40, sd = 0.35),
    x = x
  )
}

biv_gaussian_identity_formula <- function() {
  bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ x,
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
}

gaussian_identity_msg <- "Gaussian models currently require"

test_that("drm_family_type rejects composed gaussian() with non-identity links", {
  expect_error(
    drmTMB:::drm_family_type(c(stats::gaussian(link = "log"), stats::gaussian())),
    gaussian_identity_msg
  )
  expect_error(
    drmTMB:::drm_family_type(c(stats::gaussian(), stats::gaussian(link = "log"))),
    gaussian_identity_msg
  )
  expect_error(
    drmTMB:::drm_family_type(
      list(stats::gaussian(link = "log"), stats::gaussian())
    ),
    gaussian_identity_msg
  )
  expect_error(
    drmTMB:::drm_family_type(
      list(stats::gaussian(), stats::gaussian(link = "log"))
    ),
    gaussian_identity_msg
  )
})

test_that("drm_family_type accepts composed identity-link bivariate Gaussian", {
  expect_identical(
    drmTMB:::drm_family_type(c(stats::gaussian(), stats::gaussian())),
    "biv_gaussian"
  )
  expect_identical(
    drmTMB:::drm_family_type(
      list(stats::gaussian(), stats::gaussian(link = "identity"))
    ),
    "biv_gaussian"
  )
})

test_that("drmTMB rejects composed gaussian() with non-identity links before fitting", {
  dat <- biv_gaussian_link_test_data()
  form <- biv_gaussian_identity_formula()

  expect_error(
    drmTMB(form, data = dat, family = c(stats::gaussian(link = "log"), stats::gaussian())),
    gaussian_identity_msg
  )
  expect_error(
    drmTMB(form, data = dat, family = c(stats::gaussian(), stats::gaussian(link = "log"))),
    gaussian_identity_msg
  )
  expect_error(
    drmTMB(
      form,
      data = dat,
      family = list(stats::gaussian(link = "log"), stats::gaussian())
    ),
    gaussian_identity_msg
  )
  expect_error(
    drmTMB(
      form,
      data = dat,
      family = list(stats::gaussian(), stats::gaussian(link = "log"))
    ),
    gaussian_identity_msg
  )
})

test_that("composed identity-link bivariate Gaussian fits match c(gaussian(), gaussian())", {
  dat <- biv_gaussian_link_test_data()
  form <- biv_gaussian_identity_formula()
  ctrl <- drm_control(se = FALSE)

  fit_c <- drmTMB(
    form,
    data = dat,
    family = c(stats::gaussian(), stats::gaussian()),
    control = ctrl
  )
  fit_list <- drmTMB(
    form,
    data = dat,
    family = list(stats::gaussian(), stats::gaussian(link = "identity")),
    control = ctrl
  )

  expect_identical(coef(fit_c), coef(fit_list))
  expect_identical(fit_c$model$model_type, "biv_gaussian")
  expect_identical(fit_list$model$model_type, "biv_gaussian")
})
