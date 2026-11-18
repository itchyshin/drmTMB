test_that("Student Julia bridge admits only matching scalar SD routes", {
  slope <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, dpar = "mu", coef = "x") ~ z
  )
  expect_true(drm_julia_student_scalar_sd_route_admitted(slope))
  expect_no_error(drm_julia_refuse_fe_only_random_effects(slope, "student"))

  intercept <- bf(
    y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ z
  )
  expect_true(drm_julia_student_scalar_sd_route_admitted(intercept))

  no_sd <- bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1)
  expect_false(drm_julia_student_scalar_sd_route_admitted(no_sd))
  expect_error(
    drm_julia_refuse_fe_only_random_effects(no_sd, "student"),
    "fixed-effect"
  )

  random_sigma <- bf(
    y ~ x + (1 | id), sigma ~ (1 | id), nu ~ 1, sd(id) ~ z
  )
  expect_false(drm_julia_student_scalar_sd_route_admitted(random_sigma))
  correlated <- bf(
    y ~ x + (1 + x | id), sigma ~ 1, nu ~ 1, sd(id) ~ z
  )
  expect_false(drm_julia_student_scalar_sd_route_admitted(correlated))
  wrong_target <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(other, coef = "x") ~ z
  )
  expect_false(drm_julia_student_scalar_sd_route_admitted(wrong_target))
  multiple <- bf(
    y ~ x + (1 | id), sigma ~ 1, nu ~ 1,
    sd(id, coef = "(Intercept)") ~ z,
    sd(id, coef = "(Intercept)", block = "other") ~ z
  )
  expect_false(drm_julia_student_scalar_sd_route_admitted(multiple))
})

test_that("Student SD payload labels use Julia's canonical sd block", {
  dat <- data.frame(
    y = c(0.2, 0.4, 0.7, 0.8),
    x = c(-1, 1, -0.5, 0.5),
    z = rep(c(-1, 1), each = 2),
    id = factor(rep(1:2, each = 2))
  )
  intercept <- bf(
    y ~ x + (1 | id), sigma ~ 1, nu ~ 1,
    sd(id) ~ z
  )
  slope <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, dpar = "mu", coef = "x") ~ z
  )

  intercept_labels <- drm_julia_bridge_payload_coef_labels(
    intercept, dat, parent.frame(), family_type = "student"
  )
  slope_labels <- drm_julia_bridge_payload_coef_labels(
    slope, dat, parent.frame(), family_type = "student"
  )

  expect_identical(intercept_labels[["sd"]], c("(Intercept)", "z"))
  expect_identical(slope_labels[["sd"]], c("(Intercept)", "z"))
})

test_that("Student independent-slope SD regression agrees across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(202610186)
  groups <- 80L
  repeats <- 16L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[id_index]
  x <- rnorm(length(id_index))
  alpha <- c("(Intercept)" = -0.65, z = 0.45)
  slope <- exp(alpha[["(Intercept)"]] + alpha[["z"]] * z_group) *
    rnorm(groups)
  y <- 0.4 + 0.3 * x + slope[id_index] * x + 0.6 * stats::rt(length(id), df = 8)
  dat <- data.frame(y, x, z, id)
  target <- 'sd(id, dpar = "mu", coef = "x")'
  formula <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, dpar = "mu", coef = "x") ~ z
  )

  fit_tmb <- drmTMB(
    formula, family = student(), data = dat, engine = "tmb"
  )
  fit_julia <- drmTMB(
    formula, family = student(), data = dat, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_sd <- coef(fit_tmb, dpar = target)
  julia_sd <- coef(fit_julia, dpar = target)
  expect_named(tmb_sd, c("(Intercept)", "z"))
  expect_named(julia_sd, names(tmb_sd))
  expect_lt(abs(unname(tmb_sd[["z"]] - alpha[["z"]])), 0.45)
  expect_lt(abs(unname(julia_sd[["z"]] - alpha[["z"]])), 0.45)
  expect_equal(unname(julia_sd), unname(tmb_sd), tolerance = 0.30)

  expect_length(fit_tmb$sdpars[[target]], groups)
  expect_length(fit_julia$sdpars[[target]], groups)
  expect_equal(
    unname(fit_julia$sdpars[[target]]),
    unname(predict(fit_julia, dpar = target)),
    tolerance = 1e-10
  )
  row_sd <- predict(fit_julia, newdata = dat[c(4L, 1L, 8L, 2L), ], dpar = target)
  expect_equal(
    unname(row_sd),
    unname(fit_julia$sdpars[[target]])[id_index[c(4L, 1L, 8L, 2L)]],
    tolerance = 1e-10
  )
  expect_setequal(names(fit_julia$bridge$dpars), c("mu", "sigma", "nu"))

  save_path <- tempfile(fileext = ".rds")
  saveRDS(fit_julia, save_path)
  restored <- readRDS(save_path)
  expect_equal(restored$sdpars[[target]], fit_julia$sdpars[[target]])
  expect_equal(predict(restored, dpar = target), predict(fit_julia, dpar = target))
  unlink(save_path)
})

test_that("Student random-intercept SD regression passes through the Julia bridge", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(202610188)
  groups <- 60L
  repeats <- 16L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[id_index]
  alpha <- c("(Intercept)" = -0.65, z = 0.45)
  intercept <- exp(alpha[["(Intercept)"]] + alpha[["z"]] * z_group) *
    rnorm(groups)
  y <- 0.4 + intercept[id_index] + 0.6 * stats::rt(length(id), df = 8)
  dat <- data.frame(y, z, id)
  formula <- bf(y ~ 1 + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ z)

  fit_tmb <- drmTMB(
    formula, family = student(), data = dat, engine = "tmb"
  )
  fit_julia <- drmTMB(
    formula, family = student(), data = dat, engine = "julia"
  )
  tmb_sd <- coef(fit_tmb, dpar = "sd(id)")
  julia_sd <- coef(fit_julia, dpar = "sd(id)")

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(tmb_sd, c("(Intercept)", "z"))
  expect_named(julia_sd, names(tmb_sd))
  expect_lt(abs(unname(tmb_sd[["z"]] - alpha[["z"]])), 0.45)
  expect_lt(abs(unname(julia_sd[["z"]] - alpha[["z"]])), 0.45)
  expect_equal(unname(julia_sd), unname(tmb_sd), tolerance = 0.30)
  expect_equal(
    unname(fit_julia$sdpars[["sd(id)"]]),
    unname(predict(fit_julia, dpar = "sd(id)")),
    tolerance = 1e-10
  )
  expect_equal(
    unname(predict(fit_julia, newdata = dat[c(2L, 8L, 1L, 5L), ], dpar = "sd(id)")),
    unname(fit_julia$sdpars[["sd(id)"]])[id_index[c(2L, 8L, 1L, 5L)]],
    tolerance = 1e-10
  )
})
