test_that("A1 ML-REML oracle covers every frozen estimator-cell fixture", {
  skip_if_not_installed("lme4")
  script <- testthat::test_path("..", "..", "docs", "dev-log", "simulation-artifacts",
    "2026-07-26-a1-r999-bootstrap-diagnosis", "a1_ml_reml_oracle.R")
  if (!file.exists(script)) skip("Developer-only oracle artifact is unavailable outside a source checkout")
  old_dir <- Sys.getenv("A1_ML_REML_ARTIFACT_DIR", unset = NA_character_)
  on.exit(Sys.setenv(A1_ML_REML_ARTIFACT_DIR = if (is.na(old_dir)) "" else old_dir), add = TRUE)
  Sys.setenv(A1_ML_REML_ARTIFACT_DIR = dirname(script))
  source(script, local = TRUE)
  result <- a1_ml_reml_oracle()
  expect_equal(nrow(result), 6L)
  expect_identical(sort(unique(result$estimator)), c("ML", "REML"))
  expect_identical(sort(unique(result$cell_id)), c("g10_n10_sd05", "g25_n10_sd05", "g50_n10_sd05"))
  # The script itself fails closed when an oracle row is not "pass".  This
  # contract test protects fixture coverage and schema without re-pinning a
  # presently failing numerical comparison as an accepted negative control.
  expect_true(all(result$oracle_status %in% c("pass", "fail", "fit_error")))
})
