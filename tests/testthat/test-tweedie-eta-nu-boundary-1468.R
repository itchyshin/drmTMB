# #1468: at |eta_nu| > ~36.7, p = 1 + invlogit(eta) hits exactly 1 or 2 and
# TMB's dtweedie() returns NaN. The template soft-clamps eta_nu on [-35, 35]
# with the same C1 tanh tail as log(sigma).

tweedie_eta_nu_interior_reference <- function() {
  list(
    logLik = -463.22743179828,
    coef = list(
      c(`(Intercept)` = 0.17731254084666, x = 0.491866144660121),
      c(`(Intercept)` = -0.567355526363726, z = 0.182697685200557),
      c(`(Intercept)` = -1.08692863939702)
    )
  )
}

test_that("tweedie softclamp eta_nu matches R/C++ and keeps power inside (1, 2) (#1468)", {
  band <- drmTMB:::drm_tweedie_eta_nu_softclamp_bounds()
  eta_extreme <- c(-40, -36.8, -35, 0, 35, 36.8, 40)
  eta_c <- drmTMB:::drm_softclamp_tweedie_eta_nu(eta_extreme)
  p_clamped <- 1 + stats::plogis(eta_c)
  p_raw <- 1 + stats::plogis(eta_extreme)
  expect_equal(eta_c[eta_extreme == -35], -35, tolerance = 0)
  expect_equal(eta_c[eta_extreme == 35], 35, tolerance = 0)
  expect_true(all(p_clamped > 1 & p_clamped < 2))
  expect_true(any(!is.finite(p_raw) | p_raw <= 1 | p_raw >= 2))
  expect_gt(max(eta_c), band[["hi"]])
  expect_lt(max(eta_c), band[["hi"]] + band[["margin"]])
})

test_that("interior tweedie logLik and coefficients match main (#1468)", {
  set.seed(20260701)
  n <- 500L
  dat <- data.frame(
    x = stats::runif(n, -1, 1),
    z = stats::rnorm(n)
  )
  mu <- exp(0.2 + 0.45 * dat$x)
  sigma <- exp(-0.55 + 0.2 * dat$z)
  dat$y <- drmTMB:::rtweedie_compound(n, mu = mu, phi = sigma^2, power = 1.35)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = tweedie(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  ref <- tweedie_eta_nu_interior_reference()
  expect_equal(as.numeric(logLik(fit)), ref$logLik, tolerance = 1e-10)
  expect_equal(coef(fit, "mu"), ref$coef[[1L]], tolerance = 1e-10)
  expect_equal(coef(fit, "sigma"), ref$coef[[2L]], tolerance = 1e-10)
  expect_equal(coef(fit, "nu"), ref$coef[[3L]], tolerance = 1e-10)
})

test_that("tweedie eta_nu cap hit is visible in check_drm and boundary status (#1468)", {
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
    control = drm_control(se = FALSE, keep_tmb_object = TRUE)
  )
  cap_par <- fit$opt$par
  nu_pos <- which(names(cap_par) == "beta_nu")
  expect_length(nu_pos, 1L)
  cap_par[nu_pos] <- 50
  cap_full_par <- fit$tmb_state$last.par.best
  cap_full_par[fit$obj$env$lfixed()] <- cap_par
  report <- fit$obj$report(cap_full_par)
  expect_gt(report$tweedie_eta_nu_cap_hit, 0)
  expect_true(all(is.finite(report$nu)))
  expect_true(all(report$nu > 1 & report$nu < 2))

  capped_fit <- fit
  capped_fit$opt$par <- cap_par
  capped_fit$opt$convergence <- 0L
  capped_fit$tmb_state$last.par.best <- cap_full_par
  checks <- check_drm(capped_fit)
  cap_row <- checks[checks$check == "tweedie_eta_nu_cap", , drop = FALSE]
  expect_equal(nrow(cap_row), 1L)
  expect_equal(cap_row$status, "warning")
  expect_identical(convergence_status(capped_fit), "boundary")
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