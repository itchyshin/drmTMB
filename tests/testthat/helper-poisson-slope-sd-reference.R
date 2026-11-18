# Independent numerical reference for a Poisson random slope:
# y_gi | b_g ~ Poisson(exp(eta_gi + x_gi*b_g)), b_g ~ N(0, tau_g^2),
# eta_gi = beta0 + beta1*x_gi, tau_g = exp(alpha0 + a*w_g).
# The log joint is sum[y*(eta+x*b)-exp(eta+x*b)-log(y!)] + log N(b;0,tau^2).
# Its negative Hessian at the mode is 1/tau^2 + sum[x^2*exp(eta+x*b)].
# Laplace integrates the local quadratic; adaptive integration numerically
# integrates the same scalar joint after subtracting its modal log value.

poisson_slope_sd_reference_fixture <- function(seed = 41L, groups = 8L,
                                               repeats = 5L) {
  stopifnot(groups >= 2L, repeats >= 2L)
  set.seed(seed)
  group_names <- paste0("g", seq_len(groups))
  id <- factor(rep(group_names, each = repeats), levels = group_names)
  w_by_group <- stats::setNames(seq(-1, 1, length.out = groups), group_names)
  x <- rep(seq(-0.9, 1.0, length.out = repeats), groups) +
    rep(seq(-0.15, 0.15, length.out = groups), each = repeats)
  beta <- c(intercept = 0.2, slope = 0.35)
  alpha <- c(intercept = -0.45, w = 0.75)
  tau_by_group <- exp(alpha[1L] + alpha[2L] * w_by_group)
  u_by_group <- stats::setNames(stats::rnorm(groups), group_names)
  group_index <- as.character(id)
  lambda <- exp(beta[1L] + beta[2L] * x +
                  x * tau_by_group[group_index] * u_by_group[group_index])
  data <- data.frame(y = stats::rpois(length(lambda), lambda), x = x,
                     w = unname(w_by_group[group_index]), id = id)
  list(data = data, beta = beta, alpha = alpha, w_by_group = w_by_group,
       tau_by_group = tau_by_group, u_by_group = u_by_group,
       lambda = unname(lambda))
}

poisson_slope_sd_scalar_log_marginal <- function(y, eta, x, tau,
                                                 method = c("laplace", "adaptive")) {
  method <- match.arg(method)
  if (!length(y) || length(eta) != length(y) || length(x) != length(y)) {
    stop("y, eta, and x must have the same positive length", call. = FALSE)
  }
  if (anyNA(y) || any(!is.finite(y)) || any(y < 0) || any(y != floor(y))) {
    stop("y must contain finite nonnegative integer counts", call. = FALSE)
  }
  if (anyNA(eta) || any(!is.finite(eta)) || anyNA(x) || any(!is.finite(x))) {
    stop("eta and x must be finite", call. = FALSE)
  }
  if (length(tau) != 1L || !is.finite(tau) || tau <= 0) {
    stop("tau must be one finite positive SD", call. = FALSE)
  }
  if (all(x == 0)) {
    return(sum(stats::dpois(y, exp(eta), log = TRUE)))
  }

  log_joint_one <- function(b) {
    z <- eta + x * b
    if (any(z > 700)) return(-Inf)
    sum(y * z - exp(z) - lgamma(y + 1)) + stats::dnorm(b, 0, tau, log = TRUE)
  }
  log_joint <- function(b) vapply(b, log_joint_one, numeric(1))
  bound <- max(15 * tau, 5)
  optimum <- stats::optimize(function(b) -log_joint_one(b),
                             interval = c(-bound, bound), tol = 1e-10)
  mode <- optimum$minimum
  modal_log_joint <- log_joint_one(mode)
  if (!is.finite(modal_log_joint) || abs(mode) > 0.99 * bound) {
    stop("scalar mode was not bracketed", call. = FALSE)
  }
  if (method == "laplace") {
    curvature <- 1 / tau^2 + sum(x^2 * exp(eta + x * mode))
    return(modal_log_joint + 0.5 * log(2 * pi) - 0.5 * log(curvature))
  }
  shifted <- function(offset) exp(log_joint(mode + offset) - modal_log_joint)
  integral <- stats::integrate(shifted, lower = -Inf, upper = Inf,
                               rel.tol = 1e-10, subdivisions = 500L)$value
  modal_log_joint + log(integral)
}

poisson_slope_sd_group_log_marginal <- function(data, beta, alpha,
                                                method = c("laplace", "adaptive"),
                                                slope_x = data$x,
                                                w_by_group = NULL) {
  method <- match.arg(method)
  if (!all(c("y", "x", "w", "id") %in% names(data)) || !nrow(data) ||
      length(beta) != 2L || length(alpha) != 2L ||
      length(slope_x) != nrow(data)) {
    stop("group reference needs y, x, w, id, two beta/alpha values and one slope_x per row",
         call. = FALSE)
  }
  rows <- split(seq_len(nrow(data)), as.character(data$id))
  if (is.null(w_by_group)) {
    w_by_group <- vapply(rows, function(i) {
      value <- unique(data$w[i])
      if (length(value) != 1L || !is.finite(value)) {
        stop("w must be finite and constant within group", call. = FALSE)
      }
      value
    }, numeric(1))
  }
  if (is.null(names(w_by_group)) || !all(names(rows) %in% names(w_by_group)) ||
      any(!is.finite(w_by_group[names(rows)]))) {
    stop("w_by_group must name every group with finite values", call. = FALSE)
  }
  sum(vapply(names(rows), function(group) {
    i <- rows[[group]]
    eta <- beta[1L] + beta[2L] * data$x[i]
    tau <- exp(alpha[1L] + alpha[2L] * w_by_group[[group]])
    poisson_slope_sd_scalar_log_marginal(data$y[i], eta, slope_x[i], tau, method)
  }, numeric(1)))
}
