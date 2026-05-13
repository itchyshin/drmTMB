new_covariance_registry_re <- function(dpars, labels) {
  n_obs <- 4L
  group_levels <- c("g1", "g2")
  n_groups <- length(group_levels)
  n_terms <- length(dpars)
  group_index0 <- c(0L, 0L, 1L, 1L)

  groups <- rep(list(group_levels), n_terms)
  names(groups) <- labels

  list(
    n_terms = n_terms,
    n_re = n_terms * n_groups,
    index0 = matrix(rep(group_index0, n_terms), nrow = n_obs),
    value = matrix(1, nrow = n_obs, ncol = n_terms),
    term_id0 = rep(seq_len(n_terms) - 1L, each = n_groups),
    dpar_id0 = rep(seq_len(n_terms) - 1L, each = n_groups),
    re_pos0 = rep(0L, n_terms * n_groups),
    re_cor_id0 = rep(-1L, n_terms * n_groups),
    re_pair_index0 = rep(-1L, n_terms * n_groups),
    labels = labels,
    dpars = dpars,
    coef_names = rep("(Intercept)", n_terms),
    group_names = rep("id", n_terms),
    covariance_labels = rep("p", n_terms),
    groups = groups
  )
}

new_three_member_covariance_registry <- function() {
  re_mu <- new_covariance_registry_re(
    dpars = c("mu1", "mu2"),
    labels = c("mu1:(1 | p | id)", "mu2:(1 | p | id)")
  )
  re_sigma <- new_covariance_registry_re(
    dpars = "sigma1",
    labels = "sigma1:(1 | p | id)"
  )
  registry <- drmTMB:::empty_labelled_covariance_block_registry()
  registry <- drmTMB:::append_covariance_registry_block(
    registry,
    re_list = list(re_mu, re_sigma),
    member_terms = list(seq_len(re_mu$n_terms), seq_len(re_sigma$n_terms)),
    parameter = c("scaffold:12", "scaffold:13", "scaffold:23"),
    tmb_parameter = rep(NA_character_, 3L),
    tmb_index = rep(NA_integer_, 3L),
    implemented = FALSE
  )
  registry$n_blocks <- nrow(registry$blocks)
  registry
}

tmb_unstructured_corr_matrix <- function(theta) {
  q <- (1 + sqrt(1 + 8 * length(theta))) / 2
  stopifnot(q == as.integer(q))
  L <- diag(as.integer(q))
  L[lower.tri(L)] <- theta
  stats::cov2cor(L %*% t(L))
}

tmb_vecscale_sqrt_cov_scale <- function(theta, sd, z) {
  corr <- tmb_unstructured_corr_matrix(theta)
  as.vector(sd * (t(chol(corr)) %*% z))
}

test_that("internal covariance registry can describe a guarded q=3 block", {
  registry <- new_three_member_covariance_registry()
  block <- registry$blocks[1L, , drop = FALSE]
  members <- registry$members[
    order(registry$members$member_id0),
    ,
    drop = FALSE
  ]
  pairs <- registry$pairs[order(registry$pairs$pair_id0), , drop = FALSE]

  expect_equal(registry$n_blocks, 1L)
  expect_equal(block$n_members, 3L)
  expect_equal(block$n_pairs, 3L)
  expect_false(block$implemented)
  expect_equal(block$group, "id")
  expect_equal(block$block_label, "p")
  expect_equal(block$group_levels[[1L]], c("g1", "g2"))
  expect_equal(members$member_id0, 0:2)
  expect_equal(members$dpar, c("mu1", "mu2", "sigma1"))
  expect_equal(members$component, c("mu", "mu", "sigma"))
  expect_equal(members$response_index, c(1L, 2L, 1L))
  expect_equal(members$coef, rep("(Intercept)", 3L))
  expect_true(all(
    vapply(members$latent_index0, length, integer(1L)) == 4L
  ))
  expect_true(all(
    vapply(members$design_value, function(x) all(is.finite(x)), logical(1L))
  ))

  expect_equal(pairs$pair_id0, 0:2)
  expect_equal(pairs$from_member_id0, c(0L, 0L, 1L))
  expect_equal(pairs$to_member_id0, c(1L, 2L, 2L))
  expect_equal(pairs$from_dpar, c("mu1", "mu1", "mu2"))
  expect_equal(pairs$to_dpar, c("mu2", "sigma1", "sigma1"))
  expect_equal(pairs$class, c("mean-mean", "mean-scale", "mean-scale"))
  expect_equal(pairs$parameter, c("scaffold:12", "scaffold:13", "scaffold:23"))
  expect_true(all(is.na(pairs$tmb_parameter)))
  expect_true(all(is.na(pairs$tmb_index)))
})

test_that("q=3 block TMB data remains guarded until parameterization exists", {
  registry <- new_three_member_covariance_registry()

  expect_error(
    drmTMB:::labelled_covariance_block_tmb_data(registry),
    "two-member|q > 2"
  )
})

