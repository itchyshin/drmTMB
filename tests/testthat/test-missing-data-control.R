test_that("miss_control() records MD1 defaults", {
  ctrl <- miss_control()

  expect_s3_class(ctrl, "drm_missing_control")
  expect_equal(ctrl$response, "drop")
  expect_equal(ctrl$predictor, "fail")
  expect_equal(ctrl$engine, "laplace")
})

test_that("miss_control() validates implemented and reserved options", {
  expect_equal(miss_control(response = "include")$response, "include")
  expect_equal(miss_control(predictor = "model")$predictor, "model")

  expect_error(miss_control(response = "omit"), "should be one of")
  expect_error(miss_control(engine = "em"), "reserved")
  expect_error(miss_control(engine = "profile"), "reserved")
})

test_that("drmTMB() parses missing-control lists and gates unsupported response masks", {
  x <- seq(-1.2, 1.4, length.out = 12)
  dat <- data.frame(
    y = 0.4 + 0.7 * x + 0.1 * sin(seq_along(x)),
    x = x
  )
  dat$y[5] <- NA_real_

  expect_s3_class(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      missing = list(response = "include"),
      control = drm_control(se = FALSE)
    )$missing_data,
    "drm_missing_data"
  )

  # MR-T1 and MR-T2 response masks are implemented; a still-unsupported family
  # must reject via the capability gate.
  expect_error(
    drmTMB(
      bf(y ~ x),
      data = dat,
      family = beta_binomial(),
      missing = miss_control(response = "include"),
      control = drm_control(se = FALSE)
    ),
    "not implemented for the"
  )

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      impute = list(x = x ~ 1),
      control = drm_control(se = FALSE)
    ),
    "predictor = \"model\""
  )

  expect_error(
    drmTMB(
      bf(y ~ mi(x)),
      data = dat,
      family = poisson(),
      impute = list(x = x ~ 1),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "binary missing predictor"
  )
})
