test_that("Gamma relmat SD regression recovers group-level scale effects", {
  set.seed(2026102028L)
  n_group <- 24L
  n_each <- 12L
  id_levels <- paste0("id_", seq_len(n_group))
  kernel_order <- rev(seq_len(n_group))
  kernel_ids <- id_levels[kernel_order]
  K_gamma_relmat <- outer(
    kernel_order,
    kernel_order,
    function(i, j) 0.45^abs(i - j)
  )
  dimnames(K_gamma_relmat) <- list(kernel_ids, kernel_ids)
  z_group <- setNames(as.numeric(scale(stats::rnorm(n_group))), id_levels)
  alpha_sd <- c(`(Intercept)` = log(0.55), z = 0.4)
  tau_order <- exp(
    alpha_sd[[1L]] + alpha_sd[[2L]] * z_group[kernel_ids]
  )
  unit_order <- as.vector(
    t(chol(K_gamma_relmat)) %*% stats::rnorm(n_group)
  )
  names(unit_order) <- kernel_ids
  effect <- setNames(tau_order * unit_order, kernel_ids)[id_levels]

  group_index <- rep(seq_len(n_group), each = n_each)
  id_obs <- factor(id_levels[group_index], levels = id_levels)
  x <- stats::rnorm(length(id_obs))
  mu <- exp(0.4 + 0.3 * x + effect[id_obs])
  shape <- 4
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    id = id_obs,
    z = z_group[id_obs]
  )

  fit <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K_gamma_relmat),
      sigma ~ 1,
      sd(id, level = "relmat") ~ z
    ),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_constant_sd <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K_gamma_relmat),
      sigma ~ 1,
      sd(id, level = "relmat") ~ 1
    ),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_scalar <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K_gamma_relmat), sigma ~ 1),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )

  scale_coef <- coef(fit, "sd_relmat(id)")
  sd_hat <- predict(fit, dpar = "sd_relmat(id)")
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(fit_constant_sd$opt$convergence, 0L)
  expect_equal(fit_scalar$opt$convergence, 0L)
  expect_named(scale_coef, names(alpha_sd))
  expect_setequal(names(sd_hat), id_levels)
  expect_length(sd_hat, n_group)
  expect_true(all(is.finite(sd_hat)))
  expect_gt(scale_coef[["z"]], 0)
  expect_lt(abs(scale_coef[["z"]] - alpha_sd[["z"]]), 0.5)
  expect_equal(
    as.numeric(stats::logLik(fit_constant_sd)),
    as.numeric(stats::logLik(fit_scalar)),
    tolerance = 2e-5
  )
  expect_equal(
    unname(coef(fit_constant_sd, "sd_relmat(id)")[["(Intercept)"]]),
    log(unname(fit_scalar$sdpars$mu[["relmat(1 | id)"]])),
    tolerance = 1e-4
  )
})
