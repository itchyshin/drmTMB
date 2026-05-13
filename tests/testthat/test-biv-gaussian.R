new_biv_gaussian_data <- function(
  n = 500,
  beta_rho12 = atanh(0.4),
  seed = 20260512
) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z1 = stats::rnorm(n),
    z2 = stats::rnorm(n),
    w = stats::rnorm(n)
  )
  beta_mu1 <- c(0.25, 0.55)
  beta_mu2 <- c(-0.15, -0.4)
  beta_sigma1 <- c(-0.35, 0.25)
  beta_sigma2 <- c(0.05, -0.2)

  mu1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * dat$x
  mu2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * dat$x
  sigma1 <- exp(beta_sigma1[[1L]] + beta_sigma1[[2L]] * dat$z1)
  sigma2 <- exp(beta_sigma2[[1L]] + beta_sigma2[[2L]] * dat$z2)
  eta_rho12 <- beta_rho12[[1L]] +
    if (length(beta_rho12) > 1L) {
      beta_rho12[[2L]] * dat$w
    } else {
      0
    }
  rho12 <- tanh(eta_rho12)

  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat$y1 <- mu1 + sigma1 * e1
  dat$y2 <- mu2 + sigma2 * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma1 = beta_sigma1,
    beta_sigma2 = beta_sigma2,
    beta_rho12 = beta_rho12
  )
}

mvn_loglik_biv <- function(y, mu, Sigma) {
  U <- chol(Sigma)
  z <- forwardsolve(t(U), y - mu)
  -0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(U))) + sum(z^2))
}

expect_biv_covariance_block_registry <- function(
  registry,
  dpars,
  responses,
  group,
  block,
  n_obs,
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
  expect_equal(members$component, sub("[0-9]+$", "", dpars))
  expect_equal(members$dpar, dpars)
  expect_equal(members$response_index, responses)
  expect_equal(members$coef, rep("(Intercept)", length(dpars)))
  expect_equal(members$group, rep(group, length(dpars)))
  expect_equal(members$block_label, rep(block, length(dpars)))
  expect_false(anyNA(members$source_term_id0))
  expect_false(anyNA(members$coef_pos0))
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
  expect_equal(pairs$from_coef, "(Intercept)")
  expect_equal(pairs$to_coef, "(Intercept)")
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
    match(sub("[0-9]+$", "", dpars), c("mu", "sigma")) - 1L
  )
  expect_equal(
    tmb$re_cov_member_dpar[member_idx],
    match(dpars, c("mu", "sigma", "mu1", "mu2", "sigma1", "sigma2")) - 1L
  )
  expect_equal(tmb$re_cov_member_response[member_idx], responses - 1L)
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

new_biv_gaussian_known_v_data <- function(
  n = 160,
  residual_rho = -0.35,
  sampling_cor = 0.6,
  seed = 20260516
) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu1 <- c(0.2, 0.5)
  beta_mu2 <- c(-0.1, -0.35)
  sigma1 <- 0.45
  sigma2 <- 0.55
  mu1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * dat$x
  mu2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * dat$x
  v1 <- stats::runif(n, min = 0.01, max = 0.04)
  v2 <- stats::runif(n, min = 0.01, max = 0.05)
  V <- meta_vcov_bivariate(v1 = v1, v2 = v2, cor12 = sampling_cor)

  y_stack <- numeric(2L * n)
  for (i in seq_len(n)) {
    S_i <- matrix(
      c(
        v1[[i]] + sigma1^2,
        sampling_cor * sqrt(v1[[i]] * v2[[i]]) + residual_rho * sigma1 * sigma2,
        sampling_cor * sqrt(v1[[i]] * v2[[i]]) + residual_rho * sigma1 * sigma2,
        v2[[i]] + sigma2^2
      ),
      nrow = 2L
    )
    y_stack[(2L * i - 1L):(2L * i)] <- as.vector(
      c(mu1[[i]], mu2[[i]]) + t(chol(S_i)) %*% stats::rnorm(2L)
    )
  }
  dat$y1 <- y_stack[seq.int(1L, by = 2L, length.out = n)]
  dat$y2 <- y_stack[seq.int(2L, by = 2L, length.out = n)]

  list(
    data = dat,
    V = V,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    sigma1 = sigma1,
    sigma2 = sigma2,
    residual_rho = residual_rho,
    sampling_cor = sampling_cor
  )
}

new_biv_gaussian_mu_re_data <- function(
  n_id = 60,
  n_each = 7,
  rho_group = 0.45,
  residual_rho = 0.25,
  seed = 2026051101
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  beta_mu1 <- c(0.2, 0.45)
  beta_mu2 <- c(-0.15, -0.35)
  sigma1 <- 0.35
  sigma2 <- 0.45
  sd_mu1 <- 0.55
  sd_mu2 <- 0.65

  u1 <- stats::rnorm(n_id)
  u2 <- rho_group * u1 + sqrt(1 - rho_group^2) * stats::rnorm(n_id)
  b1 <- sd_mu1 * u1
  b2 <- sd_mu2 * u2
  e1 <- stats::rnorm(n)
  e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)

  dat <- data.frame(id = id, x = x)
  dat$y1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * x + b1[id] + sigma1 * e1
  dat$y2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * x + b2[id] + sigma2 * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    sigma1 = sigma1,
    sigma2 = sigma2,
    sd_mu = c(
      "mu1:(1 | p | id)" = sd_mu1,
      "mu2:(1 | p | id)" = sd_mu2
    ),
    rho_group = rho_group,
    residual_rho = residual_rho
  )
}

new_biv_gaussian_sigma_re_data <- function(
  n_id = 48,
  n_each = 8,
  rho_scale = 0.45,
  residual_rho = 0.20,
  seed = 2026051201
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z1 <- stats::rnorm(n_id)
  z2 <- stats::rnorm(n_id)
  beta_mu1 <- c(0.2, 0.45)
  beta_mu2 <- c(-0.1, -0.35)
  beta_sigma1 <- log(0.38)
  beta_sigma2 <- log(0.52)
  sd_sigma1 <- 0.28
  sd_sigma2 <- 0.34

  b1 <- sd_sigma1 * z1
  b2 <- sd_sigma2 * (rho_scale * z1 + sqrt(1 - rho_scale^2) * z2)
  e1 <- stats::rnorm(n)
  e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)

  dat <- data.frame(id = id, x = x)
  dat$y1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * x + exp(beta_sigma1 + b1[id]) * e1
  dat$y2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * x + exp(beta_sigma2 + b2[id]) * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma = c(beta_sigma1, beta_sigma2),
    sd_sigma = c(
      "sigma1:(1 | p | id)" = sd_sigma1,
      "sigma2:(1 | p | id)" = sd_sigma2
    ),
    rho_scale = rho_scale,
    residual_rho = residual_rho
  )
}

