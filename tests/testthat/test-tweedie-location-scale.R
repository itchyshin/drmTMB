new_tweedie_data <- function(
  n = 500,
  seed = 20260701,
  beta_mu = c("(Intercept)" = 0.2, x = 0.45),
  beta_sigma = c("(Intercept)" = -0.55, z = 0.20),
  nu = 1.35
) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::runif(n, -1, 1),
    z = stats::rnorm(n)
  )
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$y <- drmTMB:::rtweedie_compound(n, mu = mu, phi = sigma^2, power = nu)
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    nu = nu,
    eta_nu = stats::qlogis(nu - 1),
    mu = mu,
    sigma = sigma
  )
}

test_that("drmTMB fits fixed-effect Tweedie location-scale-power models", {
  sim <- new_tweedie_data()

  expect_gt(mean(sim$data$y == 0), 0.01)
  expect_gt(mean(sim$data$y > 0), 0.01)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = tweedie(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "tweedie")
  expect_equal(fit$opt$convergence, 0)
  expect_identical(fit$uncertainty$status, "ok")
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.15)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.15)
  expect_lt(abs(predict(fit, dpar = "nu")[[1L]] - sim$nu), 0.12)
  expect_true(all(predict(fit, dpar = "nu") > 1))
  expect_true(all(predict(fit, dpar = "nu") < 2))
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
  expect_equal(sigma(fit), predict(fit, dpar = "sigma"), tolerance = 1e-12)
  expect_equal(
    predict(fit, dpar = "nu"),
    1 + stats::plogis(predict(fit, dpar = "nu", type = "link")),
    tolerance = 1e-12
  )
  expect_true(all(is.finite(residuals(fit, type = "pearson"))))
})

test_that("Tweedie recovery covers high-zero and low-zero regimes", {
  high_zero <- new_tweedie_data(
    seed = 20260702,
    beta_mu = c("(Intercept)" = -0.60, x = 0.35),
    beta_sigma = c("(Intercept)" = 0.25, z = 0.15),
    nu = 1.55
  )
  low_zero <- new_tweedie_data(
    seed = 20260703,
    beta_mu = c("(Intercept)" = 0.20, x = 0.45),
    beta_sigma = c("(Intercept)" = -0.55, z = 0.20),
    nu = 1.35
  )

  expect_gt(mean(high_zero$data$y == 0), 0.20)
  expect_lt(mean(low_zero$data$y == 0), 0.10)

  high_fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = tweedie(),
    data = high_zero$data,
    control = drm_control(se = FALSE)
  )
  low_fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = tweedie(),
    data = low_zero$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(high_fit$opt$convergence, 0)
  expect_equal(low_fit$opt$convergence, 0)
  expect_lt(max(abs(coef(high_fit, "mu") - high_zero$beta_mu)), 0.18)
  expect_lt(max(abs(coef(high_fit, "sigma") - high_zero$beta_sigma)), 0.18)
  expect_lt(abs(predict(high_fit, dpar = "nu")[[1L]] - high_zero$nu), 0.10)
  expect_lt(max(abs(coef(low_fit, "mu") - low_zero$beta_mu)), 0.18)
  expect_lt(max(abs(coef(low_fit, "sigma") - low_zero$beta_sigma)), 0.18)
  expect_lt(abs(predict(low_fit, dpar = "nu")[[1L]] - low_zero$nu), 0.10)
})

test_that("Tweedie simulation preserves exact zeros and public sigma scale", {
  sim <- new_tweedie_data(n = 300, seed = 20260704)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = tweedie(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )

  draws <- simulate(fit, nsim = 2, seed = 20260705)
  expect_s3_class(draws, "data.frame")
  expect_named(draws, c("sim_1", "sim_2"))
  expect_true(all(vapply(draws, function(x) all(is.finite(x) & x >= 0), TRUE)))
  expect_true(any(vapply(draws, function(x) any(x == 0), TRUE)))

  phi <- sigma(fit)^2
  expect_true(all(phi > 0))
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - fitted(fit)) /
      sqrt(phi * fitted(fit)^predict(fit, dpar = "nu")),
    tolerance = 1e-12
  )
})

test_that("Tweedie supports missing filtering before response validation", {
  dat <- data.frame(
    y = c(0, 1.2, 0.4, -1),
    x = c(0, 1, -1, NA),
    z = c(0, 0.5, -0.5, 1)
  )
  expect_no_error(
    drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ 1),
      family = tweedie(),
      data = dat,
      control = drm_control(se = FALSE)
    )
  )
  dat_bad <- dat
  dat_bad$x[[4L]] <- 1
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ 1),
      family = tweedie(),
      data = dat_bad,
      control = drm_control(se = FALSE)
    ),
    "non-negative finite"
  )
})

test_that("Tweedie rejects unsupported first-slice neighbours", {
  dat <- new_tweedie_data(n = 40, seed = 20260706)$data
  dat$id <- rep(seq_len(10), each = 4)
  dat$V <- 0.1

  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1),
      family = tweedie(),
      data = dat
    ),
    "random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z + (1 | id), nu ~ 1),
      family = tweedie(),
      data = dat
    ),
    "random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ 1 + (1 | id)),
      family = tweedie(),
      data = dat
    ),
    "random effects"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z, nu ~ x), family = tweedie(), data = dat),
    "intercept-only"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ 1, zi ~ 1),
      family = tweedie(),
      data = dat
    ),
    "Unsupported parameter"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ 1, hu ~ 1),
      family = tweedie(),
      data = dat
    ),
    "Unsupported parameter"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_V(V = V), sigma ~ z, nu ~ 1),
      family = tweedie(),
      data = dat
    ),
    "meta_V"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, y) ~ x, sigma ~ z, nu ~ 1),
      family = tweedie(),
      data = dat
    ),
    "mvbind"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ 1, sd(id) ~ 1),
      family = tweedie(),
      data = dat
    ),
    "Random-effect scale"
  )
})
