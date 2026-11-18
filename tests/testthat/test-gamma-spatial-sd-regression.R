test_that("Gamma spatial intercept SD regression maps sites by name", {
  set.seed(2026102031L)
  n_site <- 24L
  n_each <- 12L
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 2 * pi, length.out = n_site + 1L)[-1L]
  coords <- data.frame(
    x = cos(theta),
    y = sin(theta),
    row.names = rev(site_levels)
  )
  coords <- coords[rev(site_levels), , drop = FALSE]
  z_site <- setNames(as.numeric(scale(stats::rnorm(n_site))), site_levels)
  alpha_sd <- c(`(Intercept)` = log(0.55), z = 0.4)
  tau <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_site[site_levels])
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = site_levels,
    group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))
  unit_field <- as.vector(
    t(chol(covariance)) %*% stats::rnorm(n_site)
  )
  names(unit_field) <- site_levels
  field <- setNames(tau * unit_field, site_levels)

  group_index <- rep(seq_len(n_site), each = n_each)
  site <- factor(site_levels[group_index], levels = site_levels)
  x <- stats::rnorm(length(site))
  mu <- exp(0.4 + 0.3 * x + field[as.character(site)])
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = 4, rate = 4 / mu),
    x = x,
    site = site,
    z = z_site[as.character(site)]
  )

  fit <- drmTMB(
    bf(
      y ~ x + spatial(1 | site, coords = coords),
      sigma ~ 1,
      sd(site, level = "spatial", dpar = "mu", coef = "(Intercept)") ~ z
    ),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_constant_sd <- drmTMB(
    bf(
      y ~ x + spatial(1 | site, coords = coords),
      sigma ~ 1,
      sd(site, level = "spatial") ~ 1
    ),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_scalar <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )

  scale_coef <- coef(fit, "sd_spatial(site)")
  sd_hat <- predict(fit, dpar = "sd_spatial(site)")
  expect_equal(as.integer(fit$opt$convergence), 0L)
  expect_equal(as.integer(fit_constant_sd$opt$convergence), 0L)
  expect_equal(as.integer(fit_scalar$opt$convergence), 0L)
  expect_named(scale_coef, names(alpha_sd))
  expect_setequal(names(sd_hat), site_levels)
  expect_length(sd_hat, n_site)
  expect_true(all(is.finite(sd_hat)))
  expect_gt(scale_coef[["z"]], 0)
  expect_lt(abs(scale_coef[["z"]] - alpha_sd[["z"]]), 0.5)
  expect_equal(
    as.numeric(stats::logLik(fit_constant_sd)),
    as.numeric(stats::logLik(fit_scalar)),
    tolerance = 2e-5
  )
  expect_equal(
    unname(coef(fit_constant_sd, "sd_spatial(site)")[["(Intercept)"]]),
    log(unname(fit_scalar$sdpars$mu[["spatial(1 | site)"]])),
    tolerance = 1e-4
  )
})

test_that("Gamma structured SD matches across engines for the same spatial kernel", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(2026102234L)
  n_site <- 32L
  n_each <- 12L
  site_levels <- paste0("site_", seq_len(n_site))
  coords <- cbind(x = seq_len(n_site) %% 6L, y = seq_len(n_site) %/% 6L)
  distances <- as.matrix(stats::dist(coords))
  positive_distances <- distances[distances > 0]
  range <- stats::median(positive_distances)
  covariance <- exp(-distances / range)
  diag(covariance) <- diag(covariance) + 1e-6
  scale <- 1 / sqrt(diag(covariance))
  K_spatial <- diag(scale) %*% covariance %*% diag(scale)
  dimnames(K_spatial) <- list(site_levels, site_levels)

  z_site <- setNames(rep(c(-1, 1), each = n_site / 2L), site_levels)
  alpha_sd <- c(`(Intercept)` = log(0.55), z = 0.4)
  tau <- exp(alpha_sd[[1L]] + alpha_sd[["z"]] * z_site)
  latent <- drop(t(chol(K_spatial)) %*% stats::rnorm(n_site))
  names(latent) <- site_levels
  effect <- setNames(tau * latent, site_levels)
  site_index <- rep(seq_len(n_site), each = n_each)
  site <- factor(site_levels[site_index], levels = site_levels)
  x <- stats::rnorm(length(site))
  mu <- exp(0.3 + 0.25 * x + effect[as.character(site)])
  data <- data.frame(
    y = stats::rgamma(length(mu), shape = 1 / 0.32^2,
                      rate = (1 / 0.32^2) / mu),
    x, site, z = z_site[as.character(site)]
  )
  formula <- bf(
    y ~ x + relmat(1 | site, K = K_spatial),
    sigma ~ 1,
    sd(site, level = "relmat") ~ z
  )

  native <- drmTMB(
    formula, family = Gamma(link = "log"), data = data, engine = "tmb"
  )
  julia <- drmTMB(
    formula, family = Gamma(link = "log"), data = data, engine = "julia"
  )

  expect_equal(as.integer(native$opt$convergence), 0L)
  expect_true(isTRUE(native$sdr$pdHess))
  expect_equal(as.integer(julia$opt$convergence), 0L)
  expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
               tolerance = 0.15)

  dpar <- "sd_relmat(site)"
  native_coef <- coef(native, dpar = dpar)
  julia_coef <- coef(julia, dpar = dpar)
  expect_named(julia_coef, names(native_coef))
  expect_equal(unname(julia_coef), unname(native_coef), tolerance = 0.15)
  expect_equal(unname(julia_coef), unname(alpha_sd), tolerance = 0.5)

  native_sd <- predict(native, dpar = dpar)
  julia_sd <- predict(julia, dpar = dpar)
  names(native_sd) <- sub("^sd_relmat\\(site\\):", "", names(native_sd))
  names(julia_sd) <- sub("^sd_relmat\\(site\\):", "", names(julia_sd))
  expect_setequal(names(julia_sd), site_levels)
  expect_equal(unname(julia_sd[site_levels]),
               unname(native_sd[site_levels]), tolerance = 0.15)
})
