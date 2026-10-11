# High-node Gauss-Hermite / integrate() references for mi() prior accuracy.
# Used by #1476 / #1477 tests. Production fits use 31 nodes; these helpers
# use 81 nodes or stats::integrate() as an independent check.

drm_mi_gh_reference <- function(n = 81L) {
  drmTMB:::drm_standard_normal_mi_quadrature(n)
}

drm_beta_mi_quadrature_mass <- function(mu, sigma, n = 31L) {
  quad <- drmTMB:::drm_beta_mi_quadrature(n)
  is <- drmTMB:::drm_beta_mi_is_nodes(quad$nodes, quad$weights, mu, sigma)
  sum(exp(is$log_prior))
}

drm_gamma_mi_quadrature_mass <- function(mu, sigma, n = 31L) {
  quad <- drmTMB:::drm_gamma_mi_quadrature(n)
  is <- drmTMB:::drm_gamma_mi_is_nodes(quad$nodes, quad$weights, mu, sigma)
  sum(exp(is$log_prior))
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

drm_gamma_mi_reference_loglik <- function(y, mu_y, sigma_y, beta_x, x_base, mu, sigma) {
  integrand <- function(x) {
    stats::dgamma(x, shape = 1 / sigma^2, scale = mu * sigma^2) *
      stats::dnorm(y, mu_y + beta_x * (x - x_base), sigma_y)
  }
  stats::integrate(integrand, lower = 0, upper = Inf, rel.tol = 1e-8)$value
}
