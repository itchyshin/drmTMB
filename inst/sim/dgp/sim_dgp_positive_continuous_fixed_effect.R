phase18_positive_continuous_fe_conditions <- function(
  family = c("lognormal", "gamma"),
  n = c(180L, 480L),
  beta_mu_intercept = 0.20,
  beta_mu_x = 0.45,
  beta_sigma_intercept = c(-0.75, -0.45),
  beta_sigma_z = c(0, 0.25),
  rho_xz = c(0, 0.50)
) {
  family <- phase18_positive_continuous_fe_family(family, several.ok = TRUE)
  base <- expand.grid(
    family = family,
    n = as.integer(n),
    beta_sigma_intercept = beta_sigma_intercept,
    beta_sigma_z = beta_sigma_z,
    rho_xz = rho_xz,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  base$beta_mu_intercept <- beta_mu_intercept
  base$beta_mu_x <- beta_mu_x
  base[c(
    "family",
    "n",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "rho_xz"
  )]
}

phase18_dgp_positive_continuous_fe <- function(
  n,
  family = c("lognormal", "gamma"),
  beta_mu = c("(Intercept)" = 0.20, x = 0.45),
  beta_sigma = c("(Intercept)" = -0.75, z = 0.25),
  rho_xz = 0,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n, "n")
  family <- phase18_positive_continuous_fe_family(family)
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  beta_sigma <- phase18_named_pair(
    beta_sigma,
    c("(Intercept)", "z"),
    "beta_sigma"
  )
  assert_phase18_correlation(rho_xz, "rho_xz")

  draw <- function() {
    x <- stats::rnorm(n)
    z_noise <- stats::rnorm(n)
    z <- rho_xz * x + sqrt(1 - rho_xz^2) * z_noise
    eta_mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    eta_sigma <- unname(
      beta_sigma[["(Intercept)"]] + beta_sigma[["z"]] * z
    )
    sigma <- exp(eta_sigma)

    if (identical(family, "lognormal")) {
      mu <- eta_mu
      response_mean <- exp(mu + 0.5 * sigma^2)
      y <- stats::rlnorm(n, meanlog = mu, sdlog = sigma)
    } else {
      mu <- exp(eta_mu)
      shape <- 1 / sigma^2
      scale <- mu * sigma^2
      response_mean <- mu
      y <- stats::rgamma(n, shape = shape, scale = scale)
    }

    dat <- data.frame(
      y = y,
      x = x,
      z = z,
      eta_mu = eta_mu,
      eta_sigma = eta_sigma,
      mu = mu,
      sigma = sigma,
      response_mean = response_mean,
      family = family,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "positive_continuous_fixed_effect",
      family = family,
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
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

phase18_positive_continuous_fe_family <- function(
  family,
  several.ok = FALSE
) {
  choices <- c("lognormal", "gamma")
  if (
    !is.character(family) ||
      length(family) == 0L ||
      anyNA(family) ||
      any(!nzchar(family)) ||
      any(!family %in% choices)
  ) {
    stop(
      "`family` must be ",
      if (several.ok) "one or more of " else "one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (!several.ok && length(family) != 1L) {
    stop(
      "`family` must be one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  unique(family)
}
