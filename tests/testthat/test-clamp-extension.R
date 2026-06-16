# Wave 2 (ML robustness): the log(sigma) soft-clamp, previously applied only to
# the Gaussian and bivariate-Gaussian likelihoods, now guards every scale-bearing
# family against a runaway log(sigma). Two contracts per family:
#   (1) in-band identity: the default band [-12, 12] leaves a normal fit
#       bit-identical to the unclamped fit (no distortion of ordinary fits);
#   (2) applied: a band that excludes the fitted log(sigma) changes the fit,
#       which can only happen if the clamp is actually wired into that branch.
# A lower-biting band (above the natural log(sigma)) is used so the clamp binds
# without tripping the upper-only clamp-active warning.

expect_clamp_in_band_identity <- function(formula, family, data) {
  unclamped <- drmTMB(
    formula,
    family = family,
    data = data,
    control = drm_control(logsigma_clamp = NULL)
  )
  default <- drmTMB(formula, family = family, data = data)
  expect_equal(
    as.numeric(logLik(default)),
    as.numeric(logLik(unclamped)),
    tolerance = 1e-8
  )
}

expect_clamp_applied <- function(formula, family, data) {
  unclamped <- drmTMB(
    formula,
    family = family,
    data = data,
    control = drm_control(logsigma_clamp = NULL)
  )
  tight <- allow_nonconvergence(drmTMB(
    formula,
    family = family,
    data = data,
    # band sits well above the natural log(sigma), forcing the lower clamp to bind
    control = drm_control(logsigma_clamp = c(2, 3))
  ))
  expect_false(isTRUE(all.equal(
    as.numeric(logLik(tight)),
    as.numeric(logLik(unclamped))
  )))
}

test_that("gamma scale is clamp-guarded", {
  set.seed(1)
  n <- 200
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  mu <- exp(0.5 + 0.3 * x)
  shape <- 1 / exp(-0.6 + 0.2 * z)^2
  dat <- data.frame(
    y = stats::rgamma(n, shape = shape, rate = shape / mu),
    x = x,
    z = z
  )
  form <- bf(y ~ x, sigma ~ z)
  expect_clamp_in_band_identity(form, stats::Gamma(link = "log"), dat)
  expect_clamp_applied(form, stats::Gamma(link = "log"), dat)
})

test_that("lognormal scale is clamp-guarded", {
  set.seed(2)
  n <- 200
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  dat <- data.frame(
    y = exp(0.4 + 0.3 * x + stats::rnorm(n, 0, exp(-0.5 + 0.2 * z))),
    x = x,
    z = z
  )
  form <- bf(y ~ x, sigma ~ z)
  expect_clamp_in_band_identity(form, lognormal(), dat)
  expect_clamp_applied(form, lognormal(), dat)
})

test_that("Student scale is clamp-guarded", {
  set.seed(3)
  n <- 250
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  dat <- data.frame(
    y = 0.4 + 0.5 * x + exp(-0.5 + 0.2 * z) * stats::rt(n, df = 8),
    x = x,
    z = z
  )
  form <- bf(y ~ x, sigma ~ z, nu ~ 1)
  expect_clamp_in_band_identity(form, student(), dat)
  expect_clamp_applied(form, student(), dat)
})

test_that("beta scale is clamp-guarded", {
  set.seed(4)
  n <- 250
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  mu <- stats::plogis(0.2 + 0.5 * x)
  phi <- exp(1.0 + 0.2 * z)
  dat <- data.frame(
    y = stats::rbeta(n, mu * phi, (1 - mu) * phi),
    x = x,
    z = z
  )
  form <- bf(y ~ x, sigma ~ z)
  expect_clamp_in_band_identity(form, beta(), dat)
  expect_clamp_applied(form, beta(), dat)
})

test_that("NB2 dispersion is clamp-guarded", {
  set.seed(5)
  n <- 300
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  mu <- exp(0.35 - 0.4 * x)
  sigma <- exp(-0.65 + 0.3 * z)
  dat <- data.frame(
    count = stats::rnbinom(n, size = 1 / sigma^2, mu = mu),
    x = x,
    z = z
  )
  form <- bf(count ~ x, sigma ~ z)
  expect_clamp_in_band_identity(form, nbinom2(), dat)
  expect_clamp_applied(form, nbinom2(), dat)
})
