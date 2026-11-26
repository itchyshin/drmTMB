test_that("predict_parameters() returns a zero-row table for zero-row newdata", {
  set.seed(20261126)
  dat <- data.frame(y = stats::rnorm(10), x = stats::rnorm(10))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    family = gaussian(),
    control = drm_control(parallel = "none")
  )
  nd0 <- dat[0L, , drop = FALSE]
  expect_identical(nrow(nd0), 0L)
  expect_equal(predict(fit, newdata = nd0, dpar = "mu"), numeric(0))

  out <- predict_parameters(fit, newdata = nd0)
  expect_s3_class(out, "data.frame")
  expect_identical(nrow(out), 0L)
  expect_named(
    out,
    c(
      "row",
      "row_label",
      "dpar",
      "component",
      "type",
      "estimate",
      "conf.status",
      "interval_source",
      "x"
    )
  )
})