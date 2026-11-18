# Numerical reference for one independent scalar cluster:
# log integral phi(z) prod_i Bin(y_i; n_i, h(eta_i + sd*z)) dz.
# Adaptive integration is a tolerance-controlled reference, not an exact integral.
# No drmTMB, TMB or Julia likelihood code is called.
scalar_binomial_log_marginal <- function(y, trials, eta, sd, link = "logit",
                                         rel.tol = 1e-8) {
  if (!length(y) || length(y) != length(trials) || length(y) != length(eta)) {
    stop("y, trials and eta must have the same positive length")
  }
  if (any(!is.finite(c(y, trials, eta)))) stop("inputs must be finite")
  if (any(y < 0 | trials < 0 | y > trials | y != floor(y) |
          trials != floor(trials))) stop("invalid binomial counts")
  if (length(sd) != 1L || !is.finite(sd) || sd < 0) stop("sd must be non-negative and finite")
  if (!is.character(link) || length(link) != 1L || is.na(link) ||
      !link %in% c("logit", "probit", "cloglog")) stop("unsupported link")
  if (length(rel.tol) != 1L || !is.finite(rel.tol) || rel.tol <= 0 ||
      rel.tol >= 1) stop("rel.tol must lie in (0,1)")
  softplus <- function(x) pmax(x, 0) + log1p(exp(-abs(x)))
  conditional <- function(z) {
    linear <- eta + sd*z
    if (link == "logit") {
      lp <- -softplus(-linear); lq <- -softplus(linear)
    } else if (link == "probit") {
      lp <- stats::pnorm(linear, log.p = TRUE)
      lq <- stats::pnorm(linear, lower.tail = FALSE, log.p = TRUE)
    } else {
      rate <- exp(linear)
      lp <- log(-expm1(-rate)); lq <- -rate
      # When exp(linear) underflows, the omitted log-probability correction
      # is itself below double precision; retain the finite log rate.
      lp[rate == 0] <- linear[rate == 0]
    }
    sum(lchoose(trials, y)) + sum(y[y > 0] * lp[y > 0]) +
      sum((trials-y)[trials > y] * lq[trials > y])
  }
  if (sd == 0) return(list(log_marginal = conditional(0), relative_error = 0,
                            subdivisions = 0L, mode = 0))
  joint <- function(z) conditional(z) + stats::dnorm(z, log = TRUE)
  # A centring point improves scaling. It is not a Laplace approximation:
  # the integral still spans the entire real line around this point.
  radius <- max(12, sqrt(2 * (abs(conditional(0)) + 1)))
  if (!is.finite(radius)) stop("cannot locate a finite integration centre")
  mode <- stats::optimize(function(z) -joint(z), c(-radius, radius),
                          tol = 1e-10)$minimum
  shift <- joint(mode)
  if (!is.finite(shift)) stop("non-finite integration centre")
  integrand <- function(offset) vapply(offset, function(value) {
    exp(joint(mode + value) - shift)
  }, numeric(1L))
  result <- stats::integrate(integrand, -Inf, Inf, rel.tol = rel.tol,
                             abs.tol = 0, subdivisions = 1000L,
                             stop.on.error = TRUE)
  if (!is.finite(result$value) || result$value <= 0 ||
      !identical(result$message, "OK")) stop("invalid adaptive integral")
  list(log_marginal = log(result$value) + shift,
       relative_error = result$abs.error / result$value,
       subdivisions = result$subdivisions, mode = mode)
}
