# Independent exact reference for a lognormal observation model with a
# group-specific ordinary random-intercept SD.
#
# Symbolic-to-code contract:
#   log(Y_gi) = beta0 + beta1*x_gi + tau_g*u_g + sigma_gi*epsilon_gi
#   tau_g     = exp(alpha0 + alpha1*w_g)
#   sigma_gi  = exp(gamma0 + gamma1*z_gi)
#   u_g, epsilon_gi are independent standard normals.
#
# The generator only transforms caller-supplied latent values. The marginal
# reference integrates u_g exactly: V_g = diag(sigma_gi^2) + tau_g^2 11',
# followed by the response-scale Jacobian -sum(log(Y_gi)). It calls no drmTMB
# fit, simulator, TMB objective, or family likelihood helper.

lognormal_sd_reference_parameters <- function() {
  list(
    beta = c(`(Intercept)` = 0.25, x = -0.45),
    alpha = c(`(Intercept)` = log(0.65), w = 0.35),
    gamma = c(`(Intercept)` = log(0.4), z = -0.3)
  )
}

lognormal_sd_reference_group_w <- function(data) {
  required <- c("group", "w")
  if (!all(required %in% names(data))) {
    stop("data must contain group and w columns", call. = FALSE)
  }
  group <- as.character(data$group)
  if (anyNA(group) || anyNA(data$w) || any(!is.finite(data$w))) {
    stop("group and w must be complete and finite", call. = FALSE)
  }
  groups <- unique(group)
  w_group <- vapply(groups, function(g) {
    values <- data$w[group == g]
    if (any(abs(values - values[[1L]]) > 1e-12)) {
      stop("w must be constant within group", call. = FALSE)
    }
    values[[1L]]
  }, numeric(1))
  stats::setNames(w_group, groups)
}

lognormal_sd_reference_dgp <- function(data, parameters, latent_u,
                                       latent_epsilon) {
  if (!all(c("x", "z") %in% names(data))) {
    stop("data must contain x and z columns", call. = FALSE)
  }
  group <- as.character(data$group)
  w_group <- lognormal_sd_reference_group_w(data)
  groups <- names(w_group)
  if (is.null(names(latent_u)) || !setequal(names(latent_u), groups)) {
    stop("latent_u must be named once for every observed group", call. = FALSE)
  }
  if (length(latent_epsilon) != nrow(data) ||
      any(!is.finite(latent_epsilon)) || any(!is.finite(latent_u))) {
    stop("latent normal values must be finite and match the data", call. = FALSE)
  }
  tau <- exp(parameters$alpha[[1L]] + parameters$alpha[[2L]] * w_group)
  sigma <- exp(parameters$gamma[[1L]] + parameters$gamma[[2L]] * data$z)
  log_y <- parameters$beta[[1L]] + parameters$beta[[2L]] * data$x +
    tau[group] * latent_u[group] + sigma * latent_epsilon
  exp(log_y)
}

lognormal_sd_exact_marginal_loglik <- function(data, parameters) {
  required <- c("y", "group", "w", "x", "z")
  if (!all(required %in% names(data))) {
    stop("data must contain y, group, w, x, and z columns", call. = FALSE)
  }
  if (any(!is.finite(data$y)) || any(data$y <= 0) ||
      any(!is.finite(data$x)) || any(!is.finite(data$z))) {
    stop("y must be positive and y, x, z must be finite", call. = FALSE)
  }
  w_group <- lognormal_sd_reference_group_w(data)
  group <- as.character(data$group)
  log_y <- log(data$y)
  mu <- parameters$beta[[1L]] + parameters$beta[[2L]] * data$x
  sigma <- exp(parameters$gamma[[1L]] + parameters$gamma[[2L]] * data$z)
  tau <- exp(parameters$alpha[[1L]] + parameters$alpha[[2L]] * w_group)
  total <- 0
  for (g in names(w_group)) {
    i <- which(group == g)
    V <- tau[[g]]^2 * matrix(1, length(i), length(i)) +
      diag(sigma[i]^2, nrow = length(i))
    R <- chol(V)
    whitened <- forwardsolve(t(R), log_y[i] - mu[i])
    total <- total - 0.5 * (
      length(i) * log(2 * pi) + 2 * sum(log(diag(R))) +
        sum(whitened^2)
    ) - sum(log(data$y[i]))
  }
  total
}
