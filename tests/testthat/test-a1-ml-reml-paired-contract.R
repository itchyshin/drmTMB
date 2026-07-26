test_that("A1 ML-REML helpers retain exactly paired estimator outcomes", {
  helper <- testthat::test_path("..", "..", "docs", "dev-log", "simulation-artifacts",
    "2026-07-26-a1-r999-bootstrap-diagnosis", "a1_ml_reml_common.R")
  if (!file.exists(helper)) skip("Developer-only campaign artifact is unavailable outside a source checkout")
  source(helper, local = TRUE)

  x <- data.frame(
    cell_id = rep("g10_n10_sd05", 4), seed = rep(1:2, each = 2),
    attempt_id = rep(1:2, each = 2), estimator = rep(c("ML", "REML"), 2),
    profile_miss_direction = c("upper", "covered", "lower", "upper"),
    profile_covers = c(FALSE, TRUE, FALSE, FALSE), profile_boundary = c(TRUE, FALSE, FALSE, FALSE)
  )
  expect_invisible(a1_ml_reml_validate_pairs(x))
  out <- a1_ml_reml_directional_summary(x)
  expect_equal(out$n_attempted, c(2, 2))
  expect_equal(sort(out$estimator), c("ML", "REML"))
  x$profile_covers[[1L]] <- NA
  x$profile_miss_direction[[1L]] <- "nonfinite"
  unavailable <- a1_ml_reml_directional_summary(x)
  expect_equal(unavailable$n_profile_unavailable[unavailable$estimator == "ML"], 1)
  expect_equal(unavailable$upper_miss_probability_all_attempts[unavailable$estimator == "ML"], 0)
  expect_error(a1_ml_reml_validate_pairs(x[-1, ]), "exactly one ML and one REML")
  expect_true(a1_ml_reml_oracle_gate_pass(c("pass", "pass")))
  expect_false(a1_ml_reml_oracle_gate_pass(c("pass", "fail")))

  ci <- data.frame(parm = "sd:mu:(1 | g)", lower = 0, upper = 0.4,
    profile.engine = "endpoint", profile.boundary = TRUE)
  prof <- a1_ml_reml_interval_row(ci, "sd:mu:(1 | g)", 0.5, "profile")
  expect_identical(prof$miss_direction, "upper")
  expect_true(prof$profile_boundary)
})
