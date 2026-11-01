test_that("Poisson SD regression applies the fixed offset once in both engines", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261023L)
  groups <- 32L
  repeats <- 20L
  id_index <- rep(seq_len(groups), each = repeats)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[id_index]
  id <- factor(id_index)
  x <- stats::rnorm(length(id_index))
  exposure <- stats::runif(length(id_index), min = 0.4, max = 2.2)
  alpha <- c(`(Intercept)` = -0.4, z = 0.45)
  b <- exp(alpha[[1L]] + alpha[[2L]] * z_group) * stats::rnorm(groups)
  y <- stats::rpois(
    length(id_index),
    exposure * exp(0.3 + 0.25 * x + b[id_index])
  )
  dat <- data.frame(y, x, z, exposure, id)
  formula <- bf(
    y ~ x + offset(log(exposure)) + (1 | id),
    sd(id, coef = "(Intercept)") ~ z
  )

  fit_tmb <- drmTMB(
    formula,
    family = stats::poisson(),
    data = dat,
    engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    formula,
    family = stats::poisson(),
    data = dat,
    engine = "julia"
  )

  sd_dpar <- grep("^sd\\(", names(fit_tmb$coefficients), value = TRUE)
  expect_length(sd_dpar, 1L)
  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_equal(
    unname(coef(fit_julia, dpar = sd_dpar)),
    unname(coef(fit_tmb, dpar = sd_dpar)),
    tolerance = 1e-3
  )
  expect_equal(
    as.numeric(logLik(fit_julia)),
    as.numeric(logLik(fit_tmb)),
    tolerance = 1e-3
  )
  expect_equal(
    unname(predict(fit_julia, newdata = dat)),
    unname(predict(fit_tmb, newdata = dat)),
    tolerance = 1e-3
  )
})
