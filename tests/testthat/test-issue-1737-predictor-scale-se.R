# refs #1737 — slope SEs invariant to affine predictor reparameterisation.

test_that("binomial slope SE scales with predictor affine transforms", {
  n <- 150L
  i <- seq_len(n)
  u <- (i * 0.6180339887) %% 1
  x <- 2 * sin(1.7 * i) + cos(0.37 * i)
  yb <- stats::qbinom(u, 8, stats::plogis(0.4 + 0.4 * x))
  d <- data.frame(
    x = x,
    s = yb,
    fl = 8 - yb,
    x1e4 = x * 1e4,
    xshift = x + 1000
  )
  fit_x <- suppressWarnings(
    drmTMB(bf(cbind(s, fl) ~ x), family = binomial(), data = d)
  )
  fit_1e4 <- suppressWarnings(
    drmTMB(bf(cbind(s, fl) ~ x1e4), family = binomial(), data = d)
  )
  fit_shift <- suppressWarnings(
    drmTMB(bf(cbind(s, fl) ~ xshift), family = binomial(), data = d)
  )
  se_x <- sqrt(diag(stats::vcov(fit_x)))[[2L]]
  se_1e4 <- sqrt(diag(stats::vcov(fit_1e4)))[[2L]]
  se_shift <- sqrt(diag(stats::vcov(fit_shift)))[[2L]]
  expect_true(is_converged(fit_x))
  expect_true(is_converged(fit_1e4))
  expect_true(is_converged(fit_shift))
  expect_equal(
    se_1e4,
    se_x / 1e4,
    tolerance = max(1e-3 * se_x / 1e4, 1e-9)
  )
  expect_equal(se_shift, se_x, tolerance = max(1e-3 * se_x, 1e-9))
  expect_equal(
    as.numeric(logLik(fit_x)),
    as.numeric(logLik(fit_1e4)),
    tolerance = 1e-6
  )
})