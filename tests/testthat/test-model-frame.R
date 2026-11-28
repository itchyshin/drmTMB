test_that("model.frame, terms, and model.matrix use the location formula frame", {
  set.seed(1)
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  mf <- stats::model.frame(fit)
  expect_s3_class(mf, "data.frame")
  expect_false(identical(mf, fit$model))
  expect_equal(nrow(mf), 20L)
  expect_named(mf, c("y", "x"))

  trm <- stats::terms(fit)
  expect_s3_class(trm, "terms")
  expect_equal(attr(trm, "response"), 1L)

  X <- stats::model.matrix(fit)
  expect_equal(nrow(X), 20L)
  expect_equal(colnames(X), c("(Intercept)", "x"))
})