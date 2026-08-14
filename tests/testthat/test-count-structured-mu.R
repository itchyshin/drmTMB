new_count_structured_mu_data <- function(
  seed = 2026052801,
  n_level = 10L,
  n_each = 12L,
  sd_spatial = 0.45,
  sd_known = 0.45,
  sigma_nb2 = 0.35
) {
  set.seed(seed)
  levels <- paste0("id", seq_len(n_level))
  theta <- seq(0, 1.75 * pi, length.out = n_level)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_level) / (4 * n_level),
    y = sin(theta)
  )
  rownames(coords) <- levels

  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = levels,
    group = "site"
  )
  spatial_covariance <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(
    t(chol(spatial_covariance)) %*% stats::rnorm(n_level, sd = sd_spatial)
  )
  names(spatial_effect) <- levels

  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(levels, levels)
  Q <- solve(K)
  known_effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_level, sd = sd_known))
  names(known_effect) <- levels

  site <- rep(levels, each = n_each)
  id <- site
  x <- stats::rnorm(length(site))
  beta_mu <- c(`(Intercept)` = 0.65, x = -0.20)
  eta_spatial <- beta_mu[[1L]] + beta_mu[[2L]] * x + spatial_effect[site]
  eta_known <- beta_mu[[1L]] + beta_mu[[2L]] * x + known_effect[id]
  data <- data.frame(
    poisson_spatial = stats::rpois(length(site), lambda = exp(eta_spatial)),
    poisson_known = stats::rpois(length(site), lambda = exp(eta_known)),
    nb2_spatial = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta_spatial)
    ),
    nb2_known = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta_known)
    ),
    x = x,
    site = site,
    id = id
  )

  list(
    data = data,
    coords = coords,
    Q = Q,
    beta_mu = beta_mu,
    sigma_nb2 = sigma_nb2
  )
}

nb2_phylo_q2_independent_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  n_phylo <- nrow(data$Q_phylo)
  u_phylo <- matrix(par$u_phylo, nrow = n_phylo)
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  for (k in seq_len(ncol(u_phylo))) {
    eta_mu <- eta_mu + data$phylo_mu_value[, k] *
      u_phylo[data$phylo_mu_node_index + 1L, k]
  }
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  quadratic <- vapply(
    seq_len(ncol(u_phylo)),
    function(k) {
      u <- u_phylo[, k]
      sum(u * as.vector(data$Q_phylo %*% u))
    },
    numeric(1L)
  )
  prior <- sum(0.5 * (
    n_phylo * log(2 * pi) + 2 * par$log_sd_phylo * n_phylo -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo) * quadratic
  ))
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dnbinom(
    data$y[observed],
    size = exp(-2 * log_sigma[observed]),
    mu = exp(eta_mu[observed]),
    log = TRUE
  ))
}

nb2_phylo_q2_covariance_nll <- function(fit, par, rho = NULL) {
  data <- fit$model$tmb_data
  n_phylo <- nrow(data$Q_phylo)
  u_phylo <- matrix(par$u_phylo, nrow = n_phylo)
  if (is.null(rho)) {
    rho <- 0.999999 * tanh(par$eta_cor_phylo)
  }
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  for (k in seq_len(ncol(u_phylo))) {
    eta_mu <- eta_mu + data$phylo_mu_value[, k] *
      u_phylo[data$phylo_mu_node_index + 1L, k]
  }
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  Q_u <- lapply(seq_len(2L), function(k) {
    as.vector(data$Q_phylo %*% u_phylo[, k])
  })
  q11 <- sum(u_phylo[, 1L] * Q_u[[1L]])
  q12 <- sum(u_phylo[, 1L] * Q_u[[2L]])
  q22 <- sum(u_phylo[, 2L] * Q_u[[2L]])
  one_minus_rho2 <- 1 - rho^2
  tau <- exp(par$log_sd_phylo)
  quadratic <- (
    q11 / tau[[1L]]^2 - 2 * rho * q12 / prod(tau) +
      q22 / tau[[2L]]^2
  ) / one_minus_rho2
  prior <- 0.5 * (
    2 * n_phylo * log(2 * pi) +
      n_phylo * (2 * sum(par$log_sd_phylo) + log(one_minus_rho2)) -
      2 * data$log_det_Q_phylo + quadratic
  )
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dnbinom(
    data$y[observed],
    size = exp(-2 * log_sigma[observed]),
    mu = exp(eta_mu[observed]),
    log = TRUE
  ))
}

nb2_phylo_q2_central_gradient <- function(fn, par) {
  vapply(
    seq_along(par),
    function(i) {
      step <- 1e-6 * max(1, abs(par[[i]]))
      plus <- minus <- par
      plus[[i]] <- plus[[i]] + step
      minus[[i]] <- minus[[i]] - step
      (fn(plus) - fn(minus)) / (2 * step)
    },
    numeric(1L)
  )
}

poisson_phylo_q2_independent_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  n_phylo <- nrow(data$Q_phylo)
  u_phylo <- matrix(par$u_phylo, nrow = n_phylo)
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  for (k in seq_len(ncol(u_phylo))) {
    eta_mu <- eta_mu + data$phylo_mu_value[, k] *
      u_phylo[data$phylo_mu_node_index + 1L, k]
  }
  quadratic <- vapply(
    seq_len(ncol(u_phylo)),
    function(k) {
      u <- u_phylo[, k]
      sum(u * as.vector(data$Q_phylo %*% u))
    },
    numeric(1L)
  )
  prior <- sum(0.5 * (
    n_phylo * log(2 * pi) + 2 * par$log_sd_phylo * n_phylo -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo) * quadratic
  ))
  prior - sum(data$weights * stats::dpois(data$y, exp(eta_mu), log = TRUE))
}

poisson_structured_q1_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  n_level <- nrow(data$Q_phylo)
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  index <- data$phylo_mu_node_index + 1L
  eta_mu <- eta_mu + data$phylo_mu_value[, 1L] * par$u_phylo[index]
  quadratic <- sum(par$u_phylo * as.vector(data$Q_phylo %*% par$u_phylo))
  prior <- 0.5 * (
    n_level * log(2 * pi) + 2 * n_level * par$log_sd_phylo[[1L]] -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo[[1L]]) * quadratic
  )
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dpois(
    data$y[observed], lambda = exp(eta_mu[observed]), log = TRUE
  ))
}

poisson_structured_q1_slope_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  n_level <- nrow(data$Q_phylo)
  u_phylo <- matrix(par$u_phylo, nrow = n_level)
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  for (k in seq_len(ncol(u_phylo))) {
    eta_mu <- eta_mu + data$phylo_mu_value[, k] *
      u_phylo[data$phylo_mu_node_index + 1L, k]
  }
  quadratic <- vapply(
    seq_len(ncol(u_phylo)),
    function(k) {
      u <- u_phylo[, k]
      sum(u * as.vector(data$Q_phylo %*% u))
    },
    numeric(1L)
  )
  prior <- sum(0.5 * (
    n_level * log(2 * pi) + 2 * par$log_sd_phylo * n_level -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo) * quadratic
  ))
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dpois(
    data$y[observed], lambda = exp(eta_mu[observed]), log = TRUE
  ))
}

nb2_structured_q1_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  n_level <- nrow(data$Q_phylo)
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  index <- data$phylo_mu_node_index + 1L
  eta_mu <- eta_mu + data$phylo_mu_value[, 1L] * par$u_phylo[index]
  quadratic <- sum(par$u_phylo * as.vector(data$Q_phylo %*% par$u_phylo))
  prior <- 0.5 * (
    n_level * log(2 * pi) + 2 * n_level * par$log_sd_phylo[[1L]] -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo[[1L]]) * quadratic
  )
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dnbinom(
    data$y[observed], size = exp(-2 * log_sigma[observed]),
    mu = exp(eta_mu[observed]), log = TRUE
  ))
}

nb2_structured_q1_slope_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  n_level <- nrow(data$Q_phylo)
  u_phylo <- matrix(par$u_phylo, nrow = n_level)
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  for (k in seq_len(ncol(u_phylo))) {
    eta_mu <- eta_mu + data$phylo_mu_value[, k] *
      u_phylo[data$phylo_mu_node_index + 1L, k]
  }
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  quadratic <- vapply(
    seq_len(ncol(u_phylo)),
    function(k) {
      u <- u_phylo[, k]
      sum(u * as.vector(data$Q_phylo %*% u))
    },
    numeric(1L)
  )
  prior <- sum(0.5 * (
    n_level * log(2 * pi) + 2 * par$log_sd_phylo * n_level -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo) * quadratic
  ))
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dnbinom(
    data$y[observed], size = exp(-2 * log_sigma[observed]),
    mu = exp(eta_mu[observed]), log = TRUE
  ))
}

