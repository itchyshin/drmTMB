# Approved 26 Nov 2026: classify silent bad fits (#1857, #1875); warn on
# logLik/AIC/BIC and confint infinite endpoints without changing twin thresholds.

test_that("student() all-zero with se = FALSE is degenerate (#1875)", {
  dat <- data.frame(y = rep(0, 15))
  fit <- suppressWarnings(
    drmTMB(
      bf(y ~ 1),
      family = student(),
      data = dat,
      control = drm_control(se = FALSE, parallel = "none")
    )
  )
  expect_false(is_converged(fit))
  expect_identical(convergence_status(fit), "degenerate")
})

test_that("tweedie all-zero warns on logLik and AIC but values stay finite (#1857)", {
  dat <- data.frame(y = rep(0, 15))
  fit <- suppressWarnings(
    drmTMB(
      bf(y ~ 1),
      family = tweedie(),
      data = dat,
      control = drm_control(se = FALSE, parallel = "none")
    )
  )
  expect_false(is_converged(fit))
  expect_true(convergence_status(fit) %in% c("degenerate", "boundary"))
  expect_warning(
    ll <- as.numeric(logLik(fit)),
    class = "drmTMB_ic_convergence_warning"
  )
  expect_true(is.finite(ll))
  expect_warning(
    aic <- AIC(fit),
    class = "drmTMB_ic_convergence_warning"
  )
  expect_true(is.finite(aic))
})

test_that("constant-y Gaussian on the lower sigma clamp stays converged", {
  dat <- data.frame(y = rep(3.5, 12))
  fit <- suppressWarnings(
    drmTMB(
      bf(y ~ 1),
      family = gaussian(),
      data = dat,
      control = drm_control(se = FALSE, parallel = "none", keep_tmb_object = TRUE)
    )
  )
  expect_true(is_converged(fit))
  expect_identical(convergence_status(fit), "converged")
})

test_that("confint warns when a Wald interval endpoint is infinite", {
  out <- data.frame(
    parm = "fixef:mu:(Intercept)",
    level = 0.95,
    lower = -Inf,
    upper = 1,
    scale = "link",
    transformation = "linear_predictor",
    tmb_parameter = "beta_mu",
    index = 1L,
    method = "wald",
    profile.engine = NA_character_,
    conf.status = "wald",
    profile.boundary = NA,
    profile.message = NA_character_,
    stringsAsFactors = FALSE
  )
  expect_warning(
    drmTMB:::warn_confint_infinite_endpoint(out),
    class = "drmTMB_confint_infinite_endpoint_warning"
  )
})