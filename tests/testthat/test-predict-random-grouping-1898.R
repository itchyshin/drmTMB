test_that("predict(newdata) rejects missing random-effect grouping levels", {
  set.seed(11261126)
  x1 <- stats::rnorm(50)
  d1 <- data.frame(
    y = stats::rpois(50, exp(0.5 + 0.3 * x1)),
    x = x1,
    g = factor(sample(1:5, 50, TRUE))
  )
  fit_re <- drmTMB(bf(y ~ x + (1 | g)), data = d1, family = poisson())
  nd_bad <- data.frame(x = 0, g = factor("NEW", levels = levels(d1$g)))
  expect_true(is.na(nd_bad$g))
  expect_error(
    predict(fit_re, newdata = nd_bad, type = "response"),
    "random-effect grouping column"
  )

  fit_fe <- drmTMB(bf(y ~ x + g), data = d1, family = poisson())
  expect_error(
    predict(fit_fe, newdata = nd_bad, type = "response"),
    "required predictor"
  )
})