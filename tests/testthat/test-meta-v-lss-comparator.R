test_that("diagonal known-V location-scale fit matches metafor on its variance scale", {
  skip_if_not_installed("metafor")
  set.seed(2026072411)
  n <- 120L
  dat <- data.frame(
    x = stats::rnorm(n),
    z = seq(-1, 1, length.out = n),
    vi = seq(0.010, 0.030, length.out = n)
  )
  dat$yi <- stats::rnorm(
    n,
    mean = 0.20 + 0.40 * dat$x,
    sd = sqrt(dat$vi + exp(-1.00 + 0.30 * dat$z)^2)
  )

  drm <- drmTMB(
    bf(yi ~ x + meta_V(V = vi), sigma ~ z),
    family = gaussian(), data = dat
  )
  mf <- metafor::rma(
    yi = yi, vi = vi, mods = ~ x, scale = ~ z,
    method = "ML", data = dat
  )

  # metafor reports log variance: alpha = 2 * gamma, never gamma^2.
  expect_equal(
    unname(stats::coef(drm, dpar = "mu")),
    unname(mf$beta[, 1L]), tolerance = 1e-5
  )
  expect_equal(
    unname(stats::coef(drm, dpar = "sigma")),
    unname(mf$alpha[, 1L] / 2), tolerance = 1e-5
  )
  expect_equal(as.numeric(stats::logLik(drm)), as.numeric(stats::logLik(mf)), tolerance = 1e-5)
})
