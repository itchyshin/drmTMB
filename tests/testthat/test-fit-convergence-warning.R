# Wave 1 honesty guard 1: a fit the optimizer reports as non-converged must not
# look fine. A pure label interprets the nlminb code; the fit path warns when it
# is non-zero; print() surfaces the interpreted code. The warning path is tested
# with a synthetic `opt` list (deterministic) rather than a forced bad fit, whose
# convergence code is optimizer/BLAS-path dependent.

test_that("drm_convergence_label returns NULL for a converged code", {
  expect_null(drm_convergence_label(0L, "relative convergence (4)"))
  expect_null(drm_convergence_label(0L, NULL))
})

test_that("drm_convergence_label interprets a non-zero code with its message", {
  lab <- drm_convergence_label(1L, "false convergence (8)")
  expect_type(lab, "character")
  expect_match(lab, "non-convergence")
  expect_match(lab, "false convergence (8)", fixed = TRUE)
})

test_that("drm_convergence_label is robust to a missing message and NA/empty code", {
  expect_match(drm_convergence_label(1L, NULL), "non-convergence")
  expect_match(drm_convergence_label(1L, ""), "non-convergence")
  expect_null(drm_convergence_label(NA_integer_, "x"))
  expect_null(drm_convergence_label(integer(0), "x"))
})

test_that("drm_warn_if_not_converged is silent on a converged fit and warns otherwise", {
  expect_no_warning(
    drm_warn_if_not_converged(list(
      convergence = 0L,
      message = "relative convergence (4)"
    ))
  )
  expect_warning(
    drm_warn_if_not_converged(list(
      convergence = 1L,
      message = "false convergence (8)"
    )),
    "non-convergence"
  )
})

test_that("a clean Gaussian fit converges and emits no convergence warning", {
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(n, 0, 0.5), x = x)
  fit <- expect_no_warning(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  )
  expect_equal(fit$opt$convergence, 0L)
})

test_that("the convergence verdict uses the Newton step in SE units", {
  set.seed(1)
  n <- 40
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.3 + 0.5 * x + stats::rnorm(n, sd = 0.4), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = stats::gaussian(), data = dat)
  expect_true(is_converged(fit))
  expect_identical(convergence_status(fit), "converged")
  expect_true(is.numeric(fit$gradient))
  expect_true(max(abs(fit$gradient)) <= drmTMB:::DRM_NEWTON_GRAD_TOL)
  stationary <- drm_gradient_stationarity(fit$gradient, fit$sdr$cov.fixed)
  expect_identical(stationary$scale, "se")
  expect_lt(stationary$measure, drmTMB:::DRM_GRADIENT_STEP_TOL)

  # A raw gradient of 1e-3 is above the polish target. On this fit the
  # matching Newton step is about 1e-3 times a sub-unit standard error, so
  # the scale-free rule still calls the fit converged.
  quiet <- numeric(length(fit$gradient))
  names(quiet) <- names(fit$gradient)
  quiet[1L] <- 1e-3
  fit$gradient <- quiet
  quiet_step <- drm_gradient_stationarity(fit$gradient, fit$sdr$cov.fixed)
  expect_identical(quiet_step$scale, "se")
  expect_lt(quiet_step$measure, drmTMB:::DRM_GRADIENT_STEP_TOL)
  expect_gt(max(abs(fit$gradient)), drmTMB:::DRM_NEWTON_GRAD_TOL)
  expect_true(is_converged(fit))
  expect_identical(convergence_status(fit), "converged")

  fit$gradient[1L] <- 10
  expect_false(is_converged(fit))
  expect_identical(convergence_status(fit), "gradient")
  row <- check_convergence_status(fit)
  expect_identical(row$status, "warning")
  expect_match(row$value, "gradient", fixed = TRUE)

  # No Hessian (`se = FALSE`): absolute 1e-3, not the polish target of 1e-8.
  # A missing `sdr` while standard errors were requested is `"degenerate"`
  # before this fallback runs.
  fit$control$se <- FALSE
  fit$sdr <- NULL
  fit$gradient <- c(beta_mu = 1e-4)
  expect_true(is_converged(fit))
  expect_identical(convergence_status(fit), "converged")
  fit$gradient <- c(beta_mu = 0.014)
  expect_false(is_converged(fit))
  expect_identical(convergence_status(fit), "gradient")

  fit$gradient <- NULL
  expect_true(is_converged(fit))
  expect_identical(convergence_status(fit), "converged")

  fit$gradient <- NA_real_
  expect_false(is_converged(fit))
  expect_identical(convergence_status(fit), "gradient")
})