poisson_phylo_q2_covariance_nll <- function(fit, par, rho = NULL) {
  data <- fit$model$tmb_data
  n_phylo <- nrow(data$Q_phylo)
  u_phylo <- matrix(par$u_phylo, nrow = n_phylo)
  if (is.null(rho)) {
    rho <- 0.999999 * tanh(par$eta_cor_phylo)
  }
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  for (k in seq_len(ncol(u_phylo))) {
    eta_mu <- eta_mu + data$phylo_mu_value[, k] *
      u_phylo[data$phylo_mu_node_index + 1L, k]
  }
  Q_u <- lapply(seq_len(2L), function(k) {
    as.vector(data$Q_phylo %*% u_phylo[, k])
  })
  q11 <- sum(u_phylo[, 1L] * Q_u[[1L]])
  q12 <- sum(u_phylo[, 1L] * Q_u[[2L]])
  q22 <- sum(u_phylo[, 2L] * Q_u[[2L]])
  one_minus_rho2 <- 1 - rho^2
  tau <- exp(par$log_sd_phylo)
  quadratic <- (
    q11 / tau[[1L]]^2 - 2 * rho * q12 / prod(tau) +
      q22 / tau[[2L]]^2
  ) / one_minus_rho2
  prior <- 0.5 * (
    2 * n_phylo * log(2 * pi) +
      n_phylo * (2 * sum(par$log_sd_phylo) + log(one_minus_rho2)) -
      2 * data$log_det_Q_phylo + quadratic
  )
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dpois(
    data$y[observed], exp(eta_mu[observed]), log = TRUE
  ))
}

poisson_provider_q2_covariance_nll <- function(fit, par, precision, rho = NULL) {
  data <- fit$model$tmb_data
  n_level <- nrow(precision)
  u <- matrix(par$u_phylo, nrow = n_level)
  if (is.null(rho)) {
    rho <- 0.999999 * tanh(par$eta_cor_phylo)
  }
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  for (k in seq_len(ncol(u))) {
    eta_mu <- eta_mu + data$phylo_mu_value[, k] *
      u[data$phylo_mu_node_index + 1L, k]
  }
  precision_u <- lapply(seq_len(2L), function(k) precision %*% u[, k])
  q11 <- sum(u[, 1L] * precision_u[[1L]])
  q12 <- sum(u[, 1L] * precision_u[[2L]])
  q22 <- sum(u[, 2L] * precision_u[[2L]])
  tau <- exp(par$log_sd_phylo)
  one_minus_rho2 <- 1 - rho^2
  quadratic <- (
    q11 / tau[[1L]]^2 - 2 * rho * q12 / prod(tau) +
      q22 / tau[[2L]]^2
  ) / one_minus_rho2
  log_det_precision <- as.numeric(determinant(precision, logarithm = TRUE)$modulus)
  prior <- 0.5 * (
    2 * n_level * log(2 * pi) +
      n_level * (2 * sum(par$log_sd_phylo) + log(one_minus_rho2)) -
      2 * log_det_precision + quadratic
  )
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dpois(
    data$y[observed], exp(eta_mu[observed]), log = TRUE
  ))
}

poisson_provider_q2_independent_nll <- function(fit, par, precision) {
  poisson_provider_q2_covariance_nll(fit, par, precision, rho = 0)
}

independent_spatial_precision <- function(coords, levels, jitter = 1e-6) {
  xy <- as.matrix(coords[levels, seq_len(2L), drop = FALSE])
  distances <- as.matrix(stats::dist(xy))
  positive_distances <- distances[distances > 0]
  range <- stats::median(positive_distances)
  covariance <- exp(-distances / range)
  diag(covariance) <- diag(covariance) + jitter
  chol2inv(chol(covariance))
}

new_count_structured_mu_plus_ordinary_data <- function(
  seed = 2026070412,
  n_site = 8L,
  n_id = 16L,
  n_each = 16L
) {
  set.seed(seed)
  sites <- paste0("site", seq_len(n_site))
  ids <- paste0("id", seq_len(n_id))
  theta <- seq(0, 1.75 * pi, length.out = n_site)
  coords <- data.frame(
    x = cos(theta),
    y = sin(theta)
  )
  rownames(coords) <- sites

  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = sites,
    group = "site"
  )
  spatial_covariance <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(
    t(chol(spatial_covariance)) %*% stats::rnorm(n_site, sd = 0.45)
  )
  names(spatial_effect) <- sites

  id <- rep(ids, each = n_each)
  site_for_id <- rep(sites, length.out = n_id)
  names(site_for_id) <- ids
  site <- unname(site_for_id[id])
  x <- stats::rnorm(length(id))
  ordinary_effect <- stats::rnorm(n_id, sd = 0.25)
  names(ordinary_effect) <- ids
  eta <- 0.55 - 0.20 * x + spatial_effect[site] + ordinary_effect[id]

  list(
    data = data.frame(
      y = stats::rpois(length(id), lambda = exp(eta)),
      x = x,
      site = factor(site, levels = sites),
      id = factor(id, levels = ids)
    ),
    coords = coords
  )
}

new_count_structured_mu_slope_data <- function(
  seed = 2026062513,
  n_level = 8L,
  n_each = 20L,
  sd_intercept = 0.25,
  sd_slope = 0.45,
  rho_phylo = 0,
  rho_provider = 0,
  sigma_nb2 = 0.20
) {
  set.seed(seed)
  levels <- paste0("id", seq_len(n_level))
  site <- rep(levels, each = n_each)
  id <- site
  x <- stats::rnorm(length(site))

  theta <- seq(0, 1.75 * pi, length.out = n_level)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_level) / (4 * n_level),
    y = sin(theta)
  )
  rownames(coords) <- levels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = levels,
    group = "site"
  )
  spatial_covariance <- solve(as.matrix(precision$precision))

  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(levels, levels)
  Q <- solve(K)

  tree <- ape::stree(n_level, type = "balanced")
  tree$tip.label <- levels
  tree$edge.length <- rep(1, nrow(tree$edge))
  phylo_covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_covariance <- phylo_covariance[levels, levels]

  draw_fields <- function(covariance, rho = 0) {
    chol_covariance <- chol(covariance + diag(1e-8, nrow(covariance)))
    z_intercept <- stats::rnorm(nrow(covariance))
    z_slope <- rho * z_intercept + sqrt(1 - rho^2) * stats::rnorm(
      nrow(covariance)
    )
    intercept <- as.vector(
      t(chol_covariance) %*% z_intercept * sd_intercept
    )
    slope <- as.vector(
      t(chol_covariance) %*% z_slope * sd_slope
    )
    names(intercept) <- rownames(covariance)
    names(slope) <- rownames(covariance)
    list(intercept = intercept, slope = slope)
  }

  fields <- list(
    phylo = draw_fields(phylo_covariance, rho = rho_phylo),
    spatial = draw_fields(spatial_covariance, rho = rho_provider),
    known = draw_fields(K, rho = rho_provider)
  )
  beta_mu <- c(`(Intercept)` = 0.55, x = -0.15)
  eta <- list(
    phylo = beta_mu[[1L]] +
      beta_mu[[2L]] * x +
      fields$phylo$intercept[site] +
      x * fields$phylo$slope[site],
    spatial = beta_mu[[1L]] +
      beta_mu[[2L]] * x +
      fields$spatial$intercept[site] +
      x * fields$spatial$slope[site],
    known = beta_mu[[1L]] +
      beta_mu[[2L]] * x +
      fields$known$intercept[id] +
      x * fields$known$slope[id]
  )

  data <- data.frame(
    poisson_phylo = stats::rpois(length(site), lambda = exp(eta$phylo)),
    poisson_spatial = stats::rpois(length(site), lambda = exp(eta$spatial)),
    poisson_known = stats::rpois(length(site), lambda = exp(eta$known)),
    nb2_phylo = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta$phylo)
    ),
    nb2_spatial = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta$spatial)
    ),
    nb2_known = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta$known)
    ),
    x = x,
    site = site,
    id = id
  )

  list(
    data = data,
    coords = coords,
    tree = tree,
    Q = Q,
    beta_mu = beta_mu,
    sigma_nb2 = sigma_nb2
  )
}

new_count_structured_mu_slope_only_data <- function(
  seed = 2026070502,
  n_level = 8L,
  n_each = 25L,
  sd_slope = 0.40,
  sigma_nb2 = 0.25
) {
  set.seed(seed)
  levels <- paste0("id", seq_len(n_level))
  site <- rep(levels, each = n_each)
  x <- stats::rnorm(length(site))

  theta <- seq(0, 1.75 * pi, length.out = n_level)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_level) / (4 * n_level),
    y = sin(theta)
  )
  rownames(coords) <- levels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = levels,
    group = "site"
  )
  spatial_covariance <- solve(as.matrix(precision$precision))
  slope <- as.vector(
    t(chol(spatial_covariance)) %*% stats::rnorm(n_level, sd = sd_slope)
  )
  names(slope) <- levels

  beta_mu <- c(`(Intercept)` = 0.45, x = -0.18)
  eta <- beta_mu[[1L]] + beta_mu[[2L]] * x + x * slope[site]
  data <- data.frame(
    poisson_spatial = stats::rpois(length(site), lambda = exp(eta)),
    nb2_spatial = stats::rnbinom(
      length(site),
      size = 1 / sigma_nb2^2,
      mu = exp(eta)
    ),
    x = x,
    site = site
  )

  list(
    data = data,
    coords = coords,
    beta_mu = beta_mu,
    sigma_nb2 = sigma_nb2
  )
}

expect_count_structured_mu_fit <- function(fit, type, group) {
  label <- paste0(type, "(1 | ", group, ")")
  key <- paste0(type, "_mu")
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$structured$phylo_mu$type, type)
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_named(fit$sdpars$mu, label)
  expect_gt(unname(fit$sdpars$mu[[label]]), 0)
  expect_equal(names(ranef(fit)), key)
  expect_equal(ranef(fit, key), fit$random_effects[[key]])

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == paste0("sd:mu:", label), , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)

  fixed_link <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    fixed_link + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
  expect_true(all(predict(fit, dpar = "mu") > 0))

  checks <- check_drm(fit)
  structured_check <- checks[checks$check == paste0(type, "_mu_diagnostics"), ]
  expect_equal(nrow(structured_check), 1L)
  expect_equal(structured_check$status, "ok")
  expect_true(attr(checks, "ok"))
}

