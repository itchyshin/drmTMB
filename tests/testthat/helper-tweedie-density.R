tweedie_compound_parameters_reference <- function(mu, phi, power) {
  stopifnot(
    is.numeric(mu),
    is.numeric(phi),
    is.numeric(power),
    all(is.finite(mu)),
    all(is.finite(phi)),
    all(is.finite(power)),
    all(mu > 0),
    all(phi > 0),
    all(power > 1),
    all(power < 2)
  )

  list(
    lambda = mu^(2 - power) / (phi * (2 - power)),
    gamma_shape = (2 - power) / (power - 1),
    gamma_scale = phi * (power - 1) * mu^(power - 1)
  )
}

tweedie_compound_log_density_one_reference <- function(
  y,
  mu,
  phi,
  power,
  max_terms = 2000L
) {
  stopifnot(is.finite(y), length(y) == 1L)
  if (y < 0) {
    return(-Inf)
  }

  params <- tweedie_compound_parameters_reference(mu, phi, power)
  if (y == 0) {
    return(-params$lambda)
  }

  j <- seq_len(max_terms)
  log_terms <- -params$lambda +
    j * log(params$lambda) -
    lgamma(j + 1) +
    stats::dgamma(
      y,
      shape = j * params$gamma_shape,
      scale = params$gamma_scale,
      log = TRUE
    )
  centre <- max(log_terms)
  centre + log(sum(exp(log_terms - centre)))
}

tweedie_compound_log_density_reference <- function(
  y,
  mu,
  phi,
  power,
  max_terms = 2000L
) {
  lengths <- lengths(list(y = y, mu = mu, phi = phi, power = power))
  n <- max(lengths)
  y <- rep_len(y, n)
  mu <- rep_len(mu, n)
  phi <- rep_len(phi, n)
  power <- rep_len(power, n)

  vapply(
    seq_len(n),
    function(i) {
      tweedie_compound_log_density_one_reference(
        y = y[[i]],
        mu = mu[[i]],
        phi = phi[[i]],
        power = power[[i]],
        max_terms = max_terms
      )
    },
    numeric(1)
  )
}
