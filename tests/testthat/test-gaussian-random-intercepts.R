new_gaussian_ri_data <- function(
  n_id = 36,
  n_each = 10,
  sd_id = 0.7,
  seed = 20260507
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u_id <- stats::rnorm(n_id, sd = sd_id)
  u_id <- u_id - mean(u_id)
  beta_mu <- c(0.35, 0.55)
  beta_sigma <- c(-0.25, 0.22)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x + u_id[id]
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      id = id
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_id = sd_id
  )
}

new_gaussian_rs_data <- function(
  n_id = 45,
  n_each = 9,
  sd_slope = 0.45,
  seed = 20260511
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u_slope <- stats::rnorm(n_id, sd = sd_slope)
  u_slope <- u_slope - mean(u_slope)
  beta_mu <- c(0.25, 0.7)
  beta_sigma <- c(-0.3, 0.2)
  mu <- beta_mu[[1L]] + (beta_mu[[2L]] + u_slope[id]) * x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      id = id
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_slope = sd_slope
  )
}

new_gaussian_corr_rs_data <- function(
  n_id = 36,
  n_each = 8,
  sd0 = 0.55,
  sd1 = 0.35,
  rho_re = 0.45,
  seed = 20260515
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  u0 <- sd0 * z0
  u1 <- sd1 * (rho_re * z0 + sqrt(1 - rho_re^2) * z1)
  beta_mu <- c(0.25, 0.65)
  beta_sigma <- c(-0.3, 0.18)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x + u0[id] + u1[id] * x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      id = id
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd = c(`(Intercept)` = sd0, x = sd1),
    rho_re = rho_re
  )
}

new_gaussian_labelled_corr_rs_data <- function(
  n_id = 30,
  n_each = 7,
  sd0 = 0.5,
  sd1 = 0.35,
  rho_re = 0.4,
  sigma = 0.45,
  seed = 20260530
) {
  set.seed(seed)
  n <- n_id * n_each
  ID <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  f <- factor(rep(c("control", "treated"), length.out = n))
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  u0 <- sd0 * z0
  u1 <- sd1 * (rho_re * z0 + sqrt(1 - rho_re^2) * z1)
  beta_mu <- c(`(Intercept)` = 0.25, x = 0.65, ftreated = 0.2)
  mu <- beta_mu[[1L]] +
    beta_mu[[2L]] * x +
    beta_mu[[3L]] * (f == "treated") +
    u0[ID] +
    u1[ID] * x

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      f = f,
      ID = ID
    ),
    beta_mu = beta_mu,
    sd = c(`(Intercept)` = sd0, x = sd1),
    rho_re = rho_re,
    sigma = sigma
  )
}

new_gaussian_sigma_ri_data <- function(
  n_id = 36,
  n_each = 8,
  sd_sigma_id = 0.35,
  seed = 20260539
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  f <- factor(rep(c("control", "treated"), length.out = n))
  a_id <- stats::rnorm(n_id, sd = sd_sigma_id)
  a_id <- a_id - mean(a_id)
  beta_mu <- c(`(Intercept)` = 0.2, x = 0.6, ftreated = 0.15)
  beta_sigma <- c(`(Intercept)` = log(0.5), z = 0.32)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x + beta_mu[[3L]] * (f == "treated")
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z + a_id[id])

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      f = f,
      id = id
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_sigma_id = sd_sigma_id
  )
}

new_gaussian_sigma_rs_data <- function(
  n_id = 42,
  n_each = 8,
  sd_sigma_slope = 0.38,
  seed = 20260633
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  w <- rep(seq(-1, 1, length.out = n_each), n_id) +
    stats::rnorm(n, sd = 0.08)
  a_slope <- stats::rnorm(n_id, sd = sd_sigma_slope)
  a_slope <- a_slope - mean(a_slope)
  beta_mu <- c(`(Intercept)` = 0.2, x = 0.6)
  beta_sigma <- c(`(Intercept)` = log(0.55), z = 0.24)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z + a_slope[id] * w)

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      w = w,
      id = id
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_sigma_slope = sd_sigma_slope
  )
}

new_gaussian_sigma_multi_rs_data <- function(
  n_id = 40,
  n_each = 8,
  sd_sigma = c(intercept = 0.24, w1 = 0.22, w2 = 0.16),
  seed = 20260682
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  w1 <- rep(seq(-1, 1, length.out = n_each), n_id) +
    stats::rnorm(n, sd = 0.06)
  w2 <- stats::rnorm(n)
  a0 <- stats::rnorm(n_id, sd = sd_sigma[["intercept"]])
  a1 <- stats::rnorm(n_id, sd = sd_sigma[["w1"]])
  a2 <- stats::rnorm(n_id, sd = sd_sigma[["w2"]])
  beta_mu <- c(`(Intercept)` = 0.15, x = 0.55)
  beta_sigma <- c(`(Intercept)` = log(0.55), z = 0.22)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x
  sigma <- exp(
    beta_sigma[[1L]] +
      beta_sigma[[2L]] * z +
      a0[id] +
      a1[id] * w1 +
      a2[id] * w2
  )

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      w1 = w1,
      w2 = w2,
      id = id
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_sigma = sd_sigma
  )
}

new_gaussian_mu_sigma_cov_data <- function(
  n_id = 56,
  n_each = 8,
  sd_mu_id = 0.55,
  sd_sigma_id = 0.32,
  rho_mu_sigma = 0.45,
  seed = 20260630
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u_mu_raw <- stats::rnorm(n_id)
  u_sigma_raw <- rho_mu_sigma *
    u_mu_raw +
    sqrt(1 - rho_mu_sigma^2) * stats::rnorm(n_id)
  b_mu <- sd_mu_id * u_mu_raw
  b_sigma <- sd_sigma_id * u_sigma_raw
  beta_mu <- c(`(Intercept)` = 0.25, x = 0.55)
  beta_sigma <- c(`(Intercept)` = log(0.55), z = 0.22)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x + b_mu[id]
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z + b_sigma[id])

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      id = id
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_mu_id = sd_mu_id,
    sd_sigma_id = sd_sigma_id,
    rho_mu_sigma = rho_mu_sigma
  )
}

new_gaussian_two_mu_sigma_cov_data <- function(
  n_id = 16,
  n_site = 8,
  n_rep = 3,
  sd_mu_id = 0.42,
  sd_sigma_id = 0.26,
  rho_id = 0.40,
  sd_mu_site = 0.30,
  sd_sigma_site = 0.22,
  rho_site = -0.35,
  seed = 20260683
) {
  set.seed(seed)
  dat <- expand.grid(
    id = factor(seq_len(n_id)),
    site = factor(seq_len(n_site)),
    rep = seq_len(n_rep)
  )
  n <- nrow(dat)
  dat$x <- stats::rnorm(n)
  dat$z <- stats::rnorm(n)

  raw_mu_id <- stats::rnorm(n_id)
  raw_sigma_id <- rho_id * raw_mu_id + sqrt(1 - rho_id^2) * stats::rnorm(n_id)
  raw_mu_site <- stats::rnorm(n_site)
  raw_sigma_site <- rho_site *
    raw_mu_site +
    sqrt(1 - rho_site^2) * stats::rnorm(n_site)
  beta_mu <- c(`(Intercept)` = 0.2, x = 0.50)
  beta_sigma <- c(`(Intercept)` = log(0.55), z = 0.18)
  id_index <- as.integer(dat$id)
  site_index <- as.integer(dat$site)
  mu <- beta_mu[[1L]] +
    beta_mu[[2L]] * dat$x +
    sd_mu_id * raw_mu_id[id_index] +
    sd_mu_site * raw_mu_site[site_index]
  sigma <- exp(
    beta_sigma[[1L]] +
      beta_sigma[[2L]] * dat$z +
      sd_sigma_id * raw_sigma_id[id_index] +
      sd_sigma_site * raw_sigma_site[site_index]
  )
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)

  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd = c(
      mu_id = sd_mu_id,
      sigma_id = sd_sigma_id,
      mu_site = sd_mu_site,
      sigma_site = sd_sigma_site
    ),
    rho = c(id = rho_id, site = rho_site)
  )
}

