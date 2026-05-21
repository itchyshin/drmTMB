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

new_biv_spatial_gaussian_data <- function(
  seed = 20260582,
  n_site = 8L,
  n_each = 5L,
  sd_spatial = c(0.50, 0.42),
  rho_spatial = 0.40,
  sigma = c(0.18, 0.20),
  rho12 = -0.10
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
  z1 <- stats::rnorm(n_site)
  z2 <- rho_spatial * z1 + sqrt(1 - rho_spatial^2) * stats::rnorm(n_site)
  spatial1 <- as.vector(t(chol(covariance)) %*% z1) * sd_spatial[[1L]]
  spatial2 <- as.vector(t(chol(covariance)) %*% z2) * sd_spatial[[2L]]
  names(spatial1) <- site_levels
  names(spatial2) <- site_levels

  site <- rep(site_levels, each = n_each)
  x <- stats::rnorm(length(site))
  beta_mu1 <- c(`(Intercept)` = 0.35, x = 0.25)
  beta_mu2 <- c(`(Intercept)` = -0.20, x = -0.30)
  e1 <- stats::rnorm(length(site))
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(length(site))

  list(
    data = data.frame(
      y1 = beta_mu1[[1L]] +
        beta_mu1[[2L]] * x +
        spatial1[site] +
        sigma[[1L]] * e1,
      y2 = beta_mu2[[1L]] +
        beta_mu2[[2L]] * x +
        spatial2[site] +
        sigma[[2L]] * e2,
      x = x,
      site = site
    ),
    coords = coords,
    covariance = covariance,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    sd_spatial = sd_spatial,
    rho_spatial = rho_spatial,
    sigma = sigma,
    rho12 = rho12
  )
}

dense_spatial_gaussian_nll <- function(y, mu, covariance) {
  chol_cov <- chol(covariance)
  resid <- y - mu
  solved <- backsolve(chol_cov, resid, transpose = TRUE)
  0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(chol_cov))) + sum(solved^2))
}