test_that("ordinary fits keep hidden q=3 probe parameter mapped off", {
  dat <- data.frame(y = c(-0.3, 0.2, 0.8, -0.1, 0.4, 0.9))
  fit <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat)

  expect_equal(fit$model$start$u_re_cov_probe, 0)
  expect_true(all(is.na(fit$model$map$u_re_cov_probe)))
  expect_false("u_re_cov_probe" %in% names(fit$opt$par))
})

test_that("mapped-off q=3 probe parameter is a no-op for ordinary fits", {
  dat <- data.frame(y = c(-0.3, 0.2, 0.8, -0.1, 0.4, 0.9))
  fit <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat)
  parameters <- fit$model$start
  parameters$u_re_cov_probe <- 7

  obj <- TMB::MakeADFun(
    data = fit$model$tmb_data,
    parameters = parameters,
    map = fit$model$map,
    random = fit$model$random_names,
    DLL = "drmTMB",
    silent = TRUE
  )

  expect_equal(names(obj$par), names(fit$opt$par))
  expect_equal(obj$fn(fit$opt$par), fit$obj$fn(fit$opt$par), tolerance = 1e-12)
  expect_equal(obj$gr(fit$opt$par), fit$obj$gr(fit$opt$par), tolerance = 1e-12)
})

test_that("hidden q=3 registry probe maps non-centered blocks by group", {
  dat <- data.frame(y = c(-0.3, 0.2, 0.8, -0.1, 0.4, 0.9))
  fit <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat)
  registry <- new_three_member_covariance_registry()
  cov_tmb <- drmTMB:::labelled_covariance_block_tmb_data(
    registry,
    allow_unimplemented = TRUE
  )
  tmb_data <- fit$model$tmb_data
  tmb_data[names(cov_tmb)] <- cov_tmb
  theta <- c(0.2, -0.4, 0.3)
  sd <- c(1.2, 0.8, 1.5)
  z <- c(-0.7, 0.4, 1.1, 0.2, -1.0, 0.5)
  tmb_data$model_type <- 97L
  tmb_data$re_cov_probe_theta <- theta
  tmb_data$re_cov_probe_sd <- sd
  tmb_data$re_cov_probe_z <- numeric(0)
  parameters <- fit$model$start
  parameters$u_re_cov_probe <- z
  map <- fit$model$map
  map$u_re_cov_probe <- NULL

  obj <- TMB::MakeADFun(
    data = tmb_data,
    parameters = parameters,
    map = map,
    random = fit$model$random_names,
    DLL = "drmTMB",
    silent = TRUE
  )

  latent_g1 <- tmb_vecscale_sqrt_cov_scale(theta, sd, z[1:3])
  latent_g2 <- tmb_vecscale_sqrt_cov_scale(theta, sd, z[4:6])
  expected <- unname(rbind(latent_g1, latent_g1, latent_g2, latent_g2))

  expect_equal(cov_tmb$re_cov_block_size, 3L)
  expect_equal(cov_tmb$re_cov_pair_parameter, rep(-1L, 3))
  expect_equal(cov_tmb$re_cov_pair_parameter_index, rep(-1L, 3))
  expect_equal(
    obj$report()$re_cov_probe_contribution,
    expected,
    tolerance = 1e-12
  )
  expect_equal(
    obj$fn(obj$par),
    sum(-stats::dnorm(z, log = TRUE)),
    tolerance = 1e-10
  )
  expect_true(is.finite(obj$fn(obj$par)))
  expect_true(all(is.finite(obj$gr(obj$par))))
})

test_that("hidden q=3 registry probe can use TMB random effects", {
  dat <- data.frame(y = c(-0.3, 0.2, 0.8, -0.1, 0.4, 0.9))
  fit <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat)
  registry <- new_three_member_covariance_registry()
  cov_tmb <- drmTMB:::labelled_covariance_block_tmb_data(
    registry,
    allow_unimplemented = TRUE
  )
  tmb_data <- fit$model$tmb_data
  tmb_data[names(cov_tmb)] <- cov_tmb
  z <- c(-0.7, 0.4, 1.1, 0.2, -1.0, 0.5)
  tmb_data$model_type <- 97L
  tmb_data$re_cov_probe_theta <- c(0.2, -0.4, 0.3)
  tmb_data$re_cov_probe_sd <- c(1.2, 0.8, 1.5)
  tmb_data$re_cov_probe_z <- numeric(0)
  parameters <- fit$model$start
  parameters$u_re_cov_probe <- z
  map <- fit$model$map
  map$u_re_cov_probe <- NULL

  obj <- TMB::MakeADFun(
    data = tmb_data,
    parameters = parameters,
    map = map,
    random = c(fit$model$random_names, "u_re_cov_probe"),
    DLL = "drmTMB",
    silent = TRUE
  )
  nll <- as.numeric(obj$fn(obj$par))
  grad <- obj$gr(obj$par)
  random <- obj$env$random

  expect_equal(names(obj$par), names(fit$opt$par))
  expect_equal(names(obj$env$par)[random], rep("u_re_cov_probe", length(z)))
  expect_equal(unname(obj$env$last.par.best[random]), rep(0, length(z)))
  expect_equal(
    obj$report()$re_cov_probe_contribution,
    matrix(0, nrow = 4, ncol = 3),
    tolerance = 1e-12
  )
  expect_equal(nll, 0, tolerance = 1e-8)
  expect_equal(grad, rep(0, length(obj$par)), tolerance = 1e-8)
})

