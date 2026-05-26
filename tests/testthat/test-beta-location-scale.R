new_beta_data <- function(n = 900, seed = 20260614) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = -0.25, x = 0.75)
  beta_sigma <- c(`(Intercept)` = -0.70, z = 0.25)
  mu <- stats::plogis(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  phi <- 1 / sigma^2
  dat$prop <- stats::rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
  list(data = dat, beta_mu = beta_mu, beta_sigma = beta_sigma)
}

new_beta_random_intercept_data <- function(
  n_id = 44,
  n_each = 10,
  seed = 20260630
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(
    id = id,
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = -0.30, x = 0.70)
  beta_sigma <- c(`(Intercept)` = -0.85, z = 0.16)
  sd_id <- 0.55
  u_id <- stats::rnorm(n_id, sd = sd_id)
  u_id <- u_id - mean(u_id)
  names(u_id) <- levels(id)
  eta_mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x + u_id[id]
  mu <- stats::plogis(eta_mu)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  phi <- 1 / sigma^2
  dat$prop <- stats::rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_id = sd_id,
    u_id = u_id
  )
}

test_that("drmTMB fits fixed-effect beta mean-scale models", {
  sim <- new_beta_data()

  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z),
    family = beta(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "beta")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.12)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.15)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(predict(fit, dpar = "mu") < 1))
  expect_true(all(sigma(fit) > 0))
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
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)

  ci <- confint(fit)
  expect_equal(
    ci$parm,
    c(
      "fixef:mu:(Intercept)",
      "fixef:mu:x",
      "fixef:sigma:(Intercept)",
      "fixef:sigma:z"
    )
  )
  expect_equal(
    ci$tmb_parameter,
    c("beta_mu", "beta_mu", "beta_sigma", "beta_sigma")
  )
  expect_true(all(ci$conf.status == "wald"))
})

test_that("beta mu supports ordinary random intercepts", {
  sim <- new_beta_random_intercept_data()

  fit <- drmTMB(
    bf(prop ~ x + (1 | id), sigma ~ z),
    family = beta(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "beta")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$mu$n_terms, 1L)
  expect_equal(fit$model$random$mu$labels, "(1 | id)")
  expect_named(fit$sdpars$mu, "(1 | id)")
  expect_gt(unname(fit$sdpars$mu[["(1 | id)"]]), 0.05)
  expect_lt(abs(unname(fit$sdpars$mu[["(1 | id)"]]) - sim$sd_id), 0.30)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.25)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.30)

  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  expect_equal(length(id_effects), length(sim$u_id))
  expect_gt(stats::cor(id_effects, sim$u_id), 0.45)
  expect_true(drmTMB:::has_ordinary_mu_random_effects(fit))
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 1L)
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    as.vector(fit$model$X$mu %*% coef(fit, "mu")) +
      drmTMB:::mu_random_effect_contribution(fit),
    tolerance = 1e-8
  )
  expect_equal(
    fitted(fit),
    stats::plogis(predict(fit, dpar = "mu", type = "link")),
    tolerance = 1e-12
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

test_that("beta likelihood matches independent dbeta calculation", {
  sim <- new_beta_data(n = 260, seed = 20260615)

  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z),
    family = beta(),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  mu <- stats::plogis(eta_mu)
  sigma <- exp(eta_sigma)
  phi <- 1 / sigma^2
  ll_independent <- sum(stats::dbeta(
    fit$model$y,
    shape1 = mu * phi,
    shape2 = (1 - mu) * phi,
    log = TRUE
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("beta methods return mean and public sigma scales", {
  sim <- new_beta_data(n = 180, seed = 20260616)
  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z),
    family = beta(),
    data = sim$data
  )

  mu <- fitted(fit)
  sigma <- sigma(fit)
  expect_equal(predict(fit, dpar = "mu"), mu, tolerance = 1e-12)
  expect_equal(predict(fit, dpar = "sigma", type = "response"), sigma)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - mu) / sqrt(mu * (1 - mu) * sigma^2 / (1 + sigma^2)),
    tolerance = 1e-12
  )
  expect_equal(residuals(fit), fit$model$y - mu, tolerance = 1e-12)
  newdata <- data.frame(x = c(-1, 0, 1), z = c(-1, 0, 1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    stats::plogis(as.vector(
      stats::model.matrix(~x, newdata) %*% coef(fit, "mu")
    )),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma", type = "link"),
    as.vector(stats::model.matrix(~z, newdata) %*% coef(fit, "sigma")),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260617)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) > 0))
  expect_true(all(unlist(sims, use.names = FALSE) < 1))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260617),
    simulate(fit, nsim = 2, seed = 20260617)
  )
})

