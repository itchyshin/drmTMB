skew_normal_test_data <- function(n = 500, seed = 20260608, nu = 1.6) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(0.20, 0.45)
  beta_sigma <- c(-0.35, 0.18)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  native <- skew_normal_public_to_native(mu = mu, sigma = sigma, nu = nu)
  dat$y <- native$xi +
    native$omega *
      (native$delta *
        abs(stats::rnorm(n)) +
        sqrt(1 - native$delta^2) * stats::rnorm(n))
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    beta_nu = nu
  )
}

skew_normal_quasi_noise <- function(n) {
  index <- seq_len(n)
  list(
    u = stats::qnorm((index - 0.5) / n),
    v = stats::qnorm((((index * 37L) %% n) + 0.5) / n)
  )
}

skew_normal_quasi_response <- function(mu, sigma, nu) {
  n <- length(mu)
  if (!identical(length(sigma), n) || !(length(nu) %in% c(1L, n))) {
    stop("`mu`, `sigma`, and `nu` lengths are incompatible.", call. = FALSE)
  }
  noise <- skew_normal_quasi_noise(n)
  native <- skew_normal_public_to_native(mu = mu, sigma = sigma, nu = nu)
  native$xi +
    native$omega *
      (native$delta *
        abs(noise$u) +
        sqrt(1 - native$delta^2) * noise$v)
}

test_that("skew-normal reference density is normalized and oriented", {
  grid <- expand.grid(
    mu = c(-0.4, 0.2),
    sigma = c(0.5, 1.3),
    nu = c(-2, 0, 1.5)
  )
  integral <- mapply(
    skew_normal_density_integral_reference,
    mu = grid$mu,
    sigma = grid$sigma,
    nu = grid$nu
  )
  expect_equal(integral, rep(1, nrow(grid)), tolerance = 1e-8)

  y <- seq(-2, 2, length.out = 9)
  expect_equal(
    skew_normal_log_density_reference(y, mu = 0.3, sigma = 0.7, nu = 0),
    stats::dnorm(y, mean = 0.3, sd = 0.7, log = TRUE),
    tolerance = 1e-12
  )

  expect_gt(skew_normal_third_central_moment_reference(sigma = 1, nu = 1.4), 0)
  expect_lt(skew_normal_third_central_moment_reference(sigma = 1, nu = -1.4), 0)
})

test_that("drmTMB fits fixed-effect skew-normal location-scale-shape models", {
  sim <- skew_normal_test_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = skew_normal(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "skew_normal")
  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.18)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$beta_sigma)), 0.20)
  expect_lt(abs(unname(coef(fit, "nu")) - sim$beta_nu), 0.60)
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
  expect_equal(
    stats::sigma(fit),
    predict(fit, dpar = "sigma"),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, dpar = "nu"),
    predict(fit, dpar = "nu", type = "link")
  )

  chk <- check_drm(fit)
  shape <- chk[chk$check == "skew_normal_nu", ]
  expect_equal(shape$status, "ok")
})

test_that("skew-normal diagnostics flag large fitted slant values", {
  n <- 360
  dat <- data.frame(
    x = seq(-1.2, 1.2, length.out = n),
    z = rep(seq(-1, 1, length.out = 24), length.out = n)
  )
  mu <- 0.2 + 0.4 * dat$x
  sigma <- exp(-0.3 + 0.15 * dat$z)
  dat$y <- skew_normal_quasi_response(mu = mu, sigma = sigma, nu = 12)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = skew_normal(),
    data = dat,
    control = drm_control(se = FALSE, optimizer_preset = "careful")
  )
  chk <- check_drm(fit)
  shape <- chk[chk$check == "skew_normal_nu", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(shape$status, "note")
  expect_match(shape$message, "large")
  expect_gt(unname(coef(fit, "nu")[["(Intercept)"]]), 10)
})

test_that("skew-normal deterministic recovery distinguishes weak and strong skew", {
  truth <- c(
    negative_strong = -2,
    negative_weak = -0.65,
    positive_weak = 0.65,
    positive_strong = 2
  )
  estimates <- vapply(
    truth,
    function(nu) {
      n <- 360
      dat <- data.frame(
        x = seq(-1.2, 1.2, length.out = n),
        z = rep(seq(-1, 1, length.out = 24), length.out = n)
      )
      mu <- 0.2 + 0.4 * dat$x
      sigma <- exp(-0.3 + 0.15 * dat$z)
      dat$y <- skew_normal_quasi_response(mu = mu, sigma = sigma, nu = nu)

      fit <- drmTMB(
        bf(y ~ x, sigma ~ z, nu ~ 1),
        family = skew_normal(),
        data = dat,
        control = drm_control(se = FALSE)
      )
      expect_equal(fit$opt$convergence, 0)
      unname(coef(fit, "nu")[["(Intercept)"]])
    },
    numeric(1L)
  )

  expect_equal(sign(estimates), sign(truth))
  expect_lt(max(abs(estimates - truth)), 0.35)
  expect_gt(
    abs(estimates[["negative_strong"]]),
    abs(estimates[["negative_weak"]])
  )
  expect_gt(
    abs(estimates[["positive_strong"]]),
    abs(estimates[["positive_weak"]])
  )
})