test_that("hidden q=3 registry probe can enter Gaussian likelihood", {
  dat <- data.frame(y = c(-0.3, 0.2, 0.8, -0.1))
  fit <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat)
  registry <- new_three_member_covariance_registry()
  cov_tmb <- drmTMB:::labelled_covariance_block_tmb_data(
    registry,
    allow_unimplemented = TRUE
  )
  tmb_data <- fit$model$tmb_data
  tmb_data[names(cov_tmb)] <- cov_tmb
  theta <- c(0.2, -0.4, 0.3)
  sd <- c(1.2, 0.8, 1.5)
  z <- c(-0.7, 0.4, 1.1, 0.2, -1.0, 0.5)
  tmb_data$model_type <- 96L
  tmb_data$re_cov_probe_theta <- theta
  tmb_data$re_cov_probe_sd <- sd
  tmb_data$re_cov_probe_z <- numeric(0)
  parameters <- fit$model$start
  parameters$u_re_cov_probe <- z
  map <- fit$model$map
  map$u_re_cov_probe <- NULL

  obj <- TMB::MakeADFun(
    data = tmb_data,
    parameters = parameters,
    map = map,
    random = fit$model$random_names,
    DLL = "drmTMB",
    silent = TRUE
  )

  latent_g1 <- tmb_vecscale_sqrt_cov_scale(theta, sd, z[1:3])
  latent_g2 <- tmb_vecscale_sqrt_cov_scale(theta, sd, z[4:6])
  contribution <- unname(rbind(latent_g1, latent_g1, latent_g2, latent_g2))
  mu <- unname(
    drop(tmb_data$X_mu %*% parameters$beta_mu) +
      contribution[, 1] +
      contribution[, 2]
  )
  log_sigma <- unname(
    drop(tmb_data$X_sigma %*% parameters$beta_sigma) + contribution[, 3]
  )
  obs_sigma <- sqrt(tmb_data$V_known + exp(log_sigma)^2)
  expected_nll <- sum(-stats::dnorm(z, log = TRUE)) +
    sum(-tmb_data$weights * stats::dnorm(dat$y, mu, obs_sigma, log = TRUE))

  report <- obj$report()
  expect_equal(
    report$re_cov_probe_contribution,
    contribution,
    tolerance = 1e-12
  )
  expect_equal(report$mu, mu, tolerance = 1e-12)
  expect_equal(report$log_sigma, log_sigma, tolerance = 1e-12)
  expect_equal(report$obs_sigma, obs_sigma, tolerance = 1e-12)
  expect_equal(obj$fn(obj$par), expected_nll, tolerance = 1e-10)
  expect_true(is.finite(obj$fn(obj$par)))
  expect_true(all(is.finite(obj$gr(obj$par))))
})

test_that("TMB q=3 covariance prototype produces positive-definite correlations", {
  dat <- data.frame(y = c(-0.3, 0.2, 0.8, -0.1, 0.4, 0.9))
  fit <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat)
  tmb_data <- fit$model$tmb_data
  theta <- c(0.2, -0.4, 0.3)
  tmb_data$model_type <- 98L
  tmb_data$re_cov_probe_theta <- theta
  tmb_data$re_cov_probe_sd <- c(1.2, 0.8, 1.5)
  tmb_data$re_cov_probe_x <- c(0.1, -0.2, 0.3)
  tmb_data$re_cov_probe_z <- c(-0.7, 0.4, 1.1)

  obj <- TMB::MakeADFun(
    data = tmb_data,
    parameters = fit$model$start,
    map = fit$model$map,
    random = fit$model$random_names,
    DLL = "drmTMB",
    silent = TRUE
  )

  corr <- obj$report()$re_cov_probe_corr
  latent <- obj$report()$re_cov_probe_latent
  eig <- eigen(corr, symmetric = TRUE, only.values = TRUE)$values

  expect_equal(corr, t(corr), tolerance = 1e-12)
  expect_equal(diag(corr), rep(1, 3), tolerance = 1e-12)
  expect_equal(corr, tmb_unstructured_corr_matrix(theta), tolerance = 1e-12)
  expect_equal(
    latent,
    tmb_vecscale_sqrt_cov_scale(
      theta,
      tmb_data$re_cov_probe_sd,
      tmb_data$re_cov_probe_z
    ),
    tolerance = 1e-12
  )
  expect_true(all(eig > 0))
  expect_true(is.finite(obj$fn(obj$par)))
  expect_true(all(is.finite(obj$gr(obj$par))))
})
