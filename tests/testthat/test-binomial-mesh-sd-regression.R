test_that("binomial mesh spatial-intercept SD regression recovers its slope", {
  skip_on_cran()
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")

  set.seed(20261027)
  n_site <- 32L
  n_each <- 40L
  site_xy <- cbind(
    longitude = rep(seq(-123.10, -123.03, length.out = 8L), each = 4L),
    latitude = rep(seq(49.20, 49.23, length.out = 4L), times = 8L)
  )
  z_by_site <- sample(rep(c(-1, 1), each = n_site / 2L))
  site <- factor(rep(seq_len(n_site), each = n_each))
  z_site <- rep(z_by_site, each = n_each)
  dat <- data.frame(
    y = 0L,
    site = site,
    z_site = z_site,
    longitude = rep(site_xy[, 1L], each = n_each),
    latitude = rep(site_xy[, 2L], each = n_each)
  )
  rownames(dat) <- paste0("obs_", seq_len(nrow(dat)))
  coords <- spatial_coords(dat, longitude, latitude, crs_out = 32610)
  mesh <- make_mesh(coords, kappa = 1 / 1000)
  A <- mesh$A_st
  Q <- mesh$kappa^4 * mesh$spde$c0 +
    2 * mesh$kappa^2 * mesh$spde$g1 + mesh$spde$g2
  Q <- as.matrix(Q)
  set.seed(20261028)
  u <- backsolve(chol(Q), stats::rnorm(ncol(A)))
  field <- as.vector(A %*% u)
  base_multiplier <- 0.4 / stats::sd(field)
  tau <- base_multiplier * exp(0.5 * dat$z_site)
  eta <- -0.15 + tau * field
  set.seed(20261029)
  dat$y <- stats::rbinom(nrow(dat), 1L, stats::plogis(eta))

  fit <- drmTMB(
    bf(
      y ~ spatial(1 | site, mesh = mesh),
      sd(site, level = "spatial") ~ z_site
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  beta_sd <- coef(fit, "sd_spatial(site)")
  sd_rows <- dat[!duplicated(dat$site), , drop = FALSE]
  sd_link <- predict(fit, newdata = sd_rows,
                     dpar = "sd_spatial(site)", type = "link")
  sd_hat <- predict(fit, newdata = sd_rows, dpar = "sd_spatial(site)")
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0L)
  expect_true(abs(unname(beta_sd[["z_site"]]) - 0.5) < 0.4)
  expect_equal(exp(sd_link), sd_hat, tolerance = 1e-10)
  expect_equal(
    unname(sd_hat),
    exp(as.vector(stats::model.matrix(~ z_site, sd_rows) %*% beta_sd)),
    tolerance = 1e-10
  )
  expect_true(isTRUE(fit$model$structured$mesh_spatial_mu$has))

  mesh <- fit$model$structured$mesh_spatial_mu
  sd_registry <- fit$model$random_scale$phylo
  sd_by_group <- predict_random_scale_dpar(fit, sd_registry$dpars[[1L]])
  sd_row <- fit$model$tmb_data$phylo_mu_sd_row + 1L
  cholesky <- mesh$precision$cholesky
  factor_error <- as.matrix(
    cholesky$P %*% mesh$precision$precision %*% Matrix::t(cholesky$P) -
      cholesky$L %*% Matrix::t(cholesky$L)
  )
  expect_lt(max(abs(factor_error)), 1e-8)
  set.seed(20261030)
  expected_latent <- as.numeric(
    Matrix::t(cholesky$P) %*%
      Matrix::solve(Matrix::t(cholesky$L), stats::rnorm(mesh$n_re))
  )
  expected_field <- as.vector(mesh$projection %*% expected_latent)
  expected_draw <- expected_field * unname(sd_by_group[sd_row])
  set.seed(20261030)
  marginal_draw <- drm_ordinary_random_effect_draws(fit)$mu
  expect_equal(marginal_draw, expected_draw, tolerance = 1e-10)

  simulated <- simulate(fit, nsim = 2L, seed = 20261031)
  expect_equal(nrow(simulated), nrow(dat))
  expect_true(all(as.matrix(simulated) %in% c(0, 1)))
  save_path <- tempfile(fileext = ".rds")
  on.exit(unlink(save_path), add = TRUE)
  saveRDS(fit, save_path)
  restored <- readRDS(save_path)
  expect_equal(
    predict(restored, dpar = "sd_spatial(site)"),
    predict(fit, dpar = "sd_spatial(site)"),
    tolerance = 1e-12
  )
  expect_identical(
    simulate(restored, nsim = 2L, seed = 20261031),
    simulated
  )
})

test_that("non-logit Binomial mesh SD routes recover and simulate", {
  skip_on_cran()
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")

  n_site <- 32L
  n_each <- 40L
  site_xy <- cbind(
    longitude = rep(seq(-123.10, -123.03, length.out = 8L), each = 4L),
    latitude = rep(seq(49.20, 49.23, length.out = 4L), times = 8L)
  )
  site <- factor(rep(seq_len(n_site), each = n_each))
  z_by_site <- sample(rep(c(-1, 1), each = n_site / 2L))
  dat <- data.frame(
    y = 0L,
    site = site,
    z_site = rep(z_by_site, each = n_each),
    longitude = rep(site_xy[, 1L], each = n_each),
    latitude = rep(site_xy[, 2L], each = n_each)
  )
  coords <- spatial_coords(dat, longitude, latitude, crs_out = 32610)
  mesh <- make_mesh(coords, kappa = 1 / 1000)
  A <- mesh$A_st
  Q <- mesh$kappa^4 * mesh$spde$c0 +
    2 * mesh$kappa^2 * mesh$spde$g1 + mesh$spde$g2
  Q <- as.matrix(Q)

  for (link in c("probit", "cloglog")) {
    set.seed(if (link == "probit") 20261032 else 20261034)
    u <- backsolve(chol(Q), stats::rnorm(ncol(A)))
    field <- as.vector(A %*% u)
    tau <- (0.4 / stats::sd(field)) * exp(0.5 * dat$z_site)
    eta <- -0.15 + tau * field
    dat$y <- stats::rbinom(
      nrow(dat), 1L, stats::make.link(link)$linkinv(eta)
    )

    fit <- drmTMB(
      bf(
        y ~ spatial(1 | site, mesh = mesh),
        sd(site, level = "spatial") ~ z_site
      ),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )

    beta_sd <- coef(fit, "sd_spatial(site)")
    sd_rows <- dat[!duplicated(dat$site), , drop = FALSE]
    sd_link <- predict(fit, newdata = sd_rows,
                       dpar = "sd_spatial(site)", type = "link")
    sd_hat <- predict(fit, newdata = sd_rows, dpar = "sd_spatial(site)")
    expect_identical(fit$opt$convergence, 0L, info = link)
    expect_true(abs(unname(beta_sd[["z_site"]]) - 0.5) < 0.4,
                info = link)
    expect_equal(exp(sd_link), sd_hat, tolerance = 1e-10, info = link)

    simulated <- simulate(fit, nsim = 1L, seed = 20261035)
    expect_equal(nrow(simulated), nrow(dat), info = link)
    expect_true(all(as.matrix(simulated) %in% c(0, 1)), info = link)
  }
})

test_that("Binomial mesh spatial-slope SD regression uses the slope design", {
  skip_on_cran()
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")

  set.seed(20261036)
  n_site <- 36L
  n_each <- 40L
  site_xy <- cbind(
    longitude = rep(seq(-123.10, -123.03, length.out = 9L), each = 4L),
    latitude = rep(seq(49.20, 49.23, length.out = 4L), times = 9L)
  )
  site <- factor(rep(seq_len(n_site), each = n_each))
  z_by_site <- sample(rep(c(-1, 1), each = n_site / 2L))
  z_site <- rep(z_by_site, each = n_each)
  x <- rep(rep(c(-1, 1), each = n_each / 2L), times = n_site)
  dat <- data.frame(
    y = 0L,
    site = site,
    x = x,
    z_site = z_site,
    longitude = rep(site_xy[, 1L], each = n_each),
    latitude = rep(site_xy[, 2L], each = n_each)
  )
  rownames(dat) <- paste0("mesh_slope_obs_", seq_len(nrow(dat)))
  coords <- spatial_coords(dat, longitude, latitude, crs_out = 32610)
  mesh <- make_mesh(coords, kappa = 1 / 1000)
  A <- mesh$A_st
  Q <- as.matrix(
    mesh$kappa^4 * mesh$spde$c0 +
      2 * mesh$kappa^2 * mesh$spde$g1 + mesh$spde$g2
  )
  set.seed(20261037)
  u <- backsolve(chol(Q), stats::rnorm(ncol(A)))
  field <- as.vector(A %*% u)
  alpha <- c(log(0.45 / stats::sd(field)), 0.55)
  eta <- -0.15 + 0.3 * x + x * exp(alpha[[1L]] + alpha[[2L]] * z_site) * field
  set.seed(20261038)
  dat$y <- stats::rbinom(nrow(dat), 1L, stats::plogis(eta))

  fit <- drmTMB(
    bf(
      y ~ 1 + x + spatial(0 + x | site, mesh = mesh),
      sd(site, level = "spatial", coef = "x") ~ z_site
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_identical(fit$opt$convergence, 0L)
  expect_lt(abs(unname(coef(fit, "sd_spatial(site)")[["z_site"]]) - 0.55), 0.4)
  sd_rows <- dat[!duplicated(dat$site), , drop = FALSE]
  sd_coef <- coef(fit, "sd_spatial(site)")
  expect_equal(
    unname(predict(fit, newdata = sd_rows, dpar = "sd_spatial(site)")),
    exp(as.vector(stats::model.matrix(~ z_site, sd_rows) %*% sd_coef)),
    tolerance = 1e-10
  )
  mesh_fit <- fit$model$structured$mesh_spatial_mu
  expect_identical(mesh_fit$coef_names, "x")
  expect_equal(mesh_fit$value, dat$x)
  ranef_mesh <- ranef(fit, "spatial_mu")
  expect_equal(
    unname(ranef_mesh$projected),
    as.vector(mesh_fit$projection %*% ranef_mesh$latent),
    tolerance = 1e-10
  )
  sd_registry <- fit$model$random_scale$phylo
  sd_by_group <- predict_random_scale_dpar(fit, sd_registry$dpars[[1L]])
  sd_row <- sd_registry$observation_sd_row0 + 1L
  factor <- mesh_fit$precision$cholesky
  set.seed(20261040)
  expected_latent <- as.numeric(
    Matrix::t(factor$P) %*%
      Matrix::solve(Matrix::t(factor$L), stats::rnorm(mesh_fit$n_re))
  )
  expected_draw <- mesh_fit$value *
    as.vector(mesh_fit$projection %*% expected_latent) *
    unname(sd_by_group[sd_row])
  set.seed(20261040)
  expect_equal(
    drm_ordinary_random_effect_draws(fit)$mu,
    expected_draw,
    tolerance = 1e-10
  )
  simulated <- simulate(fit, nsim = 2L, seed = 20261039)
  expect_true(all(as.matrix(simulated) %in% c(0, 1)))
  save_path <- tempfile(fileext = ".rds")
  on.exit(unlink(save_path), add = TRUE)
  saveRDS(fit, save_path)
  restored <- readRDS(save_path)
  expect_equal(
    predict(restored, dpar = "sd_spatial(site)"),
    predict(fit, dpar = "sd_spatial(site)"),
    tolerance = 1e-12
  )
  expect_identical(
    simulate(restored, nsim = 2L, seed = 20261039),
    simulated
  )
})

test_that("non-logit Binomial mesh slopes recover predictor-dependent SDs", {
  skip_on_cran()
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")

  n_site <- 48L
  n_each <- 48L
  site_xy <- cbind(
    longitude = rep(seq(-123.10, -123.03, length.out = 8L), each = 6L),
    latitude = rep(seq(49.20, 49.25, length.out = 6L), times = 8L)
  )
  site <- factor(rep(seq_len(n_site), each = n_each))
  x <- rep(rep(c(-1, 1), each = n_each / 2L), times = n_site)
  template <- data.frame(
    y = 0L,
    site = site,
    x = x,
    z_site = 0,
    longitude = rep(site_xy[, 1L], each = n_each),
    latitude = rep(site_xy[, 2L], each = n_each)
  )
  rownames(template) <- paste0("mesh_nonlogit_obs_", seq_len(nrow(template)))
  coords <- spatial_coords(template, longitude, latitude, crs_out = 32610)
  mesh <- make_mesh(coords, kappa = 1 / 1000)
  A <- mesh$A_st
  Q <- as.matrix(
    mesh$kappa^4 * mesh$spde$c0 +
      2 * mesh$kappa^2 * mesh$spde$g1 + mesh$spde$g2
  )

  for (link in c("probit", "cloglog")) {
    set.seed(if (link == "probit") 20261041 else 20261043)
    z_by_site <- sample(rep(c(-1, 1), each = n_site / 2L))
    dat <- template
    dat$z_site <- rep(z_by_site, each = n_each)
    u <- backsolve(chol(Q), stats::rnorm(ncol(A)))
    field <- as.vector(A %*% u)
    alpha <- c(log(0.45 / stats::sd(field)), 0.55)
    eta <- -0.15 + 0.3 * x +
      x * exp(alpha[[1L]] + alpha[[2L]] * dat$z_site) * field
    set.seed(if (link == "probit") 20261042 else 20261044)
    dat$y <- stats::rbinom(
      nrow(dat), 1L, stats::make.link(link)$linkinv(eta)
    )

    fit <- drmTMB(
      bf(
        y ~ 1 + x + spatial(0 + x | site, mesh = mesh),
        sd(site, level = "spatial", coef = "x") ~ z_site
      ),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )

    scale_coef <- coef(fit, "sd_spatial(site)")
    sd_rows <- dat[!duplicated(dat$site), , drop = FALSE]
    expect_identical(fit$opt$convergence, 0L, info = link)
    expect_true(abs(unname(scale_coef[["z_site"]]) - 0.55) < 0.4, info = link)
    expect_equal(
      unname(predict(fit, newdata = sd_rows, dpar = "sd_spatial(site)")),
      exp(as.vector(stats::model.matrix(~ z_site, sd_rows) %*% scale_coef)),
      tolerance = 1e-10,
      info = link
    )
    expect_true(
      all(as.matrix(simulate(fit, nsim = 1L, seed = 20261045)) %in% c(0, 1)),
      info = link
    )
  }
})

