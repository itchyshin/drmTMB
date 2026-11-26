# Invalid `nsim` must not leak base-R `replicate()` / `names<-` errors (#1696).

test_that("simulate() aborts when nsim is not a positive whole number", {
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  expect_error(simulate(fit, nsim = 0), "nsim")
  expect_error(simulate(fit, nsim = 0), "positive whole number")
  expect_error(simulate(fit, nsim = -1), "positive whole number")
  expect_error(simulate(fit, nsim = NA), "positive whole number")
})

test_that("simulate() still accepts fractional nsim without changing behaviour (rec)", {
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  expect_equal(ncol(simulate(fit, nsim = 1.5, seed = 1)), 1L)
})