dense_biv_spatial_gaussian_nll <- function(
  y1,
  y2,
  mu1,
  mu2,
  sigma1,
  sigma2,
  rho12,
  sd_spatial,
  rho_spatial,
  A
) {
  n <- length(y1)
  i1 <- seq.int(1L, by = 2L, length.out = n)
  i2 <- seq.int(2L, by = 2L, length.out = n)
  covariance <- matrix(0, nrow = 2L * n, ncol = 2L * n)
  covariance[i1, i1] <- sd_spatial[[1L]]^2 * A
  covariance[i2, i2] <- sd_spatial[[2L]]^2 * A
  covariance[i1, i2] <- rho_spatial *
    sd_spatial[[1L]] *
    sd_spatial[[2L]] *
    A
  covariance[i2, i1] <- t(covariance[i1, i2])
  covariance[cbind(i1, i1)] <- covariance[cbind(i1, i1)] + sigma1^2
  covariance[cbind(i2, i2)] <- covariance[cbind(i2, i2)] + sigma2^2
  residual_cov <- rho12 * sigma1 * sigma2
  covariance[cbind(i1, i2)] <- covariance[cbind(i1, i2)] + residual_cov
  covariance[cbind(i2, i1)] <- covariance[cbind(i2, i1)] + residual_cov

  y <- as.vector(rbind(y1, y2))
  mu <- as.vector(rbind(mu1, mu2))
  dense_spatial_gaussian_nll(y, mu, covariance)
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

test_that("bivariate Gaussian mu supports coordinate-based spatial correlation", {
  sim <- new_biv_spatial_gaussian_data()
  dat <- sim$data
  coords <- sim$coords

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + spatial(1 | p | site, coords = coords),
      mu2 = y2 ~ x + spatial(1 | p | site, coords = coords),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )

  fixed_mu1 <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu1"))
  fixed_mu2 <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu2"))
  A_obs <- sim$covariance[dat$site, dat$site]
  dense_nll <- dense_biv_spatial_gaussian_nll(
    y1 = dat$y1,
    y2 = dat$y2,
    mu1 = fixed_mu1,
    mu2 = fixed_mu2,
    sigma1 = stats::sigma(fit)$sigma1[[1L]],
    sigma2 = stats::sigma(fit)$sigma2[[1L]],
    rho12 = rho12(fit)[[1L]],
    sd_spatial = unname(fit$sdpars$mu),
    rho_spatial = unname(fit$corpars$spatial),
    A = A_obs
  )
  spatial_mu <- fit$model$structured$phylo_mu
  spatial_mu1 <- fit$random_effects$spatial_mu$values[
    spatial_mu$observation_node_index
  ]
  spatial_mu2 <- fit$random_effects$spatial_mu$values[
    spatial_mu$n_re + spatial_mu$observation_node_index
  ]
  pair <- corpairs(fit, level = "spatial")
  pair_ci <- corpairs(
    fit,
    level = "spatial",
    conf.int = TRUE,
    conf.level = 0.70,
    ystep = 0.50
  )
  targets <- profile_targets(fit)
  spatial_profile_names <- c(
    "sd:mu:mu1:spatial(1 | p | site)",
    "sd:mu:mu2:spatial(1 | p | site)",
    "cor:spatial:cor(mu1:(Intercept),mu2:(Intercept) | p | site)"
  )
  spatial_profile <- targets[
    match(spatial_profile_names, targets$parm),
    ,
    drop = FALSE
  ]
  covariance <- summary(fit)$covariance

  expect_equal(fit$opt$convergence, 0)
  expect_equal(spatial_mu$type, "spatial")
  expect_equal(spatial_mu$q, 2L)
  expect_named(
    fit$sdpars$mu,
    c("mu1:spatial(1 | p | site)", "mu2:spatial(1 | p | site)")
  )
  expect_named(
    fit$corpars$spatial,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | site)"
  )
  expect_equal(nrow(pair), 1L)
  expect_equal(pair$level, "spatial")
  expect_equal(pair$estimate, unname(fit$corpars$spatial))
  expect_equal(pair_ci$profile_target, spatial_profile_names[[3L]])
  expect_equal(pair_ci$conf.status, "profile")
  expect_equal(pair_ci$interval_source, "profile")
  expect_true(is.finite(pair_ci$conf.low))
  expect_true(is.finite(pair_ci$conf.high))
  expect_lt(pair_ci$conf.low, pair$estimate)
  expect_gt(pair_ci$conf.high, pair$estimate)
  expect_equal(spatial_profile$parm, spatial_profile_names)
  expect_equal(
    spatial_profile$tmb_parameter,
    c("log_sd_phylo", "log_sd_phylo", "eta_cor_phylo")
  )
  expect_equal(spatial_profile$index, c(1L, 2L, 1L))
  expect_equal(spatial_profile$target_type, rep("direct", 3L))
  expect_equal(length(fit$random_effects$spatial_mu$values), 2L * nrow(coords))
  expect_equal(fit$opt$objective, dense_nll, tolerance = 1e-4)
  expect_equal(
    predict(fit, dpar = "mu1"),
    fixed_mu1 + unname(spatial_mu1),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, dpar = "mu2"),
    fixed_mu2 + unname(spatial_mu2),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, newdata = dat[1:3, ], dpar = "mu1"),
    fixed_mu1[1:3],
    tolerance = 1e-10
  )
  sims <- simulate(fit, nsim = 2, seed = 20260641)
  expect_named(sims, c("sim_1_y1", "sim_1_y2", "sim_2_y1", "sim_2_y2"))
  expect_equal(nrow(sims), nrow(dat))
  expect_true(all(vapply(sims, is.numeric, logical(1L))))
  expect_true(all(is.finite(as.matrix(sims))))
  expect_equal(sims, simulate(fit, nsim = 2, seed = 20260641))
  expect_equal(nrow(covariance), 1L)
  expect_equal(covariance$level, "spatial")
  expect_equal(covariance$correlation_target, spatial_profile_names[[3L]])
})