gaussian_mu_sigma_joint_nll <- function(fit, par) {
  spec <- fit$model
  re_mu <- spec$random$mu
  re_sigma <- spec$random$sigma
  re_mu_sigma <- spec$random$mu_sigma
  mu <- as.vector(spec$tmb_data$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(spec$tmb_data$X_sigma %*% par$beta_sigma)

  if (re_mu$n_re > 0L) {
    sd_mu <- exp(par$log_sd_mu)
    for (i in seq_len(length(spec$data$y))) {
      for (j in seq_len(re_mu$n_terms)) {
        idx <- re_mu$index[[i, j]]
        term <- re_mu$term_id0[[idx]] + 1L
        mu[[i]] <- mu[[i]] +
          re_mu$value[[i, j]] * sd_mu[[term]] * par$u_mu[[idx]]
      }
    }
  }

  if (re_sigma$n_re > 0L) {
    sd_sigma <- exp(par$log_sd_sigma)
    rho <- 0.999999 * tanh(par$eta_cor_mu_sigma)
    for (i in seq_len(length(spec$data$y))) {
      for (j in seq_len(re_sigma$n_terms)) {
        idx <- re_sigma$index[[i, j]]
        term <- re_sigma$term_id0[[idx]] + 1L
        u_cond <- par$u_sigma[[idx]]
        cross_cor <- re_mu_sigma$sigma_cross_cor_id0[[idx]] + 1L
        if (cross_cor > 0L) {
          mu_idx <- re_mu_sigma$sigma_cross_mu_index0[[idx]] + 1L
          u_cond <- rho[[cross_cor]] *
            par$u_mu[[mu_idx]] +
            sqrt(1 - rho[[cross_cor]]^2) * par$u_sigma[[idx]]
        }
        log_sigma[[i]] <- log_sigma[[i]] +
          re_sigma$value[[i, j]] * sd_sigma[[term]] * u_cond
      }
    }
  }

  -sum(stats::dnorm(par$u_mu, log = TRUE)) -
    sum(stats::dnorm(par$u_sigma, log = TRUE)) -
    sum(stats::dnorm(spec$data$y, mu, exp(log_sigma), log = TRUE))
}

expect_gaussian_covariance_block_registry <- function(
  registry,
  dpars,
  group,
  block,
  coefs,
  n_obs,
  coef_index = seq_along(coefs) - 1L,
  class
) {
  expect_type(registry, "list")
  expect_equal(registry$n_blocks, length(unique(registry$blocks$block_id0)))
  expect_s3_class(registry$blocks, "data.frame")
  expect_s3_class(registry$members, "data.frame")
  expect_s3_class(registry$pairs, "data.frame")

  block_row <- registry$blocks[
    registry$blocks$group == group &
      registry$blocks$block_label == block,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(block_row), 1L)
  expect_equal(block_row$level, "group")
  expect_equal(block_row$n_members, length(dpars))
  expect_equal(block_row$n_pairs, 1L)
  expect_true(block_row$implemented)

  members <- registry$members[
    registry$members$block_id0 == block_row$block_id0,
    ,
    drop = FALSE
  ]
  members <- members[order(members$member_id0), , drop = FALSE]
  expect_equal(nrow(members), length(dpars))
  expect_equal(members$component, dpars)
  expect_equal(members$dpar, dpars)
  expect_true(all(is.na(members$response_index)))
  expect_equal(members$coef, coefs)
  expect_equal(members$group, rep(group, length(dpars)))
  expect_equal(members$block_label, rep(block, length(dpars)))
  expect_false(anyNA(members$source_term_id0))
  expect_equal(members$coef_pos0, coef_index)
  expect_true(is.list(members$latent_index0))
  expect_true(is.list(members$design_value))
  expect_true(all(
    vapply(members$latent_index0, length, integer(1L)) == n_obs
  ))
  expect_true(all(
    vapply(members$design_value, length, integer(1L)) == n_obs
  ))
  expect_true(all(vapply(
    members$latent_index0,
    function(x) all(x >= 0L),
    logical(1L)
  )))
  expect_true(all(vapply(
    members$design_value,
    function(x) all(is.finite(x)),
    logical(1L)
  )))

  pairs <- registry$pairs[
    registry$pairs$block_id0 == block_row$block_id0,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(pairs), 1L)
  expect_equal(pairs$from_dpar, dpars[[1L]])
  expect_equal(pairs$to_dpar, dpars[[2L]])
  expect_equal(pairs$from_coef, coefs[[1L]])
  expect_equal(pairs$to_coef, coefs[[2L]])
  expect_equal(pairs$class, class)

  tmb <- registry$tmb_data
  block_pos <- block_row$block_id0[[1L]] + 1L
  member_start <- tmb$re_cov_block_member_start[[block_pos]]
  member_idx <- seq.int(member_start + 1L, length.out = length(dpars))
  pair_start <- tmb$re_cov_block_pair_start[[block_pos]]
  pair_idx <- pair_start + 1L

  expect_equal(tmb$n_re_cov_blocks, registry$n_blocks)
  expect_true(all(tmb$re_cov_block_size == 2L))
  expect_equal(
    length(tmb$re_cov_pair_from_member),
    sum(tmb$re_cov_block_size * (tmb$re_cov_block_size - 1L) / 2L)
  )
  expect_equal(tmb$re_cov_block_size[[block_pos]], length(dpars))
  expect_equal(tmb$re_cov_block_group_count[[block_pos]], block_row$n_groups)
  expect_equal(
    tmb$re_cov_member_component[member_idx],
    match(dpars, c("mu", "sigma")) - 1L
  )
  expect_equal(
    tmb$re_cov_member_dpar[member_idx],
    match(dpars, c("mu", "sigma", "mu1", "mu2", "sigma1", "sigma2")) - 1L
  )
  expect_equal(tmb$re_cov_member_response[member_idx], rep(-1L, length(dpars)))
  expect_equal(
    tmb$re_cov_member_source_term[member_idx],
    members$source_term_id0
  )
  expect_equal(tmb$re_cov_member_coef_pos[member_idx], members$coef_pos0)
  expect_equal(
    dim(tmb$re_cov_member_latent_index),
    c(n_obs, nrow(registry$members))
  )
  expect_equal(
    dim(tmb$re_cov_member_design_value),
    c(n_obs, nrow(registry$members))
  )
  expect_equal(tmb$re_cov_pair_from_member[[pair_idx]], pairs$from_member_id0)
  expect_equal(tmb$re_cov_pair_to_member[[pair_idx]], pairs$to_member_id0)
  expect_equal(
    tmb$re_cov_pair_parameter[[pair_idx]],
    match(
      pairs$tmb_parameter,
      c("eta_cor_mu", "eta_cor_mu_sigma", "eta_cor_sigma")
    ) -
      1L
  )
  expect_equal(
    tmb$re_cov_pair_parameter_index[[pair_idx]],
    pairs$tmb_index - 1L
  )
}

test_that("Gaussian location models support random intercepts in mu", {
  sim <- new_gaussian_ri_data()

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.18)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$beta_sigma)), 0.15)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_id), 0.25)
  expect_equal(length(fit$random_effects$mu$values), nlevels(sim$data$id))
  expect_equal(ranef(fit), fit$random_effects)
  expect_equal(ranef(fit, "mu"), fit$random_effects$mu)
  expect_snapshot(ranef(fit, "tau"), error = TRUE)
  expect_named(summary(fit)$sdpars, "mu")
  expect_equal(
    length(fit$opt$par),
    length(coef(fit, "mu")) + length(coef(fit, "sigma")) + length(fit$sdpars$mu)
  )
})

