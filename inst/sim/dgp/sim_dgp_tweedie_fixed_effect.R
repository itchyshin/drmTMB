phase18_tweedie_fe_conditions <- function(
  n = c(260L, 520L),
  zero_regime = c("low", "high"),
  rho_xz = c(0, 0.40)
) {
  zero_regime <- phase18_tweedie_fe_zero_regime(
    zero_regime,
    several.ok = TRUE
  )
  regimes <- phase18_tweedie_fe_regime_table()
  regimes <- regimes[match(zero_regime, regimes$zero_regime), , drop = FALSE]
  base <- expand.grid(
    n = as.integer(n),
    zero_regime = zero_regime,
    rho_xz = rho_xz,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  out <- merge(base, regimes, by = "zero_regime", sort = FALSE)
  out[c(
    "n",
    "zero_regime",
    "target_zero_fraction",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "power",
    "rho_xz"
  )]
}

phase18_dgp_tweedie_fe <- function(
  n,
  beta_mu = c("(Intercept)" = 0.25, x = 0.35),
  beta_sigma = c("(Intercept)" = -0.65, z = 0.15),
  power = 1.30,
  rho_xz = 0,
  target_zero_fraction = NA_real_,
  zero_regime = NA_character_,
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
  phase18_assert_tweedie_power(power, "power")
  assert_phase18_correlation(rho_xz, "rho_xz")

  draw <- function() {
    x <- stats::rnorm(n)
    z_noise <- stats::rnorm(n)
    z <- rho_xz * x + sqrt(1 - rho_xz^2) * z_noise
    eta_mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    eta_sigma <- unname(
      beta_sigma[["(Intercept)"]] + beta_sigma[["z"]] * z
    )
    mu <- exp(eta_mu)
    sigma <- exp(eta_sigma)
    phi <- sigma^2
    y <- getFromNamespace("rtweedie_compound", "drmTMB")(
      n,
      mu = mu,
      phi = phi,
      power = power
    )

    dat <- data.frame(
      y = y,
      x = x,
      z = z,
      eta_mu = eta_mu,
      eta_sigma = eta_sigma,
      mu = mu,
      sigma = sigma,
      phi = phi,
      nu = power,
      response_mean = mu,
      target_zero_fraction = target_zero_fraction,
      observed_zero_fraction = mean(y == 0),
      zero_regime = zero_regime,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "tweedie_fixed_effect",
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      beta_nu = c("(Intercept)" = stats::qlogis(power - 1)),
      power = power,
      n = n,
      rho_xz = rho_xz,
      target_zero_fraction = target_zero_fraction,
      zero_regime = zero_regime,
      sigma_baseline = exp(beta_sigma[["(Intercept)"]])
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_tweedie_fe_regime_table <- function() {
  data.frame(
    zero_regime = c("low", "high"),
    target_zero_fraction = c(0.03, 0.25),
    beta_mu_intercept = c(0.25, -0.65),
    beta_mu_x = c(0.35, 0.30),
    beta_sigma_intercept = c(-0.65, 0.20),
    beta_sigma_z = c(0.15, 0.12),
    power = c(1.30, 1.55),
    stringsAsFactors = FALSE
  )
}

phase18_tweedie_fe_zero_regime <- function(
  zero_regime,
  several.ok = FALSE
) {
  choices <- phase18_tweedie_fe_regime_table()$zero_regime
  if (
    !is.character(zero_regime) ||
      length(zero_regime) == 0L ||
      anyNA(zero_regime) ||
      any(!nzchar(zero_regime)) ||
      any(!zero_regime %in% choices)
  ) {
    stop(
      "`zero_regime` must be ",
      if (several.ok) "one or more of " else "one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (!several.ok && length(zero_regime) != 1L) {
    stop(
      "`zero_regime` must be one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  unique(zero_regime)
}

phase18_assert_tweedie_power <- function(power, name) {
  ok <- is.numeric(power) &&
    length(power) == 1L &&
    is.finite(power) &&
    power > 1 &&
    power < 2
  if (!ok) {
    stop(
      "`",
      name,
      "` must be one finite Tweedie power in (1, 2).",
      call. = FALSE
    )
  }
  invisible(power)
}
