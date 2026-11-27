# Coverage top-up for R/drmTMB.R, R/family.R, and R/family-dpq.R
# (Cursor coverage 27 Nov 2026, pass 2 — complements draft PR #1905).

fast_ctrl <- drm_control(se = FALSE)

temporal_cov_dat <- function() {
  data.frame(
    id = rep(c("a", "b"), each = 3L),
    occasion = rep(0:2, 2L),
    y = stats::rnorm(6L, sd = 0.5)
  )
}

test_that("drmTMB() temporal and Julia routes refuse incompatible families and settings", {
  dat <- temporal_cov_dat()
  form <- bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1)
  expect_error(
    drmTMB(form, family = gaussian(), data = dat, engine = "julia"),
    "native TMB"
  )
  expect_error(
    drmTMB(form, family = poisson(), data = dat),
    "univariate Gaussian"
  )
  expect_error(
    drmTMB(form, family = gaussian(), data = dat, REML = TRUE),
    "maximum likelihood"
  )
})

test_that("drmTMB() refuses penalty with Julia before the bridge runs", {
  dat <- data.frame(y = stats::rnorm(12L), x = stats::rnorm(12L))
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = gaussian(),
      data = dat,
      engine = "julia",
      penalty = drm_phylo_penalty(sd_u = 1)
    ),
    "penalty"
  )
})

test_that("biv_student() rejects likelihood weights and penalized fits on the TMB route", {
  n <- 8L
  dat <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rnorm(n),
    x = stats::rnorm(n)
  )
  form <- bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ x,
    sigma1 = ~1,
    sigma2 = ~1,
    nu = ~1,
    rho12 = ~1
  )
  expect_error(
    drmTMB(form, family = biv_student(), data = dat, weights = rep(1, n), control = fast_ctrl),
    "does not support"
  )
  expect_error(
    drmTMB(
      form,
      family = biv_student(),
      data = dat,
      penalty = drm_phylo_penalty(sd_u = 1),
      control = fast_ctrl
    ),
    "penalty"
  )
})

test_that("drm_eval_family_arg() rejects a variable holding base::beta()", {
  dat <- data.frame(y = c(0.2, 0.45, 0.7), x = 1:3)
  beta_fun <- base::beta
  err <- tryCatch(
    drmTMB(bf(y ~ x, sigma ~ 1), family = beta_fun, data = dat),
    error = identity
  )
  expect_s3_class(err, "drmTMB_base_beta_family_error")
  expect_match(conditionMessage(err), "beta_family()", fixed = TRUE)
})

test_that("internal start-override validators guard malformed overrides before application", {
  validate <- drmTMB:::drm_validate_start_override
  align <- drmTMB:::drm_align_start_override_value
  map_slots <- drmTMB:::drm_start_override_mapped_slots
  spec <- list(start = list(beta_mu = c(`(Intercept)` = 0, x = 0.1)))

  expect_error(validate(spec, data.frame(a = 1)), "named list")
  expect_error(validate(spec, list()), "name every")
  expect_error(validate(spec, list(beta_mu = 0, beta_mu = 1)), "duplicate")
  expect_error(validate(spec, list(ghost = 1)), "Unknown component")
  expect_error(validate(spec, list(beta_mu = "1")), "numeric vector")
  expect_error(validate(spec, list(beta_mu = c(0, 0.2, 0.3))), "start lengths")
  expect_error(validate(spec, list(beta_mu = c(0, NA_real_))), "finite")

  expect_error(
    align(c(wrong = 1, x = 0.2), spec$start$beta_mu, "beta_mu"),
    "names that do not match"
  )
  expect_error(
    map_slots(c(TRUE, FALSE, TRUE), 2L, "beta_mu"),
    "map length"
  )
})

test_that("drm_recycle_scalar_arg() broadcasts scalar evaluation points across rows", {
  recycle <- drmTMB:::drm_recycle_scalar_arg
  params <- data.frame(mu = c(1, 2, 3), sigma = c(0.5, 0.6, 0.7))
  expect_equal(recycle(0.25, params), rep(0.25, 3L))
  expect_equal(recycle(c(0, 1, 2), params), c(0, 1, 2))
})

test_that("tweedie dpq evaluation validates power on (1, 2) before calling tweedie", {
  skip_if_not_installed("tweedie")
  dfun <- drmTMB:::drm_family_dpq_tweedie()$d
  bad <- data.frame(mu = 1, sigma = 0.5, nu = 2.5)
  expect_error(dfun(1, bad), "strictly between 1 and 2")
  ok <- data.frame(mu = c(1, 2), sigma = c(0.5, 0.6), nu = c(1.5, 1.7))
  expect_length(dfun(c(0.5, 1.5), ok), 2L)
})