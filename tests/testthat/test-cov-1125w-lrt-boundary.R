# Coverage for R/lrt-boundary.R printers and internal guards.

mock_drm_fit <- function(estimator = "ML", reml = FALSE, penalty = NULL) {
  structure(
    list(
      logLik = structure(-10, class = "logLik"),
      df = 5L,
      nobs = 20L,
      coefficients = list(mu = c("(Intercept)" = 0, x = 0.1)),
      REML = reml,
      estimator = estimator,
      penalty = penalty
    ),
    class = "drmTMB"
  )
}

test_that("print.drm_lrt_boundary() formats the chi-bar-square table", {
  x <- list(
    statistic = 3.84,
    q = 1L,
    df = 1,
    pvalue = 0.025,
    pvalue_naive = 0.05
  )
  class(x) <- "drm_lrt_boundary"
  text <- paste(capture.output(print(x)), collapse = "\n")
  expect_match(text, "Boundary-corrected likelihood-ratio test", fixed = TRUE)
  expect_match(text, "statistic = 3.8400", fixed = TRUE)
  expect_match(text, "p-value (chi-bar-square)", fixed = TRUE)
  expect_match(text, "p-value (naive chisq_1)", fixed = TRUE)
})

test_that("print.drm_lrt_boundary() notes negative statistics", {
  x <- list(
    statistic = -0.01,
    q = 2L,
    df = 1,
    pvalue = 0.75,
    pvalue_naive = 0.9
  )
  class(x) <- "drm_lrt_boundary"
  text <- paste(capture.output(print(x)), collapse = "\n")
  expect_match(text, "negative statistic clamped", fixed = TRUE)
})

test_that("drm_lrt_boundary_map_guard() refuses penalized fits", {
  full <- mock_drm_fit(estimator = "MAP")
  reduced <- mock_drm_fit()
  expect_error(
    drmTMB:::drm_lrt_boundary_map_guard(full, reduced),
    "cannot compare penalized"
  )
  penalized <- mock_drm_fit(penalty = list(kind = "pc"))
  expect_error(
    drmTMB:::drm_lrt_boundary_map_guard(reduced, penalized),
    "cannot compare penalized"
  )
})

test_that("drm_lrt_boundary_estimator() defaults missing estimator to ML", {
  expect_identical(drmTMB:::drm_lrt_boundary_estimator(mock_drm_fit()), "ML")
  expect_identical(
    drmTMB:::drm_lrt_boundary_estimator(mock_drm_fit(estimator = "REML")),
    "REML"
  )
})

test_that("drm_validate_lrt_boundary_fit() accepts drmTMB_julia", {
  julia_fit <- mock_drm_fit()
  class(julia_fit) <- c("drmTMB_julia", "drmTMB")
  expect_invisible(drmTMB:::drm_validate_lrt_boundary_fit(julia_fit, "full"))
  expect_error(
    drmTMB:::drm_validate_lrt_boundary_fit(list(), "full"),
    "must be a"
  )
})