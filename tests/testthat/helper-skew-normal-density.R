skew_normal_public_to_native <- function(mu, sigma, nu) {
  if (any(!is.finite(sigma)) || any(sigma <= 0)) {
    stop("sigma must be finite and positive", call. = FALSE)
  }

  delta <- nu / sqrt(1 + nu^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega <- sigma / sqrt(1 - mean_shift^2)
  xi <- mu - omega * mean_shift

  data.frame(
    xi = xi,
    omega = omega,
    alpha = nu,
    delta = delta
  )
}

skew_normal_log_density_reference <- function(y, mu, sigma, nu) {
  native <- skew_normal_public_to_native(mu = mu, sigma = sigma, nu = nu)
  z <- (y - native$xi) / native$omega

  log(2) -
    log(native$omega) +
    dnorm(z, log = TRUE) +
    pnorm(native$alpha * z, log.p = TRUE)
}

skew_normal_third_central_moment_reference <- function(sigma, nu) {
  native <- skew_normal_public_to_native(mu = 0, sigma = sigma, nu = nu)
  mean_shift <- native$delta * sqrt(2 / pi)
  skewness <- ((4 - pi) / 2) * mean_shift^3 / (1 - mean_shift^2)^(3 / 2)

  skewness * sigma^3
}

skew_normal_density_integral_reference <- function(mu, sigma, nu) {
  stats::integrate(
    f = function(y) {
      exp(skew_normal_log_density_reference(
        y = y,
        mu = mu,
        sigma = sigma,
        nu = nu
      ))
    },
    lower = -Inf,
    upper = Inf,
    rel.tol = 1e-10,
    abs.tol = 0
  )$value
}
