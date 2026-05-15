new_spatial_gaussian_data <- function(
  seed = 20260532,
  n_site = 10L,
  n_each = 7L,
  sd_spatial = 0.45,
  sigma = 0.14
) {
  set.seed(seed)
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 1.5 * pi, length.out = n_site)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_site) / (3 * n_site),
    y = sin(theta)
  )
  rownames(coords) <- site_levels

  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = site_levels,
    group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(
    t(chol(covariance)) %*% stats::rnorm(n_site, sd = sd_spatial)
  )
  names(spatial_effect) <- site_levels

  site <- rep(site_levels, each = n_each)
  x <- stats::rnorm(length(site))
  beta_mu <- c(`(Intercept)` = 0.6, x = -0.25)
  y <- beta_mu[[1L]] +
    beta_mu[[2L]] * x +
    spatial_effect[site] +
    stats::rnorm(length(site), sd = sigma)

  list(
    data = data.frame(y = unname(y), x = x, site = site),
    coords = coords,
    beta_mu = beta_mu,
    sd_spatial = sd_spatial,
    sigma = sigma
  )
}

test_that("Gaussian mu supports coordinate-based spatial intercepts", {
  sim <- new_spatial_gaussian_data()
  coords <- sim$coords

  fit <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true(isTRUE(fit$model$structured$phylo_mu$has))
  expect_equal(fit$model$structured$phylo_mu$type, "spatial")
  expect_named(fit$sdpars$mu, "spatial(1 | site)")
  expect_gt(unname(fit$sdpars$mu[["spatial(1 | site)"]]), 0.05)
  expect_equal(names(ranef(fit)), "spatial_mu")
  expect_equal(ranef(fit, "spatial_mu"), fit$random_effects$spatial_mu)
  targets <- profile_targets(fit)
  spatial_target <- targets[targets$parm == "sd:mu:spatial(1 | site)", ]
  expect_equal(nrow(spatial_target), 1L)
  expect_equal(spatial_target$tmb_parameter, "log_sd_phylo")
  expect_equal(spatial_target$target_type, "direct")
  expect_true(spatial_target$profile_ready)
  expect_equal(spatial_target$profile_note, "ready")

  spatial_ci <- stats::confint(
    fit,
    parm = "sd:mu:spatial(1 | site)",
    level = 0.70,
    method = "profile",
    trace = FALSE,
    ystep = 0.50
  )
  expect_equal(spatial_ci$parm, "sd:mu:spatial(1 | site)")
  expect_equal(spatial_ci$tmb_parameter, "log_sd_phylo")
  expect_equal(spatial_ci$transformation, "exp")
  expect_gt(spatial_ci$lower, 0)
  expect_lt(spatial_ci$lower, unname(fit$sdpars$mu[["spatial(1 | site)"]]))
  expect_gt(spatial_ci$upper, unname(fit$sdpars$mu[["spatial(1 | site)"]]))

  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  conditional_mu <- predict(fit, dpar = "mu", type = "link")
  expect_equal(
    unname(conditional_mu),
    fixed_mu + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
})

test_that("spatial coordinates can be supplied per observation", {
  sim <- new_spatial_gaussian_data(seed = 20260533, n_site = 8L, n_each = 5L)
  obs_coords <- sim$coords[sim$data$site, , drop = FALSE]
  rownames(obs_coords) <- NULL

  fit <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = obs_coords), sigma ~ 1),
    family = gaussian(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$structured$phylo_mu$node_labels, unique(sim$data$site))
})

test_that("spatial coordinate validation catches ambiguous inputs", {
  sim <- new_spatial_gaussian_data(seed = 20260534, n_site = 6L, n_each = 4L)
  bad_obs_coords <- sim$coords[sim$data$site, , drop = FALSE]
  bad_obs_coords[sim$data$site == sim$data$site[[1L]], "x"] <-
    seq_len(sum(sim$data$site == sim$data$site[[1L]]))
  rownames(bad_obs_coords) <- NULL

  expect_error(
    drmTMB(
      bf(y ~ x + spatial(1 | site, coords = bad_obs_coords), sigma ~ 1),
      family = gaussian(),
      data = sim$data
    ),
    "vary within spatial group"
  )

  short_coords <- sim$coords[-1L, , drop = FALSE]
  expect_error(
    drmTMB(
      bf(y ~ x + spatial(1 | site, coords = short_coords), sigma ~ 1),
      family = gaussian(),
      data = sim$data
    ),
    "one row per"
  )
})