expect_count_structured_mu_plus_ordinary_fit <- function(fit) {
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$model_type, "poisson")
  expect_equal(fit$model$structured$phylo_mu$type, "spatial")
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_setequal(names(fit$random_effects), c("mu", "spatial_mu"))
  expect_equal(ranef(fit, "mu"), fit$random_effects$mu)
  expect_equal(ranef(fit, "spatial_mu"), fit$random_effects$spatial_mu)
  expect_setequal(names(fit$sdpars$mu), c("(1 | id)", "spatial(1 | site)"))
  expect_true(all(unname(fit$sdpars$mu) > 0))

  targets <- profile_targets(fit)
  sd_target <- targets[
    targets$parm == "sd:mu:spatial(1 | site)",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)

  fixed_link <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    fixed_link +
      drmTMB:::mu_random_effect_contribution(fit) +
      drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
  expect_true(all(predict(fit, dpar = "mu") > 0))

  checks <- check_drm(fit)
  structured_check <- checks[checks$check == "spatial_mu_diagnostics", ]
  expect_equal(nrow(structured_check), 1L)
  expect_equal(structured_check$status, "ok")
  expect_true(attr(checks, "ok"))
}

expect_count_structured_mu_slope_fit <- function(fit, type, group) {
  labels <- c(
    paste0(type, "(1 | ", group, ")"),
    paste0(type, "(0 + x | ", group, ")")
  )
  key <- paste0(type, "_mu")
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$structured$phylo_mu$type, type)
  expect_equal(fit$model$structured$phylo_mu$q, 2L)
  expect_equal(
    fit$model$structured$phylo_mu$coef_names,
    c("(Intercept)", "x")
  )
  expect_setequal(names(fit$sdpars$mu), labels)
  expect_true(all(unname(fit$sdpars$mu[labels]) > 0))
  expect_equal(names(ranef(fit)), key)
  expect_setequal(names(fit$random_effects[[key]]$terms), labels)

  targets <- profile_targets(fit)
  sd_targets <- targets[
    targets$parm %in% paste0("sd:mu:", labels),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(sd_targets), 2L)
  expect_equal(sd_targets$tmb_parameter, rep("log_sd_phylo", 2L))
  expect_equal(sd_targets$target_type, rep("direct", 2L))
  expect_true(all(sd_targets$profile_ready))

  fixed_link <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    fixed_link + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
  expect_true(all(predict(fit, dpar = "mu") > 0))

  checks <- check_drm(fit)
  structured_check <- checks[checks$check == paste0(type, "_mu_diagnostics"), ]
  expect_equal(nrow(structured_check), 1L)
  expect_equal(structured_check$status, "ok")
  expect_true(attr(checks, "ok"))
}

expect_count_labelled_q2_profile_restriction <- function(
  fit,
  provider = "phylo",
  group = "site"
) {
  target_names <- c(
    paste0("sd:mu:", provider, "(1 | p | ", group, ")"),
    paste0("sd:mu:", provider, "(0 + x | p | ", group, ")"),
    paste0(
      "cor:", provider, ":cor(mu:(Intercept),mu:x | p | ", group, ")"
    )
  )
  targets <- profile_targets(fit)
  restricted <- targets[match(target_names, targets$parm), , drop = FALSE]
  expect_false(anyNA(restricted$parm))
  expect_equal(
    restricted$tmb_parameter,
    c("log_sd_phylo", "log_sd_phylo", "eta_cor_phylo")
  )
  expect_equal(restricted$target_type, rep("direct", length(target_names)))
  expect_true(all(restricted$profile_ready))
  expect_equal(
    restricted$profile_note,
    rep("ready", length(target_names))
  )
  expect_true(all(target_names %in% profile_targets(fit, ready_only = TRUE)$parm))
  # The fence that forced these targets point-fit-only is gone (profile.R),
  # so the "not ready for direct profiling" negative control no longer
  # applies. A cheap mock-based check replaces it: the endpoint engine now
  # reaches drm_profile_target_endpoint_confint() for this target instead of
  # short-circuiting to "unsupported", and the mock aborts immediately so
  # this stays fast (no real profile optimization runs here; see the
  # dedicated se = TRUE profile-interval test for a real fit).
  endpoint_called <- FALSE
  testthat::local_mocked_bindings(
    drm_profile_target_endpoint_confint = function(...) {
      endpoint_called <<- TRUE
      stop("endpoint profile must not start", call. = FALSE)
    },
    .package = "drmTMB"
  )
  endpoint <- stats::confint(
    fit,
    parm = target_names[[1L]],
    method = "profile",
    profile_engine = "endpoint"
  )
  expect_true(endpoint_called)
  expect_equal(endpoint$conf.status, "profile_failed")
  expect_match(endpoint$profile.message, "endpoint profile must not start")
}

expect_count_structured_mu_slope_only_fit <- function(fit, type, group) {
  label <- paste0(type, "(0 + x | ", group, ")")
  key <- paste0(type, "_mu")
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$structured$phylo_mu$type, type)
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_equal(fit$model$structured$phylo_mu$coef_names, "x")
  expect_named(fit$sdpars$mu, label)
  expect_gt(unname(fit$sdpars$mu[[label]]), 0)
  expect_equal(names(ranef(fit)), key)
  expect_equal(ranef(fit, key), fit$random_effects[[key]])

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == paste0("sd:mu:", label), , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)

  fixed_link <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    fixed_link + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
  expect_true(all(predict(fit, dpar = "mu") > 0))

  checks <- check_drm(fit)
  structured_check <- checks[checks$check == paste0(type, "_mu_diagnostics"), ]
  expect_equal(nrow(structured_check), 1L)
  expect_equal(structured_check$status, "ok")
  expect_true(attr(checks, "ok"))
}

test_that("Poisson mu supports q1 spatial, animal, and relmat intercepts", {
  sim <- new_count_structured_mu_data()
  dat <- sim$data
  coords <- sim$coords
  Q <- sim$Q

  fit_spatial <- drmTMB(
    bf(poisson_spatial ~ x + spatial(1 | site, coords = coords)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_animal <- drmTMB(
    bf(poisson_known ~ x + animal(1 | id, Ainv = Q)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_relmat <- drmTMB(
    bf(poisson_known ~ x + relmat(1 | id, Q = Q)),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_count_structured_mu_fit(fit_spatial, "spatial", "site")
  expect_count_structured_mu_fit(fit_animal, "animal", "id")
  expect_count_structured_mu_fit(fit_relmat, "relmat", "id")
  expect_lt(max(abs(coef(fit_spatial, "mu") - sim$beta_mu)), 0.45)
  expect_lt(max(abs(coef(fit_animal, "mu") - sim$beta_mu)), 0.45)
  expect_lt(max(abs(coef(fit_relmat, "mu") - sim$beta_mu)), 0.45)
})

test_that("Poisson spatial q1 intercept response mask has oracle and recovery evidence", {
  sim <- new_count_structured_mu_data(
    n_level = 128L, n_each = 16L, seed = 2026081739L
  )
  dat <- sim$data
  dat$poisson_spatial[seq(1L, nrow(dat), by = 16L)] <- NA_integer_
  observed <- !is.na(dat$poisson_spatial)
  coords <- sim$coords
  formula <- bf(poisson_spatial ~ x + spatial(1 | site, coords = coords))
  fit_masked <- drmTMB(
    formula, family = stats::poisson(link = "log"), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = stats::poisson(link = "log"), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), poisson_structured_q1_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  # The uncentred spatial draw shifts the realised intercept.
  expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.35)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.14)
  expect_lt(abs(unname(fit_masked$sdpars$mu) - 0.45), 0.25)
})

test_that("Poisson animal and relmat q1 intercept response masks have separate recovery evidence", {
  routes <- list(
    list(provider = "animal", seed = 2026081740L),
    list(provider = "relmat", seed = 2026081741L)
  )
  for (route in routes) {
    sim <- new_count_structured_mu_data(
      n_level = 128L, n_each = 16L, seed = route$seed
    )
    dat <- sim$data
    dat$poisson_known[seq(1L, nrow(dat), by = 16L)] <- NA_integer_
    observed <- !is.na(dat$poisson_known)
    Q <- sim$Q
    formula <- if (identical(route$provider, "animal")) {
      bf(poisson_known ~ x + animal(1 | id, Ainv = Q))
    } else {
      bf(poisson_known ~ x + relmat(1 | id, Q = Q))
    }
    fit_masked <- drmTMB(
      formula, family = stats::poisson(link = "log"), data = dat,
      missing = miss_control(response = "include"), control = drm_control(se = FALSE)
    )
    fit_observed <- drmTMB(
      formula, family = stats::poisson(link = "log"), data = dat[observed, , drop = FALSE],
      control = drm_control(se = FALSE)
    )
    obj <- TMB::MakeADFun(
      data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
      map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
    )
    probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
    par <- obj$env$parList(probe)

    expect_equal(fit_masked$opt$convergence, 0L)
    expect_equal(fit_observed$opt$convergence, 0L)
    expect_equal(nobs(fit_masked), sum(observed))
    expect_equal(fit_masked$missing_data$observed_y, observed)
    expect_equal(obj$fn(probe), poisson_structured_q1_nll(fit_masked, par),
      tolerance = 1e-7)
    expect_equal(
      as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
      tolerance = 5e-5
    )
    expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
    expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"),
      tolerance = 1e-6)
    expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu,
      tolerance = 1e-6)
    expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]),
      0.35)
    expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]),
      0.14)
    expect_lt(abs(unname(fit_masked$sdpars$mu) - 0.45), 0.25,
      )
  }
})

