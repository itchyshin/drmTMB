test_that("binomial zero-weight rows match glm() and contribute no likelihood (#1904)", {
  dat <- data.frame(
    y = c(0L, 1L, 1L),
    x = c(0, 0, 1),
    w = c(1, 0, 1)
  )
  fit <- drmTMB(
    bf(y ~ x),
    family = stats::binomial(),
    data = dat,
    weights = dat$w,
    control = drm_control(se = FALSE)
  )
  ref <- stats::glm(y ~ x, family = stats::binomial(), data = dat, weights = dat$w)

  expect_equal(coef(fit, "mu"), stats::coef(ref), tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(ref)), tolerance = 1e-6)
})