test_that("skew-normal deterministic recovery handles factor and correlated predictors", {
  n <- 360
  dat <- data.frame(
    x = seq(-1.2, 1.2, length.out = n),
    habitat = factor(rep(c("forest", "open"), length.out = n))
  )
  dat$z <- 0.55 *
    dat$x +
    0.45 * rep(seq(1, -1, length.out = 30), length.out = n)
  beta_mu <- c("(Intercept)" = 0.15, x = 0.38, habitatopen = -0.22)
  beta_sigma <- c("(Intercept)" = -0.3, z = 0.22)
  X_mu <- stats::model.matrix(~ x + habitat, dat)
  X_sigma <- stats::model.matrix(~z, dat)
  mu <- as.vector(X_mu %*% beta_mu)
  sigma <- exp(as.vector(X_sigma %*% beta_sigma))
  dat$y <- skew_normal_quasi_response(mu = mu, sigma = sigma, nu = 1.2)

  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ z, nu ~ 1),
    family = skew_normal(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(coef(fit, "mu") - beta_mu)), 0.08)
  expect_lt(max(abs(coef(fit, "sigma") - beta_sigma)), 0.08)
  expect_lt(abs(unname(coef(fit, "nu")) - 1.2), 0.25)
})

test_that("skew-normal deterministic nu slope recovery has the right direction", {
  n <- 720
  dat <- data.frame(
    x = seq(-1.2, 1.2, length.out = n),
    w = seq(-1.5, 1.5, length.out = n)
  )
  dat$z <- 0.5 * dat$x + 0.5 * rep(seq(1, -1, length.out = 25), length.out = n)
  mu <- 0.1 + 0.35 * dat$x
  sigma <- exp(-0.3 + 0.2 * dat$z)
  nu <- 1.2 * dat$w
  dat$y <- skew_normal_quasi_response(mu = mu, sigma = sigma, nu = nu)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ w),
    family = skew_normal(),
    data = dat,
    control = drm_control(se = FALSE, optimizer_preset = "careful")
  )
  nu_coef <- coef(fit, "nu")
  pred <- predict(
    fit,
    dpar = "nu",
    newdata = data.frame(x = 0, z = 0, w = c(-1, 1))
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(abs(nu_coef[["(Intercept)"]]), 0.4)
  expect_gt(nu_coef[["w"]], 0.5)
  expect_gt(diff(pred), 1)
})

test_that("skew-normal false-positive control stays near the Gaussian limit", {
  n <- 360
  dat <- data.frame(
    x = seq(-1.2, 1.2, length.out = n),
    z = rep(seq(-1, 1, length.out = 24), length.out = n)
  )
  noise <- skew_normal_quasi_noise(n)
  dat$y <- 0.2 + 0.45 * dat$x + exp(-0.25 + 0.2 * dat$z) * noise$v

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = skew_normal(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(abs(unname(coef(fit, "nu"))), 0.35)
})

test_that("skew-normal objective matches independent R likelihood", {
  sim <- skew_normal_test_data(n = 160, seed = 20260609, nu = -1.2)
  dat <- sim$data
  dat$w <- rep(seq(-0.4, 0.4, length.out = 8), length.out = nrow(dat))
  dat$obs_weight <- rep(
    seq(0.45, 1.55, length.out = 10),
    length.out = nrow(dat)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ w),
    family = skew_normal(),
    data = dat,
    weights = obs_weight,
    control = drm_control(se = FALSE)
  )
  mu <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu"))
  sigma <- exp(as.vector(stats::model.matrix(~z, dat) %*% coef(fit, "sigma")))
  nu <- as.vector(stats::model.matrix(~w, dat) %*% coef(fit, "nu"))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    fit$opt$objective,
    -sum(
      dat$obs_weight * skew_normal_log_density_reference(dat$y, mu, sigma, nu)
    ),
    tolerance = 1e-8
  )
})