test_that("beta handles factor predictors and scale edge cases", {
  n <- 500
  group <- factor(rep(c("control", "treatment"), each = n / 2))
  beta_mu <- c(-0.35, 0.70)
  beta_sigma <- c(-0.80, 0.35)
  mu <- stats::plogis(beta_mu[[1L]] + beta_mu[[2L]] * (group == "treatment"))
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * (group == "treatment"))
  phi <- 1 / sigma^2
  q <- unlist(lapply(split(seq_len(n), group), function(idx) {
    (seq_along(idx) - 0.5) / length(idx)
  }))
  dat <- data.frame(
    prop = stats::qbeta(q, shape1 = mu * phi, shape2 = (1 - mu) * phi),
    group = group
  )

  fit <- drmTMB(
    bf(prop ~ group, sigma ~ group),
    family = beta(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(unname(coef(fit, "mu")), beta_mu, tolerance = 0.02)
  expect_equal(unname(coef(fit, "sigma")), beta_sigma, tolerance = 0.02)

  beta_case <- function(mu_link, sigma_value) {
    n <- 260
    mu <- stats::plogis(mu_link)
    phi <- 1 / sigma_value^2
    dat <- data.frame(
      prop = stats::qbeta(
        (seq_len(n) - 0.5) / n,
        shape1 = mu * phi,
        shape2 = (1 - mu) * phi
      )
    )
    drmTMB(bf(prop ~ 1, sigma ~ 1), family = beta(), data = dat)
  }
  small <- beta_case(-0.25, 0.18)
  large <- beta_case(0.75, 1.10)

  expect_equal(small$opt$convergence, 0)
  expect_equal(large$opt$convergence, 0)
  expect_equal(unname(coef(small, "mu")), -0.25, tolerance = 0.03)
  expect_equal(exp(unname(coef(small, "sigma"))), 0.18, tolerance = 0.03)
  expect_equal(unname(coef(large, "mu")), 0.75, tolerance = 0.04)
  expect_equal(exp(unname(coef(large, "sigma"))), 1.10, tolerance = 0.07)
})

test_that("beta supports default sigma and complete-case filtering", {
  sim <- new_beta_data(n = 120, seed = 20260618)
  fit_default_sigma <- drmTMB(
    bf(prop ~ x),
    family = beta(),
    data = sim$data
  )

  expect_equal(fit_default_sigma$opt$convergence, 0)
  expect_length(coef(fit_default_sigma, "sigma"), 1)
  expect_equal(ncol(fit_default_sigma$model$X$sigma), 1)

  n <- 40
  dat <- data.frame(
    x = seq(-1, 1, length.out = n),
    z = rep(c(0, 1), length.out = n)
  )
  mu <- stats::plogis(-0.2 + 0.45 * dat$x)
  sigma <- exp(-0.7 + 0.20 * dat$z)
  phi <- 1 / sigma^2
  q <- (seq_len(n) - 0.5) / n
  dat$prop <- stats::qbeta(q, shape1 = mu * phi, shape2 = (1 - mu) * phi)
  dat$prop[[1L]] <- 0
  dat$x[[1L]] <- NA
  dat$prop[[2L]] <- 1
  dat$z[[2L]] <- NA

  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z),
    family = beta(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), n - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y > 0))
  expect_true(all(fit$model$y < 1))
})

test_that("beta rejects boundary and unsupported inputs", {
  dat <- data.frame(
    y = c(0.1, 0.25, 0.7, 0.9),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = beta(),
      data = transform(dat, y = c(0, 0.2, 0.7, 0.9))
    ),
    "strictly between 0 and 1"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1),
      family = beta(),
      data = transform(dat, y = c(0, 0.2, 0.7, 0.9))
    ),
    "strictly between 0 and 1"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = beta(),
      data = transform(dat, y = c(0.1, 0.2, 0.7, 1))
    ),
    "strictly between 0 and 1"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = beta(),
      data = transform(dat, y = NA_real_)
    ),
    "No complete observations"
  )
  expect_error(
    drmTMB(bf(y ~ x, phi ~ 1), family = beta(), data = dat),
    "only support|location formula"
  )
  expect_error(
    drmTMB(bf(y ~ x, nu ~ 1), family = beta(), data = dat),
    "only support|location formula"
  )
  expect_error(
    drmTMB(bf(y ~ x, zoi ~ x, coi ~ 1), family = beta(), data = dat),
    "Zero-one-inflated bounded-response likelihoods"
  )
  expect_error(
    drmTMB(bf(y ~ x, zoi ~ x + (1 | id)), family = beta(), data = dat),
    "Zero-one-inflated bounded-response random effects"
  )
  expect_error(
    drmTMB(bf(y ~ x, coi ~ x + (0 + x | id)), family = beta(), data = dat),
    "Zero-one-inflated bounded-response random effects"
  )
  expect_error(
    drmTMB(bf(mu = ~x, sigma ~ 1), family = beta(), data = dat),
    "must include a response"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sigma ~ x), family = beta(), data = dat),
    "at most one"
  )
  expect_error(
    drmTMB(bf(y ~ x + (0 + x | id), sigma ~ 1), family = beta(), data = dat),
    "random intercepts"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 | p | id), sigma ~ 1), family = beta(), data = dat),
    "random intercepts"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + (1 | id)), family = beta(), data = dat),
    "sigma.*random effects"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sd(id) ~ 1), family = beta(), data = dat),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_V(V = rep(0.1, 4)), sigma ~ 1),
      family = beta(),
      data = dat
    ),
    "meta_V"
  )
  expect_error(
    drmTMB(bf(mvbind(y, y) ~ x, sigma ~ 1), family = beta(), data = dat),
    "mvbind"
  )
  binom_dat <- data.frame(
    success = c(1, 2, 3, 4),
    failure = c(4, 3, 2, 1),
    x = c(0, 1, 0, 1)
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, sigma ~ 1),
      family = beta(),
      data = binom_dat
    ),
    "single strict proportion"
  )
})
