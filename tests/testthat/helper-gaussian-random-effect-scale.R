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
