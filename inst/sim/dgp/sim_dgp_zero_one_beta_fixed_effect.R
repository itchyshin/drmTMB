phase18_zero_one_beta_fe_conditions <- function(
  n = c(260L, 520L),
  beta_mu_intercept = -0.20,
  beta_mu_x = 0.60,
  beta_sigma_intercept = c(-0.90, -0.55),
  beta_sigma_z = c(0, 0.20),
  beta_zoi_intercept = c(-1.60, -1.05),
  beta_zoi_w = 0.35,
  beta_coi_intercept = 0.10,
  beta_coi_v = -0.35,
  rho_xz = c(0, 0.40)
) {
  base <- expand.grid(
    n = as.integer(n),
    beta_sigma_intercept = beta_sigma_intercept,
    beta_sigma_z = beta_sigma_z,
    beta_zoi_intercept = beta_zoi_intercept,
    rho_xz = rho_xz,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  base$beta_mu_intercept <- beta_mu_intercept
  base$beta_mu_x <- beta_mu_x
  base$beta_zoi_w <- beta_zoi_w
  base$beta_coi_intercept <- beta_coi_intercept
  base$beta_coi_v <- beta_coi_v

  base[c(
    "n",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "beta_zoi_intercept",
    "beta_zoi_w",
    "beta_coi_intercept",
    "beta_coi_v",
    "rho_xz"
  )]
}

phase18_dgp_zero_one_beta_fe <- function(
  n,
  beta_mu = c("(Intercept)" = -0.20, x = 0.60),
  beta_sigma = c("(Intercept)" = -0.90, z = 0.20),
  beta_zoi = c("(Intercept)" = -1.30, w = 0.35),
  beta_coi = c("(Intercept)" = 0.10, v = -0.35),
  rho_xz = 0,
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
  beta_zoi <- phase18_named_pair(
    beta_zoi,
    c("(Intercept)", "w"),
    "beta_zoi"
  )
  beta_coi <- phase18_named_pair(
    beta_coi,
    c("(Intercept)", "v"),
    "beta_coi"
  )
  assert_phase18_correlation(rho_xz, "rho_xz")

  draw <- function() {
    x <- stats::rnorm(n)
    z_noise <- stats::rnorm(n)
    w_noise <- stats::rnorm(n)
    v_noise <- stats::rnorm(n)
    z <- rho_xz * x + sqrt(1 - rho_xz^2) * z_noise
    w <- rho_xz * x + sqrt(1 - rho_xz^2) * w_noise
    v <- rho_xz * x + sqrt(1 - rho_xz^2) * v_noise

    eta_mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    eta_sigma <- unname(
      beta_sigma[["(Intercept)"]] + beta_sigma[["z"]] * z
    )
    eta_zoi <- unname(beta_zoi[["(Intercept)"]] + beta_zoi[["w"]] * w)
    eta_coi <- unname(beta_coi[["(Intercept)"]] + beta_coi[["v"]] * v)

    mu <- stats::plogis(eta_mu)
    sigma <- exp(eta_sigma)
    zoi <- stats::plogis(eta_zoi)
    coi <- stats::plogis(eta_coi)
    phi <- 1 / sigma^2
    alpha <- mu * phi
    beta_shape <- (1 - mu) * phi
    prop <- stats::rbeta(n, shape1 = alpha, shape2 = beta_shape)

    boundary <- stats::runif(n) < zoi
    prop[boundary] <- as.numeric(stats::runif(sum(boundary)) < coi[boundary])
    response_mean <- (1 - zoi) * mu + zoi * coi

    dat <- data.frame(
      prop = prop,
      x = x,
      z = z,
      w = w,
      v = v,
      eta_mu = eta_mu,
      eta_sigma = eta_sigma,
      eta_zoi = eta_zoi,
      eta_coi = eta_coi,
      mu = mu,
      sigma = sigma,
      zoi = zoi,
      coi = coi,
      response_mean = response_mean,
      phi = phi,
      alpha = alpha,
      beta_shape = beta_shape,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "zero_one_beta_fixed_effect",
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      beta_zoi = beta_zoi,
      beta_coi = beta_coi,
      n = n,
      rho_xz = rho_xz
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}