new_biv_gaussian_joint_re_data <- function(
  n_id = 70,
  n_each = 9,
  rho_mu = 0.45,
  rho_scale = 0.35,
  beta_rho12 = c(atanh(0.12), 0.22),
  seed = 2026051304
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  beta_mu1 <- c(0.15, 0.35)
  beta_mu2 <- c(-0.20, -0.30)
  beta_sigma1 <- log(0.38)
  beta_sigma2 <- log(0.52)
  sd_mu1 <- 0.50
  sd_mu2 <- 0.60
  sd_sigma1 <- 0.35
  sd_sigma2 <- 0.42

  z_mu1 <- stats::rnorm(n_id)
  z_mu2 <- rho_mu * z_mu1 + sqrt(1 - rho_mu^2) * stats::rnorm(n_id)
  z_sigma1 <- stats::rnorm(n_id)
  z_sigma2 <- rho_scale * z_sigma1 + sqrt(1 - rho_scale^2) * stats::rnorm(n_id)
  b_mu1 <- sd_mu1 * z_mu1
  b_mu2 <- sd_mu2 * z_mu2
  b_sigma1 <- sd_sigma1 * z_sigma1
  b_sigma2 <- sd_sigma2 * z_sigma2
  rho12 <- tanh(beta_rho12[[1L]] + beta_rho12[[2L]] * x)
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)

  dat <- data.frame(id = id, x = x)
  dat$y1 <- beta_mu1[[1L]] +
    beta_mu1[[2L]] * x +
    b_mu1[id] +
    exp(beta_sigma1 + b_sigma1[id]) * e1
  dat$y2 <- beta_mu2[[1L]] +
    beta_mu2[[2L]] * x +
    b_mu2[id] +
    exp(beta_sigma2 + b_sigma2[id]) * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma = c(beta_sigma1, beta_sigma2),
    sd_mu = c(
      "mu1:(1 | pm | id)" = sd_mu1,
      "mu2:(1 | pm | id)" = sd_mu2
    ),
    sd_sigma = c(
      "sigma1:(1 | ps | id)" = sd_sigma1,
      "sigma2:(1 | ps | id)" = sd_sigma2
    ),
    rho_mu = rho_mu,
    rho_scale = rho_scale,
    beta_rho12 = beta_rho12
  )
}

new_biv_gaussian_mu_sigma_re_data <- function(
  n_id = 64,
  n_each = 8,
  rho_mu_sigma = 0.45,
  residual_rho = 0.20,
  seed = 2026051305
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  beta_mu1 <- c(0.20, 0.40)
  beta_mu2 <- c(-0.15, -0.30)
  beta_sigma1 <- log(0.42)
  beta_sigma2 <- log(0.55)
  sd_mu1 <- 0.55
  sd_sigma1 <- 0.34

  z_mu1 <- stats::rnorm(n_id)
  z_sigma1 <- rho_mu_sigma *
    z_mu1 +
    sqrt(1 - rho_mu_sigma^2) * stats::rnorm(n_id)
  b_mu1 <- sd_mu1 * z_mu1
  b_sigma1 <- sd_sigma1 * z_sigma1
  e1 <- stats::rnorm(n)
  e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)

  dat <- data.frame(id = id, x = x)
  dat$y1 <- beta_mu1[[1L]] +
    beta_mu1[[2L]] * x +
    b_mu1[id] +
    exp(beta_sigma1 + b_sigma1[id]) * e1
  dat$y2 <- beta_mu2[[1L]] +
    beta_mu2[[2L]] * x +
    exp(beta_sigma2) * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma = c(beta_sigma1, beta_sigma2),
    sd_mu = c("mu1:(1 | p | id)" = sd_mu1),
    sd_sigma = c("sigma1:(1 | p | id)" = sd_sigma1),
    rho_mu_sigma = rho_mu_sigma,
    residual_rho = residual_rho
  )
}

new_biv_gaussian_location_sd_data <- function(
  n_id = 42,
  n_each = 7,
  rho_group = 0.35,
  residual_rho = 0.10,
  seed = 2026051306
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  w1_group <- stats::rnorm(n_id)
  w2_group <- stats::rnorm(n_id)
  w1 <- w1_group[id]
  w2 <- w2_group[id]
  beta_mu1 <- c(0.15, 0.35)
  beta_mu2 <- c(-0.10, -0.30)
  beta_sigma1 <- log(0.42)
  beta_sigma2 <- log(0.48)
  alpha1 <- c(`(Intercept)` = log(0.38), w1 = 0.45)
  alpha2 <- c(`(Intercept)` = log(0.52), w2 = -0.35)

  tau1 <- exp(alpha1[[1L]] + alpha1[[2L]] * w1_group)
  tau2 <- exp(alpha2[[1L]] + alpha2[[2L]] * w2_group)
  z1 <- stats::rnorm(n_id)
  z2 <- rho_group * z1 + sqrt(1 - rho_group^2) * stats::rnorm(n_id)
  b1 <- tau1 * z1
  b2 <- tau2 * z2
  e1 <- stats::rnorm(n)
  e2 <- residual_rho * e1 + sqrt(1 - residual_rho^2) * stats::rnorm(n)

  dat <- data.frame(id = id, x = x, w1 = w1, w2 = w2)
  dat$y1 <- beta_mu1[[1L]] + beta_mu1[[2L]] * x + b1[id] + exp(beta_sigma1) * e1
  dat$y2 <- beta_mu2[[1L]] + beta_mu2[[2L]] * x + b2[id] + exp(beta_sigma2) * e2

  list(
    data = dat,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma = c(beta_sigma1, beta_sigma2),
    alpha1 = alpha1,
    alpha2 = alpha2,
    tau1 = tau1,
    tau2 = tau2,
    rho_group = rho_group,
    residual_rho = residual_rho
  )
}

expect_abs_error_below <- function(actual, expected, tolerance) {
  expect_lt(max(abs(unname(actual) - unname(expected))), tolerance)
}

test_that("drmTMB fits bivariate Gaussian models with constant rho12", {
  sim <- new_biv_gaussian_data(n = 900, beta_rho12 = atanh(0.4))

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_abs_error_below(coef(fit, "mu1"), sim$beta_mu1, 0.12)
  expect_abs_error_below(coef(fit, "mu2"), sim$beta_mu2, 0.12)
  expect_abs_error_below(coef(fit, "sigma1"), sim$beta_sigma1, 0.12)
  expect_abs_error_below(coef(fit, "sigma2"), sim$beta_sigma2, 0.12)
  expect_abs_error_below(coef(fit, "rho12"), sim$beta_rho12, 0.12)
  expect_length(predict(fit), nrow(sim$data))
  expect_true(all(abs(predict(fit, dpar = "rho12")) < 1))
  expect_equal(rho12(fit), predict(fit, dpar = "rho12"), tolerance = 1e-12)
  expect_equal(
    rho12(fit, type = "link"),
    predict(fit, dpar = "rho12", type = "link"),
    tolerance = 1e-12
  )
})

