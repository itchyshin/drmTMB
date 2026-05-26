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
  expect_match(out, "condition_shard=1", fixed = TRUE)
  expect_match(out, "condition_shards=1", fixed = TRUE)
  expect_match(out, "`cores` was capped at 10", fixed = TRUE)
})

test_that("Phase 18 Actions runner loads drmTMB for real tasks", {
  script <- phase18_actions_runner_script()
  text <- paste(readLines(script, warn = FALSE), collapse = "\n")

  load_call <- regexpr("phase18_actions_load_package\\(\\)", text)[[1]]
  source_call <- regexpr(
    "phase18_actions_source_dependencies\\(task\\)",
    text
  )[[1]]

  expect_gt(load_call, 0L)
  expect_gt(source_call, 0L)
  expect_lt(load_call, source_call)
  expect_match(text, 'require\\("drmTMB"', perl = TRUE)
})

test_that("Phase 18 Actions runner validates formal condition shards", {
  script <- phase18_actions_runner_script()
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=nbinom2_phylo_q1_formal",
      "--dry-run=true",
      "--profile-parameters=log_sd_phylo",
      "--condition-shard=2",
      "--condition-shards=16"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=nbinom2_phylo_q1_formal", fixed = TRUE)
  expect_match(out, "condition_shard=2", fixed = TRUE)
  expect_match(out, "condition_shards=16", fixed = TRUE)

  rejected <- suppressWarnings(
    system2(
      file.path(R.home("bin"), "Rscript"),
      c(
        "--vanilla",
        shQuote(script),
        "--task=first_wave_summary",
        "--dry-run=true",
        "--condition-shard=2",
        "--condition-shards=16"
      ),
      stdout = TRUE,
      stderr = TRUE
    )
  )

  expect_true(!is.null(attr(rejected, "status")))
  expect_match(
    paste(rejected, collapse = "\n"),
    "Condition sharding is only available"
  )
})

test_that("Phase 18 Actions runner plans proportion fixed-effect task", {
  script <- phase18_actions_runner_script()
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=proportion_fixed_effect",
      "--dry-run=true",
      "--n-reps=1",
      "--master-seed=123"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=proportion_fixed_effect", fixed = TRUE)
  expect_match(out, "n_rep=1", fixed = TRUE)
  expect_match(out, "master_seed=123", fixed = TRUE)
})

test_that("Phase 18 Actions runner plans positive-continuous task", {
  script <- phase18_actions_runner_script()
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=positive_continuous_fixed_effect",
      "--dry-run=true",
      "--n-reps=1",
      "--master-seed=123"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=positive_continuous_fixed_effect", fixed = TRUE)
  expect_match(out, "n_rep=1", fixed = TRUE)
  expect_match(out, "master_seed=123", fixed = TRUE)
})

test_that("Phase 18 workflow concurrency is shard-aware", {
  workflow <- testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
  testthat::skip_if_not(file.exists(workflow))
  text <- paste(readLines(workflow, warn = FALSE), collapse = "\n")

  expect_match(
    text,
    "inputs.condition_shard",
    fixed = TRUE
  )
  expect_match(
    text,
    "inputs.condition_shards",
    fixed = TRUE
  )
  expect_match(text, "proportion_fixed_effect", fixed = TRUE)
  expect_match(text, "positive_continuous_fixed_effect", fixed = TRUE)
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
