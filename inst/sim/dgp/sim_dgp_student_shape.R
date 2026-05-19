phase18_student_shape_conditions <- function(
  n = c(180L, 360L),
  nu_intercept = log(c(4, 10)),
  nu_slope = c(0, 0.35),
  sigma_slope = c(0.15, 0.35),
  rho_xw = c(0, 0.5),
  beta_mu_intercept = 0.25,
  beta_mu_x = 0.55,
  beta_sigma_intercept = log(0.65)
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

phase18_dgp_student_shape <- function(
  n,
  beta_mu = c("(Intercept)" = 0.25, x = 0.55),
  beta_sigma = c("(Intercept)" = log(0.65), z = 0.25),
  beta_nu = c("(Intercept)" = log(6), w = 0.35),
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
    eta_nu <- unname(beta_nu[["(Intercept)"]] + beta_nu[["w"]] * w)
    nu <- 2 + exp(eta_nu)
    y <- mu + sigma * stats::rt(n, df = nu)

    dat <- data.frame(
      y = y,
      x = x,
      z = z,
      w = w,
      mu = mu,
      sigma = sigma,
      eta_nu = eta_nu,
      nu = nu,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "student_shape",
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      beta_nu = beta_nu,
      n = n,
      rho_xw = rho_xw
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}