test_that("conditional predictions and residuals include mu random intercepts", {
  sim <- new_gaussian_ri_data(n_id = 24, n_each = 8, seed = 20260508)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  fixed_mu <- as.vector(stats::model.matrix(~x, sim$data) %*% coef(fit, "mu"))
  conditional_mu <- predict(fit, dpar = "mu")
  response_resid <- residuals(fit)

  expect_equal(fit$opt$convergence, 0)
  expect_gt(stats::sd(conditional_mu - fixed_mu), 0.05)
  expect_equal(stats::fitted(fit), conditional_mu, tolerance = 1e-12)
  expect_lt(
    stats::sd(sim$data$y - conditional_mu),
    stats::sd(sim$data$y - fixed_mu)
  )
  expect_equal(response_resid, sim$data$y - conditional_mu, tolerance = 1e-12)

  newdata <- data.frame(x = c(-0.2, 0.3), z = c(0, 1), id = sim$data$id[1:2])
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    as.vector(stats::model.matrix(~x, newdata) %*% coef(fit, "mu")),
    tolerance = 1e-12
  )
})

test_that("multiple Gaussian mu random-intercept terms are supported", {
  set.seed(20260509)
  n_site <- 18
  n_observer <- 9
  n <- 360
  dat <- data.frame(
    site = factor(sample(seq_len(n_site), n, replace = TRUE)),
    observer = factor(sample(seq_len(n_observer), n, replace = TRUE)),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  u_site <- stats::rnorm(n_site, sd = 0.45)
  u_observer <- stats::rnorm(n_observer, sd = 0.3)
  dat$y <- stats::rnorm(
    n,
    mean = 0.2 + 0.5 * dat$x + u_site[dat$site] + u_observer[dat$observer],
    sd = exp(-0.2 + 0.15 * dat$z)
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | site) + (1 | observer), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$mu, c("(1 | site)", "(1 | observer)"))
  expect_equal(length(fit$random_effects$mu$values), n_site + n_observer)
  expect_equal(
    length(fit$opt$par),
    length(coef(fit, "mu")) + length(coef(fit, "sigma")) + length(fit$sdpars$mu)
  )
})

test_that("Gaussian mu supports labelled random intercepts", {
  sim <- new_gaussian_ri_data(n_id = 30, n_each = 8, seed = 20260529)

  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$mu, "(1 | p | id)")
  expect_equal(length(fit$random_effects$mu$values), nlevels(sim$data$id))
  expect_equal(fit$corpars, list())
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_id), 0.25)
})

test_that("Gaussian location models support simple random slopes in mu", {
  sim <- new_gaussian_rs_data()

  fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.16)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$beta_sigma)), 0.15)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_slope), 0.25)
  expect_named(fit$sdpars$mu, "(0 + x | id)")
  expect_equal(length(fit$random_effects$mu$values), nlevels(sim$data$id))
  expect_equal(
    length(fit$opt$par),
    length(coef(fit, "mu")) + length(coef(fit, "sigma")) + length(fit$sdpars$mu)
  )
})

test_that("Gaussian mu can combine independent random intercept and slope terms", {
  set.seed(20260512)
  n_id <- 36
  n_each <- 9
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u0 <- stats::rnorm(n_id, sd = 0.55)
  u1 <- stats::rnorm(n_id, sd = 0.35)
  dat <- data.frame(
    y = stats::rnorm(
      n,
      mean = 0.1 + 0.6 * x + u0[id] + u1[id] * x,
      sd = exp(-0.25 + 0.12 * z)
    ),
    x = x,
    z = z,
    id = id
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$mu, c("(1 | id)", "(0 + x | id)"))
  expect_equal(length(fit$random_effects$mu$values), 2 * n_id)
  expect_gt(unname(fit$sdpars$mu[["(1 | id)"]]), 0.15)
  expect_gt(unname(fit$sdpars$mu[["(0 + x | id)"]]), 0.1)
})

test_that("Gaussian mu supports multiple independent random slopes", {
  set.seed(20260617)
  n_id <- 28
  n_each <- 7
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x1 <- stats::rnorm(n)
  x2 <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u1 <- stats::rnorm(n_id, sd = 0.35)
  u2 <- stats::rnorm(n_id, sd = 0.28)
  beta_mu <- c(`(Intercept)` = 0.2, x1 = 0.55, x2 = -0.35)
  beta_sigma <- c(`(Intercept)` = -0.25, z = 0.18)
  mu <- beta_mu[[1L]] +
    beta_mu[[2L]] * x1 +
    beta_mu[[3L]] * x2 +
    u1[id] * x1 +
    u2[id] * x2
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)
  dat <- data.frame(
    y = stats::rnorm(n, mean = mu, sd = sigma),
    x1 = x1,
    x2 = x2,
    z = z,
    id = id
  )

  fit <- drmTMB(
    bf(y ~ x1 + x2 + (0 + x1 | id) + (0 + x2 | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$mu, c("(0 + x1 | id)", "(0 + x2 | id)"))
  expect_equal(length(fit$random_effects$mu$values), 2 * n_id)
  expect_lt(max(abs(unname(coef(fit, "mu")) - unname(beta_mu))), 0.12)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - unname(beta_sigma))), 0.18)
  expect_gt(unname(fit$sdpars$mu[["(0 + x1 | id)"]]), 0.15)
  expect_gt(unname(fit$sdpars$mu[["(0 + x2 | id)"]]), 0.10)
  expect_equal(fit$corpars, list())
})

