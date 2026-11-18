test_that("Gamma sigma SD regression passes through the Julia bridge", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261025L)
  groups <- 64L
  repeats <- 18L
  group_w <- rep(c(-1, 1), each = groups / 2L)
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  w <- group_w[id_index]
  x <- stats::rnorm(length(id))
  tau <- exp(-1.15 + 0.35 * group_w)
  b <- stats::rnorm(groups, sd = tau)
  sigma_i <- exp(-0.55 + b[id_index])
  mu <- exp(0.2 + 0.25 * x)
  y <- stats::rgamma(length(id), shape = 1 / sigma_i^2,
                     scale = mu * sigma_i^2)
  dat <- data.frame(y, x, w, id)
  formula <- bf(
    y ~ x,
    sigma ~ 1 + (1 | id),
    sd(id, dpar = "sigma") ~ w
  )
  target <- 'sd(id, dpar = "sigma")'

  expect_true(drm_julia_gamma_sigma_sd_route_admitted(formula))
  expect_false(drm_julia_gamma_sigma_sd_route_admitted(bf(
    y ~ x, sigma ~ 1 + (1 | id), sd(other, dpar = "sigma") ~ w
  )))
  expect_false(drm_julia_gamma_sigma_sd_route_admitted(bf(
    y ~ x, sigma ~ 1 + (0 + x | id), sd(id, dpar = "sigma") ~ w
  )))
  expect_false(drm_julia_gamma_sigma_sd_route_admitted(bf(
    y ~ 1 + (1 | id), sigma ~ 1 + (1 | id),
    sd(id, dpar = "sigma") ~ w
  )))

  labels <- drm_julia_bridge_payload_coef_labels(
    formula, dat, environment(), family_type = "gamma"
  )
  expect_setequal(names(labels), c("mu", "sigma", "sd"))

  fit_tmb <- drmTMB(
    formula, family = Gamma(link = "log"), data = dat, engine = "tmb"
  )
  fit <- drmTMB(
    formula, family = Gamma(link = "log"), data = dat, engine = "julia"
  )
  expect_true(is_converged(fit))
  expect_named(coef(fit, dpar = target), c("(Intercept)", "w"))
  expect_gt(coef(fit, dpar = target)[["w"]], 0)
  expect_equal(unname(coef(fit, dpar = target)),
               unname(coef(fit_tmb, dpar = target)), tolerance = 0.35)
  expect_equal(length(fit$sdpars[[target]]), groups)
  expect_equal(
    unname(predict(fit, newdata = dat, dpar = target)),
    unname(fit$sdpars[[target]])[id_index],
    tolerance = 1e-10
  )
  expect_true(all(is.finite(sigma(fit))))
})

test_that("Gamma sigma slope SD bridge admits only its selected coefficient", {
  formula <- bf(
    y ~ x,
    sigma ~ 1 + (0 + x | id),
    sd(id, dpar = "sigma", coef = "x") ~ w
  )
  expect_true(drm_julia_gamma_sigma_sd_route_admitted(formula))
  expect_identical(
    drm_julia_formula_lhs(formula$entries[[3L]]),
    "sd(id, sigma, coef(x))"
  )
  expect_false(drm_julia_gamma_sigma_sd_route_admitted(bf(
    y ~ x, sigma ~ 1 + (0 + x | id),
    sd(id, dpar = "sigma", coef = "other") ~ w
  )))
  expect_false(drm_julia_gamma_sigma_sd_route_admitted(bf(
    y ~ x, sigma ~ 1 + (0 + x | id),
    sd(other, dpar = "sigma", coef = "x") ~ w
  )))
})

test_that("Gamma sigma slope SD regression passes through the Julia bridge", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261028L)
  groups <- 120L
  repeats <- 18L
  group_w <- seq(-1, 1, length.out = groups)
  tau <- exp(log(0.18) + 0.30 * group_w)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- stats::rnorm(length(id))
  b <- stats::rnorm(groups, sd = tau)
  mu <- exp(0.2 + 0.2 * x)
  sigma_i <- exp(-0.5 + x * b[as.integer(id)])
  dat <- data.frame(
    y = stats::rgamma(length(id), shape = 1 / sigma_i^2,
                      scale = mu * sigma_i^2),
    x = x,
    w = group_w[as.integer(id)],
    id = id
  )
  formula <- bf(
    y ~ x,
    sigma ~ 1 + (0 + x | id),
    sd(id, dpar = "sigma", coef = "x") ~ w
  )
  target <- 'sd(id, dpar = "sigma", coef = "x")'
  expect_true(drm_julia_gamma_sigma_sd_route_admitted(formula, data = dat))
  labels <- drm_julia_bridge_payload_coef_labels(
    formula, dat, environment(), family_type = "gamma"
  )
  expect_setequal(names(labels), c("mu", "sigma", "sd"))

  fit_tmb <- drmTMB(
    formula, family = Gamma(link = "log"), data = dat, engine = "tmb"
  )
  fit <- drmTMB(
    formula, family = Gamma(link = "log"), data = dat, engine = "julia"
  )
  expect_true(is_converged(fit))
  estimate <- coef(fit, dpar = target)
  expect_named(estimate, c("(Intercept)", "w"))
  expect_gt(estimate[["w"]], 0)
  expect_equal(unname(estimate),
               unname(coef(fit_tmb, dpar = target)), tolerance = 0.35)
  expect_equal(length(fit$sdpars[[target]]), groups)
  pred_julia <- predict(fit, newdata = dat, dpar = target)
  pred_tmb <- predict(fit_tmb, newdata = dat, dpar = target)
  expect_equal(unname(pred_julia), unname(pred_tmb), tolerance = 0.20)
  expect_true(all(is.finite(sigma(fit))))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  reloaded <- readRDS(path)
  expect_equal(predict(reloaded, newdata = dat, dpar = target), pred_julia)
})
