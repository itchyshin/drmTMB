nbinom2_sd_slope_fixture <- function(groups = 64L, repeats = 16L,
                                    seed = 2026101821L,
                                    alpha = c(`(Intercept)` = log(0.45),
                                              w = 0.4),
                                    sigma = 0.35) {
  set.seed(seed)
  group_index <- rep(seq_len(groups), each = repeats)
  group_names <- paste0("s", seq_len(groups))
  w_group <- rep(c(-1, 1), length.out = groups)
  x_matrix <- matrix(stats::rnorm(groups * repeats), nrow = groups)
  x_matrix <- sweep(x_matrix, 1L, rowMeans(x_matrix), "-")
  x <- as.vector(t(x_matrix))
  tau_group <- exp(alpha[[1L]] + alpha[[2L]] * w_group)
  u <- stats::rnorm(groups)
  eta <- 0.35 + 0.25 * x + tau_group[group_index] * u[group_index] * x
  y <- stats::rnbinom(length(eta), size = 1 / sigma^2, mu = exp(eta))
  list(
    data = data.frame(
      y = y,
      x = x,
      w = w_group[group_index],
      id = factor(group_names[group_index], levels = group_names)
    ),
    alpha = alpha,
    sigma = sigma,
    w_group = w_group,
    tau_group = tau_group,
    x_grouped = x_matrix
  )
}

nbinom2_sd_slope_scalar_laplace_log_marginal <- function(
    y, eta, loading, sigma, tau) {
  size <- 1 / sigma^2
  nll <- function(b) {
    -sum(stats::dnbinom(
      y,
      size = size,
      mu = exp(eta + loading * b),
      log = TRUE
    )) - stats::dnorm(b, mean = 0, sd = tau, log = TRUE)
  }
  mode <- stats::optimize(nll, interval = c(-10 * tau, 10 * tau),
                          tol = 1e-11)$minimum
  mu <- exp(eta + loading * mode)
  curvature <- 1 / tau^2 + sum(
    (y + size) * size * mu / (size + mu)^2 * loading^2
  )
  -nll(mode) - 0.5 * log(curvature) + 0.5 * log(2 * pi)
}

nbinom2_sd_slope_laplace_oracle <- function(
    data, beta_mu, alpha, log_sigma, wrong_loading = FALSE) {
  rows <- split(seq_len(nrow(data)), data$id)
  sum(vapply(rows, function(i) {
    w <- data$w[i[[1L]]]
    tau <- exp(alpha[[1L]] + alpha[[2L]] * w)
    eta <- beta_mu[[1L]] + beta_mu[["x"]] * data$x[i]
    loading <- if (wrong_loading) rep(1, length(i)) else data$x[i]
    nbinom2_sd_slope_scalar_laplace_log_marginal(
      data$y[i], eta, loading, exp(log_sigma[[1L]]), tau
    )
  }, numeric(1L)))
}
