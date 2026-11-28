test_that("lognormal #1729: Inf in mu predictor aborts and names the design column", {
  set.seed(1)
  d <- data.frame(y = stats::rlnorm(20, log(2), 0.3), x = rnorm(20))
  d$x[1] <- Inf
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = d),
    regexp = "\\bx\\b",
    class = "rlang_error"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = d),
    regexp = "finite fixed-effect design",
    class = "rlang_error"
  )
})

test_that("lognormal #1729: Inf in sigma predictor aborts and names the design column", {
  set.seed(1)
  d <- data.frame(y = stats::rlnorm(20, log(2), 0.3), x = rnorm(20))
  d$x[1] <- Inf
  expect_error(
    drmTMB(bf(y ~ 1, sigma ~ x), family = lognormal(), data = d),
    regexp = "\\bx\\b",
    class = "rlang_error"
  )
  expect_error(
    drmTMB(bf(y ~ 1, sigma ~ x), family = lognormal(), data = d),
    regexp = "finite fixed-effect design",
    class = "rlang_error"
  )
})

test_that("lognormal #1729: NA predictors stay on the complete-case path", {
  set.seed(1)
  d <- data.frame(y = stats::rlnorm(20, log(2), 0.3), x = rnorm(20))
  fit_ok <- drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = d)
  expect_equal(nobs(fit_ok), 20L)

  d_na <- d
  d_na$x[1] <- NA_real_
  fit_na <- drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = d_na)
  expect_equal(nobs(fit_na), 19L)
})