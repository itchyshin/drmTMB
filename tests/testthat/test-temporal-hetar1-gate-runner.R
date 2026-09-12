test_that("hetar1 immutable reverify binds artifacts to their recorded source", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  withr::local_dir(root)
  artifact <- file.path(
    "docs", "dev-log", "simulation-artifacts",
    "2026-09-11-temporal-hetar1-interval-feasibility", "pilot"
  )
  provenance <- utils::read.csv(file.path(artifact, "provenance.csv"), stringsAsFactors = FALSE)
  source_commit <- provenance$value[provenance$key == "source_commit"]
  recorded_md5 <- provenance$value[provenance$key == "runner_md5"]
  source_runner <- system2(
    "git",
    c("show", paste0(source_commit, ":tools/run-temporal-hetar1-interval-feasibility.R")),
    stdout = TRUE,
    stderr = TRUE
  )
  source_runner_path <- tempfile("temporal-hetar1-source-runner-")
  on.exit(unlink(source_runner_path), add = TRUE)
  writeLines(source_runner, source_runner_path, useBytes = TRUE)
  expect_identical(unname(tools::md5sum(source_runner_path)), recorded_md5)

  output <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", "tools/temporal-hetar1-gates.R", "T4-11", "--reverify"),
    stdout = TRUE,
    stderr = TRUE
  )
  expect_identical(attr(output, "status"), NULL)
  expect_true(any(grepl("TEMPORAL_HETAR1_T4_11_PASS", output, fixed = TRUE)))
})