test_that("bivariate Gaussian supports labelled mu1/mu2 random-intercept covariance blocks", {
  sim <- new_biv_gaussian_mu_re_data()

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = sim$data
  )

  fixed_mu1 <- as.vector(
    stats::model.matrix(~x, sim$data) %*% coef(fit, "mu1")
  )
  fixed_mu2 <- as.vector(
    stats::model.matrix(~x, sim$data) %*% coef(fit, "mu2")
  )
  pairs <- corpairs(fit)
  group_pair <- pairs[pairs$level == "group", , drop = FALSE]
  residual_pair <- pairs[pairs$level == "residual", , drop = FALSE]

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_abs_error_below(coef(fit, "mu1"), sim$beta_mu1, 0.22)
  expect_abs_error_below(coef(fit, "mu2"), sim$beta_mu2, 0.15)
  expect_abs_error_below(
    c(mean(stats::sigma(fit)$sigma1), mean(stats::sigma(fit)$sigma2)),
    c(sim$sigma1, sim$sigma2),
    0.12
  )
  expect_abs_error_below(fit$sdpars$mu, sim$sd_mu, 0.22)
  expect_lt(abs(unname(fit$corpars$mu) - sim$rho_group), 0.28)
  expect_lt(abs(tanh(unname(coef(fit, "rho12"))) - sim$residual_rho), 0.12)
  expect_named(
    fit$corpars$mu,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  )
  expect_equal(length(fit$random_effects$mu$values), 2 * nlevels(sim$data$id))
  expect_biv_covariance_block_registry(
    fit$model$random$covariance_blocks,
    dpars = c("mu1", "mu2"),
    responses = c(1L, 2L),
    group = "id",
    block = "p",
    n_obs = fit$nobs,
    class = "mean-mean"
  )
  expect_covariance_block_tmb_data_exported(fit)
  expect_covariance_block_tmb_data_noop(fit)
  expect_gt(stats::sd(predict(fit, dpar = "mu1") - fixed_mu1), 0.05)
  expect_gt(stats::sd(predict(fit, dpar = "mu2") - fixed_mu2), 0.05)
  expect_equal(
    predict(fit, newdata = sim$data[1:3, ], dpar = "mu1"),
    fixed_mu1[1:3],
    tolerance = 1e-12
  )
  expect_equal(group_pair$from_dpar, "mu1")
  expect_equal(group_pair$to_dpar, "mu2")
  expect_equal(group_pair$group, "id")
  expect_equal(group_pair$block, "p")
  expect_equal(group_pair$from_response, "y1")
  expect_equal(group_pair$to_response, "y2")
  expect_equal(group_pair$class, "mean-mean")
  expect_equal(group_pair$estimate, unname(fit$corpars$mu), tolerance = 1e-12)
  expect_equal(residual_pair$from_dpar, "residual")
  expect_equal(residual_pair$to_dpar, "residual")
  expect_equal(residual_pair$parameter, "rho12")
  expect_equal(residual_pair$class, "residual")
  expect_equal(residual_pair$from_response, "y1")
  expect_equal(residual_pair$to_response, "y2")
  expect_equal(nrow(corpairs(fit, level = "group")), 1L)
  expect_equal(nrow(corpairs(fit, level = "residual")), 1L)
  expect_equal(nrow(corpairs(fit, class = "mean-mean")), 1L)
  expect_equal(nrow(corpairs(fit, class = "residual")), 1L)
  expect_equal(nrow(corpairs(fit, group = "id")), 1L)
  expect_equal(nrow(corpairs(fit, block = "p")), 1L)
  expect_equal(nrow(corpairs(fit, group = "missing")), 0L)
  expect_equal(nrow(corpairs(fit, block = "missing")), 0L)
})

test_that("bivariate Gaussian supports sd1(id) and sd2(id) location random-effect SD models", {
  sim <- new_biv_gaussian_location_sd_data()

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      sd1(id) ~ w1,
      sd2(id) ~ w2
    ),
    family = biv_gaussian(),
    data = sim$data,
    control = list(eval.max = 350, iter.max = 350)
  )

  sd1_hat <- predict(fit, dpar = "sd1(id)")
  sd2_hat <- predict(fit, dpar = "sd2(id)")

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(
    fit$coefficients,
    c("mu1", "mu2", "sigma1", "sigma2", "rho12", "sd1(id)", "sd2(id)")
  )
  expect_named(fit$sdpars, c("sd1(id)", "sd2(id)"))
  expect_false("mu" %in% names(fit$sdpars))
  expect_equal(unname(fit$model$random_scale$mu$target_coef), c(1L, 2L))
  expect_true(all(fit$model$random_scale$mu$re_sd_row0 >= 0L))
  expect_true(all(sd1_hat > 0))
  expect_true(all(sd2_hat > 0))
  expect_equal(length(sd1_hat), nlevels(sim$data$id))
  expect_equal(length(sd2_hat), nlevels(sim$data$id))
  expect_gt(stats::cor(log(sd1_hat), log(sim$tau1)), 0.35)
  expect_gt(stats::cor(log(sd2_hat), log(sim$tau2)), 0.35)
  expect_lt(max(abs(unname(coef(fit, "sd1(id)")) - unname(sim$alpha1))), 0.55)
  expect_lt(max(abs(unname(coef(fit, "sd2(id)")) - unname(sim$alpha2))), 0.65)
  expect_equal(nrow(corpairs(fit, level = "group")), 1L)
})

test_that("bivariate Gaussian sd1(id) and sd2(id) reject non-location and observation-level targets", {
  sim <- new_biv_gaussian_location_sd_data(n_id = 16, n_each = 4)
  dat <- sim$data
  dat$site <- dat$id

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x + (1 | p | id),
        sigma1 = ~1,
        sigma2 = ~1,
        sd1(id) ~ w1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "No bivariate location random-effect term matches"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 | p | id),
        mu2 = y2 ~ x + (1 | p | id),
        sigma1 = ~1,
        sigma2 = ~1,
        sd2(site) ~ w2
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "No bivariate location random-effect term matches"
  )

  dat$w_obs <- stats::rnorm(nrow(dat))
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 | p | id),
        mu2 = y2 ~ x + (1 | p | id),
        sigma1 = ~1,
        sigma2 = ~1,
        sd1(id) ~ w_obs
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "varies within"
  )
  expect_error(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sd_sigma1(id) ~ w1
    ),
    "not a supported"
  )
  expect_error(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sd_phylo(id) ~ w1
    ),
    "planned but not implemented"
  )
})

