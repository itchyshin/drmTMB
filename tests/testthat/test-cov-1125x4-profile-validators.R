# Lightweight validators from R/profile.R.

test_that("profile_correlation_guard() selects RE vs phylo constants", {
  expect_equal(
    drmTMB:::profile_correlation_guard("eta_cor_phylo"),
    drmTMB:::DRM_CORR_GUARD
  )
  expect_equal(
    drmTMB:::profile_correlation_guard("eta_cor_mu"),
    drmTMB:::DRM_RE_CORR_GUARD
  )
})

test_that("profile_transform_values() applies link maps", {
  target <- list(transformation = "plogis", tmb_parameter = "beta_mu")
  expect_equal(drmTMB:::profile_transform_values(0, target), 0.5, tolerance = 1e-12)
  exp_t <- list(transformation = "exp")
  expect_equal(drmTMB:::profile_transform_values(0, exp_t), 1)
})

test_that("validate_profile_plot_flag() enforces scalar logicals", {
  expect_identical(drmTMB:::validate_profile_plot_flag(TRUE, "interval"), TRUE)
  expect_error(drmTMB:::validate_profile_plot_flag(NA, "interval"), "single")
  expect_error(drmTMB:::validate_profile_plot_flag(c(TRUE, FALSE), "interval"), "single")
})

test_that("validate_interval_method() normalizes allowed methods", {
  choices <- c("wald", "profile")
  expect_identical(
    drmTMB:::validate_interval_method("wald", choices, "confint"),
    "wald"
  )
  expect_error(
    drmTMB:::validate_interval_method("bootstrap", choices, "confint"),
    "not implemented"
  )
})

test_that("resolve_profile_precision() and bootstrap parallel defaults", {
  expect_identical(drmTMB:::resolve_profile_precision("fast", FALSE), "fast")
  expect_identical(drmTMB:::resolve_profile_precision(NA, TRUE), "default")
  expect_identical(drmTMB:::resolve_bootstrap_parallel(NA, TRUE), "none")
  expect_identical(drmTMB:::resolve_bootstrap_parallel("multicore", FALSE), "multicore")
})

test_that("validate_profile_maxit() accepts positive integers", {
  expect_identical(drmTMB:::validate_profile_maxit(20L), 20L)
  expect_null(drmTMB:::validate_profile_maxit(NULL))
  expect_error(drmTMB:::validate_profile_maxit(1.5), "whole number")
})