# S0: differentiable positive-definite correlation maps for homogeneous Toeplitz.
#
# This file is deliberately independent of drmTMB's formula parser and native
# likelihood.  It makes the admissibility contract testable before S1/S2.

homtoep_reflection_rho <- function(eta) {
  eta <- as.numeric(eta)
  if (any(!is.finite(eta))) {
    stop("`eta` must be finite.", call. = FALSE)
  }
  K <- length(eta) + 1L
  if (K == 1L) return(1)

  kappa <- tanh(eta)
  rho <- numeric(K)
  rho[1L] <- 1
  ar <- numeric()
  innovation_var <- 1

  for (m in seq_along(kappa)) {
    reflection <- kappa[m]
    # Levinson recursion inverted: choose the next autocorrelation whose
    # partial autocorrelation is `reflection`.
    prediction <- if (m == 1L) 0 else sum(ar * rho[m:2L])
    rho[m + 1L] <- prediction + reflection * innovation_var

    ar_new <- numeric(m)
    ar_new[m] <- reflection
    if (m > 1L) {
      ar_new[seq_len(m - 1L)] <- ar - reflection * rev(ar)
    }
    ar <- ar_new
    innovation_var <- innovation_var * (1 - reflection^2)
  }
  rho
}

homtoep_pacf_from_rho <- function(rho) {
  rho <- as.numeric(rho)
  if (length(rho) < 1L || !isTRUE(all.equal(rho[1L], 1))) {
    stop("`rho` must start with one.", call. = FALSE)
  }
  if (any(!is.finite(rho))) stop("`rho` must be finite.", call. = FALSE)
  if (length(rho) == 1L) return(numeric())

  pacf <- numeric(length(rho) - 1L)
  ar <- numeric()
  innovation_var <- 1
  for (m in seq_along(pacf)) {
    prediction <- if (m == 1L) 0 else sum(ar * rho[m:2L])
    pacf[m] <- (rho[m + 1L] - prediction) / innovation_var
    ar_new <- numeric(m)
    ar_new[m] <- pacf[m]
    if (m > 1L) ar_new[seq_len(m - 1L)] <- ar - pacf[m] * rev(ar)
    ar <- ar_new
    innovation_var <- innovation_var * (1 - pacf[m]^2)
  }
  pacf
}

homtoep_eta_from_rho <- function(rho) {
  pacf <- homtoep_pacf_from_rho(rho)
  if (any(abs(pacf) >= 1)) {
    stop("`rho` is not strictly positive-definite Toeplitz.", call. = FALSE)
  }
  atanh(pacf)
}

homtoep_dense_from_lags <- function(rho) {
  rho <- as.numeric(rho)
  K <- length(rho)
  if (K < 1L) stop("`rho` must contain lag zero.", call. = FALSE)
  matrix(rho[abs(outer(seq_len(K), seq_len(K), `-`)) + 1L], nrow = K, ncol = K)
}

homtoep_reflection_cor <- function(eta, K = length(eta) + 1L) {
  if (length(eta) != K - 1L) {
    stop("`eta` must have K - 1 entries.", call. = FALSE)
  }
  homtoep_dense_from_lags(homtoep_reflection_rho(eta))
}

homtoep_map_jacobian <- function(eta, step = 1e-6) {
  eta <- as.numeric(eta)
  if (length(eta) == 0L) return(matrix(numeric(), nrow = 1L, ncol = 0L))
  if (!is.numeric(step) || length(step) != 1L || !is.finite(step) || step <= 0) {
    stop("`step` must be one positive finite number.", call. = FALSE)
  }
  out <- vapply(seq_along(eta), function(j) {
    plus <- eta; minus <- eta
    plus[j] <- plus[j] + step
    minus[j] <- minus[j] - step
    (homtoep_reflection_rho(plus) - homtoep_reflection_rho(minus)) / (2 * step)
  }, numeric(length(eta) + 1L))
  if (is.null(dim(out))) out <- matrix(out, ncol = 1L)
  out
}

# Comparison only: each lag lies in (-1, 1), but this does not make the
# resulting Toeplitz matrix positive-definite.
homtoep_lagwise_squash_cor <- function(eta, K = length(eta) + 1L) {
  if (length(eta) != K - 1L) stop("`eta` must have K - 1 entries.", call. = FALSE)
  homtoep_dense_from_lags(c(1, eta / sqrt(1 + eta^2)))
}

# Comparison only: generic Cholesky coordinates always yield a correlation
# matrix, but they do not preserve equal values along Toeplitz diagonals.
homtoep_generic_cholesky_cor <- function(z, K) {
  if (length(z) != K * (K + 1L) / 2L) {
    stop("`z` must contain K * (K + 1) / 2 entries.", call. = FALSE)
  }
  L <- matrix(0, K, K)
  L[lower.tri(L, diag = TRUE)] <- z
  diag(L) <- exp(diag(L))
  covariance <- tcrossprod(L)
  scale <- sqrt(diag(covariance))
  covariance / outer(scale, scale)
}

homtoep_toeplitz_deviation <- function(R) {
  K <- nrow(R)
  if (!identical(dim(R), c(K, K))) stop("`R` must be square.", call. = FALSE)
  max(vapply(0:(K - 1L), function(lag) {
    x <- diag(R[seq_len(K - lag), seq.int(1L + lag, K), drop = FALSE])
    max(abs(x - x[1L]))
  }, numeric(1)))
}

homtoep_map_study <- function() {
  set.seed(20260910)
  draws <- 0L
  min_eigenvalue <- Inf
  for (K in 1:12) {
    for (draw in seq_len(40)) {
      eta <- if (K == 1L) numeric() else rnorm(K - 1L, sd = 1.5)
      R <- homtoep_reflection_cor(eta, K)
      min_eigenvalue <- min(min_eigenvalue, eigen(R, symmetric = TRUE, only.values = TRUE)$values)
      if (min_eigenvalue <= 1e-13) stop("Reflection map produced a numerically singular R.")
      draws <- draws + 1L
    }
  }
  eta <- c(-0.8, 0.3, 1.0, -0.2)
  derivative_difference <- max(abs(
    homtoep_map_jacobian(eta, 1e-6) - homtoep_map_jacobian(eta, 1e-5)
  ))
  list(
    draws = draws,
    minimum_eigenvalue = min_eigenvalue,
    derivative_difference = derivative_difference,
    lagwise_counterexample_minimum_eigenvalue = min(eigen(
      homtoep_lagwise_squash_cor(c(1.5, -1.5), 3),
      symmetric = TRUE, only.values = TRUE
    )$values),
    generic_cholesky_toeplitz_deviation = homtoep_toeplitz_deviation(
      homtoep_generic_cholesky_cor(seq(-0.4, 0.6, length.out = 10), K = 4)
    )
  )
}
