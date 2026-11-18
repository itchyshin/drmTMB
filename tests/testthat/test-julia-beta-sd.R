test_that("Julia Beta SD payload labels use the canonical engine block", {
  data <- data.frame(
    y = c(0.2, 0.4, 0.6, 0.8),
    x = c(-1, 1, -1, 1),
    z = rep(c(-1, 1), each = 2L),
    id = factor(rep(c("a", "b"), each = 2L))
  )
  intercept <- bf(
    y ~ x + (1 | id), sigma ~ 1,
    sd(id, coef = "(Intercept)") ~ z
  )
  slope <- bf(
    y ~ x + (0 + x | id), sigma ~ 1,
    sd(id, coef = "x") ~ z
  )

  for (formula in list(intercept, slope)) {
    labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
      formula, data = data, env = environment(), family_type = "beta"
    )
    expect_true("sd" %in% names(labels))
    expect_false(any(grepl("^sdtarget_", names(labels))))
    expect_identical(labels[["sd"]], c("(Intercept)", "z"))
  }
})

test_that("public Julia Beta SD outputs retain the fitted group target", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(1819)
  groups <- 40L
  repeats <- 18L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[id_index]
  x <- rnorm(length(id_index))
  sd_group <- exp(-0.55 + 0.35 * z_group)
  b <- sd_group * rnorm(groups)
  mu <- plogis(0.25 + 0.2 * x + b[id_index])
  precision <- 1 / 0.32^2
  y <- stats::rbeta(length(id_index), mu * precision, (1 - mu) * precision)
  dat <- data.frame(y, x, z, id)
  formula <- bf(y ~ x + (1 | id), sigma ~ 1,
                sd(id, coef = "(Intercept)") ~ z)

  fit_tmb <- drmTMB(formula, family = beta_family(), data = dat, engine = "tmb")
  fit_julia <- drmTMB(formula, family = beta_family(), data = dat, engine = "julia")
  sd_dpar <- grep("^sd\\(", names(fit_tmb$coefficients), value = TRUE)
  expect_length(sd_dpar, 1L)

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_julia, dpar = sd_dpar), c("(Intercept)", "z"))
  expect_gt(coef(fit_julia, dpar = sd_dpar)[['z']], 0)
  expect_equal(unname(coef(fit_julia, dpar = sd_dpar)),
               unname(coef(fit_tmb, dpar = sd_dpar)), tolerance = 0.2)
  expect_length(fit_julia$sdpars[[sd_dpar]], groups)
  expect_true(all(is.finite(fit_julia$sdpars[[sd_dpar]])))
  # The public prediction and stored fit component use different name
  # prefixes; this check is about their group-aligned numerical values.
  expect_equal(unname(predict(fit_julia, dpar = sd_dpar)),
               unname(fit_julia$sdpars[[sd_dpar]]), tolerance = 1e-10)
  row_sd <- predict(fit_julia, newdata = dat, dpar = sd_dpar)
  expect_length(row_sd, nrow(dat))
  expect_equal(unname(row_sd),
               unname(fit_julia$sdpars[[sd_dpar]])[id_index],
               tolerance = 1e-10)

  path <- tempfile(fileext = ".rds")
  saveRDS(fit_julia, path)
  restored <- readRDS(path)
  expect_equal(restored$sdpars[[sd_dpar]], fit_julia$sdpars[[sd_dpar]])
})

test_that("live Julia Beta random-slope SD estimates match native TMB", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261030L)
  groups <- 48L
  repeats <- 22L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[id_index]
  x <- stats::rnorm(length(id_index))
  alpha <- c(`(Intercept)` = log(0.55), z = 0.4)
  slope_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  slope <- slope_sd * stats::rnorm(groups)
  mu <- stats::plogis(0.15 + 0.3 * x + slope[id_index] * x)
  precision <- 1 / 0.32^2
  dat <- data.frame(
    y = stats::rbeta(length(mu), mu * precision, (1 - mu) * precision),
    x = x, z = z, id = id
  )
  formula <- bf(y ~ x + (0 + x | id), sigma ~ 1,
                sd(id, coef = "x") ~ z)

  fit_tmb <- drmTMB(
    formula, family = beta_family(), data = dat, engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(formula, family = beta_family(), data = dat,
                      engine = "julia")
  sd_dpar <- 'sd(id, coef = "x")'

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_tmb, dpar = sd_dpar), names(alpha))
  expect_named(coef(fit_julia, dpar = sd_dpar), names(alpha))
  expect_gt(coef(fit_tmb, dpar = sd_dpar)[["z"]], 0)
  expect_gt(coef(fit_julia, dpar = sd_dpar)[["z"]], 0)
  expect_equal(unname(coef(fit_julia, dpar = sd_dpar)),
               unname(coef(fit_tmb, dpar = sd_dpar)), tolerance = 0.25)
  expect_equal(unname(predict(fit_julia, dpar = sd_dpar)),
               unname(predict(fit_tmb, dpar = sd_dpar)), tolerance = 0.25)
})
