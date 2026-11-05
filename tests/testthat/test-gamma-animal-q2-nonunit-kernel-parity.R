test_that("Gamma animal q2 fits agree with raw non-unit kernel scaling", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261033L)
  n_group <- 32L
  n_each <- 16L
  id_levels <- sprintf("animal_%02d", seq_len(n_group))
  z_group <- rep(c(-1, 1), each = n_group / 2L)
  log_kernel_scale <- 0.3
  kernel_scale <- exp(log_kernel_scale * z_group)
  correlation <- 0.45^abs(outer(seq_len(n_group), seq_len(n_group), "-"))
  A <- outer(kernel_scale, kernel_scale) * correlation
  dimnames(A) <- list(id_levels, id_levels)

  alpha0 <- c(`(Intercept)` = log(0.38), z = 0.35)
  alpha1 <- c(`(Intercept)` = log(0.30), z = -0.4)
  L <- t(chol(A))
  u0 <- drop(L %*% stats::rnorm(n_group))
  u1 <- drop(L %*% stats::rnorm(n_group))
  b0 <- exp(alpha0[[1L]] + alpha0[[2L]] * z_group) * u0
  b1 <- exp(alpha1[[1L]] + alpha1[[2L]] * z_group) * u1
  animal_index <- rep(seq_len(n_group), each = n_each)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_group)
  mu <- exp(0.25 + 0.2 * x + b0[animal_index] + x * b1[animal_index])
  sigma <- 0.4
  shape <- sigma^-2
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    id = factor(id_levels[animal_index], levels = id_levels),
    z = z_group[animal_index]
  )
  form <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z,
    sd(id, level = "animal", dpar = "mu", coef = "x") ~ z
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

  expect_gt(max(abs(sqrt(diag(A)) - 1)), 0.1)
  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  for (key in c(key0, key1)) {
    expect_named(
      coef(fit_tmb, key),
      c("(Intercept)", "z")
    )
    expect_named(
      coef(fit_julia, key),
      c("(Intercept)", "z")
    )
    expect_equal(
      unname(coef(fit_julia, key)[["(Intercept)"]]),
      unname(coef(fit_tmb, key)[["(Intercept)"]]), tolerance = 0.25
    )
    expect_equal(
      unname(coef(fit_julia, key)[["z"]]),
      unname(coef(fit_tmb, key)[["z"]]), tolerance = 0.25
    )
    tmb_group_sd <- predict(fit_tmb, dpar = key)
    julia_group_sd <- predict(fit_julia, dpar = key)
    expect_equal(
      unname(julia_group_sd),
      unname(tmb_group_sd),
      tolerance = 0.25
    )
  }
  expect_gt(coef(fit_tmb, key0)[["z"]], 0)
  expect_lt(coef(fit_tmb, key1)[["z"]], 0)
  expect_equal(
    as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
    tolerance = 1e-3
  )
})