test_that("bivariate Gaussian supports spatial q4 location-scale blocks", {
  site_levels <- paste0("site_", seq_len(8L))
  theta <- seq(0, 1.5 * pi, length.out = length(site_levels))
  coords <- data.frame(
    x = cos(theta) + seq_along(site_levels) / (3 * length(site_levels)),
    y = sin(theta)
  )
  rownames(coords) <- site_levels
  dat <- data.frame(
    y1 = seq(-0.2, 0.5, length.out = 16L),
    y2 = seq(0.3, -0.4, length.out = 16L),
    x = rep(c(-1, 1), 8L),
    z = rep(c(0, 1), each = 8L),
    site = rep(site_levels, each = 2L)
  )

  fit_q4 <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + spatial(1 | p | site, coords = coords),
        mu2 = y2 ~ x + spatial(1 | p | site, coords = coords),
        sigma1 = ~ z + spatial(1 | p | site, coords = coords),
        sigma2 = ~ z + spatial(1 | p | site, coords = coords),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = drm_control(
        se = FALSE,
        optimizer = list(eval.max = 100, iter.max = 100)
      )
    )
  )
  q4_pairs <- corpairs(fit_q4, level = "spatial")
  q4_pairs_ci <- corpairs(fit_q4, level = "spatial", conf.int = TRUE)
  q4_cov <- summary(fit_q4)$covariance
  q4_targets <- profile_targets(fit_q4)
  q4_cor_targets <- q4_targets[
    startsWith(q4_targets$parm, "cor:spatial:"),
    ,
    drop = FALSE
  ]
  q4_check <- check_drm(fit_q4)
  q4_diag <- q4_check[
    q4_check$check == "biv_spatial_q4_covariance",
    ,
    drop = FALSE
  ]

  expect_true(is.finite(fit_q4$opt$objective))
  expect_equal(fit_q4$model$structured$phylo_mu$type, "spatial")
  expect_equal(fit_q4$model$structured$phylo_mu$q, 4L)
  expect_equal(
    fit_q4$model$structured$phylo_mu$covariance_mode,
    "unstructured"
  )
  expect_named(
    fit_q4$sdpars$mu,
    c(
      "mu1:spatial(1 | p | site)",
      "mu2:spatial(1 | p | site)",
      "sigma1:spatial(1 | p | site)",
      "sigma2:spatial(1 | p | site)"
    )
  )
  expect_equal(sum(names(fit_q4$opt$par) == "theta_phylo"), 6L)
  expect_equal(nrow(q4_pairs), 6L)
  expect_equal(nrow(q4_pairs_ci), 6L)
  expect_equal(nrow(q4_cov), 6L)
  expect_equal(q4_pairs$level, rep("spatial", 6L))
  expect_equal(
    as.integer(table(q4_pairs$class)[
      c("mean-mean", "mean-scale", "scale-scale")
    ]),
    c(1L, 4L, 1L)
  )
  expect_equal(nrow(corpairs(fit_q4, class = "location-scale")), 4L)
  expect_equal(nrow(corpairs(fit_q4, block = "p")), 6L)
  expect_equal(q4_cov$parameter, q4_pairs$parameter)
  expect_equal(nrow(q4_cor_targets), 6L)
  expect_equal(q4_cor_targets$tmb_parameter, rep("theta_phylo", 6L))
  expect_equal(q4_cor_targets$target_type, rep("derived", 6L))
  expect_false(any(q4_cor_targets$profile_ready))
  expect_equal(
    q4_cor_targets$profile_note,
    rep("derived_unstructured_correlation", 6L)
  )
  expect_equal(q4_pairs_ci$profile_target, q4_cor_targets$parm)
  expect_equal(
    q4_pairs_ci$conf.status,
    rep("derived_interval_unavailable", 6L)
  )
  expect_true(all(is.na(q4_pairs_ci$conf.low)))
  expect_equal(nrow(q4_diag), 1L)
  expect_match(q4_diag$value, "covariance_mode=unstructured", fixed = TRUE)
  expect_match(q4_diag$message, "Spatial q4 location-scale")

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + spatial(1 | p | site, coords = coords),
        mu2 = y2 ~ x + spatial(1 | p | site, coords = coords),
        sigma1 = ~ z + spatial(1 | p | site, coords = coords),
        sigma2 = ~z,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Partial spatial location-scale blocks"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + spatial(1 | site, coords = coords),
        mu2 = y2 ~ x + spatial(1 | site, coords = coords),
        sigma1 = ~ z + spatial(1 | site, coords = coords),
        sigma2 = ~ z + spatial(1 | site, coords = coords),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "require an explicit covariance-block label"
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
    "Bivariate spatial location terms must be matched"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y ~ x + spatial(1 + x | site, coords = coords),
        mu2 = y2 ~ x + spatial(1 + x | site, coords = coords),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "intercept-only structured effects"
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
