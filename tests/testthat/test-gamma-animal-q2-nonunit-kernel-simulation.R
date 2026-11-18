test_that("Julia Gamma animal SD simulation preserves non-unit kernel scaling", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261032L)
  n_group <- 32L
  n_each <- 16L
  id_levels <- sprintf("animal_%02d", seq_len(n_group))
  kernel_scale <- seq(0.7, 1.3, length.out = n_group)
  correlation <- 0.45^abs(outer(seq_len(n_group), seq_len(n_group), "-"))
  A <- outer(kernel_scale, kernel_scale) * correlation
  dimnames(A) <- list(id_levels, id_levels)
  z0_group <- rep(c(-1, 1), each = n_group / 2L)
  z1_group <- rep(c(-1, 1), times = n_group / 2L)
  alpha0 <- c(`(Intercept)` = log(0.38), z0 = 0.25)
  alpha1 <- c(`(Intercept)` = log(0.30), z1 = -0.3)
  # Julia and native TMB both retain the supplied animal covariance scale.
  L <- t(chol(A))
  u0 <- drop(L %*% stats::rnorm(n_group))
  u1 <- drop(L %*% stats::rnorm(n_group))
  b0 <- exp(alpha0[[1L]] + alpha0[[2L]] * z0_group) * u0
  b1 <- exp(alpha1[[1L]] + alpha1[[2L]] * z1_group) * u1
  animal_index <- rep(seq_len(n_group), each = n_each)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_group)
  mu <- exp(0.25 + 0.2 * x + b0[animal_index] + x * b1[animal_index])
  sigma <- 0.4
  shape <- sigma^-2
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    id = factor(id_levels[animal_index], levels = id_levels),
    z0 = z0_group[animal_index],
    z1 = z1_group[animal_index]
  )
  form <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0,
    sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1
  )
  key0 <- 'sd_animal(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd_animal(id, dpar = "mu", coef = "x")'

  fit <- drmTMB(
    form, family = stats::Gamma(link = "log"), data = dat,
    engine = "julia"
  )
  expect_true(is_converged(fit))

  # `predict()` returns the SD multiplier. The supplied A contributes its
  # group-specific marginal scale through sqrt(diag(A)).
  groups <- unique(as.character(dat$id))
  expect_equal(groups, id_levels)
  expect_gt(max(abs(sqrt(diag(A)) - 1)), 0.1)
  expect_equal(diag(correlation), rep(1, n_group))
  group_sd0 <- predict(fit, dpar = key0)
  group_sd1 <- predict(fit, dpar = key1)
  expect_named(group_sd0, paste0(key0, ":", groups))
  expect_named(group_sd1, paste0(key1, ":", groups))

  simulation_seed <- 20261033L
  set.seed(simulation_seed)
  group_index <- match(as.character(dat$id), groups)
  u0 <- drop(t(chol(A)) %*% stats::rnorm(n_group))
  u1 <- drop(t(chol(A)) %*% stats::rnorm(n_group))
  eta <- as.numeric(predict(
    fit, newdata = dat, dpar = "mu", type = "link"
  )) +
    unname(group_sd0[paste0(key0, ":", groups)])[group_index] *
      u0[group_index] +
    dat$x * unname(group_sd1[paste0(key1, ":", groups)])[group_index] *
      u1[group_index]
  gamma_parameters <- drm_gamma_shape_scale(
    exp(eta), predict(fit, newdata = dat, dpar = "sigma")
  )
  expected <- stats::rgamma(
    nrow(dat), shape = gamma_parameters$shape,
    scale = gamma_parameters$scale
  )
  simulated <- simulate(fit, nsim = 1L, seed = simulation_seed)
  expect_equal(unname(simulated[[1L]]), expected)
  expect_equal(
    simulate(fit, nsim = 1L, seed = simulation_seed), simulated
  )
})