test_that("Poisson spatial q1 slope response mask has oracle and recovery evidence", {
  sim <- new_count_structured_mu_slope_only_data(
    n_level = 128L, n_each = 16L, seed = 2026081742L
  )
  dat <- sim$data
  dat$poisson_spatial[seq(1L, nrow(dat), by = 16L)] <- NA_integer_
  observed <- !is.na(dat$poisson_spatial)
  coords <- sim$coords
  formula <- bf(poisson_spatial ~ x + spatial(0 + x | site, coords = coords))
  fit_masked <- drmTMB(
    formula, family = stats::poisson(link = "log"), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = stats::poisson(link = "log"), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), poisson_structured_q1_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.15)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.18)
  expect_lt(abs(unname(fit_masked$sdpars$mu) - 0.40), 0.22)
})

test_that("NB2 phylo q1 intercept response mask has oracle and recovery evidence", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(
    n_level = 128L, n_each = 16L, sd_slope = 0, seed = 2026081746L
  )
  dat <- sim$data
  dat$nb2_phylo[seq(1L, nrow(dat), by = 16L)] <- NA_integer_
  observed <- !is.na(dat$nb2_phylo)
  tree <- sim$tree
  formula <- bf(nb2_phylo ~ x + phylo(1 | site, tree = tree), sigma ~ 1)
  fit_masked <- drmTMB(
    formula, family = nbinom2(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = nbinom2(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), nb2_structured_q1_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.38)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.20)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - log(sim$sigma_nb2)), 0.18)
  expect_lt(abs(unname(fit_masked$sdpars$mu) - 0.25), 0.22)
})

test_that("NB2 spatial, animal, and relmat q1 response masks have separate recovery evidence", {
  routes <- list(
    list(provider = "spatial", seed = 2026081743L),
    list(provider = "animal", seed = 2026081744L),
    list(provider = "relmat", seed = 2026081745L)
  )
  for (route in routes) {
    sim <- new_count_structured_mu_data(
      n_level = 128L, n_each = 16L, seed = route$seed
    )
    dat <- sim$data
    response <- if (identical(route$provider, "spatial")) "nb2_spatial" else "nb2_known"
    dat[[response]][seq(1L, nrow(dat), by = 16L)] <- NA_integer_
    observed <- !is.na(dat[[response]])
    coords <- sim$coords
    Q <- sim$Q
    formula <- switch(
      route$provider,
      spatial = bf(nb2_spatial ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
      animal = bf(nb2_known ~ x + animal(1 | id, Ainv = Q), sigma ~ 1),
      relmat = bf(nb2_known ~ x + relmat(1 | id, Q = Q), sigma ~ 1)
    )
    fit_masked <- drmTMB(
      formula, family = nbinom2(), data = dat,
      missing = miss_control(response = "include"), control = drm_control(se = FALSE)
    )
    fit_observed <- drmTMB(
      formula, family = nbinom2(), data = dat[observed, , drop = FALSE],
      control = drm_control(se = FALSE)
    )
    obj <- TMB::MakeADFun(
      data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
      map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
    )
    probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
    par <- obj$env$parList(probe)

    expect_equal(fit_masked$opt$convergence, 0L)
    expect_equal(fit_observed$opt$convergence, 0L)
    expect_equal(nobs(fit_masked), sum(observed))
    expect_equal(fit_masked$missing_data$observed_y, observed)
    expect_equal(obj$fn(probe), nb2_structured_q1_nll(fit_masked, par), tolerance = 1e-7)
    expect_equal(
      as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
      tolerance = 5e-5
    )
    expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
    expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
    expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
    expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
    expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.38)
    expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.20)
    expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - log(sim$sigma_nb2)), 0.18)
    expect_lt(abs(unname(fit_masked$sdpars$mu) - 0.45), 0.28)
  }
})

test_that("NB2 structured q1 intercept-slope response masks have separate recovery evidence", {
  testthat::skip_if_not_installed("ape")
  routes <- list(
    list(provider = "phylo", seed = 2026081747L),
    list(provider = "spatial", seed = 2026081748L),
    list(provider = "animal", seed = 2026081749L),
    list(provider = "relmat", seed = 2026081750L)
  )
  for (route in routes) {
    sim <- new_count_structured_mu_slope_data(
      n_level = 128L, n_each = 16L, seed = route$seed
    )
    dat <- sim$data
    response <- switch(
      route$provider,
      phylo = "nb2_phylo",
      spatial = "nb2_spatial",
      "nb2_known"
    )
    dat[[response]][seq(1L, nrow(dat), by = 16L)] <- NA_integer_
    observed <- !is.na(dat[[response]])
    coords <- sim$coords
    tree <- sim$tree
    Q <- sim$Q
    formula <- switch(
      route$provider,
      phylo = bf(nb2_phylo ~ x + phylo(1 + x | site, tree = tree), sigma ~ 1),
      spatial = bf(nb2_spatial ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1),
      animal = bf(nb2_known ~ x + animal(1 + x | id, Ainv = Q), sigma ~ 1),
      relmat = bf(nb2_known ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1)
    )
    fit_masked <- drmTMB(
      formula, family = nbinom2(), data = dat,
      missing = miss_control(response = "include"), control = drm_control(se = FALSE)
    )
    fit_observed <- drmTMB(
      formula, family = nbinom2(), data = dat[observed, , drop = FALSE],
      control = drm_control(se = FALSE)
    )
    obj <- TMB::MakeADFun(
      data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
      map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
    )
    probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
    par <- obj$env$parList(probe)

    expect_equal(fit_masked$opt$convergence, 0L)
    expect_equal(fit_observed$opt$convergence, 0L)
    expect_equal(nobs(fit_masked), sum(observed))
    expect_equal(fit_masked$missing_data$observed_y, observed)
    expect_equal(obj$fn(probe), nb2_structured_q1_slope_nll(fit_masked, par), tolerance = 1e-7)
    expect_equal(
      as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
      tolerance = 5e-5
    )
    expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
    expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
    expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
    expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
    expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.38)
    expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.20)
    expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - log(sim$sigma_nb2)), 0.18)
    expect_lt(abs(unname(fit_masked$sdpars$mu[[1L]]) - 0.25), 0.22)
    expect_lt(abs(unname(fit_masked$sdpars$mu[[2L]]) - 0.45), 0.25)
  }
})

test_that("Poisson phylo, animal, and relmat q1 slopes have separate response-mask recovery evidence", {
  testthat::skip_if_not_installed("ape")
  routes <- list(
    list(provider = "phylo", seed = 2026081758L),
    list(provider = "animal", seed = 2026081759L),
    list(provider = "relmat", seed = 2026081760L)
  )
  for (route in routes) {
    sim <- new_count_structured_mu_slope_data(
      n_level = 128L, n_each = 64L, seed = route$seed
    )
    dat <- sim$data
    response <- if (identical(route$provider, "phylo")) "poisson_phylo" else "poisson_known"
    dat[[response]][seq(1L, nrow(dat), by = 64L)] <- NA_integer_
    observed <- !is.na(dat[[response]])
    tree <- sim$tree
    Q <- sim$Q
    formula <- switch(
      route$provider,
      phylo = bf(poisson_phylo ~ x + phylo(1 + x | site, tree = tree)),
      animal = bf(poisson_known ~ x + animal(1 + x | id, Ainv = Q)),
      relmat = bf(poisson_known ~ x + relmat(1 + x | id, Q = Q))
    )
    fit_masked <- drmTMB(
      formula, family = stats::poisson(link = "log"), data = dat,
      missing = miss_control(response = "include"), control = drm_control(se = FALSE)
    )
    fit_observed <- drmTMB(
      formula, family = stats::poisson(link = "log"), data = dat[observed, , drop = FALSE],
      control = drm_control(se = FALSE)
    )
    obj <- TMB::MakeADFun(
      data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
      map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
    )
    probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
    par <- obj$env$parList(probe)

    expect_equal(fit_masked$opt$convergence, 0L)
    expect_equal(fit_observed$opt$convergence, 0L)
    expect_equal(nobs(fit_masked), sum(observed))
    expect_equal(fit_masked$missing_data$observed_y, observed)
    expect_equal(obj$fn(probe), poisson_structured_q1_slope_nll(fit_masked, par), tolerance = 1e-7)
    expect_equal(
      as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
      tolerance = 5e-5
    )
    expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
    expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
    expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
    expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.30)
    expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.20)
    expect_lt(abs(unname(fit_masked$sdpars$mu[[1L]]) - 0.25), 0.20)
    expect_lt(abs(unname(fit_masked$sdpars$mu[[2L]]) - 0.45), 0.22)
  }
})

