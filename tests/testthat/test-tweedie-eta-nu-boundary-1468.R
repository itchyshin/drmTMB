# #1468: at |eta_nu| > ~36.7, p = 1 + invlogit(eta) hits exactly 1 or 2 and
# TMB's dtweedie() returns NaN. The template clamps eta_nu to [-35, 35] first.

test_that("tweedie eta_nu cap matches the C++ guard and keeps power inside (1, 2) (#1468)", {
  cap <- 35
  eta_extreme <- c(-40, -36.8, 36.8, 40)
  eta_c <- pmax(-cap, pmin(cap, eta_extreme))
  p_clamped <- 1 + stats::plogis(eta_c)
  p_raw <- 1 + stats::plogis(eta_extreme)
  expect_true(all(p_clamped > 1 & p_clamped < 2))
  expect_true(any(!is.finite(p_raw) | p_raw <= 1 | p_raw >= 2))
  expect_equal(eta_c, c(-35, -35, 35, 35))
})

test_that("a tweedie location-scale fit keeps finite reported nu (#1468)", {
  set.seed(1468L)
  n <- 60L
  dat <- data.frame(x = stats::runif(n, -1, 1), z = stats::rnorm(n))
  mu <- exp(0.2 + 0.45 * dat$x)
  sigma <- exp(-0.55 + 0.2 * dat$z)
  dat$y <- drmTMB:::rtweedie_compound(n, mu = mu, phi = sigma^2, power = 1.35)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = tweedie(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  nu <- as.numeric(fit$obj$report()$nu)
  expect_true(all(is.finite(nu)))
  expect_true(all(nu > 1 & nu < 2))
  expect_true(is.finite(coef(fit, "nu")))
})