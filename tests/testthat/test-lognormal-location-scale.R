new_lognormal_data <- function(n = 700, seed = 20260518) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(0.35, 0.45)
  beta_sigma <- c(-0.65, 0.25)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$biomass <- stats::rlnorm(n, meanlog = mu, sdlog = sigma)
  list(data = dat, beta_mu = beta_mu, beta_sigma = beta_sigma)
}

test_that("drmTMB fits fixed-effect lognormal location-scale models", {
  sim <- new_lognormal_data()

  fit <- drmTMB(
    bf(biomass ~ x, sigma ~ z),
    family = lognormal(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "lognormal")
  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.08)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.08)
  expect_true(all(sigma(fit) > 0))

  fitted_mean <- exp(
    predict(fit, dpar = "mu") +
      0.5 * predict(fit, dpar = "sigma")^2
  )
  expect_equal(fitted(fit), fitted_mean, tolerance = 1e-12)
})

test_that("lognormal likelihood matches independent dlnorm calculation", {
  sim <- new_lognormal_data(n = 260, seed = 20260519)

  fit <- drmTMB(
    bf(biomass ~ x, sigma ~ z),
    family = lognormal(),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  ll_independent <- sum(stats::dlnorm(
    fit$model$y,
    meanlog = eta_mu,
    sdlog = exp(eta_sigma),
    log = TRUE
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("lognormal methods return log-scale parameters and positive simulations", {
  sim <- new_lognormal_data(n = 180, seed = 20260520)
  fit <- drmTMB(
    bf(biomass ~ x, sigma ~ z),
    family = lognormal(),
    data = sim$data
  )

  expect_equal(predict(fit, dpar = "mu", type = "link"), predict(fit, dpar = "mu"))
  expect_equal(predict(fit, dpar = "mu", type = "response"), predict(fit, dpar = "mu"))
  expect_equal(predict(fit, dpar = "sigma", type = "response"), sigma(fit))
  expect_equal(
    residuals(fit, type = "pearson"),
    (log(fit$model$y) - predict(fit, dpar = "mu")) / sigma(fit),
    tolerance = 1e-12
  )
  expect_equal(residuals(fit), fit$model$y - fitted(fit), tolerance = 1e-12)
  expect_equal(
    predict(
      fit,
      newdata = data.frame(x = c(0, 1), z = c(0, 1)),
      dpar = "sigma",
      type = "link"
    ),
    as.vector(stats::model.matrix(~ z, data.frame(z = c(0, 1))) %*% coef(fit, "sigma")),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260521)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_true(all(unlist(sims, use.names = FALSE) > 0))
})

test_that("lognormal handles factor predictors and sigma edge cases", {
  n <- 240
  group <- factor(rep(c("control", "treatment"), each = n / 2))
  q <- unlist(lapply(split(seq_len(n), group), function(idx) {
    stats::qnorm((seq_along(idx) - 0.5) / length(idx))
  }))
  mu <- 0.1 + 0.45 * (group == "treatment")
  log_sigma <- -0.55 + 0.3 * (group == "treatment")
  dat <- data.frame(
    biomass = exp(mu + exp(log_sigma) * q),
    group = group
  )

  fit <- drmTMB(
    bf(biomass ~ group, sigma ~ group),
    family = lognormal(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(unname(coef(fit, "mu")), c(0.1, 0.45), tolerance = 0.01)
  expect_equal(unname(coef(fit, "sigma")), c(-0.55, 0.3), tolerance = 0.01)

  sigma_case <- function(sigma_value) {
    n <- 160
    q <- stats::qnorm((seq_len(n) - 0.5) / n)
    dat <- data.frame(biomass = exp(0.25 + sigma_value * q))
    drmTMB(bf(biomass ~ 1, sigma ~ 1), family = lognormal(), data = dat)
  }
  small <- sigma_case(0.18)
  large <- sigma_case(1.35)

  expect_equal(small$opt$convergence, 0)
  expect_equal(large$opt$convergence, 0)
  expect_equal(unname(coef(small, "mu")), 0.25, tolerance = 0.01)
  expect_equal(exp(unname(coef(small, "sigma"))), 0.18, tolerance = 0.01)
  expect_equal(unname(coef(large, "mu")), 0.25, tolerance = 0.01)
  expect_equal(exp(unname(coef(large, "sigma"))), 1.35, tolerance = 0.01)
})

test_that("lognormal applies complete-case filtering before positivity checks", {
  n <- 30
  dat <- data.frame(
    x = seq(-1, 1, length.out = n),
    z = rep(c(0, 1), length.out = n)
  )
  q <- stats::qnorm((seq_len(n) - 0.5) / n)
  dat$biomass <- exp(0.2 + 0.3 * dat$x + exp(-0.4 + 0.15 * dat$z) * q)
  dat$biomass[[1L]] <- 0
  dat$x[[1L]] <- NA
  dat$z[[2L]] <- NA

  fit <- drmTMB(
    bf(biomass ~ x, sigma ~ z),
    family = lognormal(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), n - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y > 0))
})

test_that("lognormal models reject unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(0, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = dat),
    "positive finite response"
  )
  expect_error(
    drmTMB(bf(abs(y) + 0.1 ~ x, nu ~ 1), family = lognormal(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x + (1 | id), sigma ~ 1),
      family = lognormal(),
      data = dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x + meta_known_V(V = rep(0.1, 4)), sigma ~ 1),
      family = lognormal(),
      data = dat
    ),
    "meta_known_V"
  )
  expect_error(
    drmTMB(bf(abs(y) + 0.1 ~ x, sigma ~ 1, sd(id) ~ 1), family = lognormal(), data = dat),
    "Random-effect scale formulae"
  )
  expect_error(
    drmTMB(bf(mvbind(y, x) ~ x, sigma ~ 1), family = lognormal(), data = dat),
    "mvbind"
  )
  expect_error(
    drmTMB(bf(mu = ~ x, sigma ~ 1), family = lognormal(), data = dat),
    "must include a response"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma = ~ 1, sigma = ~ x),
      family = lognormal(),
      data = transform(dat, y = abs(y) + 0.1)
    ),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = lognormal(),
      data = transform(dat, y = NA_real_)
    ),
    "No complete observations"
  )
})
