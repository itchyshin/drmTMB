# sweep-oct16 / t5 -- independent weighted Laplace oracle for y ~ x + (1 | g).
#
# Model (drmTMB parameterisation, read from the documented likelihood, not
# from drmTMB code): eta_i = b0 + b1 * x_i + s * z_g(i), z_g ~ N(0, 1),
# s = SD of the random intercept. Prior weights multiply the row
# log-density; the random-effect prior is unweighted. Groups are
# conditionally independent, so the Laplace marginal factorises:
#   log L = sum_g [ h_g(z*) + 0.5 log(2 pi) - 0.5 log(-h_g''(z*)) ],
#   h_g(z) = sum_{i in g} w_i l_i(eta_i(z)) + log phi(z).
# For the Gaussian family h_g is quadratic in z, so this is the exact
# marginal. sigma_par is the sigma-formula intercept on its link scale:
# log(residual SD) for gaussian, log(coefficient of variation) for gamma.
row_terms <- function(family, y, eta, sigma_par) {
  switch(family,
    gaussian = {
      s2 <- exp(2 * sigma_par)
      list(l = dnorm(y, eta, sqrt(s2), log = TRUE),
           d1 = (y - eta) / s2, d2 = rep(-1 / s2, length(y)))
    },
    poisson = {
      m <- exp(eta)
      list(l = dpois(y, m, log = TRUE), d1 = y - m, d2 = -m)
    },
    gamma = {
      k <- exp(-2 * sigma_par)            # shape = 1 / cv^2
      list(l = dgamma(y, shape = k, scale = exp(eta) / k, log = TRUE),
           d1 = k * (y * exp(-eta) - 1), d2 = -k * y * exp(-eta))
    })
}

laplace_oracle <- function(family, y, x, g, w, b0, b1, sigma_par = NA_real_, sd_u) {
  stopifnot(length(y) == length(x), length(y) == length(g), length(y) == length(w),
            !anyNA(y), !anyNA(x), !anyNA(g), all(w > 0))
  idx <- split(seq_along(y), as.character(g))
  total <- 0
  for (ii in idx) {
    yy <- y[ii]; ww <- w[ii]; eta0 <- b0 + b1 * x[ii]
    z <- 0
    for (it in 1:200) {
      rt <- row_terms(family, yy, eta0 + sd_u * z, sigma_par)
      h1 <- sum(ww * sd_u * rt$d1) - z
      h2 <- sum(ww * sd_u^2 * rt$d2) - 1
      step <- h1 / h2
      z <- z - step
      if (abs(step) < 1e-15 * max(1, abs(z))) break
    }
    rt <- row_terms(family, yy, eta0 + sd_u * z, sigma_par)
    h <- sum(ww * rt$l) + dnorm(z, log = TRUE)
    h2 <- sum(ww * sd_u^2 * rt$d2) - 1
    total <- total + h + 0.5 * log(2 * pi) - 0.5 * log(-h2)
  }
  total
}
