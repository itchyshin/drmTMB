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

test_that("drm_clamped_scale_families() names the bivariate lognormal and Student families (Dinnage audit Md-A)", {
  # src/drmTMB.cpp clamps log_sigma1/log_sigma2 identically for model types
  # 2 (biv_gaussian), 19 (biv_lognormal) and 20 (biv_student) -- one shared
  # branch -- but the R-side family list previously named only biv_gaussian,
  # so check_drm() printed the false sentence "The log(sigma) clamp does not
  # apply to this family" for the other two.
  families <- drm_clamped_scale_families()
  expect_true("biv_lognormal" %in% families)
  expect_true("biv_student" %in% families)
})

test_that("check_drm() reports the clamp as applying to biv_lognormal and biv_student (Dinnage audit Md-A)", {
  set.seed(6301)
  n <- 60
  x <- stats::rnorm(n)
  z1 <- stats::rnorm(n)
  z2 <- 0.3 * z1 + sqrt(1 - 0.3^2) * stats::rnorm(n)
  dat <- data.frame(
    x = x,
    y1 = exp(0.2 + 0.3 * x + 0.4 * z1),
    y2 = exp(-0.1 - 0.2 * x + 0.5 * z2)
  )
  form <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)

  fit_lognormal <- drmTMB(form, family = biv_lognormal(), data = dat)
  chk_lognormal <- check_drm(fit_lognormal)
  row_lognormal <- chk_lognormal[
    chk_lognormal$check == "logsigma_clamp_active",
  ]
  expect_equal(nrow(row_lognormal), 1L)
  expect_false(grepl("does not apply", row_lognormal$message, fixed = TRUE))

  dat_t <- data.frame(
    x = x,
    y1 = 0.2 + 0.3 * x + 0.4 * stats::rt(n, df = 8),
    y2 = -0.1 - 0.2 * x + 0.5 * stats::rt(n, df = 8)
  )
  fit_student <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1, nu = ~1),
    family = biv_student(), data = dat_t
  )
  chk_student <- check_drm(fit_student)
  row_student <- chk_student[chk_student$check == "logsigma_clamp_active", ]
  expect_equal(nrow(row_student), 1L)
  expect_false(grepl("does not apply", row_student$message, fixed = TRUE))
})