test_that("Gaussian mu supports q > 2 correlated random-slope blocks", {
  set.seed(20260618)
  n_id <- 30
  n_each <- 8
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x1 <- rep(seq(-1.1, 1.1, length.out = n_each), times = n_id)
  x2 <- stats::rnorm(n)
  z <- stats::rnorm(n)
  sd <- c(0.5, 0.32, 0.26)
  corr <- matrix(
    c(
      1.00,
      0.35,
      -0.20,
      0.35,
      1.00,
      0.25,
      -0.20,
      0.25,
      1.00
    ),
    nrow = 3L
  )
  latent <- matrix(stats::rnorm(n_id * 3L), ncol = 3L) %*%
    chol(diag(sd) %*% corr %*% diag(sd))
  beta_mu <- c(`(Intercept)` = 0.2, x1 = 0.55, x2 = -0.35)
  beta_sigma <- c(`(Intercept)` = -0.35, z = 0.16)
  mu <- beta_mu[[1L]] +
    beta_mu[[2L]] * x1 +
    beta_mu[[3L]] * x2 +
    latent[id, 1L] +
    latent[id, 2L] * x1 +
    latent[id, 3L] * x2
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)
  dat <- data.frame(y = stats::rnorm(n, mu, sigma), x1, x2, z, id)

  fit <- drmTMB(
    bf(y ~ x1 + x2 + (1 + x1 + x2 | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(
    fit$sdpars$mu,
    c(
      "(1 + x1 + x2 | id):(Intercept)",
      "(1 + x1 + x2 | id):x1",
      "(1 + x1 + x2 | id):x2"
    )
  )
  expect_named(
    fit$corpars$re_cov,
    c(
      "cor((Intercept),x1 | id)",
      "cor((Intercept),x2 | id)",
      "cor(x1,x2 | id)"
    )
  )
  expect_equal(fit$model$random$mu$n_re, 0L)
  expect_equal(fit$model$random$covariance_blocks$n_qgt2_blocks, 1L)
  expect_true(drmTMB:::has_mu_random_effects(fit))
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 3L)
  expect_equal(
    length(fit$random_effects$covariance_blocks$values),
    3L * n_id
  )
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    unname(fit$obj$report()$mu),
    tolerance = 1e-8
  )
  expect_gt(unname(fit$sdpars$mu[[1L]]), 0.15)
  expect_gt(unname(fit$sdpars$mu[[2L]]), 0.08)
  expect_gt(unname(fit$sdpars$mu[[3L]]), 0.06)
  pairs <- corpairs(fit)
  expect_equal(nrow(pairs), 3L)
  expect_equal(
    pairs$class,
    c("mean-slope", "mean-slope", "slope-slope")
  )
  expect_equal(summary(fit)$covariance$parameter, names(fit$corpars$re_cov))

  targets <- profile_targets(fit)
  ready_targets <- profile_targets(fit, ready_only = TRUE)
  sd_parms <- paste0("sd:mu:", names(fit$sdpars$mu))
  sd_targets <- targets[match(sd_parms, targets$parm), ]
  cor_parms <- paste0("cor:re_cov:", names(fit$corpars$re_cov))
  cor_targets <- targets[match(cor_parms, targets$parm), ]
  expect_equal(sd_targets$tmb_parameter, rep("log_sd_re_cov", 3L))
  expect_equal(sd_targets$index, 1:3)
  expect_true(all(sd_targets$profile_ready))
  expect_equal(cor_targets$tmb_parameter, rep("theta_re_cov", 3L))
  expect_equal(cor_targets$target_type, rep("derived", 3L))
  expect_false(any(cor_targets$profile_ready))
  expect_equal(
    cor_targets$profile_note,
    rep("derived_unstructured_correlation", 3L)
  )
  expect_false(any(cor_parms %in% ready_targets$parm))
})

test_that("Gaussian mu reports larger ordinary multi-slope blocks consistently", {
  set.seed(20260518)
  n_id <- 28
  n_each <- 10
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x1 <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_id)
  x2 <- rep(scale(cos(seq(0, 2 * pi, length.out = n_each)))[, 1L], times = n_id)
  x3 <- stats::rnorm(n)
  z <- stats::rnorm(n)
  sd <- c(0.38, 0.22, 0.18, 0.14)
  latent <- matrix(stats::rnorm(n_id * 4L), ncol = 4L) %*% diag(sd)
  beta_mu <- c(`(Intercept)` = 0.15, x1 = 0.45, x2 = -0.25, x3 = 0.20)
  beta_sigma <- c(`(Intercept)` = -0.55, z = 0.10)
  mu <- beta_mu[[1L]] +
    beta_mu[[2L]] * x1 +
    beta_mu[[3L]] * x2 +
    beta_mu[[4L]] * x3 +
    latent[id, 1L] +
    latent[id, 2L] * x1 +
    latent[id, 3L] * x2 +
    latent[id, 4L] * x3
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)
  dat <- data.frame(y = stats::rnorm(n, mu, sigma), x1, x2, x3, z, id)

  fit <- drmTMB(
    bf(y ~ x1 + x2 + x3 + (1 + x1 + x2 + x3 | id), sigma ~ z),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expected_sd <- c(
    "(1 + x1 + x2 + x3 | id):(Intercept)",
    "(1 + x1 + x2 + x3 | id):x1",
    "(1 + x1 + x2 + x3 | id):x2",
    "(1 + x1 + x2 + x3 | id):x3"
  )
  expected_cor <- c(
    "cor((Intercept),x1 | id)",
    "cor((Intercept),x2 | id)",
    "cor((Intercept),x3 | id)",
    "cor(x1,x2 | id)",
    "cor(x1,x3 | id)",
    "cor(x2,x3 | id)"
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$mu, expected_sd)
  expect_named(fit$corpars$re_cov, expected_cor)
  expect_equal(fit$model$random$covariance_blocks$n_qgt2_blocks, 1L)
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 4L)
  expect_equal(
    length(fit$random_effects$covariance_blocks$values),
    4L * n_id
  )
  pairs <- corpairs(fit)
  expect_equal(nrow(pairs), 6L)
  expect_equal(
    pairs$class,
    c(
      rep("mean-slope", 3L),
      rep("slope-slope", 3L)
    )
  )
  expect_equal(pairs$parameter, expected_cor)

  targets <- profile_targets(fit)
  sd_parms <- paste0("sd:mu:", expected_sd)
  cor_parms <- paste0("cor:re_cov:", expected_cor)
  sd_targets <- targets[match(sd_parms, targets$parm), ]
  cor_targets <- targets[match(cor_parms, targets$parm), ]
  expect_true(all(sd_targets$profile_ready))
  expect_equal(sd_targets$index, seq_along(expected_sd))
  expect_equal(cor_targets$target_type, rep("derived", length(expected_cor)))
  expect_false(any(cor_targets$profile_ready))
  expect_equal(
    cor_targets$profile_note,
    rep("derived_unstructured_correlation", length(expected_cor))
  )
})

test_that("Gaussian mu supports correlated random intercept-slope blocks", {
  sim <- new_gaussian_corr_rs_data()

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.18)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$beta_sigma)), 0.16)
  expect_equal(length(fit$random_effects$mu$values), 2 * nlevels(sim$data$id))
  expect_named(
    fit$sdpars$mu,
    c("(1 + x | id):(Intercept)", "(1 + x | id):x")
  )
  expect_named(fit$corpars$mu, "cor((Intercept),x | id)")
  expect_lt(max(abs(unname(fit$sdpars$mu) - unname(sim$sd))), 0.25)
  expect_lt(abs(unname(fit$corpars$mu) - sim$rho_re), 0.3)
  expect_false(any(grepl("rho12", names(fit$corpars$mu), fixed = TRUE)))
})

