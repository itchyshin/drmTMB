test_that("gaussian #1697: Inf in y aborts with drmTMB finite-response error", {
  set.seed(1)
  d <- data.frame(y = rnorm(20), x = rnorm(20))
  d$y[1] <- Inf
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d),
    regexp = "finite observed response",
    class = "rlang_error"
  )
})

test_that("gaussian #1697: Inf in predictor aborts and names the design column", {
  set.seed(1)
  d <- data.frame(y = rnorm(20), x = rnorm(20))
  d$x[1] <- Inf
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d),
    regexp = "\\bx\\b",
    class = "rlang_error"
  )
})

test_that("gaussian #1697: NaN and NA responses stay dropped, not aborted", {
  set.seed(1)
  d <- data.frame(y = rnorm(20), x = rnorm(20))
  fit_ok <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d)
  expect_equal(nobs(fit_ok), 20L)

  d_nan <- d
  d_nan$y[1] <- NaN
  fit_nan <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d_nan)
  expect_equal(nobs(fit_nan), 19L)

  d_na <- d
  d_na$y[1] <- NA_real_
  fit_na <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d_na)
  expect_equal(nobs(fit_na), 19L)
})
