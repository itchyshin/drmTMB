# Independent of drmTMB simulation and the TMB likelihood.
poisson_sd_fixture <- function(groups = 48L, repeats = 10L,
                               seed = 2026101719L) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[group]
  x <- rnorm(length(group))
  alpha <- c("(Intercept)" = log(0.6), w = 0.45)
  tau_group <- exp(alpha[[1L]] + alpha[[2L]] * w_group)
  u_group <- rnorm(groups)
  eta <- -0.2 + 0.35 * x + tau_group[group] * u_group[group]
  y <- rpois(length(group), exp(eta))
  list(data = data.frame(y, x, w, id = factor(group)), alpha = alpha,
       w_group = w_group, tau_group = tau_group, u_group = u_group,
       eta = eta)
}

poisson_sd_scalar_log_marginal <- function(y, eta, tau,
                                           method = c("laplace", "adaptive")) {
  method <- match.arg(method)
  if (!length(y) || length(y) != length(eta) ||
      any(!is.finite(c(y, eta))) || any(y < 0 | y != floor(y)) ||
      length(tau) != 1L || !is.finite(tau) || tau <= 0) {
    stop("Invalid scalar Poisson SD reference input")
  }
  nll <- function(b) {
    -sum(dpois(y, exp(eta + b), log = TRUE)) - dnorm(b, 0, tau, log = TRUE)
  }
  mode <- optimize(nll, c(-15 * tau, 15 * tau), tol = 1e-10)$minimum
  curvature <- 1 / tau^2 + sum(exp(eta + mode))
  if (method == "laplace") {
    return(-nll(mode) - 0.5 * log(curvature) + 0.5 * log(2 * pi))
  }
  shift <- -nll(mode)
  integral <- integrate(function(offset) {
    vapply(offset, function(value) exp(-nll(mode + value) - shift),
           numeric(1L))
  }, -Inf, Inf, rel.tol = 1e-9, subdivisions = 1000L)
  if (!identical(integral$message, "OK") || integral$value <= 0) {
    stop("Adaptive Poisson scalar integral failed")
  }
  log(integral$value) + shift
}

poisson_sd_laplace_oracle <- function(data, beta, alpha,
                                      reverse_group_w = FALSE) {
  rows <- split(seq_len(nrow(data)), data$id)
  sum(vapply(rows, function(i) {
    w <- data$w[i[[1L]]]
    if (reverse_group_w) w <- -w
    tau <- exp(alpha[[1L]] + alpha[[2L]] * w)
    eta <- beta[[1L]] + beta[[2L]] * data$x[i]
    poisson_sd_scalar_log_marginal(data$y[i], eta, tau, "laplace")
  }, numeric(1L)))
}
