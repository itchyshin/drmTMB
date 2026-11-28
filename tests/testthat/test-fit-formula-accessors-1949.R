test_that("formula() returns a standard formula and supports model.frame()", {
  set.seed(20261127)
  dat <- data.frame(
    y = stats::rnorm(60),
    x = stats::rnorm(60),
    z = stats::rnorm(60)
  )
  fit <- suppressWarnings(
    drmTMB(bf(y ~ x, sigma ~ z), family = gaussian(), data = dat)
  )
  fml <- formula(fit)
  expect_s3_class(fml, "formula")
  expect_false(inherits(fml, "drm_formula"))
  mf <- stats::model.frame(fml, data = fit$data)
  expect_equal(nrow(mf), nobs(fit))
  expect_equal(rownames(mf), rownames(fit$model$model_frame$mu))
  mf_dat <- stats::model.frame(fml, data = dat)
  expect_equal(nrow(mf_dat), nrow(dat))
  expect_s3_class(stats::as.formula(fit$formula), "formula")
  expect_equal(
    nrow(stats::model.frame(stats::as.formula(fit$formula), data = dat)),
    nrow(dat)
  )
})