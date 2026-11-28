# Coverage: internal start-override helpers in R/drmTMB.R (not drm_translate / public contract).

minimal_start_spec <- function() {
  list(
    start = list(beta_mu = c(`(Intercept)` = 0, x = 0.1)),
    map = list()
  )
}

test_that("drm_start_override_empty_record is a zero-row frame", {
  empty <- drmTMB:::drm_start_override_empty_record()
  expect_s3_class(empty, "data.frame")
  expect_equal(nrow(empty), 0L)
  expect_equal(names(empty), c("parameter", "n_value", "n_applied", "n_mapped"))
})

test_that("drm_align_start_override_value aligns by target names", {
  target <- c(`(Intercept)` = 1, x = 2)
  value <- c(x = 5, `(Intercept)` = 3)
  out <- drmTMB:::drm_align_start_override_value(value, target, "beta_mu")
  expect_equal(unname(out), c(3, 5))
  expect_equal(names(out), names(target))
  expect_error(
    drmTMB:::drm_align_start_override_value(c(a = 1), target, "beta_mu"),
    "match"
  )
})

test_that("drm_start_override_mapped_slots respects map factors", {
  expect_equal(drmTMB:::drm_start_override_mapped_slots(NULL, 3L, "beta"), rep(FALSE, 3))
  expect_equal(
    drmTMB:::drm_start_override_mapped_slots(factor(NA), 2L, "beta"),
    rep(TRUE, 2)
  )
  mapped <- drmTMB:::drm_start_override_mapped_slots(factor(c(NA, 1L)), 2L, "beta")
  expect_equal(mapped, c(TRUE, FALSE))
  expect_error(
    drmTMB:::drm_start_override_mapped_slots(factor(c(NA, 1L, NA)), 2L, "beta"),
    "map length"
  )
})

test_that("drm_validate_start_override rejects malformed overrides", {
  spec <- minimal_start_spec()
  expect_error(drmTMB:::drm_validate_start_override(spec, data.frame()), "named list")
  expect_error(drmTMB:::drm_validate_start_override(spec, list(1, 2)), "name")
  dup <- list(1, 2)
  names(dup) <- c("beta_mu", "beta_mu")
  expect_error(drmTMB:::drm_validate_start_override(spec, dup), "duplicate")
  expect_error(
    drmTMB:::drm_validate_start_override(spec, list(unknown = 1)),
    "Unknown"
  )
  expect_error(
    drmTMB:::drm_validate_start_override(spec, list(beta_mu = c(1, 2, 3))),
    "length"
  )
  expect_error(
    drmTMB:::drm_validate_start_override(spec, list(beta_mu = c(Inf, 0))),
    "finite"
  )
  expect_error(
    drmTMB:::drm_validate_start_override(spec, list(beta_mu = matrix(0, 1, 1))),
    "numeric vector"
  )
})

test_that("drm_apply_start_override applies unmapped slots only", {
  spec <- minimal_start_spec()
  spec$start_override <- list(beta_mu = c(`(Intercept)` = 1.5, x = -0.2))
  out <- drmTMB:::drm_apply_start_override(spec)
  expect_equal(unname(out$start$beta_mu), c(1.5, -0.2))
  applied <- out$start_override_applied
  expect_equal(applied$parameter, "beta_mu")
  expect_equal(applied$n_applied, 2L)
  expect_equal(applied$n_mapped, 0L)
  spec2 <- minimal_start_spec()
  spec2$start_override <- NULL
  cleared <- drmTMB:::drm_apply_start_override(spec2)
  expect_equal(nrow(cleared$start_override_applied), 0L)
})

test_that("drm_complete_shared_tmb_parameters fills ZOI/COI inert defaults", {
  spec <- list(model_type = "gaussian", start = list(), map = list())
  out <- drmTMB:::drm_complete_shared_tmb_parameters(spec)
  expect_true("beta_sd_sigma" %in% names(out$start))
  expect_true("u_zoi" %in% names(out$start))
  expect_true("log_sd_coi" %in% names(out$start))
  expect_true(is.factor(out$map$u_zoi))
})