expect_poisson_labelled_q2_provider_fit <- function(fit, provider, group) {
  expected_correlation <- paste0(
    "cor(mu:(Intercept),mu:x | p | ", group, ")"
  )
  structured <- fit$model$structured$phylo_mu
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(structured$type, provider)
  expect_equal(structured$q, 2L)
  expect_true(
    drmTMB:::phylo_mu_has_labelled_mu_intercept_slope_q2(structured)
  )
  expect_equal(fit$model$tmb_data$has_phylo_mu_q2_covariance, 1L)
  expect_false(is.factor(fit$model$map$eta_cor_phylo))
  expect_named(
    fit$sdpars$mu,
    c(
      paste0(provider, "(1 | p | ", group, ")"),
      paste0(provider, "(0 + x | p | ", group, ")")
    )
  )
  expect_named(fit$corpars[[provider]], expected_correlation)
  expect_true(is.finite(unname(fit$corpars[[provider]][[expected_correlation]])))
  expect_lt(abs(unname(fit$corpars[[provider]][[expected_correlation]])), 1)
  par <- fit$obj$env$parList(fit$opt$par)
  rho_parameter <- 0.999999 * tanh(par$eta_cor_phylo)
  expect_equal(
    unname(fit$corpars[[provider]][[expected_correlation]]),
    unname(rho_parameter),
    tolerance = 1e-12
  )
  expect_true(is.finite(fit$obj$report()$rho_phylo))
  expect_count_labelled_q2_profile_restriction(fit, provider, group)
}

test_that("nbinom2 mu supports q1 spatial, animal, and relmat intercepts", {
  sim <- new_count_structured_mu_data(seed = 2026052802)
  dat <- sim$data
  coords <- sim$coords
  Q <- sim$Q

  fit_spatial <- drmTMB(
    bf(nb2_spatial ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )
  fit_animal <- drmTMB(
    bf(nb2_known ~ x + animal(1 | id, Ainv = Q), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )
  fit_relmat <- drmTMB(
    bf(nb2_known ~ x + relmat(1 | id, Q = Q), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )

  expect_count_structured_mu_fit(fit_spatial, "spatial", "site")
  expect_count_structured_mu_fit(fit_animal, "animal", "id")
  expect_count_structured_mu_fit(fit_relmat, "relmat", "id")
  expect_lt(max(abs(coef(fit_spatial, "mu") - sim$beta_mu)), 0.50)
  expect_lt(max(abs(coef(fit_animal, "mu") - sim$beta_mu)), 0.50)
  expect_lt(max(abs(coef(fit_relmat, "mu") - sim$beta_mu)), 0.50)
  expect_true(all(sigma(fit_spatial) > 0))
  expect_true(all(sigma(fit_animal) > 0))
  expect_true(all(sigma(fit_relmat) > 0))
})

test_that("Poisson and nbinom2 mu support one structured count slope", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data()
  dat <- sim$data
  coords <- sim$coords
  tree <- sim$tree
  Q <- sim$Q

  poisson_phylo <- drmTMB(
    bf(poisson_phylo ~ x + phylo(1 + x | site, tree = tree)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  poisson_spatial <- drmTMB(
    bf(poisson_spatial ~ x + spatial(1 + x | site, coords = coords)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  poisson_animal <- drmTMB(
    bf(poisson_known ~ x + animal(1 + x | id, Ainv = Q)),
    family = stats::poisson(link = "log"),
    data = dat
  )
  poisson_relmat <- drmTMB(
    bf(poisson_known ~ x + relmat(1 + x | id, Q = Q)),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_count_structured_mu_slope_fit(poisson_phylo, "phylo", "site")
  expect_count_structured_mu_slope_fit(poisson_spatial, "spatial", "site")
  expect_count_structured_mu_slope_fit(poisson_animal, "animal", "id")
  expect_count_structured_mu_slope_fit(poisson_relmat, "relmat", "id")

  nb2_phylo <- drmTMB(
    bf(nb2_phylo ~ x + phylo(1 + x | site, tree = tree), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 700, iter.max = 700)
  )
  nb2_spatial <- drmTMB(
    bf(nb2_spatial ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 700, iter.max = 700)
  )
  nb2_animal <- drmTMB(
    bf(nb2_known ~ x + animal(1 + x | id, Ainv = Q), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 700, iter.max = 700)
  )
  nb2_relmat <- drmTMB(
    bf(nb2_known ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 700, iter.max = 700)
  )

  expect_count_structured_mu_slope_fit(nb2_phylo, "phylo", "site")
  expect_count_structured_mu_slope_fit(nb2_spatial, "spatial", "site")
  expect_count_structured_mu_slope_fit(nb2_animal, "animal", "id")
  expect_count_structured_mu_slope_fit(nb2_relmat, "relmat", "id")
  expect_true(all(sigma(nb2_phylo) > 0))
  expect_true(all(sigma(nb2_spatial) > 0))
  expect_true(all(sigma(nb2_animal) > 0))
  expect_true(all(sigma(nb2_relmat) > 0))
})

test_that("Poisson phylo admits one labelled intercept-slope covariance block", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(
    seed = 2026072811,
    n_level = 16L,
    n_each = 24L,
    rho_phylo = 0.35
  )
  tree <- sim$tree

  fit <- drmTMB(
    bf(poisson_phylo ~ x + phylo(1 + x | p | site, tree = tree)),
    family = stats::poisson(link = "log"),
    data = sim$data,
    control = list(eval.max = 900, iter.max = 900)
  )

  structured <- fit$model$structured$phylo_mu
  expected_correlation <- "cor(mu:(Intercept),mu:x | p | site)"
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(structured$q, 2L)
  expect_true(
    drmTMB:::phylo_mu_has_labelled_mu_intercept_slope_q2(structured)
  )
  expect_equal(fit$model$tmb_data$has_phylo_mu_q2_covariance, 1L)
  expect_false(is.factor(fit$model$map$eta_cor_phylo))
  expect_named(
    fit$sdpars$mu,
    c("phylo(1 | p | site)", "phylo(0 + x | p | site)")
  )
  expect_named(fit$corpars$phylo, expected_correlation)
  expect_true(is.finite(unname(fit$corpars$phylo[[expected_correlation]])))
  expect_lt(abs(unname(fit$corpars$phylo[[expected_correlation]])), 1)
  par <- fit$obj$env$parList(fit$opt$par)
  rho_parameter <- 0.999999 * tanh(par$eta_cor_phylo)
  expect_equal(
    unname(fit$corpars$phylo[[expected_correlation]]),
    unname(rho_parameter),
    tolerance = 1e-12
  )
  rho_report <- fit$obj$report()$rho_phylo
  expect_true(is.finite(rho_report))
  expect_count_labelled_q2_profile_restriction(fit)
})

test_that("Poisson phylo labelled q2 intercept SD computes a finite ordered profile interval", {
  # Happy-path smoke test, not a boundary probe: a single-seed se = TRUE fit
  # of the same labelled q2 covariance route as the block test above, with
  # one of its three newly-ready targets (the intercept SD) checked for a
  # finite, correctly-ordered profile interval plus a Wald cross-check on the
  # same fit. This is not a coverage or recovery claim -- a single seed
  # carries no error bar for that.
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(
    seed = 2026072811,
    n_level = 16L,
    n_each = 24L,
    rho_phylo = 0.35
  )
  tree <- sim$tree

  fit <- drmTMB(
    bf(poisson_phylo ~ x + phylo(1 + x | p | site, tree = tree)),
    family = stats::poisson(link = "log"),
    data = sim$data,
    control = list(eval.max = 900, iter.max = 900)
  )
  expect_true(fit$sdr$pdHess)

  target <- profile_targets(fit)
  target <- target[target$parm == "sd:mu:phylo(1 | p | site)", , drop = FALSE]
  expect_true(target$profile_ready)

  profile_ci <- stats::confint(
    fit, parm = target$parm, level = 0.70, method = "profile", trace = FALSE, ystep = 0.50
  )
  expect_true(is.finite(profile_ci$lower))
  expect_true(is.finite(profile_ci$upper))
  expect_lt(profile_ci$lower, target$estimate)
  expect_gt(profile_ci$upper, target$estimate)
  expect_identical(profile_ci$conf.status, "profile")

  # Wald cross-check on the same fit: catches a wrong-scale transform or a
  # mislabelled row using an already-computed comparator, not a coverage
  # claim.
  wald_ci <- stats::confint(fit, parm = target$parm, level = 0.70, method = "wald")
  expect_identical(wald_ci$conf.status, "wald")
  expect_true(is.finite(wald_ci$lower))
  expect_true(is.finite(wald_ci$upper))
  expect_lt(profile_ci$lower, wald_ci$upper)
  expect_gt(profile_ci$upper, wald_ci$lower)
})

test_that("Poisson phylo q2 covariance penalty matches the dense joint oracle", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(
    seed = 2026072812,
    n_level = 8L,
    n_each = 8L,
    rho_phylo = 0.30
  )
  tree <- sim$tree
  fit <- drmTMB(
    bf(poisson_phylo ~ x + phylo(1 + x | p | site, tree = tree)),
    family = stats::poisson(link = "log"),
    data = sim$data,
    control = drm_control(se = FALSE)
  )
  full_obj <- TMB::MakeADFun(
    data = fit$model$tmb_data,
    parameters = fit$model$start,
    map = fit$model$map,
    DLL = "drmTMB",
    silent = TRUE
  )
  probe <- full_obj$par + seq(-0.04, 0.04, length.out = length(full_obj$par))
  par <- full_obj$env$parList(probe)
  expect_equal(
    poisson_phylo_q2_covariance_nll(fit, par, rho = 0),
    poisson_phylo_q2_independent_nll(fit, par),
    tolerance = 1e-10
  )
  expect_equal(
    full_obj$fn(probe),
    poisson_phylo_q2_covariance_nll(fit, par),
    tolerance = 1e-8
  )
  expect_equal(
    as.numeric(full_obj$gr(probe)),
    nb2_phylo_q2_central_gradient(full_obj$fn, probe),
    tolerance = 4e-5
  )
  eta_index <- which(names(probe) == "eta_cor_phylo")
  expect_length(eta_index, 1L)
  rho_zero <- probe
  rho_nonzero <- probe
  rho_zero[[eta_index]] <- 0
  rho_nonzero[[eta_index]] <- atanh(0.35 / 0.999999)
  expect_gt(abs(full_obj$fn(rho_nonzero) - full_obj$fn(rho_zero)), 1e-5)
})

test_that("Poisson phylo labelled q2 response mask has oracle and recovery evidence", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(
    n_level = 128L, n_each = 64L, rho_phylo = 0.35, seed = 2026081761L
  )
  dat <- sim$data
  dat$poisson_phylo[seq(1L, nrow(dat), by = 64L)] <- NA_integer_
  observed <- !is.na(dat$poisson_phylo)
  tree <- sim$tree
  formula <- bf(poisson_phylo ~ x + phylo(1 + x | p | site, tree = tree))
  fit_masked <- drmTMB(
    formula, family = stats::poisson(link = "log"), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = stats::poisson(link = "log"), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)
  correlation <- "cor(mu:(Intercept),mu:x | p | site)"

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), poisson_phylo_q2_covariance_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  expect_equal(fit_masked$corpars$phylo, fit_observed$corpars$phylo, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.30)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.20)
  expect_lt(abs(unname(fit_masked$sdpars$mu[[1L]]) - 0.25), 0.20)
  expect_lt(abs(unname(fit_masked$sdpars$mu[[2L]]) - 0.45), 0.22)
  expect_lt(abs(unname(fit_masked$corpars$phylo[[correlation]]) - 0.35), 0.22)
})

test_that("NB2 phylo admits one labelled intercept-slope covariance block", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(
    seed = 2026072801,
    n_level = 16L,
    n_each = 24L,
    rho_phylo = 0.35
  )
  tree <- sim$tree

  fit <- drmTMB(
    bf(nb2_phylo ~ x + phylo(1 + x | p | site, tree = tree), sigma ~ 1),
    family = nbinom2(),
    data = sim$data,
    control = list(eval.max = 900, iter.max = 900)
  )

  structured <- fit$model$structured$phylo_mu
  expected_correlation <- "cor(mu:(Intercept),mu:x | p | site)"
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(structured$q, 2L)
  expect_true(
    drmTMB:::phylo_mu_has_labelled_mu_intercept_slope_q2(structured)
  )
  expect_equal(fit$model$tmb_data$has_phylo_mu_q2_covariance, 1L)
  expect_false(is.factor(fit$model$map$eta_cor_phylo))
  expect_named(
    fit$sdpars$mu,
    c("phylo(1 | p | site)", "phylo(0 + x | p | site)")
  )
  expect_named(fit$corpars$phylo, expected_correlation)
  expect_true(is.finite(unname(fit$corpars$phylo[[expected_correlation]])))
  expect_lt(abs(unname(fit$corpars$phylo[[expected_correlation]])), 1)
  par <- fit$obj$env$parList(fit$opt$par)
  rho_parameter <- 0.999999 * tanh(par$eta_cor_phylo)
  expect_equal(
    unname(fit$corpars$phylo[[expected_correlation]]),
    unname(rho_parameter),
    tolerance = 1e-12
  )
  rho_report <- fit$obj$report()$rho_phylo
  expect_true(is.finite(rho_report))
  expect_count_labelled_q2_profile_restriction(fit)
})

test_that("NB2 phylo q2 covariance penalty matches the dense joint oracle", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(
    seed = 2026072802,
    n_level = 8L,
    n_each = 8L,
    rho_phylo = 0.30
  )
  tree <- sim$tree
  fit <- drmTMB(
    bf(nb2_phylo ~ x + phylo(1 + x | p | site, tree = tree), sigma ~ 1),
    family = nbinom2(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )
  full_obj <- TMB::MakeADFun(
    data = fit$model$tmb_data,
    parameters = fit$model$start,
    map = fit$model$map,
    DLL = "drmTMB",
    silent = TRUE
  )
  probe <- full_obj$par + seq(-0.04, 0.04, length.out = length(full_obj$par))
  par <- full_obj$env$parList(probe)
  expect_equal(
    nb2_phylo_q2_covariance_nll(fit, par, rho = 0),
    nb2_phylo_q2_independent_nll(fit, par),
    tolerance = 1e-10
  )
  expect_equal(
    full_obj$fn(probe),
    nb2_phylo_q2_covariance_nll(fit, par),
    tolerance = 1e-8
  )
  expect_equal(
    as.numeric(full_obj$gr(probe)),
    nb2_phylo_q2_central_gradient(full_obj$fn, probe),
    tolerance = 4e-5
  )
  eta_index <- which(names(probe) == "eta_cor_phylo")
  expect_length(eta_index, 1L)
  rho_zero <- probe
  rho_nonzero <- probe
  rho_zero[[eta_index]] <- 0
  rho_nonzero[[eta_index]] <- atanh(0.35 / 0.999999)
  expect_gt(abs(full_obj$fn(rho_nonzero) - full_obj$fn(rho_zero)), 1e-5)
})

test_that("NB2 phylo labelled q2 response mask has oracle and recovery evidence", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(
    n_level = 128L, n_each = 16L, rho_phylo = 0.35, seed = 2026081751L
  )
  dat <- sim$data
  dat$nb2_phylo[seq(1L, nrow(dat), by = 16L)] <- NA_integer_
  observed <- !is.na(dat$nb2_phylo)
  tree <- sim$tree
  formula <- bf(nb2_phylo ~ x + phylo(1 + x | p | site, tree = tree), sigma ~ 1)
  fit_masked <- drmTMB(
    formula, family = nbinom2(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = nbinom2(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)
  correlation <- "cor(mu:(Intercept),mu:x | p | site)"

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), nb2_phylo_q2_covariance_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  expect_equal(fit_masked$corpars$phylo, fit_observed$corpars$phylo, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.38)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.20)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - log(sim$sigma_nb2)), 0.18)
  expect_lt(abs(unname(fit_masked$sdpars$mu[[1L]]) - 0.25), 0.22)
  expect_lt(abs(unname(fit_masked$sdpars$mu[[2L]]) - 0.45), 0.25)
  expect_lt(abs(unname(fit_masked$corpars$phylo[[correlation]]) - 0.35), 0.25)
})

