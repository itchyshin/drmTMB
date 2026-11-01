test_that("Gaussian ordinary random-intercept SD agrees across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(202610241)
  groups <- 80L
  repeats <- 12L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[id_index]
  alpha <- c("(Intercept)" = -0.55, z = 0.4)
  b <- exp(alpha[["(Intercept)"]] + alpha[["z"]] * z_group) *
    stats::rnorm(groups)
  y <- 0.35 + b[id_index] + 0.45 * stats::rnorm(length(id_index))
  dat <- data.frame(y, z, id)
  form <- bf(y ~ 1 + (1 | id), sigma ~ 1, sd(id) ~ z)

  fit_tmb <- drmTMB(form, family = gaussian(), data = dat, engine = "tmb")
  fit_julia <- drmTMB(form, family = gaussian(), data = dat, engine = "julia")

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_sd <- coef(fit_tmb, dpar = "sd(id)")
  julia_sd <- coef(fit_julia, dpar = "sd(id)")
  expect_named(tmb_sd, c("(Intercept)", "z"))
  expect_named(julia_sd, names(tmb_sd))
  expect_lt(abs(unname(tmb_sd["z"] - alpha["z"])), 0.4)
  expect_lt(abs(unname(julia_sd["z"] - alpha["z"])), 0.4)
  expect_equal(unname(julia_sd), unname(tmb_sd), tolerance = 0.15)
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 0.05)

  expect_length(fit_tmb$sdpars[["sd(id)"]], groups)
  expect_length(fit_julia$sdpars[["sd(id)"]], groups)
  expect_equal(
    unname(predict(fit_tmb, dpar = "sd(id)")),
    unname(fit_tmb$sdpars[["sd(id)"]]),
    tolerance = 1e-10
  )
  expect_equal(
    unname(predict(fit_julia, dpar = "sd(id)")),
    unname(fit_julia$sdpars[["sd(id)"]]),
    tolerance = 1e-10
  )
  expect_equal(
    unname(fit_julia$sdpars[["sd(id)"]]),
    unname(fit_tmb$sdpars[["sd(id)"]]),
    tolerance = 0.15
  )
  rows <- c(4L, 1L, 8L, 2L)
  expect_equal(
    unname(predict(fit_julia, newdata = dat[rows, ], dpar = "sd(id)")),
    unname(fit_julia$sdpars[["sd(id)"]])[id_index[rows]],
    tolerance = 1e-10
  )
})

test_that("Gaussian independent random-slope SD agrees across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261024L)
  n_group <- 120L
  n_repeat <- 12L
  id_index <- rep(seq_len(n_group), each = n_repeat)
  x_within <- rep(seq(-1.5, 1.5, length.out = n_repeat), n_group)
  w_group <- seq(-1, 1, length.out = n_group)
  w <- w_group[id_index]
  alpha <- c(`(Intercept)` = log(0.5), w = 0.5)
  slope_sd <- exp(alpha[[1L]] + alpha[[2L]] * w_group)
  random_slope <- slope_sd * stats::rnorm(n_group)
  y <- 0.2 + 0.35 * x_within + random_slope[id_index] * x_within +
    0.4 * stats::rnorm(length(id_index))
  dat <- data.frame(y, x = x_within, w, id = factor(id_index))
  form <- bf(
    y ~ x + (0 + x | id),
    sigma ~ 1,
    sd(id, coef = "x") ~ w
  )

  fit_tmb <- drmTMB(form, family = stats::gaussian(), data = dat, engine = "tmb")
  fit_julia <- drmTMB(form, family = stats::gaussian(), data = dat, engine = "julia")
  target <- 'sd(id, coef = "x")'
  tmb_sd <- coef(fit_tmb, dpar = target)
  julia_sd <- coef(fit_julia, dpar = target)

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(tmb_sd, c("(Intercept)", "w"))
  expect_named(julia_sd, names(tmb_sd))
  expect_lt(abs(unname(tmb_sd[["w"]] - alpha[["w"]])), 0.4)
  expect_equal(unname(julia_sd), unname(tmb_sd), tolerance = 0.15)
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 0.05)
  expect_equal(
    unname(predict(fit_julia, dpar = target)),
    unname(predict(fit_tmb, dpar = target)),
    tolerance = 0.15
  )
})
