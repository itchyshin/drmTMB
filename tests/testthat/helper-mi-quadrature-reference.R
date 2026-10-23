# Unnormalised quadrature mass and integrate() references for #1476 / #1477.
# Production Beta uses the frozen 15-node Gauss-Legendre rule. Production
# Gamma uses a posterior-mode sinh-mapped trapezoid rule. These helpers do not renormalise.

drm_beta_mi_quadrature_mass <- function(mu, sigma) {
  quad <- drmTMB:::drm_beta_mi_quadrature()
  sum(quad$weights * exp(
    drmTMB:::drm_beta_missing_predictor_log_density(quad$nodes, mu, sigma)
  ))
}

drm_gamma_mi_quadrature_mass <- function(mu, sigma, n = 31L) {
  quad <- drmTMB:::drm_gamma_mi_quadrature(n)
  is <- drmTMB:::drm_gamma_mi_adaptive_nodes(
    quad$nodes,
    quad$weights,
    mu,
    sigma,
    response = "none"
  )
  sum(exp(is$log_terms))
}

drm_beta_mi_reference_loglik <- function(y, mu_y, sigma_y, beta_x, x_base, mu, sigma) {
  integrand <- function(x) {
    stats::dbeta(
      x,
      shape1 = pmax(mu / sigma^2, 1e-8),
      shape2 = pmax((1 - mu) / sigma^2, 1e-8)
    ) *
      stats::dnorm(y, mu_y + beta_x * (x - x_base), sigma_y)
  }
  stats::integrate(integrand, lower = 0, upper = 1, rel.tol = 1e-10)$value
}

drm_beta_mi_quad_loglik <- function(y, mu_y, sigma_y, beta_x, x_base, mu, sigma) {
  quad <- drmTMB:::drm_beta_mi_quadrature()
  log_terms <- log(quad$weights) +
    drmTMB:::drm_beta_missing_predictor_log_density(quad$nodes, mu, sigma) +
    stats::dnorm(y, mu_y + beta_x * (quad$nodes - x_base), sigma_y, log = TRUE)
  drmTMB:::drm_logsumexp(log_terms)
}

drm_gamma_mi_reference_loglik <- function(
  y,
  mu_y,
  sigma_y,
  beta_x,
  x_base,
  mu,
  sigma,
  response = "gaussian"
) {
  # Reference log marginal, log \int Gamma(x) f(y | x) dx, via stats::integrate()
  # on u = log(x) with the Jacobian. The integrand is evaluated in log space
  # and scaled by its maximum, over u in [-60, u_hi] in 0.5-wide pieces (plus
  # the split at the implied pole x*), so neither a tight response (sd_y = 0.1)
  # nor the exp(shape * u) left tail at CV >= 1 is truncated. The mass left of
  # u = -60 is added analytically (the integrand is C * exp(shape * u) there).
  # A reference that stops at log(mu) - 12 loses about 5% of the mass at
  # CV = 2 (shape = 0.25), which is not a quadrature error.
  shape <- 1 / sigma^2
  scale <- mu * sigma^2
  log_f <- function(u) {
    x <- exp(u)
    mu_q <- mu_y + beta_x * (x - x_base)
    log_lik <- if (identical(response, "poisson")) {
      stats::dpois(y, exp(mu_q), log = TRUE)
    } else {
      stats::dnorm(y, mu_q, sigma_y, log = TRUE)
    }
    stats::dgamma(x, shape = shape, scale = scale, log = TRUE) + log_lik + u
  }
  u_lo <- -60
  u_hi <- max(log(mu) + 10, log(40 * scale))
  breaks <- seq(u_lo, u_hi, by = 0.5)
  if (is.finite(beta_x) && abs(beta_x) > 1e-12) {
    x_star <- x_base + (y - mu_y) / beta_x
    if (is.finite(x_star) && x_star > 0) {
      breaks <- c(breaks, log(x_star))
    }
  }
  breaks <- sort(unique(breaks[is.finite(breaks)]))
  scale_ref <- max(log_f(seq(u_lo, u_hi, length.out = 4001L)))
  total <- 0
  for (i in seq_len(length(breaks) - 1L)) {
    total <- total + stats::integrate(
      function(u) exp(log_f(u) - scale_ref),
      lower = breaks[[i]],
      upper = breaks[[i + 1L]],
      rel.tol = 1e-12,
      abs.tol = 0,
      subdivisions = 400L
    )$value
  }
  total <- total + exp(log_f(u_lo) - scale_ref) / shape
  total * exp(scale_ref)
}

drm_gamma_mi_quad_loglik <- function(
  y,
  mu_y,
  sigma_y,
  beta_x,
  x_base,
  mu,
  sigma,
  response = "gaussian"
) {
  quad <- drmTMB:::drm_gamma_mi_quadrature()
  is <- drmTMB:::drm_gamma_mi_adaptive_nodes(
    quad$nodes,
    quad$weights,
    mu,
    sigma,
    y = y,
    mu_y = mu_y,
    sigma_y = sigma_y,
    beta_x = beta_x,
    x_base = x_base,
    response = response
  )
  drmTMB:::drm_logsumexp(is$log_terms)
}
