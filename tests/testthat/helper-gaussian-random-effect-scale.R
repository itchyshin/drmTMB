new_gaussian_re_scale_data <- function(n_id = 48, n_each = 8,
                                       beta_mu = c(`(Intercept)` = 0.25, x = 0.55),
                                       beta_sigma = c(`(Intercept)` = log(0.45), z = 0.18),
                                       alpha = c(`(Intercept)` = log(0.55), w = 0.45),
                                       factor_w = FALSE,
                                       sigma_mult = 1,
                                       seed = 20260550) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)

  if (factor_w) {
    w_id <- factor(rep(c("low", "high"), length.out = n_id), levels = c("low", "high"))
    W <- stats::model.matrix(~ w_id)
    alpha <- c(`(Intercept)` = log(0.45), w_idhigh = 0.55)
    eta_sd <- as.vector(W %*% alpha)
    w <- w_id[id]
  } else {
    w_id <- stats::rnorm(n_id)
    eta_sd <- alpha[[1L]] + alpha[[2L]] * w_id
    w <- w_id[id]
  }

  tau_id <- exp(eta_sd)
  b_id <- tau_id * stats::rnorm(n_id)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x + b_id[id]
  sigma <- sigma_mult * exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      w = w,
      id = id
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma + c(log(sigma_mult), 0),
    alpha = alpha,
    tau_id = tau_id
  )
}

new_gaussian_multi_re_scale_data <- function(n_id = 36, n_site = 12,
                                             beta_mu = c(`(Intercept)` = 0.20, x = 0.50),
                                             beta_sigma = c(`(Intercept)` = log(0.40), z = 0.15),
                                             alpha_id = c(`(Intercept)` = log(0.45), w_id = 0.45),
                                             alpha_site = c(`(Intercept)` = log(0.30), w_site = -0.35),
                                             seed = 20260580) {
  set.seed(seed)
  grid <- expand.grid(
    id = factor(seq_len(n_id)),
    site = factor(seq_len(n_site))
  )
  n <- nrow(grid)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)

  w_id_group <- stats::rnorm(n_id)
  w_site_group <- stats::rnorm(n_site)
  tau_id <- exp(alpha_id[[1L]] + alpha_id[[2L]] * w_id_group)
  tau_site <- exp(alpha_site[[1L]] + alpha_site[[2L]] * w_site_group)
  b_id <- tau_id * stats::rnorm(n_id)
  b_site <- tau_site * stats::rnorm(n_site)

  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x +
    b_id[grid$id] + b_site[grid$site]
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)

  list(
    data = data.frame(
      y = stats::rnorm(n, mean = mu, sd = sigma),
      x = x,
      z = z,
      w_id = w_id_group[grid$id],
      w_site = w_site_group[grid$site],
      id = grid$id,
      site = grid$site
    ),
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    alpha_id = alpha_id,
    alpha_site = alpha_site,
    tau_id = tau_id,
    tau_site = tau_site
  )
}