test_that("bivariate Gaussian supports labelled sigma1/sigma2 random-intercept covariance blocks", {
  sim <- new_biv_gaussian_sigma_re_data()

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~ 1 + (1 | p | id),
      sigma2 = ~ 1 + (1 | p | id),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = sim$data,
    control = list(eval.max = 300, iter.max = 300)
  )

  fixed_sigma1 <- as.vector(
    stats::model.matrix(~1, sim$data) %*% coef(fit, "sigma1")
  )
  fixed_sigma2 <- as.vector(
    stats::model.matrix(~1, sim$data) %*% coef(fit, "sigma2")
  )
  sigma1_link <- predict(fit, dpar = "sigma1", type = "link")
  sigma2_link <- predict(fit, dpar = "sigma2", type = "link")
  pairs <- corpairs(fit)
  group_pair <- pairs[pairs$level == "group", , drop = FALSE]
  residual_pair <- pairs[pairs$level == "residual", , drop = FALSE]
  smry <- summary(fit)
  targets <- profile_targets(fit)
  chk <- check_drm(fit)
  scale_cov <- chk[chk$check == "biv_sigma_random_effect_covariance", ]

  sd_sigma1 <- "sd:sigma:sigma1:(1 | p | id)"
  sd_sigma2 <- "sd:sigma:sigma2:(1 | p | id)"
  cor_sigma <- "cor:sigma:cor(sigma1:(Intercept),sigma2:(Intercept) | p | id)"
  sigma_targets <- targets[
    match(c(sd_sigma1, sd_sigma2, cor_sigma), targets$parm),
  ]

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$sdr$pdHess, TRUE)
  expect_abs_error_below(coef(fit, "mu1"), sim$beta_mu1, 0.18)
  expect_abs_error_below(coef(fit, "mu2"), sim$beta_mu2, 0.18)
  expect_abs_error_below(coef(fit, "sigma1"), sim$beta_sigma[[1L]], 0.25)
  expect_abs_error_below(coef(fit, "sigma2"), sim$beta_sigma[[2L]], 0.25)
  expect_abs_error_below(fit$sdpars$sigma, sim$sd_sigma, 0.22)
  expect_lt(abs(unname(fit$corpars$sigma) - sim$rho_scale), 0.35)
  expect_lt(abs(tanh(unname(coef(fit, "rho12"))) - sim$residual_rho), 0.15)
  expect_named(
    fit$corpars$sigma,
    "cor(sigma1:(Intercept),sigma2:(Intercept) | p | id)"
  )
  expect_equal(
    length(fit$random_effects$sigma$values),
    2 * nlevels(sim$data$id)
  )
  expect_biv_covariance_block_registry(
    fit$model$random$covariance_blocks,
    dpars = c("sigma1", "sigma2"),
    responses = c(1L, 2L),
    group = "id",
    block = "p",
    n_obs = fit$nobs,
    class = "scale-scale"
  )
  expect_covariance_block_tmb_data_exported(fit)
  expect_gt(stats::sd(sigma1_link - fixed_sigma1), 0.03)
  expect_gt(stats::sd(sigma2_link - fixed_sigma2), 0.03)
  expect_equal(stats::sigma(fit)$sigma1, exp(sigma1_link), tolerance = 1e-12)
  expect_equal(stats::sigma(fit)$sigma2, exp(sigma2_link), tolerance = 1e-12)
  expect_equal(
    predict(fit, newdata = sim$data[1:3, ], dpar = "sigma1", type = "link"),
    fixed_sigma1[1:3],
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = sim$data[1:3, ], dpar = "sigma2", type = "link"),
    fixed_sigma2[1:3],
    tolerance = 1e-12
  )

  expect_equal(group_pair$from_dpar, "sigma1")
  expect_equal(group_pair$to_dpar, "sigma2")
  expect_equal(group_pair$group, "id")
  expect_equal(group_pair$block, "p")
  expect_equal(group_pair$class, "scale-scale")
  expect_equal(
    group_pair$estimate,
    unname(fit$corpars$sigma),
    tolerance = 1e-12
  )
  fit_registry <- fit
  names(fit_registry$corpars$sigma) <- "cor(bad,bad | wrong | wrong)"
  registry_scale <- corpairs(fit_registry, class = "scale-scale")
  expect_equal(registry_scale$group, "id")
  expect_equal(registry_scale$block, "p")
  expect_equal(registry_scale$from_dpar, "sigma1")
  expect_equal(registry_scale$to_dpar, "sigma2")
  expect_equal(
    registry_scale$parameter,
    "cor(sigma1:(Intercept),sigma2:(Intercept) | p | id)"
  )
  expect_equal(
    registry_scale$estimate,
    unname(fit$corpars$sigma),
    tolerance = 1e-12
  )
  expect_equal(residual_pair$parameter, "rho12")
  expect_equal(residual_pair$class, "residual")
  expect_equal(nrow(corpairs(fit, level = "group")), 1L)
  expect_equal(nrow(corpairs(fit, class = "scale-scale")), 1L)
  expect_equal(nrow(corpairs(fit, class = "mean-mean")), 0L)
  expect_equal(nrow(corpairs(fit, block = "p")), 1L)

  expect_true(all(
    c(sd_sigma1, sd_sigma2, cor_sigma) %in% rownames(smry$parameters)
  ))
  expect_equal(smry$parameters[sd_sigma1, "component"], "random-effect-sd")
  expect_equal(smry$parameters[sd_sigma2, "component"], "random-effect-sd")
  expect_equal(
    smry$parameters[cor_sigma, "component"],
    "random-effect-correlation"
  )
  expect_equal(
    smry$parameters[cor_sigma, "estimate"],
    unname(fit$corpars$sigma)
  )
  expect_equal(
    sigma_targets$tmb_parameter,
    c("log_sd_sigma", "log_sd_sigma", "eta_cor_sigma")
  )
  expect_equal(
    sigma_targets$target_class,
    c(
      "random-effect-sd",
      "random-effect-sd",
      "random-effect-correlation"
    )
  )
  expect_equal(sigma_targets$index, c(1L, 2L, 1L))
  expect_true(all(sigma_targets$profile_ready))
  fit_target_registry <- fit
  names(fit_target_registry$corpars$sigma) <- "cor(bad,bad | wrong | wrong)"
  registry_sigma_targets <- profile_targets(fit_target_registry)
  expect_true(cor_sigma %in% registry_sigma_targets$parm)
  expect_equal(scale_cov$status, "ok")
  expect_match(scale_cov$value, "n_groups=48")
  expect_match(scale_cov$value, "min_group_n=8")
  expect_match(scale_cov$message, "scale-scale")

  singleton_registry <- fit
  member_row <- which(
    singleton_registry$model$random$covariance_blocks$members$dpar == "sigma1"
  )[[1L]]
  member_index <-
    singleton_registry$model$random$covariance_blocks$members$latent_index0[[
      member_row
    ]]
  first_group <- min(member_index[member_index >= 0L])
  member_index[which(member_index == first_group)[-1L]] <- first_group + 1L
  singleton_registry$model$random$covariance_blocks$members$latent_index0[[
    member_row
  ]] <- member_index
  singleton_cov <- check_drm(singleton_registry)
  singleton_scale <- singleton_cov[
    singleton_cov$check == "biv_sigma_random_effect_covariance",
  ]
  expect_equal(singleton_scale$status, "note")
  expect_match(singleton_scale$value, "singleton_groups=1")
  expect_match(singleton_scale$message, "fewer than two")
})

