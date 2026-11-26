test_that("simulate() aborts on non-integer nsim", {
  set.seed(1)
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(simulate(fit, nsim = 1.5), "whole number")
  expect_silent(simulate(fit, nsim = 2L, seed = 1))
})
