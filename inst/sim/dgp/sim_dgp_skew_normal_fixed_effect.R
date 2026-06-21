phase18_skew_normal_fe_conditions <- function(
  skew_regime = c("left", "symmetric", "right"),
  n = c(280L, 520L),
  beta_mu_intercept = 0.20,
  beta_mu_x = 0.40,
  beta_sigma_intercept = -0.35,
  beta_sigma_z = 0.18,
  rho_xz = c(0, 0.35)
) {
  skew_regime <- phase18_skew_normal_fe_regime(
    skew_regime,
    several.ok = TRUE
  )
  regime_table <- phase18_skew_normal_fe_regime_table()
  regime_table <- regime_table[
    match(skew_regime, regime_table$skew_regime),
    ,
    drop = FALSE
  ]
  base <- expand.grid(
    skew_regime = skew_regime,
    n = as.integer(n),
    rho_xz = rho_xz,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  base$beta_mu_intercept <- beta_mu_intercept
  base$beta_mu_x <- beta_mu_x
  base$beta_sigma_intercept <- beta_sigma_intercept
  base$beta_sigma_z <- beta_sigma_z
  out <- merge(base, regime_table, by = "skew_regime", sort = FALSE)
  out[c(
    "skew_regime",
    "n",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "beta_nu_intercept",
    "rho_xz"
  )]
}

phase18_skew_normal_fe_false_positive_conditions <- function(
  n = c(320L, 520L),
  beta_mu_intercept = 0.20,
  beta_mu_x = 0.40,
  beta_sigma_intercept = -0.35,
  beta_sigma_z = c(0, 0.25),
  rho_xz = c(0, 0.35)
) {
  out <- expand.grid(
    skew_regime = "symmetric",
    n = as.integer(n),
    beta_sigma_z = beta_sigma_z,
    rho_xz = rho_xz,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  out$beta_mu_intercept <- beta_mu_intercept
  out$beta_mu_x <- beta_mu_x
  out$beta_sigma_intercept <- beta_sigma_intercept
  out$beta_nu_intercept <- 0
  out[c(
    "skew_regime",
    "n",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_z",
    "beta_nu_intercept",
    "rho_xz"
  )]
}

phase18_dgp_skew_normal_fe <- function(
  n,
  skew_regime = "right",
  beta_mu = c("(Intercept)" = 0.20, x = 0.40),
  beta_sigma = c("(Intercept)" = -0.35, z = 0.18),
  beta_nu = c("(Intercept)" = 1.20),
  rho_xz = 0,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n, "n")
  skew_regime <- phase18_skew_normal_fe_regime(skew_regime)
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  beta_sigma <- phase18_named_pair(
    beta_sigma,
    c("(Intercept)", "z"),
    "beta_sigma"
  )
  beta_nu <- phase18_named_intercept(beta_nu, "beta_nu")
  assert_phase18_correlation(rho_xz, "rho_xz")

  draw <- function() {
    x <- stats::rnorm(n)
    z_noise <- stats::rnorm(n)
    z <- rho_xz * x + sqrt(1 - rho_xz^2) * z_noise
    mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    eta_sigma <- unname(
      beta_sigma[["(Intercept)"]] + beta_sigma[["z"]] * z
    )
    sigma <- exp(eta_sigma)
    nu <- rep(unname(beta_nu[["(Intercept)"]]), n)
    y <- getFromNamespace("rskew_normal_public", "drmTMB")(
      n,
      mu = mu,
      sigma = sigma,
      nu = nu
    )

    dat <- data.frame(
      y = y,
      x = x,
      z = z,
      mu = mu,
      eta_sigma = eta_sigma,
      sigma = sigma,
      nu = nu,
      skew_regime = skew_regime,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "skew_normal_fixed_effect",
      skew_regime = skew_regime,
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      beta_nu = beta_nu,
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

phase18_skew_normal_fe_regime_table <- function() {
  data.frame(
    skew_regime = c("left", "symmetric", "right"),
    beta_nu_intercept = c(-1.20, 0, 1.20),
    stringsAsFactors = FALSE
  )
}

phase18_skew_normal_fe_regime <- function(
  skew_regime,
  several.ok = FALSE
) {
  choices <- phase18_skew_normal_fe_regime_table()$skew_regime
  if (
    !is.character(skew_regime) ||
      length(skew_regime) == 0L ||
      anyNA(skew_regime) ||
      any(!nzchar(skew_regime)) ||
      any(!skew_regime %in% choices)
  ) {
    stop(
      "`skew_regime` must be ",
      if (several.ok) "one or more of " else "one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (!several.ok && length(skew_regime) != 1L) {
    stop(
      "`skew_regime` must be one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  unique(skew_regime)
}

phase18_named_intercept <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
    stop(
      "`",
      name,
      "` must be a finite numeric vector of length 1.",
      call. = FALSE
    )
  }
  current <- names(x)
  if (is.null(current) || !nzchar(current[[1L]])) {
    names(x) <- "(Intercept)"
    return(x)
  }
  if (!identical(current, "(Intercept)")) {
    stop(
      "`",
      name,
      "` must be unnamed or named with (Intercept).",
      call. = FALSE
    )
  }
  x
}