test_that("labelled Gaussian mu correlated blocks match unlabelled block semantics", {
  sim <- new_gaussian_labelled_corr_rs_data()

  fit_labelled <- drmTMB(
    bf(y ~ x + f + (1 + x | p | ID)),
    family = gaussian(),
    data = sim$data
  )
  fit_unlabelled <- drmTMB(
    bf(y ~ x + f + (1 + x | ID)),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit_labelled$opt$convergence, 0)
  expect_equal(fit_unlabelled$opt$convergence, 0)
  expect_equal(
    unname(coef(fit_labelled, "mu")),
    unname(coef(fit_unlabelled, "mu")),
    tolerance = 1e-6
  )
  expect_equal(
    stats::sigma(fit_labelled),
    stats::sigma(fit_unlabelled),
    tolerance = 1e-6
  )
  expect_equal(
    unname(fit_labelled$sdpars$mu),
    unname(fit_unlabelled$sdpars$mu),
    tolerance = 1e-6
  )
  expect_equal(
    unname(fit_labelled$corpars$mu),
    unname(fit_unlabelled$corpars$mu),
    tolerance = 1e-6
  )
  expect_equal(
    as.numeric(stats::logLik(fit_labelled)),
    as.numeric(stats::logLik(fit_unlabelled)),
    tolerance = 1e-6
  )
  expect_named(
    fit_labelled$sdpars$mu,
    c("(1 + x | p | ID):(Intercept)", "(1 + x | p | ID):x")
  )
  expect_named(fit_labelled$corpars$mu, "cor((Intercept),x | p | ID)")
  pairs <- corpairs(fit_labelled)
  location_slope_pairs <- corpairs(fit_labelled, class = "location-slope")
  expect_equal(nrow(pairs), 1L)
  expect_equal(pairs$level, "group")
  expect_equal(pairs$group, "ID")
  expect_equal(pairs$block, "p")
  expect_equal(pairs$from_dpar, "mu")
  expect_equal(pairs$to_dpar, "mu")
  expect_equal(pairs$from_coef, "(Intercept)")
  expect_equal(pairs$to_coef, "x")
  expect_equal(pairs$class, "mean-slope")
  expect_equal(pairs$parameter, "cor((Intercept),x | p | ID)")
  expect_equal(pairs, location_slope_pairs)
  expect_gaussian_covariance_block_registry(
    fit_labelled$model$random$covariance_blocks,
    dpars = c("mu", "mu"),
    group = "ID",
    block = "p",
    coefs = c("(Intercept)", "x"),
    n_obs = fit_labelled$nobs,
    class = "mean-slope"
  )
  expect_covariance_block_tmb_data_exported(fit_labelled)
  expect_false(any(grepl(
    "rho12",
    names(fit_labelled$corpars$mu),
    fixed = TRUE
  )))
})

test_that("labelled Gaussian mu correlated blocks recover moderate covariance parameters", {
  sim <- new_gaussian_labelled_corr_rs_data(
    n_id = 34,
    n_each = 8,
    sd0 = 0.55,
    sd1 = 0.35,
    rho_re = 0.45,
    sigma = 0.45,
    seed = 20260531
  )

  fit <- drmTMB(
    bf(y ~ x + f + (1 + x | p | ID)),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - unname(sim$beta_mu))), 0.22)
  expect_lt(abs(stats::sigma(fit)[[1L]] - sim$sigma), 0.12)
  expect_lt(max(abs(unname(fit$sdpars$mu) - unname(sim$sd))), 0.25)
  expect_lt(abs(unname(fit$corpars$mu) - sim$rho_re), 0.35)
})

test_that("labelled Gaussian mu correlated blocks handle near-zero and high correlations", {
  cases <- list(
    near_zero = list(rho = 0.02, seed = 20260532),
    high_pos = list(rho = 0.8, seed = 20260533),
    high_neg = list(rho = -0.8, seed = 20260534)
  )

  for (case in cases) {
    sim <- new_gaussian_labelled_corr_rs_data(
      n_id = 28,
      n_each = 7,
      sd0 = 0.6,
      sd1 = 0.4,
      rho_re = case$rho,
      seed = case$seed
    )

    fit <- drmTMB(
      bf(y ~ x + (1 + x | p | ID)),
      family = gaussian(),
      data = sim$data
    )
    cor_est <- unname(fit$corpars$mu)

    expect_equal(fit$opt$convergence, 0)
    expect_true(all(is.finite(c(fit$sdpars$mu, cor_est))))
    expect_lt(abs(cor_est), 1)
    if (abs(case$rho) < 0.1) {
      expect_lt(abs(cor_est), 0.35)
    } else {
      expect_equal(sign(cor_est), sign(case$rho))
    }
  }
})

test_that("labelled correlated blocks remain stable with small and large residual sigma", {
  cases <- list(
    small = list(sigma = 0.08, tol = 0.07, seed = 20260535),
    large = list(sigma = 1.4, tol = 0.40, seed = 20260536)
  )

  for (case in cases) {
    sim <- new_gaussian_labelled_corr_rs_data(
      n_id = 30,
      n_each = 8,
      sigma = case$sigma,
      seed = case$seed
    )

    fit <- drmTMB(
      bf(y ~ x + (1 + x | p | ID)),
      family = gaussian(),
      data = sim$data
    )

    expect_equal(fit$opt$convergence, 0)
    expect_true(all(is.finite(c(fit$sdpars$mu, fit$corpars$mu))))
    expect_lt(abs(stats::sigma(fit)[[1L]] - case$sigma), case$tol)
  }
})

test_that("labelled correlated-block variables participate in missingness", {
  sim <- new_gaussian_labelled_corr_rs_data(
    n_id = 12,
    n_each = 5,
    seed = 20260537
  )
  dat <- sim$data
  dat$y[2] <- NA_real_
  dat$x[5] <- NA_real_
  dat$f[7] <- NA
  dat$ID[11] <- NA
  keep <- stats::complete.cases(dat[c("y", "x", "f", "ID")])

  fit <- drmTMB(
    bf(y ~ x + f + (1 + x | p | ID)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_false(anyNA(fit$data[c("y", "x", "f", "ID")]))
})

test_that("Gaussian sigma supports residual-scale random intercepts", {
  sim <- new_gaussian_sigma_ri_data()

  fit <- drmTMB(
    bf(y ~ x + f, sigma ~ z + (1 | id)),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(length(fit$random_effects$sigma$values), nlevels(sim$data$id))
  expect_named(fit$sdpars$sigma, "(1 | id)")
  expect_lt(max(abs(unname(coef(fit, "mu")) - unname(sim$beta_mu))), 0.18)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - unname(sim$beta_sigma))), 0.22)
  expect_lt(abs(unname(fit$sdpars$sigma) - sim$sd_sigma_id), 0.30)
  expect_true(all(stats::sigma(fit) > 0))
  expect_false(any(grepl("rho12", names(fit$sdpars$sigma), fixed = TRUE)))
})

test_that("Gaussian sigma supports independent residual-scale random slopes", {
  sim <- new_gaussian_sigma_rs_data()

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z + (0 + w | id)),
    family = gaussian(),
    data = sim$data,
    control = list(eval.max = 500, iter.max = 500)
  )
  fixed_sigma <- as.vector(
    fit$model$tmb_data$X_sigma %*% coef(fit, "sigma")
  )
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  contribution <- drmTMB:::sigma_random_effect_contribution(fit)

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$sigma, "(0 + w | id)")
  expect_equal(length(fit$random_effects$sigma$values), nlevels(sim$data$id))
  expect_gt(stats::sd(contribution), 0.03)
  expect_equal(sigma_link, fixed_sigma + contribution, tolerance = 1e-10)
  expect_equal(stats::sigma(fit), exp(sigma_link), tolerance = 1e-10)
})