test_that("NB2 labelled phylo covariance keeps non-C1 forms closed", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(n_level = 8L, n_each = 4L)
  tree <- sim$tree
  coords <- sim$coords
  Q <- sim$Q
  sim$data$z <- sim$data$x^2
  sim$data$id <- factor(sim$data$id, levels = rownames(Q))
  expect_error(
    drmTMB(
      bf(nb2_phylo ~ x + phylo(1 | p | site, tree = tree), sigma ~ 1),
      family = nbinom2(),
      data = sim$data
    ),
    "implemented labelled covariance forms"
  )
  expect_error(
    drmTMB(
      bf(nb2_spatial ~ x + spatial(1 + x | p | site, coords = coords), sigma ~ 1),
      family = nbinom2(),
      data = sim$data
    ),
    "implemented labelled covariance forms"
  )
  expect_error(
    drmTMB(
      bf(nb2_phylo ~ x + phylo(0 + x | p | site, tree = tree), sigma ~ 1),
      family = nbinom2(),
      data = sim$data
    ),
    "implemented labelled covariance forms"
  )
  expect_error(
    drmTMB(
      bf(
        nb2_phylo ~ x + phylo(1 + x + z | p | site, tree = tree),
        sigma ~ 1
      ),
      family = nbinom2(),
      data = sim$data
    ),
    "implemented labelled covariance forms"
  )
  expect_error(
    drmTMB(
      bf(
        nb2_phylo ~ x + phylo(1 + x | p | site, tree = tree) + (1 | id),
        sigma ~ 1
      ),
      family = nbinom2(),
      data = sim$data
    ),
    "cannot be combined"
  )
  expect_error(
    drmTMB(
      bf(
        nb2_phylo ~ x + phylo(1 + x | p | site, tree = tree) +
          spatial(1 | site, coords = coords),
        sigma ~ 1
      ),
      family = nbinom2(),
      data = sim$data
    )
  )
  expect_error(
    drmTMB(
      bf(
        nb2_phylo ~ x + phylo(1 + x | p | site, tree = tree),
        sigma ~ phylo(1 | species, tree = tree)
      ),
      family = nbinom2(),
      data = sim$data
    )
  )
  expect_error(
    drmTMB(
      bf(
        nb2_phylo ~ x + phylo(1 + x | p | site, tree = tree),
        sigma ~ 1,
        zi ~ 1
      ),
      family = nbinom2(),
      data = sim$data
    ),
    "zero-inflated"
  )
})

