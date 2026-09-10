homtoep_dense_covariance <- function(id, occasion, sd_temporal, sigma, rho) {
  id <- as.character(id)
  occasion <- as.numeric(occasion)
  schedule <- sort(unique(occasion))
  stopifnot(length(rho) == length(schedule))
  out <- matrix(0, length(id), length(id))
  for (series in unique(id)) {
    rows <- which(id == series)
    lag <- abs(outer(match(occasion[rows], schedule), match(occasion[rows], schedule), "-"))
    out[rows, rows] <- sd_temporal^2 * rho[lag + 1L]
  }
  diag(out) <- diag(out) + sigma^2
  out
}

homtoep_dense_gaussian_nll <- function(y, X, beta, id, occasion, sd_temporal, sigma, rho) {
  V <- homtoep_dense_covariance(id, occasion, sd_temporal, sigma, rho)
  residual <- y - as.vector(X %*% beta)
  chol_V <- chol(V)
  0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(chol_V))) +
    sum(forwardsolve(t(chol_V), residual)^2))
}

# Independent inverse-Levinson recursion: this deliberately does not call the
# package's transform so the native likelihood is checked against a separate
# implementation of the admissible Toeplitz covariance.
homtoep_reference_correlations <- function(theta) {
  n_occ <- length(theta) + 1L
  rho <- numeric(n_occ)
  ar <- numeric(n_occ - 1L)
  rho[[1L]] <- 1
  innovation_var <- 1
  for (m in seq_len(n_occ - 1L)) {
    reflection <- tanh(theta[[m]])
    prediction <- if (m == 1L) 0 else sum(ar[seq_len(m - 1L)] * rho[m:2L])
    rho[[m + 1L]] <- prediction + reflection * innovation_var
    ar_new <- numeric(n_occ - 1L)
    ar_new[[m]] <- reflection
    if (m > 1L) {
      for (j in seq_len(m - 1L)) {
        ar_new[[j]] <- ar[[j]] - reflection * ar[[m - j]]
      }
    }
    ar <- ar_new
    innovation_var <- innovation_var * (1 - reflection^2)
  }
  rho
}

homtoep_dense_nll_at <- function(fit, par) {
  parameter_names <- names(par)
  beta <- unname(par[parameter_names == "beta_mu"])
  sigma <- exp(unname(par[match("beta_sigma", parameter_names)]))
  sd_temporal <- exp(unname(par[match("log_sd_temporal", parameter_names)]))
  rho <- homtoep_reference_correlations(unname(par[parameter_names == "theta_temporal"]))
  homtoep_dense_gaussian_nll(
    y = fit$model$y,
    X = as.matrix(fit$model$X$mu),
    beta = beta,
    id = fit$data[[fit$model$structured$temporal_mu$group]],
    occasion = fit$data[[fit$model$structured$temporal_mu$time]],
    sd_temporal = sd_temporal,
    sigma = sigma,
    rho = rho
  )
}

homtoep_dense_conditional_modes <- function(fit) {
  temporal <- fit$model$structured$temporal_mu
  par <- fit$opt$par
  parameter_names <- names(par)
  beta <- unname(par[parameter_names == "beta_mu"])
  sigma <- exp(unname(par[match("beta_sigma", parameter_names)]))
  sd_temporal <- exp(unname(par[match("log_sd_temporal", parameter_names)]))
  rho <- homtoep_reference_correlations(unname(par[parameter_names == "theta_temporal"]))
  R_inv <- solve(toeplitz(rho))
  posterior_precision <- R_inv + diag((sd_temporal / sigma)^2, length(rho))
  X <- as.matrix(fit$model$X$mu)
  out <- numeric(temporal$n_re)
  for (series_index in seq_along(temporal$series_levels)) {
    id <- temporal$series_levels[[series_index]]
    rows <- which(as.character(fit$data[[temporal$group]]) == id)
    rows <- rows[order(fit$data[[temporal$time]][rows])]
    residual <- fit$model$y[rows] - as.vector(X[rows, , drop = FALSE] %*% beta)
    node <- seq.int(
      temporal$series_start0[[series_index]] + 1L,
      temporal$series_start0[[series_index + 1L]]
    )
    out[node] <- solve(posterior_precision, sd_temporal / sigma^2 * residual)
  }
  stats::setNames(out, temporal$node_labels)
}
