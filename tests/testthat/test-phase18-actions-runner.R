phase18_actions_runner_script <- function() {
  candidates <- c(
    testthat::test_path(
      "..",
      "..",
      "inst",
      "sim",
      "run",
      "sim_run_actions_cell.R"
    ),
    system.file(
      "sim",
      "run",
      "sim_run_actions_cell.R",
      package = "drmTMB"
    )
  )
  candidates <- candidates[nzchar(candidates)]
  candidates <- candidates[file.exists(candidates)]
  testthat::expect_true(
    length(candidates) > 0,
    info = "Could not find installed or source-tree Phase 18 Actions runner"
  )
  normalizePath(candidates[[1]], winslash = "/", mustWork = TRUE)
}

test_that("Phase 18 Actions runner dry-run parses options and caps cores", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
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

test_that("Phase 18 Actions runner accepts proportion fixed-effect task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-proportion-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=proportion_fixed_effect",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=proportion_fixed_effect", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner accepts positive-continuous fixed-effect task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-positive-continuous-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=positive_continuous_fixed_effect",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=positive_continuous_fixed_effect", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner accepts ordinal fixed-effect task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-ordinal-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=ordinal_fixed_effect",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=ordinal_fixed_effect", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner rejects nested parallel requests", {
  script <- phase18_actions_runner_script()
  out <- suppressWarnings(
    system2(
      file.path(R.home("bin"), "Rscript"),
      c(
        "--vanilla",
        shQuote(script),
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