test_that("Poisson admits only the C2 labelled provider covariance cohort", {
  testthat::skip_if_not_installed("ape")
  sim <- new_count_structured_mu_slope_data(
    seed = 2026072908,
    n_level = 16L,
    n_each = 24L,
    rho_provider = 0.35
  )
  tree <- sim$tree
  coords <- sim$coords
  Q <- sim$Q
  sim$data$z <- sim$data$x^2
  sim$data$id <- factor(sim$data$id, levels = rownames(Q))
  expect_error(
    drmTMB(
      bf(poisson_phylo ~ x + phylo(1 | p | site, tree = tree)),
      family = stats::poisson(link = "log"),
      data = sim$data
    ),
    "implemented labelled covariance forms"
  )
  expect_error(
    drmTMB(
      bf(poisson_phylo ~ x + phylo(0 + x | p | site, tree = tree)),
      family = stats::poisson(link = "log"),
      data = sim$data
    ),
    "implemented labelled covariance forms"
  )
  expect_error(
    drmTMB(
      bf(poisson_phylo ~ x + phylo(1 + x + z | p | site, tree = tree)),
      family = stats::poisson(link = "log"),
      data = sim$data
    ),
    "implemented labelled covariance forms"
  )
  expect_error(
    drmTMB(
      bf(
        poisson_phylo ~ x + phylo(1 + x | p | site, tree = tree) + (1 | id)
      ),
      family = stats::poisson(link = "log"),
      data = sim$data
    ),
    "cannot be combined"
  )
  spatial_fit <- drmTMB(
    bf(poisson_spatial ~ x + spatial(1 + x | p | site, coords = coords)),
    family = stats::poisson(link = "log"),
    data = sim$data,
    control = list(eval.max = 900, iter.max = 900)
  )
  animal_fit <- drmTMB(
    bf(poisson_known ~ x + animal(1 + x | p | id, Ainv = Q)),
    family = stats::poisson(link = "log"),
    data = sim$data,
    control = list(eval.max = 900, iter.max = 900)
  )
  relmat_fit <- drmTMB(
    bf(poisson_known ~ x + relmat(1 + x | p | id, Q = Q)),
    family = stats::poisson(link = "log"),
    data = sim$data,
    control = list(eval.max = 900, iter.max = 900)
  )
  expect_poisson_labelled_q2_provider_fit(spatial_fit, "spatial", "site")
  expect_poisson_labelled_q2_provider_fit(animal_fit, "animal", "id")
  expect_poisson_labelled_q2_provider_fit(relmat_fit, "relmat", "id")
  expect_error(
    drmTMB(
      bf(poisson_known ~ x + animal(1 + x + z | p | id, Ainv = Q)),
      family = stats::poisson(link = "log"),
      data = sim$data
    ),
    "implemented labelled covariance forms"
  )
  expect_error(
    drmTMB(
      bf(poisson_known ~ x + relmat(0 + x | p | id, Q = Q)),
      family = stats::poisson(link = "log"),
      data = sim$data
    ),
    "implemented labelled covariance forms"
  )
  expect_error(
    drmTMB(
      bf(poisson_phylo ~ x + phylo(1 + x | p | site, tree = tree), zi ~ 1),
      family = stats::poisson(link = "log"),
      data = sim$data
    ),
    "ordinary Poisson"
  )
})

test_that("Poisson C2 provider q2 penalties match independent provider oracles", {
  sim <- new_count_structured_mu_slope_data(
    seed = 2026072901,
    n_level = 8L,
    n_each = 8L,
    rho_phylo = 0.30
  )
  dat <- sim$data
  dat$id <- factor(dat$id)
  coords <- sim$coords
  Q <- sim$Q
  inputs <- list(
    spatial = list(
      formula = bf(poisson_spatial ~ x + spatial(1 + x | p | site, coords = coords)),
      response = "poisson_spatial",
      precision = function(fit) {
        independent_spatial_precision(
          sim$coords,
          fit$model$structured$phylo_mu$node_labels
        )
      }
    ),
    relmat = list(
      formula = bf(poisson_known ~ x + relmat(1 + x | p | id, Q = Q)),
      response = "poisson_known",
      precision = function(fit) {
        nodes <- fit$model$structured$phylo_mu$node_labels
        unname(sim$Q[nodes, nodes, drop = FALSE])
      }
    ),
    animal = list(
      formula = bf(poisson_known ~ x + animal(1 + x | p | id, Ainv = Q)),
      response = "poisson_known",
      precision = function(fit) {
        nodes <- fit$model$structured$phylo_mu$node_labels
        unname(sim$Q[nodes, nodes, drop = FALSE])
      }
    )
  )
  for (provider in names(inputs)) {
    fit <- drmTMB(
      inputs[[provider]]$formula,
      family = stats::poisson(link = "log"),
      data = dat,
      control = drm_control(se = FALSE)
    )
    full_obj <- TMB::MakeADFun(
      data = fit$model$tmb_data,
      parameters = fit$model$start,
      map = fit$model$map,
      DLL = "drmTMB",
      silent = TRUE
    )
    probe <- full_obj$par + seq(-0.04, 0.04, length.out = length(full_obj$par))
    par <- full_obj$env$parList(probe)
    precision <- inputs[[provider]]$precision(fit)
    expect_equal(
      poisson_provider_q2_covariance_nll(fit, par, precision, rho = 0),
      poisson_provider_q2_independent_nll(fit, par, precision),
      tolerance = 1e-10,
      info = provider
    )
    expect_equal(
      full_obj$fn(probe),
      poisson_provider_q2_covariance_nll(fit, par, precision),
      tolerance = 1e-8,
      info = provider
    )
    expect_equal(
      as.numeric(full_obj$gr(probe)),
      nb2_phylo_q2_central_gradient(full_obj$fn, probe),
      tolerance = 4e-5,
      info = provider
    )
    eta_index <- which(names(probe) == "eta_cor_phylo")
    expect_length(eta_index, 1L)
    rho_zero <- probe
    rho_nonzero <- probe
    rho_zero[[eta_index]] <- 0
    rho_nonzero[[eta_index]] <- atanh(0.35 / 0.999999)
    expect_gt(
      abs(full_obj$fn(rho_nonzero) - full_obj$fn(rho_zero)),
      1e-5
    )
  }
})

test_that("Poisson spatial, animal, and relmat labelled q2 masks have separate recovery evidence", {
  testthat::skip_if_not_installed("ape")
  routes <- list(
    list(provider = "spatial", seed = 2026081762L),
    list(provider = "animal", seed = 2026081763L),
    list(provider = "relmat", seed = 2026081764L)
  )
  for (route in routes) {
    sim <- new_count_structured_mu_slope_data(
      n_level = 128L, n_each = 64L, rho_provider = 0.35, seed = route$seed
    )
    dat <- sim$data
    response <- if (identical(route$provider, "spatial")) "poisson_spatial" else "poisson_known"
    dat[[response]][seq(1L, nrow(dat), by = 64L)] <- NA_integer_
    observed <- !is.na(dat[[response]])
    coords <- sim$coords
    Q <- sim$Q
    formula <- switch(
      route$provider,
      spatial = bf(poisson_spatial ~ x + spatial(1 + x | p | site, coords = coords)),
      animal = bf(poisson_known ~ x + animal(1 + x | p | id, Ainv = Q)),
      relmat = bf(poisson_known ~ x + relmat(1 + x | p | id, Q = Q))
    )
    fit_masked <- drmTMB(
      formula, family = stats::poisson(link = "log"), data = dat,
      missing = miss_control(response = "include"), control = drm_control(se = FALSE)
    )
    fit_observed <- drmTMB(
      formula, family = stats::poisson(link = "log"), data = dat[observed, , drop = FALSE],
      control = drm_control(se = FALSE)
    )
    obj <- TMB::MakeADFun(
      data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
      map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
    )
    probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
    par <- obj$env$parList(probe)
    precision <- if (identical(route$provider, "spatial")) {
      independent_spatial_precision(coords, fit_masked$model$structured$phylo_mu$node_labels)
    } else {
      nodes <- fit_masked$model$structured$phylo_mu$node_labels
      unname(Q[nodes, nodes, drop = FALSE])
    }
    group <- if (identical(route$provider, "spatial")) "site" else "id"
    correlation <- paste0("cor(mu:(Intercept),mu:x | p | ", group, ")")

    expect_equal(fit_masked$opt$convergence, 0L)
    expect_equal(fit_observed$opt$convergence, 0L)
    expect_equal(nobs(fit_masked), sum(observed))
    expect_equal(fit_masked$missing_data$observed_y, observed)
    expect_equal(
      obj$fn(probe), poisson_provider_q2_covariance_nll(fit_masked, par, precision),
      tolerance = 1e-7
    )
    expect_equal(
      as.numeric(obj$gr(probe)), nb2_phylo_q2_central_gradient(obj$fn, probe),
      tolerance = 5e-5
    )
    expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0, 12))
    expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
    expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
    expect_equal(
      fit_masked$corpars[[route$provider]], fit_observed$corpars[[route$provider]],
      tolerance = 1e-6
    )
    expect_lt(abs(coef(fit_masked, "mu")[["(Intercept)"]] - sim$beta_mu[["(Intercept)"]]), 0.30)
    expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.30)
    expect_lt(abs(unname(fit_masked$sdpars$mu[[1L]]) - 0.25), 0.20)
    expect_lt(abs(unname(fit_masked$sdpars$mu[[2L]]) - 0.45), 0.22)
    expect_lt(abs(unname(fit_masked$corpars[[route$provider]][[correlation]]) - 0.35), 0.22)
  }
})

