test_that("Julia bridge fits a ZIP mean random-intercept SD regression", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261024L)
  groups <- 80L
  repeats <- 16L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  z_group <- rep(c(0, 1), each = groups / 2L)
  z <- z_group[id_index]
  x <- stats::rnorm(length(id_index))
  alpha <- c(-0.50, 0.40)
  b <- exp(alpha[[1L]] + alpha[[2L]] * z_group) * stats::rnorm(groups)
  zi <- stats::plogis(rep(-1.5, length(id_index)))
  lambda <- exp(0.35 + 0.25 * x + b[id_index])
  y <- ifelse(stats::runif(length(id_index)) < zi, 0L, stats::rpois(length(id_index), lambda))
  dat <- data.frame(y, x, z, id)
  formula <- bf(y ~ x + (1 | id), zi ~ 1, sd(id) ~ z)
  sd_dpar <- "sd(id)"

  fit_tmb <- drmTMB(
    formula, family = stats::poisson(), data = dat, engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    formula, family = stats::poisson(), data = dat, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_julia, dpar = sd_dpar), c("(Intercept)", "z"))
  expect_gt(coef(fit_julia, dpar = sd_dpar)[["z"]], 0)
  expect_equal(
    unname(coef(fit_julia, dpar = sd_dpar)),
    unname(coef(fit_tmb, dpar = sd_dpar)),
    tolerance = 0.45
  )
  expect_length(fit_julia$sdpars[[sd_dpar]], groups)
  expect_equal(
    unname(predict(fit_julia, dpar = sd_dpar)),
    unname(fit_julia$sdpars[[sd_dpar]]),
    tolerance = 1e-10
  )
  expect_equal(
    unname(predict(fit_julia, newdata = dat, dpar = sd_dpar)),
    unname(fit_julia$sdpars[[sd_dpar]])[id_index],
    tolerance = 1e-10
  )
  expect_setequal(names(fit_julia$bridge$dpars), c("mu", "zi"))
  expect_length(sigma(fit_julia), 0L)
})

test_that("Julia bridge fits a ZIP selected mean-slope SD regression", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261025L)
  groups <- 80L
  repeats <- 16L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  z_group <- rep(c(0, 1), each = groups / 2L)
  z <- z_group[id_index]
  x <- stats::rnorm(length(id_index))
  alpha <- c(-0.50, 0.40)
  b <- exp(alpha[[1L]] + alpha[[2L]] * z_group) * stats::rnorm(groups)
  zi <- stats::plogis(rep(-1.5, length(id_index)))
  lambda <- exp(0.35 + 0.25 * x + b[id_index] * x)
  y <- ifelse(stats::runif(length(id_index)) < zi, 0L, stats::rpois(length(id_index), lambda))
  dat <- data.frame(y, x, z, id)
  formula <- bf(y ~ x + (0 + x | id), zi ~ 1,
                sd(id, dpar = "mu", coef = "x") ~ z)
  sd_dpar <- 'sd(id, dpar = "mu", coef = "x")'

  fit_tmb <- drmTMB(
    formula, family = stats::poisson(), data = dat, engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    formula, family = stats::poisson(), data = dat, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_julia, dpar = sd_dpar), c("(Intercept)", "z"))
  expect_gt(coef(fit_julia, dpar = sd_dpar)[["z"]], 0)
  expect_equal(
    unname(coef(fit_julia, dpar = sd_dpar)),
    unname(coef(fit_tmb, dpar = sd_dpar)),
    tolerance = 0.60
  )
  expect_length(fit_julia$sdpars[[sd_dpar]], groups)
  expect_equal(
    unname(predict(fit_julia, dpar = sd_dpar)),
    unname(fit_julia$sdpars[[sd_dpar]]),
    tolerance = 1e-10
  )
  expect_equal(
    unname(predict(fit_julia, newdata = dat, dpar = sd_dpar)),
    unname(fit_julia$sdpars[[sd_dpar]])[id_index],
    tolerance = 1e-10
  )
  expect_length(sigma(fit_julia), 0L)
})