test_that("bivariate Gaussian keeps mu and sigma covariance blocks distinct", {
  sim <- new_biv_gaussian_joint_re_data()

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | pm | id),
      mu2 = y2 ~ x + (1 | pm | id),
      sigma1 = ~ 1 + (1 | ps | id),
      sigma2 = ~ 1 + (1 | ps | id),
      rho12 = ~x
    ),
    family = biv_gaussian(),
    data = sim$data,
    control = list(eval.max = 500, iter.max = 500)
  )

  pairs <- corpairs(fit)
  group_pairs <- pairs[pairs$level == "group", , drop = FALSE]
  mean_pair <- pairs[pairs$class == "mean-mean", , drop = FALSE]
  scale_pair <- pairs[pairs$class == "scale-scale", , drop = FALSE]
  residual_pair <- pairs[pairs$class == "residual", , drop = FALSE]
  smry <- summary(fit)
  summary_covariance <- smry$covariance
  summary_mean_covariance <- summary_covariance[
    summary_covariance$class == "mean-mean",
    ,
    drop = FALSE
  ]
  summary_scale_covariance <- summary_covariance[
    summary_covariance$class == "scale-scale",
    ,
    drop = FALSE
  ]
  targets <- profile_targets(fit)
  chk <- check_drm(fit)
  cov_checks <- chk[
    chk$check %in%
      c(
        "biv_mu_random_effect_covariance",
        "biv_sigma_random_effect_covariance"
      ),
  ]

  target_names <- c(
    "sd:mu:mu1:(1 | pm | id)",
    "sd:mu:mu2:(1 | pm | id)",
    "cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | pm | id)",
    "sd:sigma:sigma1:(1 | ps | id)",
    "sd:sigma:sigma2:(1 | ps | id)",
    "cor:sigma:cor(sigma1:(Intercept),sigma2:(Intercept) | ps | id)"
  )
  joint_targets <- targets[match(target_names, targets$parm), ]

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$sdr$pdHess, TRUE)
  expect_abs_error_below(coef(fit, "mu1"), sim$beta_mu1, 0.12)
  expect_abs_error_below(coef(fit, "mu2"), sim$beta_mu2, 0.12)
  expect_abs_error_below(coef(fit, "sigma1"), sim$beta_sigma[[1L]], 0.18)
  expect_abs_error_below(coef(fit, "sigma2"), sim$beta_sigma[[2L]], 0.18)
  expect_abs_error_below(fit$sdpars$mu, sim$sd_mu, 0.18)
  expect_abs_error_below(fit$sdpars$sigma, sim$sd_sigma, 0.18)
  expect_lt(abs(unname(fit$corpars$mu) - sim$rho_mu), 0.25)
  expect_lt(abs(unname(fit$corpars$sigma) - sim$rho_scale), 0.18)
  expect_abs_error_below(coef(fit, "rho12"), sim$beta_rho12, 0.12)
  expect_equal(
    fit$model$random$mu$coef_names,
    c("(Intercept)", "(Intercept)")
  )
  expect_equal(fit$model$random$mu$group_names, c("id", "id"))
  expect_equal(fit$model$random$mu$covariance_labels, c("pm", "pm"))
  expect_equal(
    fit$model$random$sigma$coef_names,
    c("(Intercept)", "(Intercept)")
  )
  expect_equal(fit$model$random$sigma$group_names, c("id", "id"))
  expect_equal(fit$model$random$sigma$covariance_labels, c("ps", "ps"))
  expect_biv_covariance_block_registry(
    fit$model$random$covariance_blocks,
    dpars = c("mu1", "mu2"),
    responses = c(1L, 2L),
    group = "id",
    block = "pm",
    n_obs = fit$nobs,
    class = "mean-mean"
  )
  expect_biv_covariance_block_registry(
    fit$model$random$covariance_blocks,
    dpars = c("sigma1", "sigma2"),
    responses = c(1L, 2L),
    group = "id",
    block = "ps",
    n_obs = fit$nobs,
    class = "scale-scale"
  )
  expect_covariance_block_tmb_data_exported(fit)

  expect_equal(nrow(pairs), 3L)
  expect_equal(nrow(group_pairs), 2L)
  expect_equal(nrow(mean_pair), 1L)
  expect_equal(nrow(scale_pair), 1L)
  expect_equal(nrow(residual_pair), 1L)
  expect_equal(nrow(corpairs(fit, group = "id")), 2L)
  expect_equal(nrow(corpairs(fit, block = "pm")), 1L)
  expect_equal(nrow(corpairs(fit, block = "ps")), 1L)
  expect_equal(mean_pair$block, "pm")
  expect_equal(mean_pair$from_dpar, "mu1")
  expect_equal(mean_pair$to_dpar, "mu2")
  expect_equal(mean_pair$estimate, unname(fit$corpars$mu), tolerance = 1e-12)
  expect_equal(scale_pair$block, "ps")
  expect_equal(scale_pair$from_dpar, "sigma1")
  expect_equal(scale_pair$to_dpar, "sigma2")
  expect_equal(
    scale_pair$estimate,
    unname(fit$corpars$sigma),
    tolerance = 1e-12
  )
  expect_equal(nrow(summary_covariance), 2L)
  expect_setequal(summary_covariance$block, c("pm", "ps"))
  expect_setequal(summary_covariance$class, c("mean-mean", "scale-scale"))
  expect_false(any(grepl("rho12", summary_covariance$parameter, fixed = TRUE)))
  expect_equal(
    summary_covariance$covariance_conf.status,
    rep("not_requested", 2L)
  )
  expect_equal(summary_mean_covariance$from_dpar, "mu1")
  expect_equal(summary_mean_covariance$to_dpar, "mu2")
  expect_equal(summary_mean_covariance$from_scale, "identity")
  expect_equal(summary_mean_covariance$to_scale, "identity")
  expect_equal(
    summary_mean_covariance$covariance,
    unname(fit$sdpars$mu[[1L]]) *
      unname(fit$sdpars$mu[[2L]]) *
      unname(fit$corpars$mu[[1L]]),
    tolerance = 1e-12
  )
  expect_equal(summary_scale_covariance$from_dpar, "sigma1")
  expect_equal(summary_scale_covariance$to_dpar, "sigma2")
  expect_equal(summary_scale_covariance$from_scale, "log")
  expect_equal(summary_scale_covariance$to_scale, "log")
  expect_equal(
    summary_scale_covariance$covariance,
    unname(fit$sdpars$sigma[[1L]]) *
      unname(fit$sdpars$sigma[[2L]]) *
      unname(fit$corpars$sigma[[1L]]),
    tolerance = 1e-12
  )
  fit_partial_registry <- fit
  fit_partial_registry$model$random$covariance_blocks$pairs <-
    fit_partial_registry$model$random$covariance_blocks$pairs[
      fit_partial_registry$model$random$covariance_blocks$pairs$tmb_parameter ==
        "eta_cor_mu",
      ,
      drop = FALSE
    ]
  partial_group_pairs <- corpairs(fit_partial_registry, level = "group")
  expect_equal(nrow(partial_group_pairs), 2L)
  expect_setequal(partial_group_pairs$block, c("pm", "ps"))
  expect_equal(
    partial_group_pairs$parameter[partial_group_pairs$block == "ps"],
    names(fit$corpars$sigma)
  )
  expect_equal(residual_pair$parameter, "rho12")
  expect_equal(residual_pair$modelled, TRUE)
  expect_gt(residual_pair$max - residual_pair$min, 0.05)

  expect_true(all(target_names %in% rownames(smry$parameters)))
  expect_equal(
    smry$parameters[target_names[3L], "component"],
    "random-effect-correlation"
  )
  expect_equal(
    smry$parameters[target_names[6L], "component"],
    "random-effect-correlation"
  )
  expect_equal(
    joint_targets$tmb_parameter,
    c(
      "log_sd_mu",
      "log_sd_mu",
      "eta_cor_mu",
      "log_sd_sigma",
      "log_sd_sigma",
      "eta_cor_sigma"
    )
  )
  expect_equal(joint_targets$index, c(1L, 2L, 1L, 1L, 2L, 1L))
  expect_true(all(joint_targets$profile_ready))
  expect_equal(cov_checks$status, c("ok", "ok"))
  expect_match(cov_checks$value, "n_groups=70", all = FALSE)
  expect_match(cov_checks$message, "covariance", all = FALSE)
  expect_match(cov_checks$message, "scale-scale", all = FALSE)
})

