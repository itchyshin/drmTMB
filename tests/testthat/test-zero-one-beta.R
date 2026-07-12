new_zero_one_beta_data <- function(n = 1600, seed = 20260620) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    w = stats::rnorm(n),
    v = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = -0.20, x = 0.65)
  beta_sigma <- c(`(Intercept)` = -0.85, z = 0.22)
  beta_zoi <- c(`(Intercept)` = -1.00, w = 0.45)
  beta_coi <- c(`(Intercept)` = 0.15, v = -0.55)
  mu <- stats::plogis(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  zoi <- stats::plogis(beta_zoi[[1L]] + beta_zoi[[2L]] * dat$w)
  coi <- stats::plogis(beta_coi[[1L]] + beta_coi[[2L]] * dat$v)
  y <- stats::rbeta(n, shape1 = mu / sigma^2, shape2 = (1 - mu) / sigma^2)
  boundary <- stats::runif(n) < zoi
  y[boundary] <- as.numeric(stats::runif(sum(boundary)) < coi[boundary])
  dat$prop <- y
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    beta_zoi = beta_zoi,
    beta_coi = beta_coi
  )
}

dzoibeta_drm <- function(y, mu, sigma, zoi, coi, log = FALSE) {
  phi <- 1 / sigma^2
  out <- numeric(length(y))
  is_zero <- y == 0
  is_one <- y == 1
  is_interior <- y > 0 & y < 1
  out[is_zero] <- log(zoi[is_zero]) + log1p(-coi[is_zero])
  out[is_one] <- log(zoi[is_one]) + log(coi[is_one])
  out[is_interior] <- log1p(-zoi[is_interior]) +
    stats::dbeta(
      y[is_interior],
      shape1 = mu[is_interior] * phi[is_interior],
      shape2 = (1 - mu[is_interior]) * phi[is_interior],
      log = TRUE
    )
  if (isTRUE(log)) out else exp(out)
}

test_that("drmTMB fits fixed-effect zero-one beta models", {
  sim <- new_zero_one_beta_data()

  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
    family = zero_one_beta(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "zero_one_beta")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.10)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.12)
  expect_lt(max(abs(coef(fit, "zoi") - sim$beta_zoi)), 0.12)
  expect_lt(max(abs(coef(fit, "coi") - sim$beta_coi)), 0.22)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(predict(fit, dpar = "mu") < 1))
  expect_true(all(predict(fit, dpar = "zoi") > 0))
  expect_true(all(predict(fit, dpar = "zoi") < 1))
  expect_true(all(predict(fit, dpar = "coi") > 0))
  expect_true(all(predict(fit, dpar = "coi") < 1))
  expect_true(all(sigma(fit) > 0))

  fitted_mean <- (1 - predict(fit, dpar = "zoi")) *
    predict(fit, dpar = "mu") +
    predict(fit, dpar = "zoi") * predict(fit, dpar = "coi")
  expect_equal(fitted(fit), fitted_mean, tolerance = 1e-12)

  ci <- confint(fit)
  expect_equal(
    ci$parm,
    c(
      "fixef:mu:(Intercept)",
      "fixef:mu:x",
      "fixef:sigma:(Intercept)",
      "fixef:sigma:z",
      "fixef:zoi:(Intercept)",
      "fixef:zoi:w",
      "fixef:coi:(Intercept)",
      "fixef:coi:v"
    )
  )
  expect_equal(
    ci$tmb_parameter,
    c(
      "beta_mu",
      "beta_mu",
      "beta_sigma",
      "beta_sigma",
      "beta_zoi",
      "beta_zoi",
      "beta_coi",
      "beta_coi"
    )
  )
  expect_true(all(ci$conf.status == "wald"))
})

test_that("zero-one beta likelihood matches independent mixture calculation", {
  sim <- new_zero_one_beta_data(n = 420, seed = 20260621)

  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
    family = zero_one_beta(),
    data = sim$data
  )
  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  eta_zoi <- as.vector(fit$model$X$zoi %*% coef(fit, "zoi"))
  eta_coi <- as.vector(fit$model$X$coi %*% coef(fit, "coi"))
  ll_independent <- sum(dzoibeta_drm(
    fit$model$y,
    mu = stats::plogis(eta_mu),
    sigma = exp(eta_sigma),
    zoi = stats::plogis(eta_zoi),
    coi = stats::plogis(eta_coi),
    log = TRUE
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)

  weights <- seq(0.5, 1.5, length.out = nrow(sim$data))
  fit_w <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
    family = zero_one_beta(),
    data = sim$data,
    weights = weights
  )
  ll_weighted <- sum(
    weights *
      dzoibeta_drm(
        fit_w$model$y,
        mu = predict(fit_w, dpar = "mu"),
        sigma = predict(fit_w, dpar = "sigma"),
        zoi = predict(fit_w, dpar = "zoi"),
        coi = predict(fit_w, dpar = "coi"),
        log = TRUE
      )
  )

  expect_equal(fit_w$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit_w)), ll_weighted, tolerance = 1e-6)
})

