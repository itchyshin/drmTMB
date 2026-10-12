# Unnormalised quadrature mass and integrate() references for #1476 / #1477.
# Production Beta uses the frozen 15-node Gauss-Legendre rule. Production
# Gamma uses posterior-mode Gauss-Hermite. These helpers do not renormalise.

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
  # Integrate on u = log(x) so a tight response (sd_y = 0.1) does not
  # miss the posterior the way stats::integrate(0, Inf) can. Split at
  # the prior mean and the implied x so a pole or tail spike is hit.
  integrand <- function(u) {
    x <- exp(u)
    prior <- stats::dgamma(x, shape = 1 / sigma^2, scale = mu * sigma^2)
    mu_q <- mu_y + beta_x * (x - x_base)
    lik <- if (identical(response, "poisson")) {
      stats::dpois(y, exp(mu_q))
    } else {
      stats::dnorm(y, mu_q, sigma_y)
    }
    prior * lik * x
  }
  u_lo <- log(mu) - 12
  u_hi <- log(mu) + 12
  breaks <- seq(u_lo, u_hi, by = 0.25)
  if (is.finite(beta_x) && abs(beta_x) > 1e-12) {
    x_star <- x_base + (y - mu_y) / beta_x
    if (is.finite(x_star) && x_star > 0) {
      breaks <- c(breaks, log(x_star))
    }
  }
  breaks <- sort(unique(breaks[is.finite(breaks)]))
  total <- 0
  for (i in seq_len(length(breaks) - 1L)) {
    total <- total + stats::integrate(
      integrand,
      lower = breaks[[i]],
      upper = breaks[[i + 1L]],
      rel.tol = 1e-10,
      subdivisions = 200L
    )$value
  }
  total
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
