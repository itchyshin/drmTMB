test_that("predict() errors when newdata omits an ordinary random-effect grouping column (#1916)", {
  set.seed(331127)
  n <- 80L
  dat <- data.frame(
    x = rnorm(n),
    g = factor(sample(1:4, n, TRUE)),
    y = rnorm(n)
  )
  fit <- drmTMB(
    drm_formula(y ~ x + (1 | g), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  expect_error(
    predict(fit, newdata = data.frame(x = 0)),
    "missing random-effect grouping column"
  )
})