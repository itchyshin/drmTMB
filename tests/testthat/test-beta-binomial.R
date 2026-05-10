new_beta_binomial_data <- function(n = 1200, seed = 20260510) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    trials = sample(8:24, n, replace = TRUE)
  )
  beta_mu <- c(`(Intercept)` = -0.20, x = 0.70)
  beta_sigma <- c(`(Intercept)` = -1.10, z = 0.25)
  mu <- stats::plogis(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  phi <- 1 / sigma^2
  p <- stats::rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
  dat$success <- stats::rbinom(n, size = dat$trials, prob = p)
  dat$failure <- dat$trials - dat$success
  list(data = dat, beta_mu = beta_mu, beta_sigma = beta_sigma)
}

dbetabinom_drm <- function(success, trials, mu, sigma, log = FALSE) {
  phi <- 1 / sigma^2
  alpha <- mu * phi
  beta_shape <- (1 - mu) * phi
  failure <- trials - success
  out <- lgamma(trials + 1) -
    lgamma(success + 1) -
    lgamma(failure + 1) +
    lgamma(phi) -
    lgamma(trials + phi) +
    lgamma(success + alpha) -
    lgamma(alpha) +
    lgamma(failure + beta_shape) -
    lgamma(beta_shape)
  if (isTRUE(log)) out else exp(out)
}

test_that("drmTMB fits fixed-effect beta-binomial models", {
  sim <- new_beta_binomial_data()

  fit <- drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ z),
    family = beta_binomial(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "beta_binomial")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.18)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.25)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(predict(fit, dpar = "mu") < 1))
  expect_true(all(sigma(fit) > 0))
  expect_equal(fit$model$trials, sim$data$trials)
})

test_that("beta-binomial likelihood matches independent calculation", {
  sim <- new_beta_binomial_data(n = 320, seed = 20260511)

  fit <- drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ z),
    family = beta_binomial(),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  mu <- stats::plogis(eta_mu)
  sigma <- exp(eta_sigma)
  ll_independent <- sum(dbetabinom_drm(
    fit$model$y,
    fit$model$trials,
    mu,
    sigma,
    log = TRUE
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)

  w <- seq(0.5, 1.5, length.out = nrow(sim$data))
  fit_w <- drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ z),
    family = beta_binomial(),
    data = sim$data,
    weights = w
  )
  eta_mu_w <- as.vector(fit_w$model$X$mu %*% coef(fit_w, "mu"))
  eta_sigma_w <- as.vector(fit_w$model$X$sigma %*% coef(fit_w, "sigma"))
  ll_weighted <- sum(
    w *
      dbetabinom_drm(
        fit_w$model$y,
        fit_w$model$trials,
        stats::plogis(eta_mu_w),
        exp(eta_sigma_w),
        log = TRUE
      )
  )

  expect_equal(fit_w$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit_w)), ll_weighted, tolerance = 1e-6)
})

test_that("beta-binomial methods return probability and overdispersion scales", {
  sim <- new_beta_binomial_data(n = 220, seed = 20260512)
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ z),
    family = beta_binomial(),
    data = sim$data
  )

  mu <- predict(fit, dpar = "mu")
  sigma <- predict(fit, dpar = "sigma")
  observed <- fit$model$y / fit$model$trials
  expected_var <- beta_binomial_proportion_variance(mu, sigma, fit$model$trials)

  expect_equal(
    predict(fit, dpar = "mu"),
    stats::plogis(predict(fit, dpar = "mu", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, dpar = "sigma"),
    exp(predict(fit, dpar = "sigma", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(fitted(fit), mu, tolerance = 1e-12)
  expect_equal(residuals(fit), observed - mu, tolerance = 1e-12)
  expect_equal(
    residuals(fit, type = "pearson"),
    (observed - mu) / sqrt(expected_var),
    tolerance = 1e-12
  )

  newdata <- data.frame(x = c(-1, 0, 1), z = c(-1, 0, 1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu", type = "link"),
    as.vector(stats::model.matrix(~x, newdata) %*% coef(fit, "mu")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    stats::plogis(predict(fit, newdata = newdata, dpar = "mu", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma", type = "link"),
    as.vector(stats::model.matrix(~z, newdata) %*% coef(fit, "sigma")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma"),
    exp(predict(fit, newdata = newdata, dpar = "sigma", type = "link")),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260513)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_true(all(vapply(sims, is.integer, logical(1))))
  expect_true(all(sims$sim_1 >= 0))
  expect_true(all(sims$sim_1 <= fit$model$trials))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260513),
    simulate(fit, nsim = 2, seed = 20260513)
  )
})

test_that("beta-binomial supports default sigma and complete-case filtering", {
  sim <- new_beta_binomial_data(n = 160, seed = 20260514)
  dat <- sim$data
  dat$success[[1L]] <- NA
  dat$z[[2L]] <- NA

  fit <- drmTMB(
    bf(cbind(success, failure) ~ x),
    family = beta_binomial(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 1L)
  expect_equal(fit$model$keep[[1L]], FALSE)
  expect_equal(coef(fit, "sigma"), c(`(Intercept)` = coef(fit, "sigma")[[1L]]))
})

test_that("beta-binomial boundary count patterns remain finite", {
  dat <- data.frame(
    success = c(rep(0, 10), rep(10, 10)),
    failure = c(rep(10, 10), rep(0, 10)),
    x = rep(c(-1, 1), each = 10)
  )

  fit <- suppressWarnings(drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ 1),
    family = beta_binomial(),
    data = dat
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_true(is.finite(as.numeric(logLik(fit))))
  expect_true(all(is.finite(predict(fit, dpar = "mu", type = "link"))))
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(predict(fit, dpar = "mu") < 1))
  expect_true(all(is.finite(sigma(fit))))
})

test_that("beta-binomial rejects malformed and unsupported inputs", {
  dat <- data.frame(
    success = c(1, 2, 3, 4),
    failure = c(4, 3, 2, 1),
    y = c(0.2, 0.4, 0.6, 0.8),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = beta_binomial(), data = dat),
    "two-column count syntax"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, phi ~ 1),
      family = beta_binomial(),
      data = dat
    ),
    "only support|location formula"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x + (1 | id), sigma ~ 1),
      family = beta_binomial(),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, sigma ~ 1, sd(id) ~ 1),
      family = beta_binomial(),
      data = dat
    ),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(
        cbind(success, failure) ~ x + meta_known_V(V = rep(0.1, 4)),
        sigma ~ 1
      ),
      family = beta_binomial(),
      data = dat
    ),
    "meta_known_V"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, sigma ~ 1),
      family = beta_binomial(),
      data = transform(dat, success = c(1, 2.5, 3, 4))
    ),
    "non-negative integers"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, sigma ~ 1),
      family = beta_binomial(),
      data = transform(dat, success = 0, failure = 0)
    ),
    "positive"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, sigma ~ 1),
      family = beta_binomial(),
      data = transform(dat, success = c(1, -1, 3, 4))
    ),
    "non-negative integers"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, sigma ~ 1),
      family = beta_binomial(),
      data = transform(dat, failure = c(4, Inf, 2, 1))
    ),
    "non-negative integers"
  )
  expect_error(
    drmTMB(
      bf(cbind(success) ~ x, sigma ~ 1),
      family = beta_binomial(),
      data = dat
    ),
    "two-column count"
  )
})
