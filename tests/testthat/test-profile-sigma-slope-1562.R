# refs #1562: sweep-oct16 t9 reproducer; profile still misses the truth at this seed.

test_that("profile fixef:sigma:x at cell 4 rep 15 matches the sweep-oct16 t9 receipt", {
  spec_seed <- 20261017814L
  set.seed(as.integer(spec_seed %% 2147483647L))
  G <- 30L
  n_g <- 10L
  sd_g <- 0.5
  g <- factor(rep(seq_len(G), each = n_g))
  x <- rep(seq(-1, 1, length.out = n_g), times = G)
  u <- stats::rnorm(G, 0, sd_g)
  sigma <- exp(0 + 0.3 * x)
  y <- 0 + 0.5 * x + u[as.integer(g)] + stats::rnorm(length(x), 0, sigma)
  dat <- data.frame(y = y, x = x, g = g)
  fit <- drmTMB(
    bf(y ~ x + (1 | g), sigma ~ x),
    family = gaussian(),
    data = dat
  )
  ci <- confint(fit, parm = "fixef:sigma:x", method = "profile")
  expect_equal(ci$conf.status[[1L]], "profile")
  expect_true(all(is.finite(c(ci$lower, ci$upper))))
  expect_gt(ci$lower, 0.37)
  expect_lt(ci$upper, 0.67)
  expect_gt(ci$lower, 0.3)
})