phase18_skew_normal_fe_conditions <- function(
  n = c(720L, 1440L),
  nu_intercept = c(-1.20, 1.20),
  nu_slope = c(0, 0.35),
  sigma_slope = c(0.15, 0.30),
  rho_xw = c(0, 0.40),
  beta_mu_intercept = 0.20,
  beta_mu_x = 0.40,
  beta_sigma_intercept = log(0.70)
) {
  conditions <- expand.grid(
    n = as.integer(n),
    nu_intercept = nu_intercept,
    nu_slope = nu_slope,
    sigma_slope = sigma_slope,
    rho_xw = rho_xw,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$beta_mu_intercept <- beta_mu_intercept
  conditions$beta_mu_x <- beta_mu_x
  conditions$beta_sigma_intercept <- beta_sigma_intercept
  conditions
}

phase18_dgp_skew_normal_fe <- function(
  n,
  beta_mu = c("(Intercept)" = 0.20, x = 0.40),
  beta_sigma = c("(Intercept)" = log(0.70), z = 0.20),
  beta_nu = c("(Intercept)" = 1.20, w = 0.35),
  rho_xw = 0,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n, "n")
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  beta_sigma <- phase18_named_pair(
    beta_sigma,
    c("(Intercept)", "z"),
    "beta_sigma"
  )
  beta_nu <- phase18_named_pair(beta_nu, c("(Intercept)", "w"), "beta_nu")
  assert_phase18_correlation(rho_xw, "rho_xw")

  draw <- function() {
    x <- stats::rnorm(n)
    w_noise <- stats::rnorm(n)
    w <- rho_xw * x + sqrt(1 - rho_xw^2) * w_noise
    z <- stats::rnorm(n)
    mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    log_sigma <- unname(
      beta_sigma[["(Intercept)"]] + beta_sigma[["z"]] * z
    )
    sigma <- exp(log_sigma)
    nu <- unname(beta_nu[["(Intercept)"]] + beta_nu[["w"]] * w)
    native <- phase18_skew_normal_fe_public_to_native(mu, sigma, nu)
    y <- native$xi +
      native$omega *
        (
          native$delta * abs(stats::rnorm(n)) +
            sqrt(1 - native$delta^2) * stats::rnorm(n)
        )

    dat <- data.frame(
      y = y,
      x = x,
      z = z,
      w = w,
      eta_mu = mu,
      eta_sigma = log_sigma,
      eta_nu = nu,
      mu = mu,
      sigma = sigma,
      nu = nu,
      native_xi = native$xi,
      native_omega = native$omega,
      native_delta = native$delta,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "skew_normal_fixed_effect",
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      beta_nu = beta_nu,
      n = n,
      rho_xw = rho_xw,
      sigma_baseline = exp(beta_sigma[["(Intercept)"]]),
      nu_baseline = beta_nu[["(Intercept)"]]
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_skew_normal_fe_public_to_native <- function(mu, sigma, nu) {
  delta <- nu / sqrt(1 + nu^2)
  native_mean <- delta * sqrt(2 / pi)
  native_sd <- sqrt(1 - native_mean^2)
  list(
    xi = mu - sigma * native_mean / native_sd,
    omega = sigma / native_sd,
    delta = delta
  )
}