test_that("count structured mu keeps planned neighboring routes closed", {
  sim <- new_count_structured_mu_data(n_level = 6L, n_each = 4L)
  dat <- sim$data
  coords <- sim$coords
  Q <- sim$Q

  sim_slope_only <- new_count_structured_mu_slope_only_data()
  dat_slope_only <- sim_slope_only$data
  coords_slope_only <- sim_slope_only$coords
  fit_slope_only <- drmTMB(
    bf(poisson_spatial ~ x + spatial(0 + x | site, coords = coords_slope_only)),
    family = stats::poisson(link = "log"),
    data = dat_slope_only,
    control = list(eval.max = 600, iter.max = 600)
  )
  expect_count_structured_mu_slope_only_fit(
    fit_slope_only,
    "spatial",
    "site"
  )
  expect_error(
    drmTMB(
      bf(nb2_spatial ~ x + spatial(0 + x | site, coords = coords_slope_only)),
      family = nbinom2(),
      data = dat_slope_only
    ),
    "intercept-only or one-slope"
  )
  fit_labelled_scalar <- drmTMB(
    bf(poisson_spatial ~ x + spatial(1 | p | site, coords = coords)),
    family = stats::poisson(link = "log"),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )
  expect_s3_class(fit_labelled_scalar, "drmTMB")
  expect_equal(fit_labelled_scalar$opt$convergence, 0)
  expect_true(fit_labelled_scalar$sdr$pdHess)
  expect_equal(fit_labelled_scalar$model$model_type, "poisson")
  expect_equal(fit_labelled_scalar$model$structured$phylo_mu$type, "spatial")
  expect_equal(fit_labelled_scalar$model$structured$phylo_mu$q, 1L)
  expect_equal(fit_labelled_scalar$model$structured$phylo_mu$covariance_label, "p")
  expect_equal(fit_labelled_scalar$model$structured$phylo_mu$covariance_mode, "scalar")
  expect_named(fit_labelled_scalar$sdpars$mu, "spatial(1 | p | site)")
  expect_gt(unname(fit_labelled_scalar$sdpars$mu[["spatial(1 | p | site)"]]), 0)
  expect_equal(names(ranef(fit_labelled_scalar)), "spatial_mu")
  expect_equal(
    ranef(fit_labelled_scalar, "spatial_mu"),
    fit_labelled_scalar$random_effects$spatial_mu
  )
  labelled_target <- profile_targets(fit_labelled_scalar)
  labelled_target <- labelled_target[
    labelled_target$parm == "sd:mu:spatial(1 | p | site)",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(labelled_target), 1L)
  expect_equal(labelled_target$tmb_parameter, "log_sd_phylo")
  expect_equal(labelled_target$target_type, "direct")
  expect_true(labelled_target$profile_ready)
  sim_plus_ordinary <- new_count_structured_mu_plus_ordinary_data()
  coords_plus_ordinary <- sim_plus_ordinary$coords
  fit_plus_ordinary <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords_plus_ordinary) + (1 | id)),
    family = stats::poisson(link = "log"),
    data = sim_plus_ordinary$data
  )
  expect_count_structured_mu_plus_ordinary_fit(fit_plus_ordinary)

  sim_zi <- new_count_structured_mu_data(
    seed = 2026070408,
    n_level = 8L,
    n_each = 20L
  )
  dat_zi <- sim_zi$data
  coords_zi <- sim_zi$coords
  set.seed(2026070409)
  dat_zi$poisson_zi_spatial <- ifelse(
    stats::rbinom(nrow(dat_zi), size = 1L, prob = 0.25) == 1L,
    0L,
    dat_zi$poisson_spatial
  )
  set.seed(2026070410)
  dat_zi$nb2_zi_spatial <- ifelse(
    stats::rbinom(nrow(dat_zi), size = 1L, prob = 0.25) == 1L,
    0L,
    dat_zi$nb2_spatial
  )
  fit_zi_mu <- drmTMB(
    bf(poisson_zi_spatial ~ x + spatial(1 | site, coords = coords_zi), zi ~ 1),
    family = stats::poisson(link = "log"),
    data = dat_zi,
    control = list(eval.max = 600, iter.max = 600)
  )
  expect_s3_class(fit_zi_mu, "drmTMB")
  expect_equal(fit_zi_mu$opt$convergence, 0)
  expect_true(fit_zi_mu$sdr$pdHess)
  expect_equal(fit_zi_mu$model$model_type, "zi_poisson")
  expect_equal(fit_zi_mu$model$dpars, c("mu", "zi"))
  expect_equal(fit_zi_mu$model$structured$phylo_mu$type, "spatial")
  expect_equal(fit_zi_mu$model$structured$phylo_mu$q, 1L)
  expect_named(fit_zi_mu$sdpars$mu, "spatial(1 | site)")
  expect_gt(unname(fit_zi_mu$sdpars$mu[["spatial(1 | site)"]]), 0)
  expect_equal(names(ranef(fit_zi_mu)), "spatial_mu")
  expect_equal(ranef(fit_zi_mu, "spatial_mu"), fit_zi_mu$random_effects$spatial_mu)
  sd_target <- profile_targets(fit_zi_mu)
  sd_target <- sd_target[
    sd_target$parm == "sd:mu:spatial(1 | site)",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)
  expect_true(all(is.finite(predict(fit_zi_mu, dpar = "mu", type = "link"))))
  expect_true(all(predict(fit_zi_mu, dpar = "mu") > 0))
  expect_true(all(is.finite(predict(fit_zi_mu, dpar = "zi", type = "link"))))
  fit_zi_nb2_mu <- drmTMB(
    bf(
      nb2_zi_spatial ~ x + spatial(1 | site, coords = coords_zi),
      sigma ~ 1,
      zi ~ 1
    ),
    family = nbinom2(),
    data = dat_zi,
    control = list(eval.max = 700, iter.max = 700)
  )
  expect_s3_class(fit_zi_nb2_mu, "drmTMB")
  expect_equal(fit_zi_nb2_mu$opt$convergence, 0)
  expect_equal(fit_zi_nb2_mu$model$model_type, "zi_nbinom2")
  expect_equal(fit_zi_nb2_mu$model$dpars, c("mu", "sigma", "zi"))
  expect_equal(fit_zi_nb2_mu$model$structured$phylo_mu$type, "spatial")
  expect_equal(fit_zi_nb2_mu$model$structured$phylo_mu$q, 1L)
  expect_named(fit_zi_nb2_mu$sdpars$mu, "spatial(1 | site)")
  expect_gt(unname(fit_zi_nb2_mu$sdpars$mu[["spatial(1 | site)"]]), 0)
  expect_equal(names(ranef(fit_zi_nb2_mu)), "spatial_mu")
  expect_equal(
    ranef(fit_zi_nb2_mu, "spatial_mu"),
    fit_zi_nb2_mu$random_effects$spatial_mu
  )
  sd_target <- profile_targets(fit_zi_nb2_mu)
  sd_target <- sd_target[
    sd_target$parm == "sd:mu:spatial(1 | site)",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)
  expect_true(all(is.finite(predict(fit_zi_nb2_mu, dpar = "mu", type = "link"))))
  expect_true(all(predict(fit_zi_nb2_mu, dpar = "mu") > 0))
  expect_true(all(sigma(fit_zi_nb2_mu) > 0))
  expect_true(all(is.finite(predict(fit_zi_nb2_mu, dpar = "zi", type = "link"))))
  expect_error(
    drmTMB(
      bf(
        nb2_zi_spatial ~ x + spatial(1 + x | site, coords = coords_zi),
        sigma ~ 1,
        zi ~ 1
      ),
      family = nbinom2(),
      data = dat_zi
    ),
    "intercept gate"
  )
  expect_error(
    drmTMB(
      bf(
        poisson_zi_spatial ~ x + spatial(1 | site, coords = coords_zi),
        zi ~ spatial(1 | site, coords = coords_zi)
      ),
      family = stats::poisson(link = "log"),
      data = dat_zi
    ),
    "cannot be combined"
  )
  # Row 105 (M5): the intercept-only two-provider location combo is now admitted
  # (spatial coordinate kernel + relatedness Q, each with its own group
  # precision). It builds and disambiguates the two fields onto separate internal
  # scales; jointly identifiable recovery lives in
  # test-count-multiprovider-structured-mu.R on a crossed design.
  fit_two_provider <- suppressWarnings(drmTMB(
    bf(
      nb2_spatial ~ x +
        spatial(1 | site, coords = coords) +
        relmat(1 | id, Q = Q),
      sigma ~ 1
    ),
    family = nbinom2(),
    data = dat,
    control = drm_control(
      se = FALSE, optimizer = list(eval.max = 500, iter.max = 500)
    )
  ))
  expect_s3_class(fit_two_provider, "drmTMB")
  expect_setequal(
    names(fit_two_provider$sdpars$mu),
    c("spatial(1 | site)", "relmat(1 | id)")
  )
  expect_true(all(
    c("spatial_mu", "relmat_mu") %in% names(ranef(fit_two_provider))
  ))
  two_provider_targets <- profile_targets(fit_two_provider)
  two_provider_targets <- two_provider_targets[
    startsWith(two_provider_targets$parm, "sd:mu:"),
    ,
    drop = FALSE
  ]
  expect_equal(
    two_provider_targets$tmb_parameter[
      two_provider_targets$parm == "sd:mu:spatial(1 | site)"
    ],
    "log_sd_phylo"
  )
  expect_equal(
    two_provider_targets$tmb_parameter[
      two_provider_targets$parm == "sd:mu:relmat(1 | id)"
    ],
    "log_sd_phylo2"
  )
  expect_error(
    drmTMB(
      bf(
        nb2_known ~ x + relmat(1 | id, Q = Q),
        sigma ~ animal(1 | id, Ainv = Q)
      ),
      family = nbinom2(),
      data = dat
    ),
    "cannot be combined"
  )
})
