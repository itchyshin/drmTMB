# refs #1737: Wald SEs must follow affine reparameterisation of numeric predictors.

test_that("binomial slope SE on x * 1e4 matches SE on x divided by 1e4", {
  n <- 150L
  i <- seq_len(n)
  u <- (i * 0.6180339887) %% 1
  x <- 2 * sin(1.7 * i) + cos(0.37 * i)
  yb <- stats::qbinom(u, 8, stats::plogis(0.4 + 0.4 * x))
  d <- data.frame(x = x, s = yb, fl = 8 - yb)
  d$x1e4 <- d$x * 1e4
  fit_x <- suppressWarnings(
    drmTMB(bf(cbind(s, fl) ~ x), family = binomial(), data = d)
  )
  fit_1e4 <- suppressWarnings(
    drmTMB(bf(cbind(s, fl) ~ x1e4), family = binomial(), data = d)
  )
  se_x <- unname(sqrt(diag(stats::vcov(fit_x))))[2L]
  se_1e4 <- unname(sqrt(diag(stats::vcov(fit_1e4))))[2L]
  expect_true(is_converged(fit_1e4))
  expect_equal(se_1e4, se_x / 1e4, tolerance = se_x / 1e4 * 1e-3)
  expect_equal(as.numeric(logLik(fit_x)), as.numeric(logLik(fit_1e4)),
    tolerance = 1e-6)
})

test_that("poisson slope SE is invariant to shifting a numeric predictor by 1000", {
  n <- 150L
  i <- seq_len(n)
  u <- (i * 0.6180339887) %% 1
  x <- 2 * sin(1.7 * i) + cos(0.37 * i)
  d <- data.frame(
    x = x,
    yp = stats::qpois(u, exp(0.7 + 0.24 * x))
  )
  d$xshift <- d$x + 1000
  fit_x <- suppressWarnings(drmTMB(bf(yp ~ x), family = poisson(), data = d))
  fit_shift <- suppressWarnings(
    drmTMB(bf(yp ~ xshift), family = poisson(), data = d)
  )
  se_x <- unname(sqrt(diag(stats::vcov(fit_x))))[2L]
  se_shift <- unname(sqrt(diag(stats::vcov(fit_shift))))[2L]
  expect_true(is_converged(fit_shift))
  expect_equal(se_shift, se_x, tolerance = se_x * 1e-3)
})