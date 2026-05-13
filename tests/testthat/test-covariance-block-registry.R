new_covariance_registry_re <- function(
  dpars,
  labels,
  group_index0 = c(0L, 0L, 1L, 1L),
  group_levels = NULL,
  value = NULL,
  coef_names = NULL
) {
  n_obs <- length(group_index0)
  if (is.null(group_levels)) {
    group_levels <- paste0("g", seq_len(max(group_index0) + 1L))
  }
  n_groups <- length(group_levels)
  n_terms <- length(dpars)
  if (is.null(value)) {
    value <- matrix(1, nrow = n_obs, ncol = n_terms)
  }
  if (is.null(coef_names)) {
    coef_names <- rep("(Intercept)", n_terms)
  }

  groups <- rep(list(group_levels), n_terms)
  names(groups) <- labels

  list(
    n_terms = n_terms,
    n_re = n_terms * n_groups,
    index0 = matrix(rep(group_index0, n_terms), nrow = n_obs),
    value = value,
    term_id0 = rep(seq_len(n_terms) - 1L, each = n_groups),
    dpar_id0 = rep(seq_len(n_terms) - 1L, each = n_groups),
    re_pos0 = rep(0L, n_terms * n_groups),
    re_cor_id0 = rep(-1L, n_terms * n_groups),
    re_pair_index0 = rep(-1L, n_terms * n_groups),
    labels = labels,
    dpars = dpars,
    coef_names = coef_names,
    group_names = rep("id", n_terms),
    covariance_labels = rep("p", n_terms),
    groups = groups
  )
}

