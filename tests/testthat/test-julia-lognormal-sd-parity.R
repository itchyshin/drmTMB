test_that("LogNormal random-intercept SD outputs agree across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261022L)
  groups <- 36L
  repeats <- 12L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(paste0("group_", id_index))
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[id_index]
  x <- stats::rnorm(length(id_index))
  alpha <- c(`(Intercept)` = log(0.65), z = 0.35)
  random_intercept <- exp(alpha[[1L]] + alpha[[2L]] * z_group) *
    stats::rnorm(groups)
  eta <- 0.25 - 0.35 * x + random_intercept[id_index]
  y <- stats::rlnorm(length(id_index), meanlog = eta, sdlog = 0.4)
  dat <- data.frame(y, x, z, id)
  formula <- bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z)

  fit_tmb <- drmTMB(
    formula, family = lognormal(), data = dat, engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    formula, family = lognormal(), data = dat, engine = "julia"
  )
  dpar <- "sd(id)"

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_tmb, dpar), names(alpha))
  expect_named(coef(fit_julia, dpar), names(alpha))
  expect_gt(coef(fit_tmb, dpar)[["z"]], 0)
  expect_gt(coef(fit_julia, dpar)[["z"]], 0)
  expect_equal(unname(coef(fit_julia, dpar)),
               unname(coef(fit_tmb, dpar)), tolerance = 1e-4)

  expect_length(fit_tmb$sdpars[[dpar]], groups)
  expect_length(fit_julia$sdpars[[dpar]], groups)
  julia_group_sd <- predict(fit_julia, dpar = dpar)
  tmb_group_sd <- predict(fit_tmb, dpar = dpar)
  prefix <- paste0(dpar, ":")
  expect_true(all(startsWith(names(julia_group_sd), prefix)))
  julia_group_labels <- substring(names(julia_group_sd), nchar(prefix) + 1L)
  names(julia_group_sd) <- julia_group_labels
  expect_setequal(names(julia_group_sd), names(tmb_group_sd))
  expect_equal(
    unname(julia_group_sd[names(tmb_group_sd)]),
    unname(tmb_group_sd), tolerance = 1e-4
  )
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 1e-3)
  julia_row_sd <- predict(fit_julia, newdata = dat, dpar = dpar)
  tmb_row_sd <- predict(fit_tmb, newdata = dat, dpar = dpar)
  expect_equal(unname(julia_row_sd),
               unname(fit_julia$sdpars[[dpar]])[id_index], tolerance = 1e-10)
  expect_equal(unname(julia_row_sd), unname(tmb_row_sd), tolerance = 1e-4)

  path <- tempfile(fileext = ".rds")
  saveRDS(fit_julia, path)
  restored <- readRDS(path)
  expect_equal(coef(restored, dpar), coef(fit_julia, dpar))
  expect_equal(predict(restored, newdata = dat, dpar = dpar), julia_row_sd)
})

test_that("LogNormal random-slope SD outputs agree across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(202610221L)
  groups <- 48L
  repeats <- 8L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(paste0("group_", id_index))
  z_group <- seq(-1, 1, length.out = groups)
  z <- z_group[id_index]
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  alpha <- c(`(Intercept)` = log(0.55), z = 0.35)
  random_slope <- exp(alpha[[1L]] + alpha[[2L]] * z_group) *
    stats::rnorm(groups)
  eta <- 0.2 + 0.45 * x + x * random_slope[id_index]
  y <- stats::rlnorm(length(id_index), meanlog = eta, sdlog = 0.4)
  dat <- data.frame(y, x, z, id)
  formula <- bf(
    y ~ x + (0 + x | id), sigma ~ 1,
    sd(id, coef = "x") ~ z
  )
  dpar <- 'sd(id, coef = "x")'

  fit_tmb <- drmTMB(
    formula, family = lognormal(), data = dat, engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    formula, family = lognormal(), data = dat, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_sd <- coef(fit_tmb, dpar = dpar)
  julia_sd <- coef(fit_julia, dpar = dpar)
  expect_named(tmb_sd, names(alpha))
  expect_named(julia_sd, names(alpha))
  expect_gt(tmb_sd[["z"]], 0)
  expect_gt(julia_sd[["z"]], 0)
  expect_lt(abs(tmb_sd[["z"]] - alpha[["z"]]), 0.25)
  expect_equal(unname(julia_sd), unname(tmb_sd), tolerance = 1e-4)
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 1e-3)

  expect_length(fit_tmb$sdpars[[dpar]], groups)
  expect_length(fit_julia$sdpars[[dpar]], groups)
  julia_group_sd <- predict(fit_julia, dpar = dpar)
  tmb_group_sd <- predict(fit_tmb, dpar = dpar)
  prefix <- paste0(dpar, ":")
  expect_true(all(startsWith(names(julia_group_sd), prefix)))
  julia_group_labels <- substring(names(julia_group_sd), nchar(prefix) + 1L)
  names(julia_group_sd) <- julia_group_labels
  expect_setequal(names(julia_group_sd), names(tmb_group_sd))
  expect_equal(unname(julia_group_sd[names(tmb_group_sd)]),
               unname(tmb_group_sd), tolerance = 1e-4)
  julia_row_sd <- predict(fit_julia, newdata = dat, dpar = dpar)
  tmb_row_sd <- predict(fit_tmb, newdata = dat, dpar = dpar)
  expect_equal(unname(julia_row_sd), unname(tmb_row_sd), tolerance = 1e-4)
})
