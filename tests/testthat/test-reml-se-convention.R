# REML mean-block SE convention label (#1201, owner decision 2026-10-11,
# option (a)). Under REML each engine reports its own mean-block SE convention:
# native TMB `sdreport` over a random set that contains beta_mu
# ("sdreport-inflated"), DRM.jl the closed-form `(Xmu' Vhat^-1 Xmu)^-1`
# ("canonical GLS"). Neither engine changes; the SEs are labelled.

reml_se_convention_fixture <- function(n = 40L, seed = 11L) {
  set.seed(seed)
  x <- stats::rnorm(n)
  data.frame(x = x, y = 0.3 + 0.5 * x + stats::rnorm(n, sd = 0.7))
}

reml_se_convention_messages <- function(x) {
  withr::local_options(cli.width = 500)
  paste(testthat::capture_messages(print(x)), collapse = " ")
}

test_that("the label helper names each engine's REML convention and nothing else", {
  expect_identical(
    drmTMB:::drm_reml_se_convention(list(estimator = "REML")),
    "sdreport-inflated"
  )
  expect_identical(
    drmTMB:::drm_reml_se_convention(
      structure(list(estimator = "REML"), class = "drmTMB_julia")
    ),
    "canonical GLS"
  )
  expect_true(is.na(drmTMB:::drm_reml_se_convention(list(estimator = "ML"))))
  expect_true(is.na(drmTMB:::drm_reml_se_convention(
    structure(list(estimator = "ML"), class = "drmTMB_julia")
  )))
  expect_true(is.na(drmTMB:::drm_reml_se_convention(list(estimator = NULL))))
})

test_that("native REML summary carries and prints the sdreport-inflated label", {
  dat <- reml_se_convention_fixture()
  fit_reml <- drmTMB(
    bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat, REML = TRUE
  )
  fit_ml <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  s_reml <- summary(fit_reml)
  expect_identical(s_reml$se_convention, "sdreport-inflated")
  msg <- reml_se_convention_messages(s_reml)
  expect_match(msg, "REML mean-block standard errors", fixed = TRUE)
  expect_match(msg, "sdreport-inflated", fixed = TRUE)

  s_ml <- summary(fit_ml)
  expect_true(is.na(s_ml$se_convention))
  expect_no_match(
    reml_se_convention_messages(s_ml), "mean-block standard errors"
  )
})

test_that("the Julia-engine summary printer shows the canonical GLS label", {
  coefs <- data.frame(
    dpar = "mu", term = "(Intercept)", estimate = 0.1, std.error = 0.2
  )
  base <- list(nobs = 10L, logLik = -5, coefficients = coefs)
  s_reml <- structure(
    c(base, list(se_convention = "canonical GLS")),
    class = "summary.drmTMB_julia"
  )
  msg <- reml_se_convention_messages(s_reml)
  expect_match(msg, "REML mean-block standard errors", fixed = TRUE)
  expect_match(msg, "canonical GLS", fixed = TRUE)

  s_ml <- structure(
    c(base, list(se_convention = NA_character_)),
    class = "summary.drmTMB_julia"
  )
  expect_no_match(
    reml_se_convention_messages(s_ml), "mean-block standard errors"
  )
})