new_three_member_covariance_registry <- function(
  group_index0 = c(0L, 0L, 1L, 1L),
  group_levels = NULL,
  value = NULL,
  coef_names = NULL
) {
  n_obs <- length(group_index0)
  if (is.null(value)) {
    value <- matrix(1, nrow = n_obs, ncol = 3L)
  }
  if (is.null(coef_names)) {
    coef_names <- rep("(Intercept)", 3L)
  }
  re_mu <- new_covariance_registry_re(
    dpars = c("mu1", "mu2"),
    labels = c("mu1:(1 | p | id)", "mu2:(1 | p | id)"),
    group_index0 = group_index0,
    group_levels = group_levels,
    value = value[, 1:2, drop = FALSE],
    coef_names = coef_names[1:2]
  )
  re_sigma <- new_covariance_registry_re(
    dpars = "sigma1",
    labels = "sigma1:(1 | p | id)",
    group_index0 = group_index0,
    group_levels = group_levels,
    value = value[, 3, drop = FALSE],
    coef_names = coef_names[3]
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

new_four_member_covariance_registry <- function(
  group_index0 = c(0L, 0L, 1L, 1L),
  group_levels = NULL,
  value = NULL,
  coef_names = NULL
) {
  n_obs <- length(group_index0)
  if (is.null(value)) {
    value <- matrix(1, nrow = n_obs, ncol = 4L)
  }
  if (is.null(coef_names)) {
    coef_names <- rep("(Intercept)", 4L)
  }
  re_mu <- new_covariance_registry_re(
    dpars = c("mu1", "mu2"),
    labels = c("mu1:(1 | p | id)", "mu2:(1 | p | id)"),
    group_index0 = group_index0,
    group_levels = group_levels,
    value = value[, 1:2, drop = FALSE],
    coef_names = coef_names[1:2]
  )
  re_sigma <- new_covariance_registry_re(
    dpars = c("sigma1", "sigma2"),
    labels = c("sigma1:(1 | p | id)", "sigma2:(1 | p | id)"),
    group_index0 = group_index0,
    group_levels = group_levels,
    value = value[, 3:4, drop = FALSE],
    coef_names = coef_names[3:4]
  )
  registry <- drmTMB:::empty_labelled_covariance_block_registry()
  registry <- drmTMB:::append_covariance_registry_block(
    registry,
    re_list = list(re_mu, re_sigma),
    member_terms = list(seq_len(re_mu$n_terms), seq_len(re_sigma$n_terms)),
    parameter = paste0("scaffold:", c("12", "13", "14", "23", "24", "34")),
    tmb_parameter = rep(NA_character_, 6L),
    tmb_index = rep(NA_integer_, 6L),
    implemented = FALSE
  )
  registry$n_blocks <- nrow(registry$blocks)
  registry
}

tmb_unstructured_corr_matrix <- function(theta) {
  q <- (1 + sqrt(1 + 8 * length(theta))) / 2
  stopifnot(q == as.integer(q))
  L <- diag(as.integer(q))
  # TMB fills the strict lower triangle row-wise for q > 3.
  lower <- which(lower.tri(L), arr.ind = TRUE)
  lower <- lower[order(lower[, "row"], lower[, "col"]), , drop = FALSE]
  L[lower] <- theta
  stats::cov2cor(L %*% t(L))
}

tmb_vecscale_sqrt_cov_scale <- function(theta, sd, z) {
  corr <- tmb_unstructured_corr_matrix(theta)
  as.vector(sd * (t(chol(corr)) %*% z))
}

biv_gaussian_nll <- function(
  y1,
  y2,
  mu1,
  mu2,
  log_sigma1,
  log_sigma2,
  rho12,
  weights = rep(1, length(y1))
) {
  sigma1 <- exp(log_sigma1)
  sigma2 <- exp(log_sigma2)
  z1 <- (y1 - mu1) / sigma1
  z2 <- (y2 - mu2) / sigma2
  one_minus_rho2 <- 1 - rho12^2
  row_nll <- log(2 * pi) +
    log_sigma1 +
    log_sigma2 +
    0.5 * log(one_minus_rho2) +
    0.5 * (z1^2 - 2 * rho12 * z1 * z2 + z2^2) / one_minus_rho2
  sum(weights * row_nll)
}

rmse <- function(x, y) sqrt(mean((x - y)^2))

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

test_that("internal covariance registry can describe a guarded q=4 endpoint block", {
  registry <- new_four_member_covariance_registry()
  block <- registry$blocks[1L, , drop = FALSE]
  members <- registry$members[
    order(registry$members$member_id0),
    ,
    drop = FALSE
  ]
  pairs <- registry$pairs[order(registry$pairs$pair_id0), , drop = FALSE]

  expect_equal(registry$n_blocks, 1L)
  expect_equal(block$n_members, 4L)
  expect_equal(block$n_pairs, 6L)
  expect_false(block$implemented)
  expect_equal(block$group, "id")
  expect_equal(block$block_label, "p")
  expect_equal(block$group_levels[[1L]], c("g1", "g2"))
  expect_equal(members$member_id0, 0:3)
  expect_equal(members$dpar, c("mu1", "mu2", "sigma1", "sigma2"))
  expect_equal(members$component, c("mu", "mu", "sigma", "sigma"))
  expect_equal(members$response_index, c(1L, 2L, 1L, 2L))
  expect_equal(members$coef, rep("(Intercept)", 4L))

  expect_equal(pairs$pair_id0, 0:5)
  expect_equal(pairs$from_member_id0, c(0L, 0L, 0L, 1L, 1L, 2L))
  expect_equal(pairs$to_member_id0, c(1L, 2L, 3L, 2L, 3L, 3L))
  expect_equal(
    pairs$from_dpar,
    c("mu1", "mu1", "mu1", "mu2", "mu2", "sigma1")
  )
  expect_equal(
    pairs$to_dpar,
    c("mu2", "sigma1", "sigma2", "sigma1", "sigma2", "sigma2")
  )
  expect_equal(
    pairs$class,
    c(
      "mean-mean",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "scale-scale"
    )
  )
  expect_equal(
    pairs$parameter,
    paste0("scaffold:", c("12", "13", "14", "23", "24", "34"))
  )
  expect_true(all(is.na(pairs$tmb_parameter)))
  expect_true(all(is.na(pairs$tmb_index)))
})

test_that("corpairs can format fitted-like q=4 endpoint registry rows", {
  dat <- data.frame(
    y1 = c(-0.3, 0.1, 0.4, 0.8, -0.1, 0.6),
    y2 = c(0.2, -0.2, 0.5, 0.7, 0.1, 0.4)
  )
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ 1,
      mu2 = y2 ~ 1,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat
  )
  registry <- new_four_member_covariance_registry(
    group_index0 = c(0L, 0L, 1L, 1L, 2L, 2L),
    group_levels = paste0("g", 1:3)
  )
  pair_labels <- c(
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)",
    "cor(mu1:(Intercept),sigma1:(Intercept) | p | id)",
    "cor(mu1:(Intercept),sigma2:(Intercept) | p | id)",
    "cor(mu2:(Intercept),sigma1:(Intercept) | p | id)",
    "cor(mu2:(Intercept),sigma2:(Intercept) | p | id)",
    "cor(sigma1:(Intercept),sigma2:(Intercept) | p | id)"
  )
  estimates <- c(0.12, -0.21, 0.16, 0.08, -0.14, 0.27)
  registry$blocks$implemented <- TRUE
  registry$pairs$parameter <- pair_labels
  registry$pairs$tmb_parameter <- c(
    "eta_cor_mu",
    rep("eta_cor_mu_sigma", 4L),
    "eta_cor_sigma"
  )
  registry$pairs$tmb_index <- c(1L, 1L, 2L, 3L, 4L, 1L)
  fit_q4 <- fit
  fit_q4$model$random$covariance_blocks <- registry
  fit_q4$corpars <- list(
    mu = stats::setNames(estimates[[1L]], pair_labels[[1L]]),
    mu_sigma = stats::setNames(estimates[2:5], pair_labels[2:5]),
    sigma = stats::setNames(estimates[[6L]], pair_labels[[6L]])
  )
  sd_values <- c(mu1 = 0.4, mu2 = 0.5, sigma1 = 0.2, sigma2 = 0.3)
  fit_q4$sdpars <- list(
    mu = stats::setNames(
      sd_values[c("mu1", "mu2")],
      registry$members$label[registry$members$component == "mu"]
    ),
    sigma = stats::setNames(
      sd_values[c("sigma1", "sigma2")],
      registry$members$label[registry$members$component == "sigma"]
    )
  )

  pairs <- corpairs(fit_q4, level = "group")
  covariance_summaries <- drmTMB:::random_effect_covariance_summaries(fit_q4)
  correlation_targets <- paste0(
    "cor:",
    c("mu", rep("mu_sigma", 4L), "sigma"),
    ":",
    pair_labels
  )
  sd_targets <- c(
    paste0("sd:mu:", names(fit_q4$sdpars$mu)),
    paste0("sd:sigma:", names(fit_q4$sdpars$sigma))
  )
  interval_table <- data.frame(
    parm = c(correlation_targets, sd_targets),
    lower = c(
      estimates - 0.05,
      unname(c(fit_q4$sdpars$mu, fit_q4$sdpars$sigma)) - 0.02
    ),
    upper = c(
      estimates + 0.05,
      unname(c(fit_q4$sdpars$mu, fit_q4$sdpars$sigma)) + 0.02
    ),
    method = "profile",
    stringsAsFactors = FALSE
  )
  covariance_summaries_ci <- drmTMB:::random_effect_covariance_summaries(
    fit_q4,
    intervals = interval_table
  )

  expect_equal(nrow(pairs), 6L)
  expect_equal(pairs$group, rep("id", 6L))
  expect_equal(pairs$block, rep("p", 6L))
  expect_equal(
    pairs$from_dpar,
    c("mu1", "mu1", "mu1", "mu2", "mu2", "sigma1")
  )
  expect_equal(
    pairs$to_dpar,
    c("mu2", "sigma1", "sigma2", "sigma1", "sigma2", "sigma2")
  )
  expect_equal(
    pairs$class,
    c(
      "mean-mean",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "scale-scale"
    )
  )
  expect_equal(pairs$parameter, pair_labels)
  expect_equal(pairs$estimate, estimates, tolerance = 1e-12)
  expect_equal(
    pairs$link_estimate,
    atanh(estimates / 0.999999),
    tolerance = 1e-12
  )
  expect_equal(nrow(corpairs(fit_q4, class = "mean-scale")), 4L)
  expect_equal(nrow(corpairs(fit_q4, class = "mean-mean")), 1L)
  expect_equal(nrow(corpairs(fit_q4, class = "scale-scale")), 1L)
  expect_equal(nrow(corpairs(fit_q4, group = "missing")), 0L)
  expect_equal(nrow(covariance_summaries), 6L)
  expect_equal(covariance_summaries$parameter, pair_labels)
  expect_equal(covariance_summaries$correlation, estimates, tolerance = 1e-12)
  expect_equal(
    covariance_summaries$from_sd,
    unname(sd_values[c("mu1", "mu1", "mu1", "mu2", "mu2", "sigma1")]),
    tolerance = 1e-12
  )
  expect_equal(
    covariance_summaries$to_sd,
    unname(sd_values[c(
      "mu2",
      "sigma1",
      "sigma2",
      "sigma1",
      "sigma2",
      "sigma2"
    )]),
    tolerance = 1e-12
  )
  expect_equal(
    covariance_summaries$from_variance,
    covariance_summaries$from_sd^2,
    tolerance = 1e-12
  )
  expect_equal(
    covariance_summaries$to_variance,
    covariance_summaries$to_sd^2,
    tolerance = 1e-12
  )
  expect_equal(
    covariance_summaries$covariance,
    covariance_summaries$correlation *
      covariance_summaries$from_sd *
      covariance_summaries$to_sd,
    tolerance = 1e-12
  )
  expect_equal(
    covariance_summaries$from_scale,
    c("identity", "identity", "identity", "identity", "identity", "log")
  )
  expect_equal(
    covariance_summaries$to_scale,
    c("identity", "log", "log", "log", "log", "log")
  )
  expect_equal(covariance_summaries$correlation_target, correlation_targets)
  expect_equal(
    covariance_summaries$covariance_conf.status,
    rep("not_requested", 6L)
  )
  expect_equal(
    covariance_summaries$from_sd_target,
    sd_targets[c(1L, 1L, 1L, 2L, 2L, 3L)]
  )
  expect_equal(
    covariance_summaries$to_sd_target,
    sd_targets[c(2L, 3L, 4L, 3L, 4L, 4L)]
  )
  expect_true(all(is.na(covariance_summaries$correlation_conf.low)))
  expect_equal(
    covariance_summaries_ci$correlation_conf.low,
    estimates - 0.05,
    tolerance = 1e-12
  )
  expect_equal(
    covariance_summaries_ci$from_sd_conf.low,
    interval_table$lower[match(
      covariance_summaries_ci$from_sd_target,
      interval_table$parm
    )],
    tolerance = 1e-12
  )
  expect_equal(
    covariance_summaries_ci$to_sd_conf.high,
    interval_table$upper[match(
      covariance_summaries_ci$to_sd_target,
      interval_table$parm
    )],
    tolerance = 1e-12
  )
  expect_equal(
    covariance_summaries_ci$correlation_conf.method,
    rep("profile", 6L)
  )
  expect_true(all(is.na(covariance_summaries_ci$covariance_conf.low)))
  expect_true(all(is.na(covariance_summaries_ci$covariance_conf.method)))
  expect_equal(
    covariance_summaries_ci$covariance_conf.status,
    rep("derived_interval_unavailable", 6L)
  )

  fit_dormant <- fit
  fit_dormant$model$random$covariance_blocks <-
    new_four_member_covariance_registry()
  expect_equal(nrow(corpairs(fit_dormant, level = "group")), 0L)
  expect_equal(
    nrow(drmTMB:::random_effect_covariance_summaries(fit_dormant)),
    0L
  )

  registry_mixed <- new_four_member_covariance_registry()
  registry_mixed$blocks$implemented <- TRUE
  registry_mixed$pairs$parameter[[1L]] <- pair_labels[[1L]]
  registry_mixed$pairs$tmb_parameter[[1L]] <- "eta_cor_mu"
  registry_mixed$pairs$tmb_index[[1L]] <- 1L
  fit_mixed <- fit
  fit_mixed$model$random$covariance_blocks <- registry_mixed
  fit_mixed$corpars <- list(
    mu = stats::setNames(estimates[[1L]], pair_labels[[1L]])
  )
  fit_mixed$sdpars <- fit_q4$sdpars
  mixed_pairs <- corpairs(fit_mixed, level = "group")
  mixed_summaries <- drmTMB:::random_effect_covariance_summaries(fit_mixed)
  expect_equal(nrow(mixed_pairs), 1L)
  expect_equal(mixed_pairs$parameter, pair_labels[[1L]])
  expect_equal(mixed_pairs$estimate, estimates[[1L]], tolerance = 1e-12)
  expect_equal(nrow(mixed_summaries), 1L)
  expect_equal(mixed_summaries$parameter, pair_labels[[1L]])
  expect_equal(mixed_summaries$covariance, 0.12 * 0.4 * 0.5, tolerance = 1e-12)
  expect_equal(mixed_summaries$covariance_conf.status, "not_requested")
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

test_that("hidden q=4 registry probe maps full endpoint block by group", {
  dat <- data.frame(y = c(-0.3, 0.2, 0.8, -0.1, 0.4, 0.9))
  fit <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat)
  group_index0 <- c(0L, 0L, 1L, 1L, 2L, 2L)
  value <- cbind(
    1,
    c(-0.4, 0.6, -0.2, 0.8, -0.7, 0.3),
    1,
    c(0.5, -0.5, 0.7, -0.3, 0.2, -0.8)
  )
  registry <- new_four_member_covariance_registry(
    group_index0 = group_index0,
    group_levels = paste0("g", 1:3),
    value = value,
    coef_names = c("(Intercept)", "x", "(Intercept)", "z")
  )
  cov_tmb <- drmTMB:::labelled_covariance_block_tmb_data(
    registry,
    allow_unimplemented = TRUE
  )
  tmb_data <- fit$model$tmb_data
  tmb_data[names(cov_tmb)] <- cov_tmb
  theta <- c(0.15, -0.25, 0.10, 0.20, -0.15, 0.30)
  sd <- c(1.1, 0.7, 1.3, 0.9)
  z <- c(
    -0.7,
    0.4,
    1.1,
    -0.2,
    0.2,
    -1.0,
    0.5,
    0.8,
    -0.4,
    0.9,
    -0.6,
    0.3
  )
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

  z_by_group <- matrix(z, ncol = 4L, byrow = TRUE)
  latent <- t(apply(
    z_by_group,
    1L,
    tmb_vecscale_sqrt_cov_scale,
    theta = theta,
    sd = sd
  ))
  expected <- value * latent[group_index0 + 1L, ]
  corr <- obj$report()$re_cov_probe_corr
  eig <- eigen(corr, symmetric = TRUE, only.values = TRUE)$values

  expect_equal(cov_tmb$re_cov_block_size, 4L)
  expect_equal(cov_tmb$re_cov_pair_parameter, rep(-1L, 6))
  expect_equal(cov_tmb$re_cov_pair_parameter_index, rep(-1L, 6))
  expect_equal(corr, t(corr), tolerance = 1e-12)
  expect_equal(diag(corr), rep(1, 4), tolerance = 1e-12)
  expect_true(all(eig > 0))
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

test_that("hidden q=4 registry bridge feeds bivariate Gaussian likelihood", {
  dat <- data.frame(
    y1 = c(-0.25, 0.15, 0.65, -0.35, 0.45, 0.85),
    y2 = c(0.10, -0.20, 0.40, 0.30, -0.15, 0.55)
  )
  group_index0 <- c(0L, 0L, 1L, 1L, 2L, 2L)
  value <- cbind(
    1,
    c(-0.30, 0.45, -0.10, 0.55, -0.40, 0.25),
    1,
    c(0.35, -0.25, 0.50, -0.20, 0.15, -0.45)
  )
  form <- bf(
    mu1 = y1 ~ 1,
    mu2 = y2 ~ 1,
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  spec <- drmTMB:::drm_build_biv_gaussian_spec(
    form,
    data = dat,
    env = environment(),
    weights = NULL
  )
  registry <- new_four_member_covariance_registry(
    group_index0 = group_index0,
    group_levels = paste0("g", 1:3),
    value = value
  )
  cov_tmb <- drmTMB:::labelled_covariance_block_tmb_data(
    registry,
    allow_unimplemented = TRUE
  )
  tmb_data <- spec$tmb_data
  tmb_data[names(cov_tmb)] <- cov_tmb
  theta <- c(0.12, -0.20, 0.08, 0.18, -0.14, 0.26)
  sd <- c(0.50, 0.35, 0.25, 0.30)
  z <- c(
    -0.70,
    0.40,
    1.10,
    -0.20,
    0.20,
    -1.00,
    0.50,
    0.80,
    -0.40,
    0.90,
    -0.60,
    0.30
  )
  parameters <- spec$start
  parameters$beta_mu1 <- 0.15
  parameters$beta_mu2 <- -0.10
  parameters$beta_sigma1 <- log(0.55)
  parameters$beta_sigma2 <- log(0.70)
  parameters$beta_rho12 <- atanh(0.18)
  parameters$u_re_cov_probe <- z
  map <- spec$map
  map$u_re_cov_probe <- NULL
  tmb_data$model_type <- 95L
  tmb_data$re_cov_probe_theta <- theta
  tmb_data$re_cov_probe_sd <- sd
  tmb_data$re_cov_probe_z <- numeric(0)

  obj <- TMB::MakeADFun(
    data = tmb_data,
    parameters = parameters,
    map = map,
    random = spec$random_names,
    DLL = "drmTMB",
    silent = TRUE
  )

  z_by_group <- matrix(z, ncol = 4L, byrow = TRUE)
  latent <- t(apply(
    z_by_group,
    1L,
    tmb_vecscale_sqrt_cov_scale,
    theta = theta,
    sd = sd
  ))
  contribution <- value * latent[group_index0 + 1L, ]
  mu1 <- as.vector(tmb_data$X_mu1 %*% parameters$beta_mu1) +
    contribution[, 1L]
  mu2 <- as.vector(tmb_data$X_mu2 %*% parameters$beta_mu2) +
    contribution[, 2L]
  log_sigma1 <- as.vector(tmb_data$X_sigma1 %*% parameters$beta_sigma1) +
    contribution[, 3L]
  log_sigma2 <- as.vector(tmb_data$X_sigma2 %*% parameters$beta_sigma2) +
    contribution[, 4L]
  rho12 <- 0.99999999 *
    tanh(
      as.vector(tmb_data$X_rho12 %*% parameters$beta_rho12)
    )
  expected_nll <- sum(-stats::dnorm(z, log = TRUE)) +
    biv_gaussian_nll(
      y1 = dat$y1,
      y2 = dat$y2,
      mu1 = mu1,
      mu2 = mu2,
      log_sigma1 = log_sigma1,
      log_sigma2 = log_sigma2,
      rho12 = rho12,
      weights = tmb_data$weights
    )
  report <- obj$report()

  expect_equal(
    report$re_cov_probe_contribution,
    contribution,
    tolerance = 1e-12
  )
  expect_equal(report$mu1, mu1, tolerance = 1e-12)
  expect_equal(report$mu2, mu2, tolerance = 1e-12)
  expect_equal(report$log_sigma1, log_sigma1, tolerance = 1e-12)
  expect_equal(report$log_sigma2, log_sigma2, tolerance = 1e-12)
  expect_equal(report$sigma1, exp(log_sigma1), tolerance = 1e-12)
  expect_equal(report$sigma2, exp(log_sigma2), tolerance = 1e-12)
  expect_equal(report$rho12, rho12, tolerance = 1e-12)
  expect_equal(obj$fn(obj$par), expected_nll, tolerance = 1e-10)
  expect_true(is.finite(obj$fn(obj$par)))
  expect_true(all(is.finite(obj$gr(obj$par))))
})

test_that("hidden q=4 bivariate likelihood can use TMB random effects", {
  n_groups <- 3L
  n_each <- 5L
  group_index0 <- rep(seq_len(n_groups) - 1L, each = n_each)
  x <- rep(seq(-0.8, 0.8, length.out = n_each), times = n_groups)
  z_sigma <- rep(c(-0.6, -0.2, 0.2, 0.6, 0.0), times = n_groups)
  value <- cbind(1, x, 1, z_sigma)
  theta <- c(0.12, -0.20, 0.08, 0.18, -0.14, 0.26)
  sd <- c(0.55, 0.40, 0.30, 0.35)
  true_z <- c(
    -0.70,
    0.40,
    1.10,
    -0.20,
    0.20,
    -1.00,
    0.50,
    0.80,
    -0.40,
    0.90,
    -0.60,
    0.30
  )
  latent <- t(apply(
    matrix(true_z, ncol = 4L, byrow = TRUE),
    1L,
    tmb_vecscale_sqrt_cov_scale,
    theta = theta,
    sd = sd
  ))
  group <- group_index0 + 1L
  contribution <- value * latent[group, ]
  beta_mu1 <- 0.10
  beta_mu2 <- -0.05
  beta_sigma1 <- log(0.20)
  beta_sigma2 <- log(0.24)
  beta_rho12 <- atanh(0.16)
  mu1 <- beta_mu1 + contribution[, 1L]
  mu2 <- beta_mu2 + contribution[, 2L]
  log_sigma1 <- beta_sigma1 + contribution[, 3L]
  log_sigma2 <- beta_sigma2 + contribution[, 4L]
  eps1 <- rep(c(-1.2, -0.3, 0.4, 1.1, 0.0), times = n_groups)
  eps2_raw <- rep(c(0.7, -0.8, 0.2, -0.1, 1.0), times = n_groups)
  rho <- tanh(beta_rho12)
  eps2 <- rho * eps1 + sqrt(1 - rho^2) * eps2_raw
  dat <- data.frame(
    y1 = mu1 + exp(log_sigma1) * eps1,
    y2 = mu2 + exp(log_sigma2) * eps2
  )
  form <- bf(
    mu1 = y1 ~ 1,
    mu2 = y2 ~ 1,
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  spec <- drmTMB:::drm_build_biv_gaussian_spec(
    form,
    data = dat,
    env = environment(),
    weights = NULL
  )
  registry <- new_four_member_covariance_registry(
    group_index0 = group_index0,
    group_levels = paste0("g", seq_len(n_groups)),
    value = value,
    coef_names = c("(Intercept)", "x", "(Intercept)", "z_sigma")
  )
  cov_tmb <- drmTMB:::labelled_covariance_block_tmb_data(
    registry,
    allow_unimplemented = TRUE
  )
  tmb_data <- spec$tmb_data
  tmb_data[names(cov_tmb)] <- cov_tmb
  tmb_data$model_type <- 95L
  tmb_data$re_cov_probe_theta <- theta
  tmb_data$re_cov_probe_sd <- sd
  tmb_data$re_cov_probe_z <- numeric(0)
  parameters <- spec$start
  parameters$beta_mu1 <- beta_mu1
  parameters$beta_mu2 <- beta_mu2
  parameters$beta_sigma1 <- beta_sigma1
  parameters$beta_sigma2 <- beta_sigma2
  parameters$beta_rho12 <- beta_rho12
  parameters$u_re_cov_probe <- rep(0, length(true_z))
  map <- spec$map
  map$u_re_cov_probe <- NULL

  obj <- TMB::MakeADFun(
    data = tmb_data,
    parameters = parameters,
    map = map,
    random = c(spec$random_names, "u_re_cov_probe"),
    DLL = "drmTMB",
    silent = TRUE
  )
  nll <- as.numeric(obj$fn(obj$par))
  grad <- obj$gr(obj$par)
  random <- obj$env$random
  mode <- unname(obj$env$last.par.best[random])
  mode_latent <- t(apply(
    matrix(mode, ncol = 4L, byrow = TRUE),
    1L,
    tmb_vecscale_sqrt_cov_scale,
    theta = theta,
    sd = sd
  ))
  mode_contribution <- unname(value * mode_latent[group, ])
  mode_mu1 <- unname(
    as.vector(tmb_data$X_mu1 %*% parameters$beta_mu1) +
      mode_contribution[, 1L]
  )
  mode_mu2 <- unname(
    as.vector(tmb_data$X_mu2 %*% parameters$beta_mu2) +
      mode_contribution[, 2L]
  )
  mode_log_sigma1 <- unname(
    as.vector(tmb_data$X_sigma1 %*% parameters$beta_sigma1) +
      mode_contribution[, 3L]
  )
  mode_log_sigma2 <- unname(
    as.vector(tmb_data$X_sigma2 %*% parameters$beta_sigma2) +
      mode_contribution[, 4L]
  )
  report <- obj$report()

  expect_false("u_re_cov_probe" %in% names(obj$par))
  expect_equal(
    names(obj$env$par)[random],
    rep("u_re_cov_probe", length(true_z))
  )
  expect_gt(max(abs(mode)), 1e-4)
  expect_equal(
    report$re_cov_probe_contribution,
    mode_contribution,
    tolerance = 1e-8
  )
  expect_equal(report$mu1, mode_mu1, tolerance = 1e-8)
  expect_equal(report$mu2, mode_mu2, tolerance = 1e-8)
  expect_equal(report$log_sigma1, mode_log_sigma1, tolerance = 1e-8)
  expect_equal(report$log_sigma2, mode_log_sigma2, tolerance = 1e-8)
  expect_equal(report$sigma1, exp(mode_log_sigma1), tolerance = 1e-8)
  expect_equal(report$sigma2, exp(mode_log_sigma2), tolerance = 1e-8)
  expect_true(is.finite(nll))
  expect_true(all(is.finite(grad)))
})

test_that("hidden q=4 bivariate likelihood recovers endpoint predictor signal", {
  n_groups <- 10L
  n_each <- 16L
  group_index0 <- rep(seq_len(n_groups) - 1L, each = n_each)
  value <- matrix(1, nrow = length(group_index0), ncol = 4L)
  theta <- c(0.22, -0.15, 0.10, 0.18, -0.12, 0.24)
  sd <- c(0.55, 0.50, 0.32, 0.35)
  z <- c(
    -0.8,
    0.4,
    0.9,
    -0.3,
    0.7,
    -0.5,
    -0.4,
    0.6,
    -0.2,
    -0.9,
    0.5,
    0.8,
    0.9,
    0.2,
    -0.7,
    -0.4,
    -0.6,
    0.8,
    0.3,
    -0.9,
    0.4,
    -0.2,
    -0.8,
    0.7,
    -0.9,
    -0.6,
    0.6,
    0.2,
    0.3,
    0.9,
    -0.5,
    -0.7,
    -0.4,
    0.6,
    0.8,
    -0.2,
    0.8,
    -0.7,
    -0.3,
    0.5
  )
  latent <- t(apply(
    matrix(z, ncol = 4L, byrow = TRUE),
    1L,
    tmb_vecscale_sqrt_cov_scale,
    theta = theta,
    sd = sd
  ))
  group <- group_index0 + 1L
  beta_mu1 <- 0.20
  beta_mu2 <- -0.15
  beta_sigma1 <- log(0.18)
  beta_sigma2 <- log(0.22)
  beta_rho12 <- atanh(0.18)
  true_mu1 <- beta_mu1 + latent[group, 1L]
  true_mu2 <- beta_mu2 + latent[group, 2L]
  true_log_sigma1 <- beta_sigma1 + latent[group, 3L]
  true_log_sigma2 <- beta_sigma2 + latent[group, 4L]
  eps1 <- c(
    -1.6,
    -1.2,
    -0.9,
    -0.6,
    -0.3,
    -0.1,
    0.1,
    0.3,
    0.6,
    0.9,
    1.2,
    1.6,
    -0.45,
    0.45,
    -1.05,
    1.05
  )
  eps2_raw <- c(
    0.7,
    -0.8,
    0.2,
    -0.1,
    1.0,
    -1.1,
    0.5,
    -0.5,
    1.3,
    -1.4,
    0.9,
    -0.9,
    0.1,
    -0.2,
    1.5,
    -1.6
  )
  eps1 <- as.numeric(scale(eps1, center = TRUE, scale = stats::sd(eps1)))
  eps2_raw <- as.numeric(
    scale(eps2_raw, center = TRUE, scale = stats::sd(eps2_raw))
  )
  eps2_raw <- eps2_raw - sum(eps1 * eps2_raw) / sum(eps1^2) * eps1
  eps2_raw <- as.numeric(
    scale(eps2_raw, center = TRUE, scale = stats::sd(eps2_raw))
  )
  rho <- tanh(beta_rho12)
  eps1 <- rep(eps1, times = n_groups)
  eps2 <- rho * eps1 + sqrt(1 - rho^2) * rep(eps2_raw, times = n_groups)
  expect_equal(unname(stats::cor(eps1, eps2)), rho, tolerance = 1e-12)
  dat <- data.frame(
    y1 = true_mu1 + exp(true_log_sigma1) * eps1,
    y2 = true_mu2 + exp(true_log_sigma2) * eps2
  )
  form <- bf(
    mu1 = y1 ~ 1,
    mu2 = y2 ~ 1,
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  spec <- drmTMB:::drm_build_biv_gaussian_spec(
    form,
    data = dat,
    env = environment(),
    weights = NULL
  )
  registry <- new_four_member_covariance_registry(
    group_index0 = group_index0,
    group_levels = paste0("g", seq_len(n_groups)),
    value = value
  )
  cov_tmb <- drmTMB:::labelled_covariance_block_tmb_data(
    registry,
    allow_unimplemented = TRUE
  )
  tmb_data <- spec$tmb_data
  tmb_data[names(cov_tmb)] <- cov_tmb
  tmb_data$model_type <- 95L
  tmb_data$re_cov_probe_theta <- theta
  tmb_data$re_cov_probe_sd <- sd
  tmb_data$re_cov_probe_z <- numeric(0)
  parameters <- spec$start
  parameters$u_re_cov_probe <- rep(0, length(z))
  map <- spec$map
  map$u_re_cov_probe <- NULL

  obj <- TMB::MakeADFun(
    data = tmb_data,
    parameters = parameters,
    map = map,
    random = c(spec$random_names, "u_re_cov_probe"),
    DLL = "drmTMB",
    silent = TRUE
  )
  opt <- stats::nlminb(
    obj$par,
    obj$fn,
    obj$gr,
    control = list(iter.max = 120, eval.max = 180)
  )
  obj$fn(opt$par)
  report <- obj$report()
  baseline_mu1 <- rep(mean(dat$y1), nrow(dat))
  baseline_mu2 <- rep(mean(dat$y2), nrow(dat))
  baseline_log_sigma1 <- rep(log(stats::sd(dat$y1)), nrow(dat))
  baseline_log_sigma2 <- rep(log(stats::sd(dat$y2)), nrow(dat))

  expect_equal(opt$convergence, 0)
  expect_lt(rmse(report$mu1, true_mu1), 0.55 * rmse(baseline_mu1, true_mu1))
  expect_lt(rmse(report$mu2, true_mu2), 0.60 * rmse(baseline_mu2, true_mu2))
  expect_lt(
    rmse(report$log_sigma1, true_log_sigma1),
    0.80 * rmse(baseline_log_sigma1, true_log_sigma1)
  )
  expect_lt(
    rmse(report$log_sigma2, true_log_sigma2),
    0.80 * rmse(baseline_log_sigma2, true_log_sigma2)
  )
  expect_gt(stats::cor(report$mu1, true_mu1), 0.90)
  expect_gt(stats::cor(report$mu2, true_mu2), 0.90)
  expect_gt(stats::cor(report$log_sigma1, true_log_sigma1), 0.55)
  expect_gt(stats::cor(report$log_sigma2, true_log_sigma2), 0.55)
  expect_true(is.finite(obj$fn(opt$par)))
  expect_true(all(is.finite(obj$gr(opt$par))))
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

test_that("hidden q=3 Gaussian likelihood can use TMB random effects", {
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
    random = c(fit$model$random_names, "u_re_cov_probe"),
    DLL = "drmTMB",
    silent = TRUE
  )
  nll <- as.numeric(obj$fn(obj$par))
  grad <- obj$gr(obj$par)
  random <- obj$env$random
  mode <- unname(obj$env$last.par.best[random])

  latent_g1 <- tmb_vecscale_sqrt_cov_scale(theta, sd, mode[1:3])
  latent_g2 <- tmb_vecscale_sqrt_cov_scale(theta, sd, mode[4:6])
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
  report <- obj$report()

  expect_equal(names(obj$par), names(fit$opt$par))
  expect_equal(names(obj$env$par)[random], rep("u_re_cov_probe", length(z)))
  expect_gt(max(abs(mode)), 1e-4)
  expect_equal(report$re_cov_probe_contribution, contribution, tolerance = 1e-8)
  expect_equal(report$mu, mu, tolerance = 1e-8)
  expect_equal(report$log_sigma, log_sigma, tolerance = 1e-8)
  expect_equal(report$obs_sigma, obs_sigma, tolerance = 1e-8)
  expect_true(is.finite(nll))
  expect_true(all(is.finite(grad)))
})

test_that("hidden q=3 Gaussian likelihood recovers simulated predictor signal", {
  n_groups <- 8L
  n_each <- 12L
  group_index0 <- rep(seq_len(n_groups) - 1L, each = n_each)
  group_levels <- paste0("g", seq_len(n_groups))
  x <- rep(seq(-1.15, 1.15, length.out = n_each), times = n_groups)
  value <- cbind(1, x, 1)
  registry <- new_three_member_covariance_registry(
    group_index0 = group_index0,
    group_levels = group_levels,
    value = value,
    coef_names = c("(Intercept)", "x", "(Intercept)")
  )
  cov_tmb <- drmTMB:::labelled_covariance_block_tmb_data(
    registry,
    allow_unimplemented = TRUE
  )
  theta <- c(0.25, -0.15, 0.20)
  sd <- c(0.45, 0.35, 0.28)
  z <- c(
    -0.8,
    0.4,
    0.6,
    0.7,
    -0.5,
    -0.4,
    -0.3,
    -0.9,
    0.5,
    0.9,
    0.3,
    -0.7,
    -0.6,
    0.8,
    -0.2,
    0.4,
    -0.2,
    0.9,
    0.2,
    0.7,
    -0.6,
    -0.9,
    -0.4,
    0.3
  )
  z_by_group <- matrix(z, ncol = 3L, byrow = TRUE)
  latent <- t(apply(
    z_by_group,
    1L,
    tmb_vecscale_sqrt_cov_scale,
    theta = theta,
    sd = sd
  ))
  group <- group_index0 + 1L
  beta_mu <- 0.35
  beta_sigma <- log(0.22)
  true_mu <- beta_mu + latent[group, 1L] + x * latent[group, 2L]
  true_log_sigma <- beta_sigma + latent[group, 3L]
  eps <- c(-1.4, 0.2, 1.0, -0.8, 1.4, -0.2, -1.0, 0.8, -1.2, 0.4, 1.2, -0.4)
  eps <- as.numeric(scale(eps, center = TRUE, scale = stats::sd(eps)))
  dat <- data.frame(y = true_mu + exp(true_log_sigma) * rep(eps, n_groups))
  fit <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat)

  tmb_data <- fit$model$tmb_data
  tmb_data[names(cov_tmb)] <- cov_tmb
  tmb_data$model_type <- 96L
  tmb_data$re_cov_probe_theta <- theta
  tmb_data$re_cov_probe_sd <- sd
  tmb_data$re_cov_probe_z <- numeric(0)
  parameters <- fit$model$start
  parameters$u_re_cov_probe <- rep(0, length(z))
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
  opt <- stats::nlminb(
    obj$par,
    obj$fn,
    obj$gr,
    control = list(iter.max = 100, eval.max = 150)
  )
  obj$fn(opt$par)
  report <- obj$report()
  baseline_mu <- rep(mean(dat$y), nrow(dat))
  baseline_log_sigma <- rep(log(stats::sd(dat$y)), nrow(dat))

  expect_equal(opt$convergence, 0)
  expect_lt(rmse(report$mu, true_mu), 0.55 * rmse(baseline_mu, true_mu))
  expect_lt(
    rmse(report$log_sigma, true_log_sigma),
    0.80 * rmse(baseline_log_sigma, true_log_sigma)
  )
  expect_gt(stats::cor(report$mu, true_mu), 0.90)
  expect_gt(stats::cor(report$log_sigma, true_log_sigma), 0.55)
  expect_true(is.finite(obj$fn(opt$par)))
  expect_true(all(is.finite(obj$gr(opt$par))))
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