test_that("zero-one beta methods use the unconditional response mean", {
  sim <- new_zero_one_beta_data(n = 360, seed = 20260622)
  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
    family = zero_one_beta(),
    data = sim$data
  )

  mu <- predict(fit, dpar = "mu")
  sigma <- predict(fit, dpar = "sigma")
  zoi <- predict(fit, dpar = "zoi")
  coi <- predict(fit, dpar = "coi")
  fitted_mean <- (1 - zoi) * mu + zoi * coi
  beta_var <- mu * (1 - mu) * sigma^2 / (1 + sigma^2)
  mixture_var <- (1 - zoi) * (beta_var + mu^2) + zoi * coi - fitted_mean^2

  expect_equal(residuals(fit), fit$model$y - fitted_mean, tolerance = 1e-12)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - fitted_mean) / sqrt(mixture_var),
    tolerance = 1e-12
  )

  newdata <- data.frame(
    x = c(-1, 0, 1),
    z = c(-1, 0, 1),
    w = c(-1, 0, 1),
    v = c(-1, 0, 1)
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "zoi", type = "link"),
    as.vector(stats::model.matrix(~w, newdata) %*% coef(fit, "zoi")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "coi"),
    stats::plogis(predict(fit, newdata = newdata, dpar = "coi", type = "link")),
    tolerance = 1e-12
  )

  sims <- simulate(fit, nsim = 2, seed = 20260623)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) >= 0))
  expect_true(all(unlist(sims, use.names = FALSE) <= 1))
  expect_true(any(unlist(sims, use.names = FALSE) == 0))
  expect_true(any(unlist(sims, use.names = FALSE) == 1))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260623),
    simulate(fit, nsim = 2, seed = 20260623)
  )
})

test_that("zero-one beta handles pure interior and one-sided boundary cells", {
  n <- 500
  dat <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  mu <- stats::plogis(0.10 + 0.50 * dat$x)
  sigma <- exp(-0.80 + 0.20 * dat$z)
  dat$prop <- stats::rbeta(
    n,
    shape1 = mu / sigma^2,
    shape2 = (1 - mu) / sigma^2
  )

  pure_interior <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ 1, coi ~ 1),
    family = zero_one_beta(),
    data = dat
  )
  expect_equal(pure_interior$opt$convergence, 0)
  expect_true(is.finite(as.numeric(logLik(pure_interior))))
  expect_lt(unique(predict(pure_interior, dpar = "zoi")), 1e-4)

  zero_only <- transform(dat, prop = replace(prop, seq(1, n, by = 4), 0))
  one_only <- transform(dat, prop = replace(prop, seq(1, n, by = 4), 1))
  fit_zero <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ 1, coi ~ 1),
    family = zero_one_beta(),
    data = zero_only
  )
  fit_one <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ 1, coi ~ 1),
    family = zero_one_beta(),
    data = one_only
  )

  expect_equal(fit_zero$opt$convergence, 0)
  expect_equal(fit_one$opt$convergence, 0)
  expect_true(fit_zero$sdr$pdHess)
  expect_true(fit_one$sdr$pdHess)
  expect_lt(coef(fit_zero, "coi")[[1L]], -10)
  expect_gt(coef(fit_one, "coi")[[1L]], 10)
})

test_that("zero-one beta validates malformed and neighbouring inputs", {
  dat <- data.frame(
    y = c(0, 1, seq(0.12, 0.88, length.out = 10)),
    x = rep(c(0, 1), 6),
    id = factor(rep(1:3, each = 4)),
    success = c(0, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2),
    failure = c(4, 0, 3, 2, 1, 0, 3, 2, 1, 0, 3, 2)
  )

  expect_no_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    )
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = beta(), data = dat),
    "strictly between 0 and 1"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "single continuous bounded response"
  )
  # A `mu` random intercept `(1 | id)` is now supported (Arc 2a); recovery is
  # checked in test-arc2a-mu-random-intercept.R. Inflation- and scale-side
  # random effects remain rejected.
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ x + (1 | id), coi ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "Zero-one-inflation random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ x + (0 + x | id)),
      family = zero_one_beta(),
      data = dat
    ),
    "One-inflation random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "sigma.*random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1, sd(id) ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_V(V = rep(0.1, 4)), sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "meta_V"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = transform(dat, y = replace(y, 1, -0.1))
    ),
    "closed interval"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = transform(dat, y = rep(c(0, 1), length.out = nrow(dat)))
    ),
    "at least one interior"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, y) ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "mvbind"
  )
})
