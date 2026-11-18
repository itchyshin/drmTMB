test_that("Binomial spatial intercepts support predictor-dependent SDs", {
  skip_on_cran()

  set.seed(20261030L)
  n_site <- 32L
  n_each <- 24L
  site_levels <- paste0("s", seq_len(n_site))
  coords <- cbind(
    east = seq(0, 1, length.out = n_site),
    north = sin(seq(0, 2 * pi, length.out = n_site))
  )
  rownames(coords) <- site_levels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))
  z_site <- sample(rep(c(-1, 1), length.out = n_site))
  alpha_sd <- c(`(Intercept)` = log(0.45), z = 0.45)
  site_sd <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_site)
  latent <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_site))
  site_index <- rep(seq_len(n_site), each = n_each)
  site <- factor(site_levels[site_index], levels = site_levels)
  x <- stats::rnorm(length(site_index))
  eta <- -0.2 + 0.35 * x + (site_sd * latent)[site_index]
  for (link in c("logit", "probit", "cloglog")) {
    p <- switch(
      link,
      logit = stats::plogis(eta),
      probit = stats::pnorm(eta),
      cloglog = -expm1(-exp(eta))
    )
    y <- stats::rbinom(length(eta), 1L, p)
    dat <- data.frame(y, x, site, z = z_site[site_index])
    fit <- drmTMB(
      bf(
        y ~ x + spatial(1 | site, coords = coords),
        sd(site, level = "spatial") ~ z
      ),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )

    sd_coef <- coef(fit, dpar = "sd_spatial(site)")
    expect_true(is_converged(fit))
    expect_gt(sd_coef[["z"]], 0)
    expect_lt(abs(sd_coef[["z"]] - alpha_sd[["z"]]), 0.4)
    expect_equal(
      as.vector(predict(fit, dpar = "sd_spatial(site)")),
      as.vector(exp(stats::model.matrix(~z, data.frame(z = z_site)) %*% sd_coef)),
      tolerance = 1e-8
    )

    simulated <- simulate(fit, nsim = 2L, seed = 202610301L)
    expect_length(simulated, 2L)
    expect_true(all(vapply(simulated, length, integer(1L)) == nrow(dat)))
    expect_true(all(unlist(simulated, use.names = FALSE) %in% 0:1))
  }
})

test_that("Binomial spatial slopes support predictor-dependent SDs", {
  skip_on_cran()

  set.seed(20261031L)
  n_site <- 64L
  n_each <- 48L
  site_levels <- paste0("s", seq_len(n_site))
  axis <- seq(0, 1, length.out = n_site)
  coords <- cbind(east = axis, north = sin(2 * pi * axis))
  rownames(coords) <- site_levels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))
  z_site <- sample(rep(c(-1, 1), length.out = n_site))
  alpha_sd <- c(`(Intercept)` = log(0.55), z = 0.6)
  site_sd <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_site)
  latent <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_site))
  site_index <- rep(seq_len(n_site), each = n_each)
  site <- factor(site_levels[site_index], levels = site_levels)
  x <- rep(seq(-1.5, 1.5, length.out = n_each), times = n_site)
  eta <- -0.2 + 0.25 * x + x * (site_sd * latent)[site_index]

  for (link in c("logit", "probit", "cloglog")) {
    p <- switch(
      link,
      logit = stats::plogis(eta),
      probit = stats::pnorm(eta),
      cloglog = -expm1(-exp(eta))
    )
    y <- stats::rbinom(length(eta), 1L, p)
    dat <- data.frame(y, x, site, z = z_site[site_index])
    fit <- drmTMB(
      bf(
        y ~ x + spatial(0 + x | site, coords = coords),
        sd(site, level = "spatial") ~ z
      ),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )

    sd_coef <- coef(fit, dpar = "sd_spatial(site)")
    expect_true(is_converged(fit))
    expect_gt(sd_coef[["z"]], 0)
    expect_lt(abs(sd_coef[["z"]] - alpha_sd[["z"]]), 0.45)
    expect_equal(
      as.vector(predict(fit, dpar = "sd_spatial(site)")),
      as.vector(exp(stats::model.matrix(~z, data.frame(z = z_site)) %*% sd_coef)),
      tolerance = 1e-8
    )
    simulated <- simulate(fit, nsim = 2L, seed = 202610311L)
    expect_length(simulated, 2L)
    expect_true(all(vapply(simulated, length, integer(1L)) == nrow(dat)))
    expect_true(all(unlist(simulated, use.names = FALSE) %in% 0:1))
  }
})
