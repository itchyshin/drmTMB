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

new_spatial_gaussian_slope_data <- function(
  seed = 20260572,
  n_site = 12L,
  n_each = 8L,
  sd_intercept = 0.45,
  sd_slope = 0.30,
  sigma = 0.16
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
  spatial_intercept <- as.vector(
    t(chol(covariance)) %*% stats::rnorm(n_site, sd = sd_intercept)
  )
  spatial_slope <- as.vector(
    t(chol(covariance)) %*% stats::rnorm(n_site, sd = sd_slope)
  )
  names(spatial_intercept) <- site_levels
  names(spatial_slope) <- site_levels

  site <- rep(site_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_site)
  beta_mu <- c(`(Intercept)` = 0.6, x = -0.25)
  y <- beta_mu[[1L]] +
    beta_mu[[2L]] * x +
    spatial_intercept[site] +
    spatial_slope[site] * x +
    stats::rnorm(length(site), sd = sigma)

  list(
    data = data.frame(y = unname(y), x = x, site = site),
    coords = coords,
    beta_mu = beta_mu,
    sd_intercept = sd_intercept,
    sd_slope = sd_slope,
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

test_that("Gaussian mu supports coordinate-based spatial one-slope fields", {
  sim <- new_spatial_gaussian_slope_data()
  coords <- sim$coords

  fit <- drmTMB(
    bf(y ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1),
    family = gaussian(),
    data = sim$data
  )

  sd_names <- c("spatial(1 | site)", "spatial(0 + x | site)")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$structured$phylo_mu$type, "spatial")
  expect_equal(fit$model$structured$phylo_mu$q, 2L)
  expect_equal(fit$model$structured$phylo_mu$coef_names, c("(Intercept)", "x"))
  expect_named(fit$sdpars$mu, sd_names)
  expect_true(all(is.finite(fit$sdpars$mu[sd_names])))
  expect_true(all(unname(fit$sdpars$mu[sd_names]) > 0.02))
  expect_equal(fit$corpars, list())

  spatial_re <- ranef(fit, "spatial_mu")
  expect_equal(spatial_re, fit$random_effects$spatial_mu)
  expect_named(spatial_re$terms, sd_names)
  expect_length(spatial_re$values, 2L * nrow(sim$coords))
  expect_length(spatial_re$terms[[sd_names[[1L]]]], nrow(sim$coords))
  expect_length(spatial_re$terms[[sd_names[[2L]]]], nrow(sim$coords))

  targets <- profile_targets(fit)
  spatial_targets <- targets[
    targets$parm %in% paste0("sd:mu:", sd_names),
  ]
  expect_equal(spatial_targets$parm, paste0("sd:mu:", sd_names))
  expect_equal(spatial_targets$tmb_parameter, rep("log_sd_phylo", 2L))
  expect_equal(spatial_targets$index, 1:2)
  expect_equal(spatial_targets$target_type, rep("direct", 2L))
  expect_true(all(spatial_targets$profile_ready))

  slope_ci <- stats::confint(
    fit,
    parm = "sd:mu:spatial(0 + x | site)",
    level = 0.70,
    method = "profile",
    trace = FALSE,
    ystep = 0.50
  )
  slope_sd <- unname(fit$sdpars$mu[["spatial(0 + x | site)"]])
  expect_equal(slope_ci$parm, "sd:mu:spatial(0 + x | site)")
  expect_equal(slope_ci$tmb_parameter, "log_sd_phylo")
  expect_equal(slope_ci$index, 2L)
  expect_equal(slope_ci$transformation, "exp")
  expect_true(all(is.finite(c(slope_ci$lower, slope_ci$upper))))
  expect_gt(slope_ci$lower, 0)
  expect_lt(slope_ci$lower, slope_sd)
  expect_gt(slope_ci$upper, slope_sd)

  chk <- check_drm(fit)
  spatial_check <- chk[chk$check == "spatial_mu_diagnostics", ]
  expect_equal(nrow(spatial_check), 1L)
  expect_match(spatial_check$value, "n_coef=2", fixed = TRUE)
  expect_match(spatial_check$value, "min_spatial_sd=", fixed = TRUE)
  expect_match(spatial_check$value, "min_sd_ratio=", fixed = TRUE)

  index <- fit$model$structured$phylo_mu$observation_node_index
  manual_spatial <- spatial_re$terms[[sd_names[[1L]]]][index] +
    sim$data$x * spatial_re$terms[[sd_names[[2L]]]][index]
  expect_equal(
    drmTMB:::phylo_mu_contribution(fit),
    unname(manual_spatial),
    tolerance = 1e-8
  )
  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  conditional_mu <- predict(fit, dpar = "mu", type = "link")
  expect_equal(
    unname(conditional_mu),
    fixed_mu + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
})

test_that("spatial one-slope support stays limited to univariate mu", {
  sim <- new_spatial_gaussian_slope_data(
    seed = 20260575,
    n_site = 6L,
    n_each = 4L
  )
  coords <- sim$coords
  dat <- sim$data
  dat$z <- stats::rnorm(nrow(dat))
  dat$y2 <- dat$y + stats::rnorm(nrow(dat), sd = 0.1)

  expect_error(
    drmTMB(
      bf(y ~ x + spatial(1 + x + z | site, coords = coords), sigma ~ 1),
      family = gaussian(),
      data = dat
    ),
    "intercept and one-slope structured terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords)),
      family = gaussian(),
      data = dat
    ),
    "Structured-effect syntax is planned"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y ~ x + spatial(1 + x | site, coords = coords),
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Structured-effect syntax is planned"
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

test_that("spatial one-slope fields use slope variables in complete cases", {
  sim <- new_spatial_gaussian_slope_data(
    seed = 20260573,
    n_site = 8L,
    n_each = 5L
  )
  coords <- sim$coords
  dat <- sim$data
  dat$y[2L] <- NA_real_
  dat$x[7L] <- NA_real_
  keep <- stats::complete.cases(dat[c("y", "x", "site")])

  fit <- drmTMB(
    bf(y ~ spatial(1 + x | site, coords = coords), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$nobs, sum(keep))
  expect_equal(fit$model$keep, keep)
  expect_equal(nrow(fit$model$structured$phylo_mu$value), sum(keep))
  expect_equal(
    colnames(fit$model$structured$phylo_mu$value),
    c("(Intercept)", "x")
  )
})

test_that("spatial one-slope fields require numeric finite slope values", {
  sim <- new_spatial_gaussian_slope_data(
    seed = 20260574,
    n_site = 6L,
    n_each = 4L
  )
  coords <- sim$coords
  bad_type <- sim$data
  bad_type$x <- factor(bad_type$x)

  expect_error(
    drmTMB(
      bf(y ~ spatial(1 + x | site, coords = coords), sigma ~ 1),
      family = gaussian(),
      data = bad_type
    ),
    "slope variable .* must be numeric"
  )

  bad_value <- sim$data
  bad_value$x[1L] <- Inf
  expect_error(
    drmTMB(
      bf(y ~ spatial(1 + x | site, coords = coords), sigma ~ 1),
      family = gaussian(),
      data = bad_value
    ),
    "slope variable .* finite values"
  )
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