test_that("bivariate Gaussian fits same-response mu/sigma covariance", {
  sim <- new_biv_gaussian_mu_sigma_re_data()
  form <- bf(
    mu1 = y1 ~ x + (1 | p | id),
    mu2 = y2 ~ x,
    sigma1 = ~ 1 + (1 | p | id),
    sigma2 = ~1,
    rho12 = ~1
  )
  spec <- drmTMB:::drm_build_biv_gaussian_spec(
    form,
    data = sim$data,
    env = environment(),
    weights = NULL
  )
  re_sigma <- spec$random$sigma
  re_mu_sigma <- spec$random$mu_sigma
  rho_transform <- 0.4
  transform_par <- list(
    u_mu = seq(-0.8, 0.7, length.out = spec$random$mu$n_re),
    u_sigma = seq(0.9, -0.6, length.out = re_sigma$n_re),
    log_sd_sigma = log(sim$sd_sigma),
    eta_cor_sigma = 0,
    eta_cor_mu_sigma = atanh(rho_transform / 0.999999)
  )

  transformed <- drmTMB:::transform_biv_sigma_random_effects(
    latent = transform_par$u_sigma,
    par = transform_par,
    re_sigma = re_sigma,
    re_mu_sigma = re_mu_sigma
  )
  matched <- which(re_mu_sigma$sigma_cross_cor_id0 >= 0L)
  mu_idx <- re_mu_sigma$sigma_cross_mu_index0[matched] + 1L
  expected_transform <- unname(sim$sd_sigma) *
    (rho_transform *
      transform_par$u_mu[mu_idx] +
      sqrt(1 - rho_transform^2) * transform_par$u_sigma[matched])

  fit <- drmTMB(
    form,
    family = biv_gaussian(),
    data = sim$data,
    control = list(eval.max = 500, iter.max = 500)
  )

  pairs <- corpairs(fit)
  mean_scale <- pairs[pairs$class == "mean-scale", , drop = FALSE]
  residual_pair <- pairs[pairs$class == "residual", , drop = FALSE]
  targets <- profile_targets(fit)
  target_names <- c(
    "sd:mu:mu1:(1 | p | id)",
    "sd:sigma:sigma1:(1 | p | id)",
    "cor:mu_sigma:cor(mu1:(Intercept),sigma1:(Intercept) | p | id)"
  )
  cross_targets <- targets[match(target_names, targets$parm), ]
  chk <- check_drm(fit)
  cov_check <- chk[chk$check == "biv_mu_sigma_random_effect_covariance", ]

  expect_equal(spec$tmb_data$n_sigma_re_cors, 0L)
  expect_equal(spec$tmb_data$n_mu_sigma_re_cors, 1L)
  expect_equal(re_mu_sigma$n_cors, 1L)
  expect_equal(unique(re_mu_sigma$sigma_cross_cor_id0[matched]), 0L)
  expect_equal(
    spec$tmb_data$sigma_re_cross_cor,
    re_mu_sigma$sigma_cross_cor_id0
  )
  expect_equal(
    spec$tmb_data$sigma_re_cross_mu,
    re_mu_sigma$sigma_cross_mu_index0
  )
  expect_length(matched, nlevels(sim$data$id))
  expect_equal(transformed[matched], expected_transform)

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$sdr$pdHess, TRUE)
  expect_abs_error_below(coef(fit, "mu1"), sim$beta_mu1, 0.15)
  expect_abs_error_below(coef(fit, "mu2"), sim$beta_mu2, 0.15)
  expect_abs_error_below(coef(fit, "sigma1"), sim$beta_sigma[[1L]], 0.20)
  expect_abs_error_below(coef(fit, "sigma2"), sim$beta_sigma[[2L]], 0.14)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_mu), 0.25)
  expect_lt(abs(unname(fit$sdpars$sigma) - sim$sd_sigma), 0.22)
  expect_named(
    fit$corpars$mu_sigma,
    "cor(mu1:(Intercept),sigma1:(Intercept) | p | id)"
  )
  expect_lt(abs(unname(fit$corpars$mu_sigma) - sim$rho_mu_sigma), 0.35)
  expect_equal(nrow(pairs), 2L)
  expect_equal(nrow(mean_scale), 1L)
  expect_equal(nrow(residual_pair), 1L)
  expect_equal(mean_scale$level, "group")
  expect_equal(mean_scale$group, "id")
  expect_equal(mean_scale$block, "p")
  expect_equal(mean_scale$from_dpar, "mu1")
  expect_equal(mean_scale$to_dpar, "sigma1")
  expect_equal(mean_scale$from_response, "y1")
  expect_equal(mean_scale$to_response, "y1")
  expect_equal(
    mean_scale$estimate,
    unname(fit$corpars$mu_sigma),
    tolerance = 1e-12
  )
  expect_equal(
    cross_targets$tmb_parameter,
    c("log_sd_mu", "log_sd_sigma", "eta_cor_mu_sigma")
  )
  expect_equal(cross_targets$index, c(1L, 1L, 1L))
  expect_true(all(cross_targets$profile_ready))
  fit_target_registry <- fit
  names(fit_target_registry$corpars$mu_sigma) <- "cor(bad,bad | wrong | wrong)"
  registry_cross_targets <- profile_targets(fit_target_registry)
  expect_true(target_names[[3L]] %in% registry_cross_targets$parm)
  expect_equal(cov_check$status, "ok")
  expect_match(cov_check$value, "n_groups=64")
  expect_match(cov_check$message, "mu/sigma")
})

