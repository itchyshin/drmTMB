test_that("terms() returns the primary location terms object", {
  set.seed(20261127)
  dat <- data.frame(
    y = 0.3 + 0.5 * stats::rnorm(60) + stats::rnorm(60, sd = 0.5),
    x = stats::rnorm(60),
    z = stats::rnorm(60)
  )
  fit <- suppressWarnings(
    drmTMB(bf(y ~ x, sigma ~ z), family = gaussian(), data = dat)
  )
  expect_s3_class(terms(fit), "terms")
  expect_identical(terms(fit), fit$model$terms$mu)
  expect_equal(nrow(stats::model.frame(terms(fit), data = dat)), nrow(dat))
})