test_that("Gaussian sigma supports multiple independent residual-scale terms", {
  sim <- new_gaussian_sigma_multi_rs_data()

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z + (1 | id) + (0 + w1 | id) + (0 + w2 | id)),
    family = gaussian(),
    data = sim$data,
    control = list(eval.max = 500, iter.max = 500)
  )
  fixed_sigma <- as.vector(
    fit$model$tmb_data$X_sigma %*% coef(fit, "sigma")
  )
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  contribution <- drmTMB:::sigma_random_effect_contribution(fit)
  targets <- profile_targets(fit)
  sigma_sd_parms <- paste0("sd:sigma:", names(fit$sdpars$sigma))
  sigma_sd_targets <- targets[match(sigma_sd_parms, targets$parm), ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$random$sigma$n_cors, 0L)
  expect_false("sigma" %in% names(fit$corpars))
  expect_named(
    fit$sdpars$sigma,
    c("(1 | id)", "(0 + w1 | id)", "(0 + w2 | id)")
  )
  expect_equal(
    length(fit$random_effects$sigma$values),
    nlevels(sim$data$id) * 3L
  )
  expect_true(all(is.finite(unname(fit$sdpars$sigma))))
  expect_true(all(unname(fit$sdpars$sigma) > 0))
  expect_gt(stats::sd(contribution), 0.04)
  expect_equal(sigma_link, fixed_sigma + contribution, tolerance = 1e-10)
  expect_equal(sigma_sd_targets$tmb_parameter, rep("log_sd_sigma", 3L))
  expect_equal(sigma_sd_targets$index, 1:3)
  expect_true(all(sigma_sd_targets$profile_ready))
  expect_false(any(grepl("^cor:sigma:", targets$parm)))
})

test_that("Gaussian sigma random intercepts handle boundary and large scale heterogeneity", {
  cases <- list(
    near_zero = list(sd_sigma_id = 0.06, max_est = 0.30, seed = 20260540),
    large = list(sd_sigma_id = 0.85, max_abs = 0.50, seed = 20260541)
  )

  for (case in cases) {
    sim <- new_gaussian_sigma_ri_data(
      n_id = 32,
      n_each = 9,
      sd_sigma_id = case$sd_sigma_id,
      seed = case$seed
    )

    fit <- drmTMB(
      bf(y ~ x, sigma ~ z + (1 | id)),
      family = gaussian(),
      data = sim$data
    )

    expect_equal(fit$opt$convergence, 0)
    expect_true(all(is.finite(c(fit$sdpars$sigma, coef(fit, "sigma")))))
    expect_true(all(stats::sigma(fit) > 0))
    if (!is.null(case$max_est)) {
      expect_lt(unname(fit$sdpars$sigma), case$max_est)
    } else {
      expect_lt(abs(unname(fit$sdpars$sigma) - case$sd_sigma_id), case$max_abs)
    }
  }
})

test_that("Gaussian sigma random intercepts participate in missingness", {
  sim <- new_gaussian_sigma_ri_data(n_id = 12, n_each = 5, seed = 20260542)
  dat <- sim$data
  dat$y[2] <- NA_real_
  dat$x[5] <- NA_real_
  dat$z[7] <- NA_real_
  dat$f[9] <- NA
  dat$id[11] <- NA
  keep <- stats::complete.cases(dat[c("y", "x", "z", "f", "id")])

  fit <- drmTMB(
    bf(y ~ x + f, sigma ~ z + (1 | id)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_false(anyNA(fit$data[c("y", "x", "z", "f", "id")]))
})

test_that("Gaussian mu and sigma random intercepts can coexist independently", {
  sim <- new_gaussian_ri_data(
    n_id = 30,
    n_each = 8,
    sd_id = 0.55,
    seed = 20260543
  )
  dat <- sim$data
  log_sigma_group <- stats::rnorm(nlevels(dat$id), sd = 0.3)
  dat$y <- stats::rnorm(
    nrow(dat),
    mean = sim$beta_mu[[1L]] + sim$beta_mu[[2L]] * dat$x,
    sd = exp(
      sim$beta_sigma[[1L]] +
        sim$beta_sigma[[2L]] * dat$z +
        log_sigma_group[dat$id]
    )
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z + (1 | id)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars, c("mu", "sigma"))
  expect_named(fit$sdpars$mu, "(1 | id)")
  expect_named(fit$sdpars$sigma, "(1 | id)")
  expect_equal(length(fit$random_effects$mu$values), nlevels(dat$id))
  expect_equal(length(fit$random_effects$sigma$values), nlevels(dat$id))
  expect_equal(ranef(fit, "sigma"), fit$random_effects$sigma)
  expect_true(all(stats::sigma(fit) > 0))
})

test_that("Gaussian mu/sigma labelled random-intercept covariance is fitted", {
  sim <- new_gaussian_mu_sigma_cov_data()

  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
    family = gaussian(),
    data = sim$data
  )
  pairs <- corpairs(fit)
  targets <- profile_targets(fit)
  mean_scale <- pairs[pairs$class == "mean-scale", , drop = FALSE]

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$mu, "(1 | p | id)")
  expect_named(fit$sdpars$sigma, "(1 | p | id)")
  expect_named(
    fit$corpars$mu_sigma,
    "cor(mu:(Intercept),sigma:(Intercept) | p | id)"
  )
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_mu_id), 0.25)
  expect_lt(abs(unname(fit$sdpars$sigma) - sim$sd_sigma_id), 0.22)
  expect_lt(abs(unname(fit$corpars$mu_sigma) - sim$rho_mu_sigma), 0.35)
  expect_equal(length(fit$random_effects$mu$values), nlevels(sim$data$id))
  expect_equal(length(fit$random_effects$sigma$values), nlevels(sim$data$id))
  expect_gt(
    stats::sd(
      predict(fit, dpar = "sigma", type = "link") -
        as.vector(stats::model.matrix(~z, sim$data) %*% coef(fit, "sigma"))
    ),
    0.03
  )
  expect_equal(nrow(mean_scale), 1L)
  expect_equal(mean_scale$level, "group")
  expect_equal(mean_scale$group, "id")
  expect_equal(mean_scale$block, "p")
  expect_equal(mean_scale$from_dpar, "mu")
  expect_equal(mean_scale$to_dpar, "sigma")
  expect_equal(mean_scale$from_response, "y")
  expect_equal(mean_scale$to_response, "y")
  expect_equal(
    mean_scale$estimate,
    unname(fit$corpars$mu_sigma),
    tolerance = 1e-12
  )
  fit_registry <- fit
  names(fit_registry$corpars$mu_sigma) <- "cor(bad,bad | wrong | wrong)"
  registry_mean_scale <- corpairs(fit_registry)
  expect_equal(registry_mean_scale$group, "id")
  expect_equal(registry_mean_scale$block, "p")
  expect_equal(registry_mean_scale$from_dpar, "mu")
  expect_equal(registry_mean_scale$to_dpar, "sigma")
  expect_equal(
    registry_mean_scale$parameter,
    "cor(mu:(Intercept),sigma:(Intercept) | p | id)"
  )
  expect_equal(
    registry_mean_scale$estimate,
    unname(fit$corpars$mu_sigma),
    tolerance = 1e-12
  )
  expect_gaussian_covariance_block_registry(
    fit$model$random$covariance_blocks,
    dpars = c("mu", "sigma"),
    group = "id",
    block = "p",
    coefs = c("(Intercept)", "(Intercept)"),
    n_obs = fit$nobs,
    coef_index = c(0L, 0L),
    class = "mean-scale"
  )
  expect_covariance_block_tmb_data_exported(fit)
  expect_true(
    "cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)" %in%
      targets$parm
  )
})

