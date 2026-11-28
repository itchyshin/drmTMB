# Invalid `predict.drmTMB(..., type = )` must not leak raw `match.arg()` errors (#1864).

test_that("predict() aborts with supported type choices for an invalid type", {
  dat <- data.frame(y = rnorm(40), x = rnorm(40))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  expect_error(predict(fit, type = "terms"), "type")
  expect_error(
    predict(fit, type = "terms"),
    "response.*link.*quantile.*mean"
  )
  expect_length(predict(fit, type = "link"), nrow(dat))
})