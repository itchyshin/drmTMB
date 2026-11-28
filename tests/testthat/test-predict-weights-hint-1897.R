test_that("predict() names weights instead of the generic reserved dots error (#1897)", {
  skip_on_cran()
  set.seed(1)
  d <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  fit <- drmTMB(
    bf(y ~ x),
    family = gaussian(),
    data = d,
    weights = rep(2, 20),
    control = drm_control(parallel = "none", se = FALSE)
  )
  expect_error(
    predict(fit, newdata = data.frame(x = 0), weights = 2),
    "does not accept",
    fixed = TRUE
  )
  expect_error(
    predict(fit, newdata = data.frame(x = 0), weights = 2),
    "weights",
    fixed = TRUE
  )
  expect_no_error(predict(fit, newdata = data.frame(x = 0), weights = 1))
})