test_that("Gaussian mu/sigma supports two independent matched covariance blocks", {
  sim <- new_gaussian_two_mu_sigma_cov_data()

  fit <- drmTMB(
    bf(
      y ~ x + (1 | p | id) + (1 | q | site),
      sigma ~ z + (1 | p | id) + (1 | q | site)
    ),
    family = gaussian(),
    data = sim$data,
    control = list(eval.max = 600, iter.max = 600)
  )
  pairs <- corpairs(fit, class = "mean-scale")
  smry <- summary(fit)
  targets <- profile_targets(fit)
  cor_parms <- paste0("cor:mu_sigma:", names(fit$corpars$mu_sigma))
  cor_targets <- targets[match(cor_parms, targets$parm), ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$random$mu_sigma$n_cors, 2L)
  expect_equal(fit$model$tmb_data$n_mu_sigma_re_cors, 2L)
  expect_named(fit$sdpars$mu, c("(1 | p | id)", "(1 | q | site)"))
  expect_named(fit$sdpars$sigma, c("(1 | p | id)", "(1 | q | site)"))
  expect_named(
    fit$corpars$mu_sigma,
    c(
      "cor(mu:(Intercept),sigma:(Intercept) | p | id)",
      "cor(mu:(Intercept),sigma:(Intercept) | q | site)"
    )
  )
  expect_equal(nrow(pairs), 2L)
  expect_equal(smry$covariance$parameter, names(fit$corpars$mu_sigma))
  expect_equal(pairs$group, c("id", "site"))
  expect_equal(pairs$block, c("p", "q"))
  expect_equal(pairs$estimate, unname(fit$corpars$mu_sigma), tolerance = 1e-12)
  expect_equal(
    sort(unique(fit$model$random$mu_sigma$sigma_cross_cor_id0[
      fit$model$random$mu_sigma$sigma_cross_cor_id0 >= 0L
    ])),
    0:1
  )
  expect_equal(cor_targets$tmb_parameter, rep("eta_cor_mu_sigma", 2L))
  expect_equal(cor_targets$index, 1:2)
  expect_equal(cor_targets$target_type, rep("direct", 2L))
  expect_true(all(cor_targets$profile_ready))
})

test_that("Gaussian mu/sigma covariance maps only the labelled sigma block", {
  sim <- new_gaussian_mu_sigma_cov_data(n_id = 14, n_each = 5)
  dat <- sim$data
  dat$site <- factor(rep(seq_len(7), length.out = nrow(dat)))

  spec <- drmTMB:::drm_build_gaussian_ls_spec(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | site) + (1 | p | id)),
    data = dat,
    env = environment(),
    weights = NULL
  )
  sigma_labels <- spec$random$sigma$labels[spec$random$sigma$term_id0 + 1L]
  labelled <- sigma_labels == "(1 | p | id)"

  expect_true(any(labelled))
  expect_true(any(!labelled))
  expect_true(all(spec$random$mu_sigma$sigma_cross_cor_id0[!labelled] == -1L))
  expect_true(all(spec$random$mu_sigma$sigma_cross_mu_index0[!labelled] == -1L))
  expect_equal(unique(spec$random$mu_sigma$sigma_cross_cor_id0[labelled]), 0L)
  expect_equal(
    spec$tmb_data$sigma_re_cross_cor,
    spec$random$mu_sigma$sigma_cross_cor_id0
  )
  expect_equal(
    spec$tmb_data$sigma_re_cross_mu,
    spec$random$mu_sigma$sigma_cross_mu_index0
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | site) + (1 | p | id)),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(
    fit$corpars$mu_sigma,
    "cor(mu:(Intercept),sigma:(Intercept) | p | id)"
  )
  expect_equal(length(fit$sdpars$sigma), 2L)
})

test_that("Gaussian mu/sigma covariance transforms only matched sigma effects", {
  sim <- new_gaussian_mu_sigma_cov_data(n_id = 4, n_each = 3)
  dat <- sim$data
  dat$site <- factor(rep(seq_len(3), length.out = nrow(dat)))
  spec <- drmTMB:::drm_build_gaussian_ls_spec(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | site) + (1 | p | id)),
    data = dat,
    env = environment(),
    weights = NULL
  )

  re_sigma <- spec$random$sigma
  re_mu_sigma <- spec$random$mu_sigma
  rho <- 0.4
  par <- list(
    u_mu = seq(-0.8, 0.7, length.out = spec$random$mu$n_re),
    u_sigma = seq(0.9, -0.6, length.out = re_sigma$n_re),
    log_sd_sigma = log(c(0.25, 0.55)),
    eta_cor_mu_sigma = atanh(rho / 0.999999)
  )

  actual <- drmTMB:::transform_sigma_random_effects(
    latent = par$u_sigma,
    par = par,
    re_sigma = re_sigma,
    re_mu_sigma = re_mu_sigma
  )
  sigma_sd <- exp(par$log_sd_sigma[re_sigma$term_id0 + 1L])
  expected <- sigma_sd * par$u_sigma
  matched <- which(re_mu_sigma$sigma_cross_cor_id0 >= 0L)
  unmatched <- which(re_mu_sigma$sigma_cross_cor_id0 < 0L)
  mu_idx <- re_mu_sigma$sigma_cross_mu_index0[matched] + 1L
  expected[matched] <- sigma_sd[matched] *
    (rho * par$u_mu[mu_idx] + sqrt(1 - rho^2) * par$u_sigma[matched])

  expect_length(matched, nlevels(dat$id))
  expect_length(unmatched, nlevels(dat$site))
  expect_equal(actual, expected)
  expect_equal(
    actual[unmatched],
    sigma_sd[unmatched] * par$u_sigma[unmatched]
  )
})

test_that("Gaussian mu/sigma covariance joint objective matches R nll", {
  sim <- new_gaussian_mu_sigma_cov_data(n_id = 12, n_each = 5, seed = 20260631)
  dat <- sim$data
  dat$site <- factor(rep(seq_len(6), length.out = nrow(dat)))
  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | site) + (1 | p | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )
  par <- split(
    unname(fit$obj$env$last.par.best),
    names(fit$obj$env$last.par.best)
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    fit$obj$env$f(fit$obj$env$last.par.best),
    gaussian_mu_sigma_joint_nll(fit, par),
    tolerance = 1e-8
  )
})

test_that("Gaussian mu/sigma covariance contributes to sigma predictions", {
  sim <- new_gaussian_mu_sigma_cov_data(n_id = 12, n_each = 5, seed = 20260632)
  dat <- sim$data
  dat$site <- factor(rep(seq_len(6), length.out = nrow(dat)))
  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | site) + (1 | p | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )
  re_sigma <- fit$model$random$sigma
  contribution <- drmTMB:::sigma_random_effect_contribution(fit)
  manual <- rowSums(
    matrix(
      fit$random_effects$sigma$values[re_sigma$index],
      nrow = nrow(re_sigma$index)
    ) *
      re_sigma$value
  )
  fixed_sigma <- as.vector(
    fit$model$tmb_data$X_sigma %*% coef(fit, "sigma")
  )
  sigma_link <- predict(fit, dpar = "sigma", type = "link")

  expect_equal(fit$opt$convergence, 0)
  expect_equal(contribution, manual)
  expect_equal(sigma_link, fixed_sigma + contribution, tolerance = 1e-10)
  expect_equal(stats::sigma(fit), exp(sigma_link), tolerance = 1e-10)
})

test_that("labelled sigma covariance needs a matching labelled mu intercept", {
  sim <- new_gaussian_mu_sigma_cov_data(n_id = 8, n_each = 3)

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ z + (1 | p | id)),
      family = gaussian(),
      data = sim$data
    ),
    "matching labelled"
  )

  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | p | id), sigma ~ z + (1 | p | id)),
      family = gaussian(),
      data = sim$data
    ),
    "intercept-only"
  )
})

