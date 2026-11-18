test_that("drm_lrtest() rejects equal nobs on different contributing rows (#1661)", {
  set.seed(20260814)
  n <- 120L
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  dat <- data.frame(
    y = 0.4 + 0.9 * x + exp(-0.3 + 0.25 * z) * stats::rnorm(n),
    x = x,
    z = z
  )
  dat_a <- dat
  dat_b <- dat
  dat_a$y[5L] <- NA_real_
  dat_b$y[6L] <- NA_real_
  reduced <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat_a)
  full_b <- drmTMB(bf(y ~ x, sigma ~ z), family = gaussian(), data = dat_b)
  expect_identical(stats::nobs(reduced), stats::nobs(full_b))
  expect_error(drmTMB:::drm_lrtest(reduced, full_b), "same contributing")
})

test_that("lrt_boundary() rejects equal nobs on different contributing rows (#1661)", {
  set.seed(20261118L)
  m <- 8L
  G <- 12L
  g <- factor(rep(seq_len(G), each = m))
  x <- stats::rnorm(length(g))
  dat <- data.frame(
    y = 0.5 - 0.4 * x + stats::rnorm(length(g), sd = 0.7),
    x = x,
    g = g
  )
  dat_a <- dat
  dat_b <- dat
  dat_a$y[3L] <- NA_real_
  dat_b$y[7L] <- NA_real_
  full_a <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat_a)
  reduced_b <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat_b)
  expect_identical(stats::nobs(full_a), stats::nobs(reduced_b))
  expect_error(lrt_boundary(full_a, reduced_b, q = 1L), "same contributing")
})
