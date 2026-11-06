test_that("Julia Gamma animal intercept SD fits support marginal simulation", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261034L)
  n_group <- 28L
  n_each <- 12L
  id_levels <- sprintf("animal_%02d", seq_len(n_group))
  kernel_scale <- seq(0.75, 1.25, length.out = n_group)
  correlation <- 0.4^abs(outer(seq_len(n_group), seq_len(n_group), "-"))
  A <- outer(kernel_scale, kernel_scale) * correlation
  dimnames(A) <- list(id_levels, id_levels)
  z_group <- rep(c(-1, 1), each = n_group / 2L)
  alpha <- c(`(Intercept)` = log(0.42), z = 0.35)
  group_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  animal_index <- rep(seq_len(n_group), each = n_each)
  latent <- drop(t(chol(correlation)) %*% stats::rnorm(n_group)) * group_sd
  x <- stats::rnorm(length(animal_index))
  mu <- exp(0.2 + 0.15 * x + latent[animal_index])
  sigma <- 0.4
  shape <- sigma^-2
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    id = factor(id_levels[animal_index], levels = id_levels),
    z = z_group[animal_index]
  )
  form <- bf(
    y ~ x + animal(1 | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )
  fit <- drmTMB(
    form, family = stats::Gamma(link = "log"), data = dat, engine = "julia"
  )
  expect_true(is_converged(fit))

  dpar <- "sd_animal(id)"
  groups <- unique(as.character(dat$id))
  expect_equal(groups, id_levels)
  expect_gt(max(abs(sqrt(diag(A)) - 1)), 0.1)
  expect_named(predict(fit, dpar = dpar), paste0(dpar, ":", groups))

  simulation_seed <- 20261035L
  set.seed(simulation_seed)
  normalized_A <- A / outer(sqrt(diag(A)), sqrt(diag(A)))
  u <- drop(t(chol(normalized_A)) %*% stats::rnorm(n_group))
  eta <- as.numeric(predict(
    fit, newdata = dat, dpar = "mu", type = "link"
  )) + unname(predict(fit, dpar = dpar))[match(dat$id, groups)] * u[match(dat$id, groups)]
  gamma_parameters <- drm_gamma_shape_scale(
    exp(eta), predict(fit, newdata = dat, dpar = "sigma")
  )
  expected <- stats::rgamma(
    nrow(dat), shape = gamma_parameters$shape,
    scale = gamma_parameters$scale
  )
  simulated <- simulate(fit, nsim = 1L, seed = simulation_seed)
  expect_equal(unname(simulated[[1L]]), expected)
  expect_identical(
    simulate(fit, nsim = 1L, seed = simulation_seed), simulated
  )
})
