test_that("NB2 sigma SD bridge admits only its matching scalar routes", {
  dat <- data.frame(
    y = c(0, 1, 2, 3), x = c(-1, 1, -0.5, 0.5),
    w = rep(c(-1, 1), each = 2), id = factor(rep(1:2, each = 2))
  )
  intercept <- bf(
    y ~ x, sigma ~ 1 + (1 | id),
    sd(id, dpar = "sigma") ~ w
  )
  slope <- bf(
    y ~ x, sigma ~ 1 + (0 + x | id),
    sd(id, dpar = "sigma", coef = "x") ~ w
  )
  expect_true(drm_julia_negbin2_sigma_sd_route_admitted(intercept, dat))
  expect_true(drm_julia_negbin2_sigma_sd_route_admitted(slope, dat))

  wrong_target <- bf(
    y ~ x, sigma ~ 1 + (0 + x | id),
    sd(id, dpar = "mu", coef = "x") ~ w
  )
  random_mu <- bf(
    y ~ x + (1 | id), sigma ~ 1 + (1 | id),
    sd(id, dpar = "sigma") ~ w
  )
  expect_false(drm_julia_negbin2_sigma_sd_route_admitted(wrong_target, dat))
  expect_false(drm_julia_negbin2_sigma_sd_route_admitted(random_mu, dat))

  labels <- drm_julia_bridge_payload_coef_labels(
    slope, dat, parent.frame(), family_type = "nbinom2"
  )
  expect_identical(labels[["sd"]], c("(Intercept)", "w"))
})

nbinom2_sigma_sd_bridge_fixture <- function(slope = FALSE, seed = 20261035L) {
  set.seed(seed + as.integer(slope))
  groups <- if (slope) 180L else 240L
  repeats <- if (slope) 36L else 40L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[id_index]
  x <- stats::rnorm(length(id_index))
  z <- stats::rnorm(length(id_index))
  alpha <- if (slope) c(`(Intercept)` = log(0.45), w = 0.35) else
    c(`(Intercept)` = log(0.55), w = 0.4)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * w_group)
  loading <- if (slope) z else rep(1, length(x))
  b <- tau * stats::rnorm(groups)
  eta_sigma <- (if (slope) -0.55 else -0.6) + loading * b[id_index]
  mu <- exp(0.5 - 0.18 * x)
  y <- stats::rnbinom(length(mu), size = exp(-2 * eta_sigma), mu = mu)
  list(data = data.frame(y, x, z, w, id), alpha = alpha, slope = slope)
}

test_that("NB2 sigma intercept and slope SDs pass through the Julia bridge", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (slope in c(FALSE, TRUE)) {
    sim <- nbinom2_sigma_sd_bridge_fixture(slope = slope)
    sd_formula <- if (slope) {
      quote(sd(id, dpar = "sigma", coef = "z") ~ w)
    } else {
      quote(sd(id, dpar = "sigma") ~ w)
    }
    sigma_formula <- if (slope) quote(sigma ~ 1 + (0 + z | id)) else
      quote(sigma ~ 1 + (1 | id))
    formula <- eval(substitute(
      bf(y ~ x, SIGMA, SD), list(SIGMA = sigma_formula, SD = sd_formula)
    ), envir = environment())
    fit_tmb <- drmTMB(formula, family = nbinom2(), data = sim$data, engine = "tmb")
    fit_julia <- drmTMB(formula, family = nbinom2(), data = sim$data, engine = "julia")
    target <- if (slope) {
      'sd(id, dpar = "sigma", coef = "z")'
    } else {
      'sd(id, dpar = "sigma")'
    }
    tmb_sd <- coef(fit_tmb, dpar = target)
    julia_sd <- coef(fit_julia, dpar = target)
    expect_true(is_converged(fit_tmb))
    expect_true(is_converged(fit_julia))
    expect_named(julia_sd, names(tmb_sd))
    expect_lt(abs(unname(julia_sd[["w"]] - sim$alpha[["w"]])), 0.45)
    expect_equal(unname(julia_sd), unname(tmb_sd), tolerance = 0.4)
    expect_equal(
      unname(predict(fit_julia, dpar = target)),
      unname(fit_julia$sdpars[[target]]), tolerance = 1e-10
    )
    expect_equal(length(sigma(fit_julia)), nrow(sim$data))
  }
})