test_that("Gaussian mu correlated blocks handle near-zero and negative correlations", {
  cases <- list(
    near_zero = list(rho = 0.02, seed = 20260516),
    negative = list(rho = -0.5, seed = 20260517)
  )

  for (case in cases) {
    sim <- new_gaussian_corr_rs_data(
      n_id = 32,
      n_each = 7,
      rho_re = case$rho,
      seed = case$seed
    )

    fit <- drmTMB(
      bf(y ~ x + (1 + x | id), sigma ~ z),
      family = gaussian(),
      data = sim$data
    )

    cor_est <- unname(fit$corpars$mu)
    expect_equal(fit$opt$convergence, 0)
    expect_true(all(is.finite(fit$sdpars$mu)))
    expect_true(all(is.finite(cor_est)))
    expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.22)
    if (case$rho > -0.1) {
      expect_lt(abs(cor_est), 0.35)
    } else {
      expect_lt(cor_est, -0.15)
      expect_lt(abs(cor_est - case$rho), 0.35)
    }
  }
})

test_that("Gaussian mu correlated blocks remain finite near high correlations", {
  cases <- list(
    positive = list(rho = 0.8, seed = 20260518),
    negative = list(rho = -0.8, seed = 20260519)
  )

  for (case in cases) {
    sim <- new_gaussian_corr_rs_data(
      n_id = 28,
      n_each = 7,
      sd0 = 0.6,
      sd1 = 0.4,
      rho_re = case$rho,
      seed = case$seed
    )

    fit <- drmTMB(
      bf(y ~ x + (1 + x | id), sigma ~ z),
      family = gaussian(),
      data = sim$data
    )

    cor_est <- unname(fit$corpars$mu)
    expect_equal(fit$opt$convergence, 0)
    expect_true(all(is.finite(c(fit$sdpars$mu, cor_est))))
    expect_lt(abs(cor_est), 1)
    expect_equal(sign(cor_est), sign(case$rho))
    expect_true(all(unname(fit$sdpars$mu) > 0))
    expect_true(all(unname(fit$sdpars$mu) < 2))
  }
})

test_that("Gaussian mu correlated blocks handle weak random-slope SDs", {
  sim <- new_gaussian_corr_rs_data(
    sd0 = 0.55,
    sd1 = 0.06,
    rho_re = 0.3,
    seed = 20260520
  )

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ z),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(abs(unname(fit$sdpars$mu[[1L]]) - sim$sd[[1L]]), 0.3)
  expect_true(is.finite(unname(fit$sdpars$mu[[2L]])))
  expect_lt(unname(fit$sdpars$mu[[2L]]), 0.3)
  expect_true(is.finite(unname(fit$corpars$mu)))
  expect_lt(abs(unname(fit$corpars$mu)), 1)
})

test_that("Gaussian mu correlated blocks support factor fixed predictors", {
  sim <- new_gaussian_corr_rs_data(n_id = 32, n_each = 8, seed = 20260522)
  dat <- sim$data
  dat$f <- factor(rep(c("control", "treated"), length.out = nrow(dat)))
  dat$y <- dat$y + ifelse(dat$f == "treated", 0.25, 0)

  fit <- drmTMB(
    bf(y ~ x + f + (1 + x | id), sigma ~ z + f),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true("ftreated" %in% names(coef(fit, "mu")))
  expect_true("ftreated" %in% names(coef(fit, "sigma")))
  expect_true(all(is.finite(c(coef(fit, "mu"), coef(fit, "sigma")))))
  expect_true(all(is.finite(c(fit$sdpars$mu, fit$corpars$mu))))
  expect_lt(abs(unname(fit$corpars$mu)), 1)
})

test_that("correlated random-block variables participate in missingness", {
  sim <- new_gaussian_corr_rs_data(n_id = 12, n_each = 5, seed = 20260523)
  dat <- sim$data
  dat$y[2] <- NA_real_
  dat$x[5] <- NA_real_
  dat$z[7] <- NA_real_
  dat$id[11] <- NA
  keep <- stats::complete.cases(dat[c("y", "x", "z", "id")])

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_false(anyNA(fit$data[c("y", "x", "z", "id")]))
})

test_that("random-slope variables participate in missingness", {
  sim <- new_gaussian_rs_data(n_id = 12, n_each = 5, seed = 20260513)
  dat <- sim$data
  dat$y[2] <- NA_real_
  dat$x[5] <- NA_real_
  dat$z[7] <- NA_real_
  dat$id[11] <- NA
  keep <- stats::complete.cases(dat[c("y", "x", "z", "id")])

  fit <- drmTMB(
    bf(y ~ 1 + (0 + x | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_false(anyNA(fit$data[c("y", "x", "z", "id")]))
})

test_that("random-intercept grouping variables participate in missingness", {
  sim <- new_gaussian_ri_data(n_id = 10, n_each = 4, seed = 20260510)
  dat <- sim$data
  dat$y[2] <- NA_real_
  dat$x[5] <- NA_real_
  dat$z[7] <- NA_real_
  dat$id[11] <- NA
  keep <- stats::complete.cases(dat[c("y", "x", "z", "id")])

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_false(anyNA(fit$data[c("y", "x", "z", "id")]))
})

test_that("unsupported random-effect cases fail clearly", {
  dat <- data.frame(
    y = stats::rnorm(20),
    y2 = stats::rnorm(20),
    x = stats::rnorm(20),
    id = factor(rep("one", 20))
  )

  expect_error(
    drmTMB(bf(y ~ x + (1 | id)), family = gaussian(), data = dat),
    "fewer than two levels"
  )
  dat$id <- factor(rep(seq_len(4), each = 5))
  dat$single <- factor(seq_len(nrow(dat)))
  expect_error(
    drmTMB(bf(y ~ x + (1 | single)), family = gaussian(), data = dat),
    "only singleton groups"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y ~ x + (1 | id), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "covariance-block labels"
  )
  expect_error(
    drmTMB(bf(y ~ x + (0 + x + y2 | id)), family = gaussian(), data = dat),
    "ordinary Gaussian location block"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | id) + (0 + x | id)),
      family = gaussian(),
      data = dat
    ),
    "Overlapping random-effect terms"
  )
  dat$group_label <- factor(rep(letters[1:2], length.out = nrow(dat)))
  expect_error(
    drmTMB(bf(y ~ x + (0 + group_label | id)), family = gaussian(), data = dat),
    "must be numeric"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + group_label | p | id)),
      family = gaussian(),
      data = dat
    ),
    "must be numeric"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (0 + x + y2 | p | id)),
      family = gaussian(),
      data = dat
    ),
    "ordinary Gaussian location block"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | p | id) + (0 + x | id)),
      family = gaussian(),
      data = dat
    ),
    "Overlapping random-effect terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | p | id) + (1 + x | q | id)),
      family = gaussian(),
      data = dat
    ),
    "Overlapping random-effect terms"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 + x | 1 | id)), family = gaussian(), data = dat),
    "covariance-block labels"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 + x | rho12 | id)), family = gaussian(), data = dat),
    "reserved distributional parameter"
  )
  expect_no_error(
    drmTMB(bf(y ~ x, sigma ~ (0 + x | id)), family = gaussian(), data = dat)
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ (1 + x | id)), family = gaussian(), data = dat),
    "Only independent residual-scale random slopes"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ (0 + x | p | id)),
      family = gaussian(),
      data = dat
    ),
    "Labelled residual-scale random-slope covariance blocks"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ (0 + group_label | id)),
      family = gaussian(),
      data = dat
    ),
    "must be numeric"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ (1 | p | id)), family = gaussian(), data = dat),
    "matching labelled"
  )
})
