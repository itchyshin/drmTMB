# Internal adequacy helpers in R/adequacy.R.

mock_fit <- function(type = "gaussian", y = 1:5) {
  structure(
    list(
      model = list(model_type = type, y = y, y1 = y, y2 = y + 0.1),
      missing_data = list(
        response_policy = "include",
        observed_y1 = c(TRUE, TRUE, FALSE, TRUE, TRUE),
        observed_y2 = rep(TRUE, 5)
      )
    ),
    class = "drmTMB"
  )
}

test_that("drm_quantile_residual_response_y() selects bivariate columns", {
  fit <- mock_fit("biv_gaussian")
  expect_identical(drmTMB:::drm_quantile_residual_response_y(fit, 1L), fit$model$y1)
  expect_identical(drmTMB:::drm_quantile_residual_response_y(fit, 2L), fit$model$y2)
  uni <- mock_fit("gaussian")
  expect_identical(drmTMB:::drm_quantile_residual_response_y(uni, NULL), uni$model$y)
})

test_that("drm_quantile_residual_mask() masks missing bivariate rows", {
  fit <- mock_fit("biv_gaussian")
  masked <- drmTMB:::drm_quantile_residual_mask(fit, rep(0.5, 5), response = 1L)
  expect_true(is.na(masked[[3L]]))
  expect_false(is.na(masked[[1L]]))
})

test_that("drm_atom_left_limit() subtracts point mass at atoms", {
  fd <- list(
    discrete = FALSE,
    has_atom = TRUE,
    atoms = c(0, 1),
    d = function(y) ifelse(y %in% c(0, 1), 0.2, 0),
    p = function(y) pmin(pmax(y, 0), 1)
  )
  y <- c(0, 0.5, 1)
  upper <- c(0.2, 0.5, 1)
  lower <- drmTMB:::drm_atom_left_limit(fd, y, upper)
  expect_equal(lower[c(1L, 3L)], c(0, 0.8), tolerance = 1e-12)
  expect_equal(lower[2L], upper[2L])
})

test_that("drm_warn_adequacy_spike() fires once per model type", {
  drmTMB:::drm_reset_adequacy_warning_state()
  expect_warning(
    drmTMB:::drm_warn_adequacy_spike("spike", "tweedie"),
    "feasibility-grade"
  )
  expect_silent(drmTMB:::drm_warn_adequacy_spike("spike", "tweedie"))
  expect_invisible(drmTMB:::drm_warn_adequacy_spike("reference", "gaussian"))
  drmTMB:::drm_reset_adequacy_warning_state()
})

test_that("drm_adequacy_envelope() builds rank-wise bands", {
  dat <- data.frame(
    rank = rep(1:3, each = 2),
    theoretical = rep(c(-1, 0, 1), each = 2),
    sample = c(-0.9, -1.1, 0.1, -0.1, 1.2, 0.8)
  )
  env <- drmTMB:::drm_adequacy_envelope(dat, "sample")
  expect_identical(nrow(env), 3L)
  expect_equal(env$ymin[1L], -1.1)
  expect_equal(env$ymax[1L], -0.9)
})