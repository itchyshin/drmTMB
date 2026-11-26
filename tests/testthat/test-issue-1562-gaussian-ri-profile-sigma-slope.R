# refs #1562 — sweep-oct16 t9 cell: profile sigma slope at G = 30, sd_g = 0.5.

test_that("gaussian RI profile for sigma slope returns finite bounds (refs #1562 reproducer)", {
  spec_seed <- 20261017814
  set.seed(as.integer(spec_seed %% 2147483647))
  G <- 30L
  n_g <- 10L
  sd_g <- 0.5
  g <- factor(rep(seq_len(G), each = n_g))
  x <- rep(seq(-1, 1, length.out = n_g), times = G)
  u <- stats::rnorm(G, 0, sd_g)
  sigma <- exp(0 + 0.3 * x)
  y <- 0 + 0.5 * x + u[as.integer(g)] + stats::rnorm(length(x), 0, sigma)
  dat <- data.frame(y = y, x = x, g = g)
  fit <- suppressWarnings(
    drmTMB(bf(y ~ x + (1 | g), sigma ~ x), family = gaussian(), data = dat)
  )
  expect_true(is_converged(fit))
  ci <- confint(fit, parm = "fixef:sigma:x", method = "profile")
  expect_true(all(is.finite(ci$lower)))
  expect_true(all(is.finite(ci$upper)))
  expect_false(any(is.nan(ci$lower) | is.nan(ci$upper)))
  expect_gt(ci$upper, ci$lower)
})