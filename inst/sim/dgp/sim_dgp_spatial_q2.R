phase18_spatial_q2_conditions <- function(
  n_site = 10L,
  n_each = 6L,
  geometry = c("ring", "stretched", "clustered"),
  sd_spatial1 = 0.50,
  sd_spatial2 = 0.42,
  rho_spatial = 0.35,
  sigma1 = 0.18,
  sigma2 = 0.20,
  rho12 = -0.10,
  beta_mu1_intercept = 0.35,
  beta_mu1_x = 0.25,
  beta_mu2_intercept = -0.20,
  beta_mu2_x = -0.30
) {
  geometry <- match.arg(
    geometry,
    choices = c("ring", "stretched", "clustered"),
    several.ok = TRUE
  )
  conditions <- expand.grid(
    n_site = as.integer(n_site),
    n_each = as.integer(n_each),
    geometry = geometry,
    sd_spatial1 = sd_spatial1,
    sd_spatial2 = sd_spatial2,
    rho_spatial = rho_spatial,
    sigma1 = sigma1,
    sigma2 = sigma2,
    rho12 = rho12,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$beta_mu1_intercept <- beta_mu1_intercept
  conditions$beta_mu1_x <- beta_mu1_x
  conditions$beta_mu2_intercept <- beta_mu2_intercept
  conditions$beta_mu2_x <- beta_mu2_x
  conditions
}

phase18_dgp_spatial_q2 <- function(
  n_site,
  n_each,
  geometry = c("ring", "stretched", "clustered"),
  beta_mu1 = c("(Intercept)" = 0.35, x = 0.25),
  beta_mu2 = c("(Intercept)" = -0.20, x = -0.30),
  sd_spatial = c(mu1 = 0.50, mu2 = 0.42),
  rho_spatial = 0.35,
  sigma = c(sigma1 = 0.18, sigma2 = 0.20),
  rho12 = -0.10,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_site, "n_site")
  assert_positive_whole_number(n_each, "n_each")
  geometry <- match.arg(geometry)
  beta_mu1 <- phase18_named_pair(
    beta_mu1,
    c("(Intercept)", "x"),
    "beta_mu1"
  )
  beta_mu2 <- phase18_named_pair(
    beta_mu2,
    c("(Intercept)", "x"),
    "beta_mu2"
  )
  if (
    !is.numeric(sd_spatial) ||
      length(sd_spatial) != 2L ||
      any(!is.finite(sd_spatial)) ||
      any(sd_spatial <= 0)
  ) {
    stop("`sd_spatial` must be two positive finite numbers.", call. = FALSE)
  }
  if (
    !is.numeric(sigma) ||
      length(sigma) != 2L ||
      any(!is.finite(sigma)) ||
      any(sigma <= 0)
  ) {
    stop("`sigma` must be two positive finite numbers.", call. = FALSE)
  }
  assert_phase18_correlation(rho_spatial, "rho_spatial")
  assert_phase18_correlation(rho12, "rho12")

  draw <- function() {
    site_levels <- paste0("site_", seq_len(n_site))
    coords <- phase18_spatial_q2_coords(site_levels, geometry = geometry)
    precision <- drmTMB:::drm_spatial_coords_precision(
      coords,
      site = site_levels,
      group = "site"
    )
    covariance <- solve(as.matrix(precision$precision))

    z1 <- stats::rnorm(n_site)
    z2 <- rho_spatial * z1 + sqrt(1 - rho_spatial^2) * stats::rnorm(n_site)
    spatial1 <- as.vector(t(chol(covariance)) %*% z1) * sd_spatial[[1L]]
    spatial2 <- as.vector(t(chol(covariance)) %*% z2) * sd_spatial[[2L]]
    names(spatial1) <- site_levels
    names(spatial2) <- site_levels

    site <- rep(site_levels, each = n_each)
    n <- length(site)
    x <- stats::rnorm(n)
    e1 <- stats::rnorm(n)
    e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
    mu1 <- unname(
      beta_mu1[["(Intercept)"]] +
        beta_mu1[["x"]] * x +
        spatial1[site]
    )
    mu2 <- unname(
      beta_mu2[["(Intercept)"]] +
        beta_mu2[["x"]] * x +
        spatial2[site]
    )

    dat <- data.frame(
      y1 = mu1 + sigma[[1L]] * e1,
      y2 = mu2 + sigma[[2L]] * e2,
      x = x,
      site = factor(site, levels = site_levels),
      mu1 = mu1,
      mu2 = mu2,
      sigma1 = sigma[[1L]],
      sigma2 = sigma[[2L]],
      rho12 = rho12,
      residual_covariance = rho12 * sigma[[1L]] * sigma[[2L]],
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "spatial_q2",
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      sd_spatial = stats::setNames(as.numeric(sd_spatial), c("mu1", "mu2")),
      rho_spatial = rho_spatial,
      sigma = stats::setNames(as.numeric(sigma), c("sigma1", "sigma2")),
      rho12 = rho12,
      coords = coords,
      covariance = covariance,
      n_site = n_site,
      n_each = n_each,
      geometry = geometry
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_spatial_q2_coords <- function(site_levels, geometry) {
  site_levels <- as.character(site_levels)
  n_site <- length(site_levels)
  if (n_site < 2L || anyNA(site_levels) || any(!nzchar(site_levels))) {
    stop(
      "`site_levels` must contain at least two non-missing labels.",
      call. = FALSE
    )
  }
  geometry <- match.arg(geometry, c("ring", "stretched", "clustered"))
  index <- seq_len(n_site)
  if (identical(geometry, "ring")) {
    theta <- seq(0, 1.5 * pi, length.out = n_site)
    coords <- data.frame(
      coord_x = cos(theta) + index / (3 * n_site),
      coord_y = sin(theta)
    )
  } else if (identical(geometry, "stretched")) {
    coords <- data.frame(
      coord_x = seq(-1, 1, length.out = n_site),
      coord_y = 0.20 * sin(seq(0, 2 * pi, length.out = n_site))
    )
  } else {
    half <- ceiling(n_site / 2)
    coords <- data.frame(
      coord_x = c(
        seq(-0.9, -0.4, length.out = half),
        seq(0.4, 0.9, length.out = n_site - half)
      ),
      coord_y = c(
        seq(-0.2, 0.2, length.out = half),
        seq(0.2, -0.2, length.out = n_site - half)
      )
    )
  }
  row.names(coords) <- site_levels
  coords
}
