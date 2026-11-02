test_that("Gamma animal intercept and slope SD regressions agree across engines", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261030L)
  n_group <- 32L
  n_each <- 16L
  id_levels <- sprintf("animal_%02d", seq_len(n_group))
  A <- 0.45^abs(outer(seq_len(n_group), seq_len(n_group), "-"))
  dimnames(A) <- list(id_levels, id_levels)
  z0_group <- rep(c(-1, 1), each = n_group / 2L)
  z1_group <- rep(c(-1, 1), times = n_group / 2L)
  alpha0 <- c(`(Intercept)` = log(0.38), z0 = 0.35)
  alpha1 <- c(`(Intercept)` = log(0.30), z1 = -0.4)
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

  fit_tmb <- drmTMB(
    form, family = stats::Gamma(link = "log"), data = dat,
    engine = "tmb"
  )
  fit_julia <- drmTMB(
    form, family = stats::Gamma(link = "log"), data = dat,
    engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  for (key in c(key0, key1)) {
    expect_named(coef(fit_tmb, key), c("(Intercept)", if (key == key0) "z0" else "z1"))
    expect_named(coef(fit_julia, key), c("(Intercept)", if (key == key0) "z0" else "z1"))
    expect_equal(coef(fit_julia, key), coef(fit_tmb, key), tolerance = 0.25)
    expect_equal(
      unname(predict(fit_julia, dpar = key)),
      unname(predict(fit_tmb, dpar = key)),
      tolerance = 0.25
    )
  }
  expect_gt(coef(fit_tmb, key0)[["z0"]], 0)
  expect_lt(coef(fit_tmb, key1)[["z1"]], 0)
  expect_lt(
    max(abs(coef(fit_tmb, key0)[names(alpha0)] - alpha0)),
    0.55
  )
  expect_lt(
    max(abs(coef(fit_tmb, key1)[names(alpha1)] - alpha1)),
    0.55
  )
  expect_equal(
    as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
    tolerance = 1e-3
  )
  expect_true(all(c(key0, key1) %in% names(fit_julia$sdpars)))
  expect_true(all(c(key0, key1) %in% names(fit_tmb$sdpars)))
  parameter_table <- predict_parameters(
    fit_julia, dpar = c(key0, key1), conf.int = FALSE
  )
  expect_setequal(unique(parameter_table$dpar), c(key0, key1))
  expect_equal(nrow(parameter_table), 2L * n_group)
  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(fit_julia, saved)
  reloaded <- readRDS(saved)
  expect_equal(coef(reloaded, key0), coef(fit_julia, key0))
  expect_equal(predict(reloaded, dpar = key1), predict(fit_julia, dpar = key1))

  simulation_seed <- 20261031L
  set.seed(simulation_seed)
  groups <- unique(as.character(dat$id))
  group_index <- match(as.character(dat$id), groups)
  u0 <- drop(t(chol(A)) %*% stats::rnorm(n_group))
  u1 <- drop(t(chol(A)) %*% stats::rnorm(n_group))
  sd0 <- predict(fit_julia, dpar = key0)
  sd1 <- predict(fit_julia, dpar = key1)
  eta_sim <- as.numeric(predict(
    fit_julia, newdata = dat, dpar = "mu", type = "link"
  )) +
    unname(sd0[paste0(key0, ":", groups)])[group_index] * u0[group_index] +
    dat$x * unname(sd1[paste0(key1, ":", groups)])[group_index] * u1[group_index]
  gamma_parameters <- drm_gamma_shape_scale(exp(eta_sim), predict(fit_julia, dpar = "sigma"))
  expected <- stats::rgamma(
    nrow(dat), shape = gamma_parameters$shape, scale = gamma_parameters$scale
  )
  simulated <- simulate(fit_julia, nsim = 1L, seed = simulation_seed)
  expect_equal(unname(simulated[[1L]]), expected)
  expect_equal(
    simulate(fit_julia, nsim = 1L, seed = simulation_seed), simulated
  )
  set.seed(318L)
  expected_next_rng <- stats::runif(1L)
  set.seed(318L)
  simulate(fit_julia, nsim = 1L, seed = simulation_seed)
  expect_equal(stats::runif(1L), expected_next_rng)
  expect_error(
    simulate(fit_julia, nsim = 1L, seed = simulation_seed, re.form = NULL),
    "Conditional simulation is unavailable"
  )
})
