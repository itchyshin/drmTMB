test_that("glm-style positional (formula, data, family) names the argument order", {
  set.seed(1126)
  dat <- data.frame(
    y = stats::rnorm(12),
    x = stats::rnorm(12)
  )
  f <- bf(y ~ x)
  gauss <- stats::gaussian()
  msg <- "formula, family, data"
  expect_error(drmTMB(f, dat, gauss), msg)
  expect_error(drmTMB(f, dat, gauss), "family")
  expect_error(drmTMB(f, dat, gauss), "data frame")
})