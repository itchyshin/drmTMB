phase18_spatial_mu_slope_conditions <- function(
  n_site = c(12L, 18L),
  n_each = c(8L, 10L),
  sd_intercept = 0.45,
  sd_slope = 0.30,
  beta_mu_intercept = 0.60,
  beta_mu_x = -0.25,
  sigma = 0.16
) {
  conditions <- expand.grid(
    n_site = as.integer(n_site),
    n_each = as.integer(n_each),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$sd_intercept <- sd_intercept
  conditions$sd_slope <- sd_slope
  conditions$beta_mu_intercept <- beta_mu_intercept
  conditions$beta_mu_x <- beta_mu_x
  conditions$sigma <- sigma
  conditions
}

phase18_dgp_spatial_mu_slope <- function(
  n_site,
  n_each,
  beta_mu = c("(Intercept)" = 0.60, x = -0.25),
  sigma = 0.16,
  sd = c("(Intercept)" = 0.45, x = 0.30),
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_site, "n_site")
  assert_positive_whole_number(n_each, "n_each")
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  sd <- phase18_named_pair(sd, c("(Intercept)", "x"), "sd")
  if (any(sd <= 0)) {
    stop("`sd` values must be positive.", call. = FALSE)
  }
  assert_phase18_positive_number(sigma, "sigma")

  draw <- function() {
    site_levels <- paste0("site_", seq_len(n_site))
    theta <- seq(0, 1.5 * pi, length.out = n_site)
    coords <- data.frame(
      coord_x = cos(theta) + seq_len(n_site) / (3 * n_site),
      coord_y = sin(theta)
    )
    row.names(coords) <- site_levels

    precision <- drmTMB:::drm_spatial_coords_precision(
      coords,
      site = site_levels,
      group = "site"
    )
    covariance <- solve(as.matrix(precision$precision))
    spatial_intercept <- as.vector(
      t(chol(covariance)) %*% stats::rnorm(n_site, sd = sd[["(Intercept)"]])
    )
    spatial_slope <- as.vector(
      t(chol(covariance)) %*% stats::rnorm(n_site, sd = sd[["x"]])
    )
    names(spatial_intercept) <- site_levels
    names(spatial_slope) <- site_levels

    site <- rep(site_levels, each = n_each)
    x <- rep(seq(-1, 1, length.out = n_each), times = n_site)
    mu <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x"]] * x +
        spatial_intercept[site] +
        spatial_slope[site] * x
    )
    y <- stats::rnorm(length(site), mean = mu, sd = sigma)

    dat <- data.frame(
      y = y,
      x = x,
      site = site,
      mu = mu,
      sigma = sigma,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "spatial_mu_slope",
      beta_mu = beta_mu,
      sigma = sigma,
      sd = stats::setNames(
        sd,
        c("spatial(1 | site)", "spatial(0 + x | site)")
      ),
      coords = coords,
      n_site = n_site,
      n_each = n_each
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}
