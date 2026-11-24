# Issue #1336 (Dinnage audit A-6): Wald SEs on nu ~ x near the Gaussian null.

test_that("check_drm notes when the skew-normal nu submodel has covariates (#1336)", {
  set.seed(133601L)
  n <- 160L
  dat <- data.frame(
    x = stats::rnorm(n),
    y = stats::rnorm(n)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ x),
    family = skew_normal(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_gt(ncol(fit$model$X$nu), 1L)

  chk <- check_drm(fit)
  shape <- chk[chk$check == "skew_normal_nu", ]
  expect_equal(shape$status, "note")
  expect_match(shape$message, "Wald standard errors on nu slopes", fixed = TRUE)
  expect_match(shape$message, "Gaussian null", fixed = TRUE)
  expect_match(shape$value, "nu_regression=TRUE", fixed = TRUE)
})

test_that("intercept-only nu still passes the skew_normal_nu check", {
  set.seed(20260608L)
  n <- 200L
  dat <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  mu <- 0.2 + 0.45 * dat$x
  sigma <- exp(-0.35 + 0.18 * dat$z)
  native <- skew_normal_public_to_native(mu = mu, sigma = sigma, nu = 1.6)
  dat$y <- native$xi +
    native$omega *
      (native$delta * abs(stats::rnorm(n)) +
        sqrt(1 - native$delta^2) * stats::rnorm(n))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = skew_normal(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  chk <- check_drm(fit)
  shape <- chk[chk$check == "skew_normal_nu", ]
  expect_equal(shape$status, "ok")
  expect_false(grepl("nu_regression=TRUE", shape$value, fixed = TRUE))
})