test_that("Phase 18 Actions runner dry-run parses options and caps cores", {
  script <- testthat::test_path(
    "..",
    "..",
    "inst",
    "sim",
    "run",
    "sim_run_actions_cell.R"
  )
  output_dir <- tempfile("phase18-actions-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      script,
      "--task=first_wave_summary",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--cores=30",
      "--backend=multicore",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=first_wave_summary", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
  expect_match(out, "backend=multicore", fixed = TRUE)
  expect_match(out, "cores=10", fixed = TRUE)
  expect_match(out, "`cores` was capped at 10", fixed = TRUE)
})

test_that("Phase 18 Actions runner rejects nested parallel requests", {
  script <- testthat::test_path(
    "..",
    "..",
    "inst",
    "sim",
    "run",
    "sim_run_actions_cell.R"
  )
  out <- suppressWarnings(
    system2(
      file.path(R.home("bin"), "Rscript"),
      c(
        "--vanilla",
        script,
        "--task=interval_heavy_summary",
        "--dry-run=true",
        "--backend=multicore",
        "--cores=2",
        "--bootstrap-backend=multicore",
        "--bootstrap-cores=2",
        "--bootstrap-nsim=2"
      ),
      stdout = TRUE,
      stderr = TRUE
    )
  )

  expect_true(!is.null(attr(out, "status")))
  expect_match(
    paste(out, collapse = "\n"),
    "either the replicate layer or the bootstrap layer"
  )
})
