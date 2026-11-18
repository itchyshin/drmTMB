test_that("zero-inflated NB2 sigma-intercept SD passes through Julia bridge", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261055L)
  groups <- 64L
  repeats <- 30L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[id_index]
  x <- stats::rnorm(length(id_index))
  alpha <- c(`(Intercept)` = -0.75, w = 0.45)
  beta_zi <- -1.1
  tau <- exp(alpha[[1L]] + alpha[[2L]] * w_group)
  b <- tau * stats::rnorm(groups)
  eta_sigma <- -0.55 + b[id_index]
  mu <- exp(0.35 - 0.18 * x)
  y <- stats::rnbinom(length(mu), size = exp(-2 * eta_sigma), mu = mu)
  y[stats::runif(length(y)) < stats::plogis(beta_zi)] <- 0L
  dat <- data.frame(y, x, w, id)
  formula <- bf(
    y ~ x, sigma ~ 1 + (1 | id), zi ~ 1,
    sd(id, dpar = "sigma") ~ w
  )

  fit_tmb <- drmTMB(formula, family = nbinom2(), data = dat, engine = "tmb")
  fit_julia <- drmTMB(formula, family = nbinom2(), data = dat, engine = "julia")
  target <- 'sd(id, dpar = "sigma")'
  tmb_sd <- coef(fit_tmb, dpar = target)
  julia_sd <- coef(fit_julia, dpar = target)
  tmb_zi <- coef(fit_tmb, dpar = "zi")
  julia_zi <- coef(fit_julia, dpar = "zi")
  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(julia_sd, names(tmb_sd))
  expect_named(julia_zi, names(tmb_zi))
  expect_lt(abs(unname(julia_sd[["(Intercept)"]] - alpha[["(Intercept)"]])), 0.5)
  expect_lt(abs(unname(julia_sd[["w"]] - alpha[["w"]])), 0.5)
  expect_lt(abs(unname(julia_zi[["(Intercept)"]] - beta_zi)), 0.5)
  expect_equal(unname(julia_sd), unname(tmb_sd), tolerance = 0.5)
  expect_equal(unname(julia_zi), unname(tmb_zi), tolerance = 0.5)
  expect_equal(
    unname(predict(fit_julia, dpar = target)),
    unname(fit_julia$sdpars[[target]]), tolerance = 1e-10
  )
  julia_sigma <- sigma(fit_julia)
  expect_type(julia_sigma, "double")
  expect_equal(length(julia_sigma), nrow(dat))
})