test_that("scale changes that inflate the raw gradient stay converged", {
  set.seed(1)
  n <- 40
  x <- stats::rnorm(n)
  y <- 0.3 + 0.5 * x + stats::rnorm(n, sd = 0.4)
  rescaled <- data.frame(y = y, x = 1000 * x)
  fit_rescaled <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = stats::gaussian(),
    data = rescaled
  )
  expect_true(is_converged(fit_rescaled))
  expect_identical(convergence_status(fit_rescaled), "converged")
  expect_identical(
    drm_gradient_stationarity(
      fit_rescaled$gradient,
      fit_rescaled$sdr$cov.fixed
    )$scale,
    "se"
  )

  year <- 1990:2029
  y_year <- 1 + 0.02 * (year - 2000) + stats::rnorm(length(year), sd = 0.3)
  fit_year <- drmTMB(
    bf(y ~ year, sigma ~ 1),
    family = stats::gaussian(),
    data = data.frame(y = y_year, year = year)
  )
  expect_true(is_converged(fit_year))
  expect_identical(convergence_status(fit_year), "converged")

  unpolished <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = stats::gaussian(),
    data = data.frame(y = y, x = x),
    control = drm_control(newton_polish = FALSE)
  )
  expect_equal(unpolished$opt$convergence, 0L)
  expect_true(is_converged(unpolished))
  expect_identical(convergence_status(unpolished), "converged")
})

test_that("an iteration cap that misses the optimum is not converged", {
  set.seed(1)
  n <- 40
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.3 + 0.5 * x + stats::rnorm(n, sd = 0.4), x = x)
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = stats::gaussian(),
    data = dat,
    control = drm_control(
      optimizer = list(iter.max = 2L, eval.max = 2L),
      newton_polish = FALSE,
      start = list(
        "fixef:mu:(Intercept)" = 40,
        "fixef:mu:x" = 40,
        "fixef:sigma:(Intercept)" = 4
      )
    )
  ))
  expect_false(is_converged(fit))
  expect_true(convergence_status(fit) %in% c("gradient", "degenerate"))
})

test_that("a non-stationary stored gradient warns and names the component", {
  expect_no_warning(
    drm_warn_if_gradient_not_stationary(
      c(beta_mu = 1e-12),
      "beta_mu",
      newton_polish = TRUE
    )
  )
  expect_warning(
    drm_warn_if_gradient_not_stationary(
      c(beta_sigma = 0.014),
      "beta_sigma",
      newton_polish = TRUE
    ),
    "beta_sigma",
    class = "drmTMB_gradient_warning"
  )
  expect_warning(
    drm_warn_if_gradient_not_stationary(NA_real_, NA_character_, newton_polish = TRUE),
    "not finite",
    class = "drmTMB_gradient_warning"
  )
})

test_that("drm_warn_if_nonfinite_objective is silent on a finite objective and warns otherwise", {
  expect_no_warning(drm_warn_if_nonfinite_objective(list(objective = -123.4)))
  expect_warning(
    drm_warn_if_nonfinite_objective(list(objective = NaN)),
    "not finite"
  )
  expect_warning(
    drm_warn_if_nonfinite_objective(list(objective = Inf)),
    "not finite"
  )
})