test_that("composed Gaussian family syntax routes to bivariate Gaussian", {
  sim <- new_biv_gaussian_data(
    n = 400,
    beta_rho12 = atanh(0.3),
    seed = 20260561
  )

  fit_c <- drmTMB(
    drm_formula(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )
  fit_list <- drmTMB(
    drm_formula(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family = list(gaussian(), gaussian()),
    data = sim$data
  )

  expect_equal(fit_c$model$model_type, "biv_gaussian")
  expect_equal(fit_list$model$model_type, "biv_gaussian")
  expect_equal(fit_c$opt$convergence, 0)
  expect_equal(fit_list$opt$convergence, 0)
  expect_abs_error_below(coef(fit_c, "rho12"), atanh(0.3), 0.15)
})

test_that("mvbind shorthand expands to identical bivariate location formulas", {
  sim <- new_biv_gaussian_data(
    n = 360,
    beta_rho12 = atanh(0.25),
    seed = 20260562
  )

  fit_explicit <- drmTMB(
    drm_formula(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )
  fit_mvbind <- drmTMB(
    drm_formula(
      mvbind(y1, y2) ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )

  expect_equal(fit_mvbind$opt$convergence, 0)
  expect_equal(fit_mvbind$model$model_type, "biv_gaussian")
  expect_equal(
    fit_mvbind$model$dpars,
    c("mu1", "mu2", "sigma1", "sigma2", "rho12")
  )
  expect_equal(fit_mvbind$model$y1, sim$data$y1)
  expect_equal(fit_mvbind$model$y2, sim$data$y2)
  expect_equal(
    as.numeric(stats::logLik(fit_mvbind)),
    as.numeric(stats::logLik(fit_explicit)),
    tolerance = 1e-8
  )
  expect_equal(
    coef(fit_mvbind, "mu1"),
    coef(fit_explicit, "mu1"),
    tolerance = 1e-8
  )
  expect_equal(
    coef(fit_mvbind, "mu2"),
    coef(fit_explicit, "mu2"),
    tolerance = 1e-8
  )
})

test_that("drmTMB recovers predictor-dependent bivariate rho12", {
  sim <- new_biv_gaussian_data(
    n = 1200,
    beta_rho12 = c(-0.1, 0.45),
    seed = 20260513
  )

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~w
    ),
    family = biv_gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_abs_error_below(coef(fit, "rho12"), sim$beta_rho12, 0.12)
  expect_equal(
    predict(fit, dpar = "rho12", type = "link"),
    as.vector(stats::model.matrix(~w, sim$data) %*% coef(fit, "rho12")),
    tolerance = 1e-12
  )
  expect_true(all(abs(predict(fit, dpar = "rho12")) < 1))

  pearson <- residuals(fit, type = "pearson")
  expect_lt(abs(stats::cor(pearson[, "y1"], pearson[, "y2"])), 0.08)
  expect_lt(abs(stats::sd(pearson[, "y1"]) - 1), 0.1)
  expect_lt(abs(stats::sd(pearson[, "y2"]) - 1), 0.1)

  newdata <- data.frame(
    x = c(-0.5, 0.2),
    z1 = c(0, 1),
    z2 = c(1, 0),
    w = c(-1, 1)
  )
  expect_equal(length(predict(fit, newdata = newdata, dpar = "rho12")), 2)
  expect_equal(
    rho12(fit, newdata = newdata),
    predict(fit, newdata = newdata, dpar = "rho12"),
    tolerance = 1e-12
  )
})

test_that("bivariate rho12 handles near-zero and negative correlations", {
  targets <- c(near_zero = 0.02, negative = -0.45)
  for (i in seq_along(targets)) {
    sim <- new_biv_gaussian_data(
      n = 700,
      beta_rho12 = atanh(targets[[i]]),
      seed = 20260520 + i
    )
    fit <- drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~z1,
        sigma2 = ~z2,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = sim$data
    )

    expect_equal(fit$opt$convergence, 0)
    expect_lt(abs(tanh(unname(coef(fit, "rho12"))) - targets[[i]]), 0.12)
  }
})

test_that("bivariate rho12 handles high positive and high negative correlations", {
  targets <- c(high_positive = 0.8, high_negative = -0.8)
  for (i in seq_along(targets)) {
    sim <- new_biv_gaussian_data(
      n = 1200,
      beta_rho12 = atanh(targets[[i]]),
      seed = 20260620 + i
    )
    fit <- drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~z1,
        sigma2 = ~z2,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = sim$data
    )

    rho_hat <- predict(fit, dpar = "rho12")

    expect_equal(fit$opt$convergence, 0)
    expect_equal(fit$sdr$pdHess, TRUE)
    expect_lt(abs(tanh(unname(coef(fit, "rho12"))) - targets[[i]]), 0.15)
    expect_lt(max(abs(rho_hat)), 1)
    expect_equal(rho_hat, rho12(fit), tolerance = 1e-12)
  }
})

test_that("bivariate Gaussian methods return expected structures", {
  sim <- new_biv_gaussian_data(
    n = 160,
    beta_rho12 = atanh(0.25),
    seed = 20260514
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family = biv_gaussian(),
    data = sim$data
  )

  fitted_mu <- stats::fitted(fit)
  sig <- stats::sigma(fit)
  sims <- simulate(fit, nsim = 2, seed = 1)
  res <- residuals(fit)
  pearson <- residuals(fit, type = "pearson")

  expect_equal(fit$opt$convergence, 0)
  expect_equal(dim(fitted_mu), c(nrow(sim$data), 2))
  expect_equal(colnames(fitted_mu), c("mu1", "mu2"))
  expect_equal(
    fitted_mu[, "mu1"],
    predict(fit, dpar = "mu1"),
    tolerance = 1e-12
  )
  expect_equal(
    fitted_mu[, "mu2"],
    predict(fit, dpar = "mu2"),
    tolerance = 1e-12
  )
  expect_equal(stats::nobs(fit), nrow(sim$data))
  expect_equal(stats::df.residual(fit), fit$nobs - fit$df)
  expect_equal(
    stats::deviance(fit),
    -2 * as.numeric(stats::logLik(fit)),
    tolerance = 1e-12
  )
  expect_named(sig, c("sigma1", "sigma2"))
  expect_equal(length(sig$sigma1), nrow(sim$data))
  expect_equal(dim(sims), c(nrow(sim$data), 4))
  expect_equal(dim(res), c(nrow(sim$data), 2))
  expect_equal(dim(pearson), c(nrow(sim$data), 2))

  labels <- unlist(
    lapply(names(coef(fit)), function(dpar) {
      paste0(dpar, ":", names(coef(fit, dpar)))
    }),
    use.names = FALSE
  )
  expect_equal(rownames(stats::vcov(fit)), labels)
  expect_equal(colnames(stats::vcov(fit)), labels)
  expect_equal(rownames(summary(fit)$coefficients), labels)
})

test_that("bivariate Gaussian known V likelihood matches a base R MVN calculation", {
  sim <- new_biv_gaussian_known_v_data(n = 45, seed = 20260517)
  V <- sim$V

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + meta_known_V(V = V),
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )

  mu1 <- predict(fit, dpar = "mu1")
  mu2 <- predict(fit, dpar = "mu2")
  sigma1 <- predict(fit, dpar = "sigma1")
  sigma2 <- predict(fit, dpar = "sigma2")
  rho <- predict(fit, dpar = "rho12")
  Sigma <- fit$model$V_known
  i1 <- seq.int(1L, by = 2L, length.out = fit$nobs)
  i2 <- i1 + 1L
  Sigma[cbind(i1, i1)] <- Sigma[cbind(i1, i1)] + sigma1^2
  Sigma[cbind(i2, i2)] <- Sigma[cbind(i2, i2)] + sigma2^2
  Sigma[cbind(i1, i2)] <- Sigma[cbind(i1, i2)] + rho * sigma1 * sigma2
  Sigma[cbind(i2, i1)] <- Sigma[cbind(i2, i1)] + rho * sigma1 * sigma2

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$V_known_type, "matrix")
  expect_true(isTRUE(fit$model$has_known_v))
  expect_equal(
    as.numeric(stats::logLik(fit)),
    mvn_loglik_biv(
      as.vector(rbind(fit$model$y1, fit$model$y2)),
      as.vector(rbind(mu1, mu2)),
      Sigma
    ),
    tolerance = 1e-6
  )
})