test_that("skew-normal fixed-effect shape intervals are visible", {
  set.seed(20260612)
  n <- 260
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  mu <- 0.15 + 0.35 * dat$x
  sigma <- exp(-0.25 + 0.15 * dat$z)
  nu <- 0.65 + 0.30 * dat$x
  native <- skew_normal_public_to_native(mu = mu, sigma = sigma, nu = nu)
  dat$y <- native$xi +
    native$omega *
      (native$delta *
        abs(stats::rnorm(n)) +
        sqrt(1 - native$delta^2) * stats::rnorm(n))

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ x),
    family = skew_normal(),
    data = dat,
    control = drm_control(optimizer_preset = "careful")
  )

  targets <- profile_targets(fit)
  nu_targets <- targets[targets$dpar == "nu", , drop = FALSE]
  # Wald slant intervals now warn that they are miscalibrated near nu = 0; the
  # values are still returned for visibility, so capture the expected warning.
  expect_warning(
    ci <- stats::confint(fit, parm = "nu:x", level = 0.90),
    "slant",
    ignore.case = TRUE
  )
  expect_warning(
    summary_ci <- summary(fit, conf.int = TRUE, level = 0.90),
    "slant",
    ignore.case = TRUE
  )
  pred <- predict_parameters(
    fit,
    newdata = data.frame(x = c(-0.5, 0.5), z = 0),
    dpar = "nu",
    conf.int = TRUE,
    conf.level = 0.90,
    include_newdata = FALSE
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(
    nu_targets$parm,
    c("fixef:nu:(Intercept)", "fixef:nu:x")
  )
  expect_equal(nu_targets$target_class, rep("fixed-effect", 2L))
  expect_equal(nu_targets$tmb_parameter, rep("beta_nu", 2L))
  expect_equal(nu_targets$scale, rep("link", 2L))
  expect_true(all(nu_targets$profile_ready))
  expect_equal(ci$parm, "fixef:nu:x")
  expect_equal(ci$method, "wald")
  expect_equal(ci$conf.status, "wald")
  expect_true(all(is.finite(ci$lower)))
  expect_true(all(is.finite(ci$upper)))
  expect_true(all(
    c("fixef:nu:(Intercept)", "fixef:nu:x") %in% summary_ci$confint$parm
  ))
  expect_equal(
    summary_ci$coefficients[c("nu:(Intercept)", "nu:x"), "conf.status"],
    rep("wald", 2L)
  )
  expect_equal(pred$dpar, rep("nu", 2L))
  expect_equal(pred$conf.status, rep("wald", 2L))
  expect_equal(pred$interval_source, rep("wald", 2L))
  expect_true(all(is.finite(pred$std.error)))
  expect_true(all(is.finite(pred$conf.low)))
  expect_true(all(is.finite(pred$conf.high)))
})

test_that("skew-normal nu-free model reaches the Gaussian normal limit", {
  set.seed(20260610)
  dat <- data.frame(
    x = stats::rnorm(120),
    z = stats::rnorm(120)
  )
  dat$y <- 0.1 + 0.5 * dat$x + exp(-0.4 + 0.2 * dat$z) * stats::rnorm(120)

  fit_gaussian <- drmTMB(bf(y ~ x, sigma ~ z), data = dat)
  fit_skew_zero <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 0),
    family = skew_normal(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(
    coef(fit_skew_zero, "mu"),
    coef(fit_gaussian, "mu"),
    tolerance = 1e-6
  )
  expect_equal(
    coef(fit_skew_zero, "sigma"),
    coef(fit_gaussian, "sigma"),
    tolerance = 1e-6
  )
  expect_equal(
    as.numeric(stats::logLik(fit_skew_zero)),
    as.numeric(stats::logLik(fit_gaussian)),
    tolerance = 1e-6
  )
})

test_that("skew-normal methods simulate and compute residuals", {
  sim <- skew_normal_test_data(n = 120, seed = 20260611)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = skew_normal(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )

  sims <- simulate(fit, nsim = 2, seed = 1)
  expect_s3_class(sims, "data.frame")
  expect_equal(dim(sims), c(nrow(sim$data), 2))
  expect_length(residuals(fit), nrow(sim$data))
  expect_length(residuals(fit, type = "pearson"), nrow(sim$data))
  expect_true(all(is.finite(residuals(fit, type = "pearson"))))
})

test_that("skew-normal first slice rejects unsupported neighbours clearly", {
  dat <- data.frame(
    y = stats::rnorm(16),
    x = stats::rnorm(16),
    z = stats::rnorm(16),
    id = rep(1:4, each = 4),
    V = rep(0.01, 16),
    y2 = stats::rnorm(16)
  )

  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1),
      family = skew_normal(),
      data = dat
    ),
    "random effects are not implemented"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z + (1 | id), nu ~ 1),
      family = skew_normal(),
      data = dat
    ),
    "random effects are not implemented"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ x + (1 | id)),
      family = skew_normal(),
      data = dat
    ),
    "random effects are not implemented"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z, sd(id) ~ x),
      family = skew_normal(),
      data = dat
    ),
    "Random-effect scale formulae"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_V(V = V), sigma ~ z, nu ~ 1),
      family = skew_normal(),
      data = dat
    ),
    "not implemented"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, y2) ~ x, sigma ~ z, nu ~ 1),
      family = skew_normal(),
      data = dat
    ),
    "one continuous response"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z, rho12 ~ 1), family = skew_normal(), data = dat),
    "Unsupported parameter"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ z, skew ~ x), family = skew_normal(), data = dat),
    "Unsupported parameter"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z, `skew(id)` ~ x),
      family = skew_normal(),
      data = dat
    ),
    "Latent skewness syntax"
  )
})
