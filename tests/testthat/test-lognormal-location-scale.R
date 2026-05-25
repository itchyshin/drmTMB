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

new_lognormal_random_intercept_data <- function(
  n_id = 36,
  n_each = 9,
  seed = 20260627
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(
    id = id,
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(0.25, 0.40)
  beta_sigma <- c(-0.75, 0.18)
  sd_id <- 0.55
  u_id <- stats::rnorm(n_id, sd = sd_id)
  u_id <- u_id - mean(u_id)
  names(u_id) <- levels(id)
  eta_mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x + u_id[id]
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$biomass <- stats::rlnorm(n, meanlog = eta_mu, sdlog = sigma)
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_id = sd_id,
    u_id = u_id
  )
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
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.08)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.08)
  expect_true(all(sigma(fit) > 0))

  fitted_mean <- exp(
    predict(fit, dpar = "mu") +
      0.5 * predict(fit, dpar = "sigma")^2
  )
  expect_equal(fitted(fit), fitted_mean, tolerance = 1e-12)
})

test_that("lognormal mu supports ordinary random intercepts", {
  sim <- new_lognormal_random_intercept_data()

  fit <- drmTMB(
    bf(biomass ~ x + (1 | id), sigma ~ z),
    family = lognormal(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "lognormal")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$mu$n_terms, 1L)
  expect_equal(fit$model$random$mu$labels, "(1 | id)")
  expect_named(fit$sdpars$mu, "(1 | id)")
  expect_gt(unname(fit$sdpars$mu[["(1 | id)"]]), 0.05)
  expect_lt(abs(unname(fit$sdpars$mu[["(1 | id)"]]) - sim$sd_id), 0.25)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.18)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.20)

  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  expect_equal(length(id_effects), length(sim$u_id))
  expect_gt(stats::cor(id_effects, sim$u_id), 0.50)
  expect_true(drmTMB:::has_ordinary_mu_random_effects(fit))
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 1L)
  expect_equal(
    predict(fit, dpar = "mu"),
    as.vector(fit$model$X$mu %*% coef(fit, "mu")) +
      drmTMB:::mu_random_effect_contribution(fit),
    tolerance = 1e-8
  )

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == "sd:mu:(1 | id)", , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_mu")
  expect_true(sd_target$profile_ready)

  chk <- check_drm(fit)
  replication <- chk[chk$check == "mu_random_effect_replication", ]
  expect_equal(replication$status, "ok")
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

  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    predict(fit, dpar = "mu")
  )
  expect_equal(
    predict(fit, dpar = "mu", type = "response"),
    predict(fit, dpar = "mu")
  )
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
    as.vector(
      stats::model.matrix(~z, data.frame(z = c(0, 1))) %*% coef(fit, "sigma")
    ),
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
      bf(abs(y) + 0.1 ~ x + (0 + x | id), sigma ~ 1),
      family = lognormal(),
      data = dat
    ),
    "random intercepts"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x + (1 | p | id), sigma ~ 1),
      family = lognormal(),
      data = dat
    ),
    "random intercepts"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x, sigma ~ 1 + (1 | id)),
      family = lognormal(),
      data = dat
    ),
    "sigma.*random effects"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x + meta_V(V = rep(0.1, 4)), sigma ~ 1),
      family = lognormal(),
      data = dat
    ),
    "meta_V"
  )
  expect_error(
    drmTMB(
      bf(abs(y) + 0.1 ~ x, sigma ~ 1, sd(id) ~ 1),
      family = lognormal(),
      data = dat
    ),
    "Random-effect scale formulae"
  )
  expect_error(
    drmTMB(bf(mvbind(y, x) ~ x, sigma ~ 1), family = lognormal(), data = dat),
    "mvbind"
  )
  expect_error(
    drmTMB(bf(mu = ~x, sigma ~ 1), family = lognormal(), data = dat),
    "must include a response"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma = ~1, sigma = ~x),
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