test_that("bivariate Gaussian known V recovers residual rho12 separately from sampling correlation", {
  sim <- new_biv_gaussian_known_v_data(
    n = 150,
    residual_rho = -0.35,
    sampling_cor = 0.65,
    seed = 20260518
  )
  V <- sim$V

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + meta_known_V(V = V),
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(abs(tanh(coef(fit, "rho12")) - sim$residual_rho), 0.22)
  expect_gt(abs(tanh(coef(fit, "rho12")) - sim$sampling_cor), 0.5)
  sims <- simulate(fit, nsim = 2, seed = 1)
  pearson <- residuals(fit, type = "pearson")
  expect_equal(dim(sims), c(nrow(sim$data), 4))
  expect_equal(dim(pearson), c(nrow(sim$data), 2))
  expect_true(all(is.finite(pearson)))
})

test_that("bivariate Gaussian likelihood weights are complete-row multipliers", {
  sim <- new_biv_gaussian_data(
    n = 120,
    beta_rho12 = atanh(0.35),
    seed = 20260564
  )

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data
  )
  fit_double <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = sim$data,
    weights = rep(2, nrow(sim$data))
  )

  expect_equal(stats::weights(fit_double), rep(2, nrow(sim$data)))
  expect_equal(coef(fit_double, "mu1"), coef(fit, "mu1"), tolerance = 1e-5)
  expect_equal(coef(fit_double, "mu2"), coef(fit, "mu2"), tolerance = 1e-5)
  expect_equal(coef(fit_double, "rho12"), coef(fit, "rho12"), tolerance = 1e-5)
  expect_equal(
    as.numeric(stats::logLik(fit_double)),
    2 * as.numeric(stats::logLik(fit)),
    tolerance = 1e-4
  )
})

test_that("rho12 response-scale transform stays inside the correlation boundary", {
  eta <- c(-1e6, -20, 0, 20, 1e6)
  rho12 <- drmTMB:::rho_response(eta)

  expect_true(all(abs(rho12) < 1))
  expect_equal(rho12[[3L]], 0)
})

test_that("bivariate Gaussian uses complete cases across all parameter formulas", {
  sim <- new_biv_gaussian_data(
    n = 60,
    beta_rho12 = c(0.1, 0.2),
    seed = 20260515
  )
  dat <- sim$data
  dat$y1[2] <- NA_real_
  dat$y2[5] <- NA_real_
  dat$x[11] <- NA_real_
  dat$z1[17] <- NA_real_
  dat$z2[23] <- NA_real_
  dat$w[31] <- NA_real_
  keep <- stats::complete.cases(dat[c("y1", "y2", "x", "z1", "z2", "w")])

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~w
    ),
    family = biv_gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_equal(sum(is.na(fit$data[c("y1", "y2", "x", "z1", "z2", "w")])), 0)
})

test_that("bivariate Gaussian known V removes paired rows and columns consistently", {
  sim <- new_biv_gaussian_known_v_data(n = 12, seed = 20260519)
  dat <- sim$data
  V <- sim$V
  dat$y1[3] <- NA_real_
  pair <- (2L * 3L - 1L):(2L * 3L)
  V[pair, ] <- NA_real_
  V[, pair] <- NA_real_
  diag(V)[pair] <- c(0.02, 0.03)

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + meta_known_V(V = V),
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = dat
  )

  keep <- stats::complete.cases(dat[c("y1", "y2", "x")])
  pair_keep <- as.vector(rbind(keep, keep))
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$V_known, sim$V[pair_keep, pair_keep])
})

test_that("bivariate Gaussian rejects unsupported Phase 3 syntax clearly", {
  dat <- data.frame(
    y1 = stats::rnorm(20),
    y2 = stats::rnorm(20),
    x = stats::rnorm(20),
    vi = rep(0.02, 20),
    id = rep(1:4, each = 5)
  )

  expect_error(
    drmTMB(bf(mu1 = y1 ~ x), family = biv_gaussian(), data = dat),
    "mu2"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~x, rho12 = ~1),
      family = biv_gaussian(),
      data = dat
    ),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~ x + (1 | p | id)),
      family = biv_gaussian(),
      data = dat
    ),
    "within-observation"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + meta_known_V(V = vi), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "2n.*2n"
  )
  V <- diag(rep(0.01, 40))
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + meta_known_V(V = V), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat,
      weights = rep(1.5, nrow(dat))
    ),
    "full.*meta_known_V.*covariance"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + meta_known_V(V = V),
        mu2 = y2 ~ x + meta_known_V(V = V)
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Only one.*meta_known_V"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "covariance-block labels"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + (1 | p | id), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "implemented covariance block"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x + (1 | id)),
      family = biv_gaussian(),
      data = dat
    ),
    "covariance-block labels"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + (1 | p | id), mu2 = y2 ~ x + (1 | q | id)),
      family = biv_gaussian(),
      data = dat
    ),
    "same covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1 + (1 | p | id),
        sigma2 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "matching labelled.*mu"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1 + (1 | id),
        sigma2 = ~ 1 + (1 | id)
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "covariance-block labels"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ 1 + (1 | p | id),
        sigma2 = ~ 1 + (1 | q | id)
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "same covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 | p | id),
        mu2 = y2 ~ x + (1 | p | id),
        sigma1 = ~ 1 + (1 | p | id),
        sigma2 = ~ 1 + (1 | p | id),
        rho12 = ~x
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Reusing one bivariate covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 | p | id),
        mu2 = y2 ~ x + (1 | p | id),
        sigma1 = ~ 1 + (1 | p | id),
        sigma2 = ~1,
        rho12 = ~x
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Larger labelled covariance blocks"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 | p | id),
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~ 1 + (1 | p | id),
        rho12 = ~x
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "same-response only"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + meta_known_V(V = V), mu2 = y2 ~ x + (1 | p | id)),
      family = biv_gaussian(),
      data = dat
    ),
    "cannot yet be combined"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + meta_known_V(V = V),
        mu2 = y2 ~ x,
        sigma1 = ~ 1 + (1 | p | id),
        sigma2 = ~ 1 + (1 | p | id)
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "cannot yet be combined"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 + x | p | id),
        mu2 = y2 ~ x + (1 + x | p | id),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~x
      ),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "Only bivariate random intercepts"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x + phylo(1 | id, tree = tree), mu2 = y2 ~ x),
      family = biv_gaussian(),
      data = dat
    ),
    "must be matched"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | id, tree = tree),
        mu2 = y2 ~ x + phylo(1 | species, tree = tree)
      ),
      family = biv_gaussian(),
      data = transform(dat, species = id)
    ),
    "same grouping variable and tree"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + meta_known_V(V = V) + phylo(1 | id, tree = tree),
        mu2 = y2 ~ x + phylo(1 | id, tree = tree),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~x
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "cannot yet be combined"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
      family = c(gaussian(), poisson()),
      data = dat
    ),
    "Mixed-response bivariate families"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
      family = c(gaussian(), gaussian(), gaussian()),
      data = dat
    ),
    "one-response and two-response models only"
  )
  expect_error(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
      family = list(gaussian(), gaussian(), gaussian()),
      data = dat
    ),
    "one-response and two-response models only"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y1, y2) ~ x),
      family = gaussian(),
      data = dat
    ),
    "mvbind.*only available"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y1, y2, y3) ~ x),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "exactly two"
  )
  expect_error(
    drmTMB(
      bf(mu1 = mvbind(y1, y2) ~ x, mu2 = y2 ~ x),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "unnamed"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y1, y2) ~ x, mu2 = y2 ~ x),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "cannot be combined"
  )
})
