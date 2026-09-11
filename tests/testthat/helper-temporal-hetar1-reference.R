hetar1_dense_covariance <- function(id, occasion, sd_temporal, sigma, phi) {
  id <- as.character(id)
  occasion <- as.numeric(occasion)
  levels <- sort(unique(occasion))
  stopifnot(length(sd_temporal) == length(levels))
  out <- matrix(0, length(id), length(id))
  for (series in unique(id)) {
    rows <- which(id == series)
    level_index <- match(occasion[rows], levels)
    gap <- abs(outer(occasion[rows], occasion[rows], "-"))
    D <- diag(sd_temporal[level_index], nrow = length(rows))
    out[rows, rows] <- D %*% (phi^gap) %*% D
  }
  diag(out) <- diag(out) + sigma^2
  out
}

hetar1_dense_nll <- function(y, X, beta, id, occasion, sd_temporal, sigma, phi) {
  V <- hetar1_dense_covariance(id, occasion, sd_temporal, sigma, phi)
  residual <- y - as.vector(X %*% beta)
  root <- chol(V)
  0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(root))) +
    sum(forwardsolve(t(root), residual)^2))
}

hetar1_dense_nll_at <- function(fit, par) {
  names_par <- names(par)
  temporal <- fit$model$structured$temporal_mu
  hetar1_dense_nll(
    y = fit$model$y,
    X = as.matrix(fit$model$X$mu),
    beta = unname(par[names_par == "beta_mu"]),
    id = fit$data[[temporal$group]],
    occasion = fit$data[[temporal$time]],
    sd_temporal = exp(unname(par[names_par == "log_sd_temporal"])),
    sigma = exp(unname(par[match("beta_sigma", names_par)])),
    phi = tanh(unname(par[match("theta_temporal", names_par)]))
  )
}
