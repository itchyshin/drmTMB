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

test_that("Phase 18 Actions runner accepts truncated NB2 mu random-intercept task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-truncated-nb2-mu-ri-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=truncated_nbinom2_mu_random_intercept",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(
    out,
    "task=truncated_nbinom2_mu_random_intercept",
    fixed = TRUE
  )
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner accepts bounded-response mu random-intercept task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-bounded-response-mu-ri-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=bounded_response_mu_random_intercept",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=bounded_response_mu_random_intercept", fixed = TRUE)
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

test_that("Phase 18 Actions runner accepts Tweedie fixed-effect task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-tweedie-fe-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=tweedie_fixed_effect",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=tweedie_fixed_effect", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner sources Tweedie task dependencies", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  tweedie_paths <- c(
    "sim/dgp/sim_dgp_tweedie_fixed_effect.R",
    "sim/fit/sim_summarise_tweedie_fixed_effect.R",
    "sim/run/sim_run_tweedie_fixed_effect_smoke.R",
    "sim/run/sim_summary_tweedie_fixed_effect_smoke.R",
    "sim/run/sim_write_tweedie_fixed_effect_grid.R"
  )
  expect_true(all(
    tweedie_paths %in%
      env$phase18_actions_task_paths(
        "first_wave_summary"
      )
  ))
  expect_equal(
    env$phase18_actions_task_paths("tweedie_fixed_effect"),
    tweedie_paths
  )
})

test_that("Phase 18 Actions runner accepts count structured q1 task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-count-structured-q1-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=count_structured_q1",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--profile-parameters=log_sd_phylo",
      "--profile-level=0.70",
      "--condition-set=stable",
      "--require-complete=true",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=count_structured_q1", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
  expect_match(out, "profile_parameters=log_sd_phylo", fixed = TRUE)
  expect_match(out, "profile_level=0.7", fixed = TRUE)
  expect_match(out, "condition_set=stable", fixed = TRUE)
  expect_match(out, "require_complete=TRUE", fixed = TRUE)
})

test_that("Phase 18 Actions runner prints require-complete after real runs", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  env$phase18_actions_load_package <- function() {
    invisible(TRUE)
  }
  env$phase18_actions_source_dependencies <- function(task) {
    invisible(task)
  }
  env$phase18_count_structured_q1_followup_conditions <- function(
    condition_set
  ) {
    data.frame(cell_id = paste0("mock_", condition_set))
  }
  env$phase18_write_count_structured_q1_grid_outputs <- function(...) {
    list(ok = TRUE)
  }

  output_dir <- tempfile("phase18-actions-count-structured-q1-run-")
  out <- capture.output(
    env$phase18_actions_main(
      c(
        "--task=count_structured_q1",
        paste0("--output-dir=", output_dir),
        "--n-reps=1",
        "--master-seed=123",
        "--profile-parameters=log_sd_phylo",
        "--profile-level=0.70",
        "--condition-set=stable",
        "--require-complete=true"
      )
    )
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "require_complete=TRUE", fixed = TRUE)
  expect_true(file.exists(file.path(output_dir, "phase18-actions-result.rds")))
})

test_that("Phase 18 Actions runner sources count structured q1 task dependencies", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  count_structured_paths <- c(
    "sim/dgp/sim_dgp_count_structured_q1.R",
    "sim/fit/sim_summarise_count_structured_q1.R",
    "sim/run/sim_run_count_structured_q1_smoke.R",
    "sim/run/sim_summary_count_structured_q1_smoke.R",
    "sim/run/sim_write_count_structured_q1_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("count_structured_q1"),
    count_structured_paths
  )
})

test_that("Phase 18 Actions runner accepts positive-continuous mu random-intercept task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-positive-continuous-mu-ri-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=positive_continuous_mu_random_intercept",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(
    out,
    "task=positive_continuous_mu_random_intercept",
    fixed = TRUE
  )
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner accepts Student-t mu random-intercept task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-student-mu-ri-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=student_mu_random_intercept",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=student_mu_random_intercept", fixed = TRUE)
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

test_that("Phase 18 Actions runner accepts zero-one beta fixed-effect task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-zero-one-beta-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=zero_one_beta_fixed_effect",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=zero_one_beta_fixed_effect", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner accepts bivariate Gaussian mu-slope task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-biv-gaussian-mu-slope-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=biv_gaussian_mu_slope",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=biv_gaussian_mu_slope", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner sources bivariate Gaussian mu-slope task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  paths <- c(
    "sim/dgp/sim_dgp_biv_gaussian_mu_slope.R",
    "sim/fit/sim_summarise_biv_gaussian_mu_slope.R",
    "sim/run/sim_run_biv_gaussian_mu_slope_smoke.R",
    "sim/run/sim_summary_biv_gaussian_mu_slope_smoke.R",
    "sim/run/sim_write_biv_gaussian_mu_slope_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("biv_gaussian_mu_slope"),
    paths
  )
})

test_that("Phase 18 Actions runner dispatches bivariate Gaussian mu-slope task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  env$phase18_actions_load_package <- function() {
    invisible(TRUE)
  }
  env$phase18_actions_source_dependencies <- function(task) {
    invisible(task)
  }
  env$phase18_write_biv_gaussian_mu_slope_grid_outputs <- function(...) {
    args <- list(...)
    list(
      ok = TRUE,
      output_dir = args$output_dir,
      n_rep = args$n_rep,
      master_seed = args$master_seed,
      backend = args$backend,
      cores = args$cores
    )
  }

  output_dir <- tempfile("phase18-actions-biv-gaussian-mu-slope-run-")
  out <- capture.output(
    env$phase18_actions_main(
      c(
        "--task=biv_gaussian_mu_slope",
        paste0("--output-dir=", output_dir),
        "--n-reps=1",
        "--master-seed=237",
        "--backend=none",
        "--cores=1"
      )
    )
  )
  out <- paste(out, collapse = "\n")
  result <- readRDS(file.path(output_dir, "phase18-actions-result.rds"))

  expect_match(out, "task=biv_gaussian_mu_slope", fixed = TRUE)
  expect_true(result$ok)
  expect_equal(result$n_rep, 1L)
  expect_equal(result$master_seed, 237L)
  expect_equal(result$backend, "none")
  expect_equal(result$cores, 1L)
})

test_that("Phase 18 Actions runner accepts bivariate Gaussian q4 location task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-biv-gaussian-q4-location-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=biv_gaussian_q4_location",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=biv_gaussian_q4_location", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner sources bivariate Gaussian q4 location task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  paths <- c(
    "sim/dgp/sim_dgp_biv_gaussian_q4_location.R",
    "sim/fit/sim_summarise_biv_gaussian_q4_location.R",
    "sim/run/sim_run_biv_gaussian_q4_location_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q4_location_smoke.R",
    "sim/run/sim_write_biv_gaussian_q4_location_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("biv_gaussian_q4_location"),
    paths
  )
})

test_that("Phase 18 Actions runner dispatches bivariate Gaussian q4 location task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  env$phase18_actions_load_package <- function() {
    invisible(TRUE)
  }
  env$phase18_actions_source_dependencies <- function(task) {
    invisible(task)
  }
  env$phase18_write_biv_gaussian_q4_location_grid_outputs <- function(...) {
    args <- list(...)
    list(
      ok = TRUE,
      output_dir = args$output_dir,
      n_rep = args$n_rep,
      master_seed = args$master_seed,
      backend = args$backend,
      cores = args$cores
    )
  }

  output_dir <- tempfile("phase18-actions-biv-gaussian-q4-location-run-")
  out <- capture.output(
    env$phase18_actions_main(
      c(
        "--task=biv_gaussian_q4_location",
        paste0("--output-dir=", output_dir),
        "--n-reps=1",
        "--master-seed=239",
        "--backend=none",
        "--cores=1"
      )
    )
  )
  out <- paste(out, collapse = "\n")
  result <- readRDS(file.path(output_dir, "phase18-actions-result.rds"))

  expect_match(out, "task=biv_gaussian_q4_location", fixed = TRUE)
  expect_true(result$ok)
  expect_equal(result$n_rep, 1L)
  expect_equal(result$master_seed, 239L)
  expect_equal(result$backend, "none")
  expect_equal(result$cores, 1L)
})

test_that("Phase 18 Actions runner accepts spatial mu-slope task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-spatial-mu-slope-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=spatial_mu_slope",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=spatial_mu_slope", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner sources spatial mu-slope task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  paths <- c(
    "sim/dgp/sim_dgp_spatial_mu_slope.R",
    "sim/fit/sim_summarise_spatial_mu_slope.R",
    "sim/run/sim_run_spatial_mu_slope_smoke.R",
    "sim/run/sim_summary_spatial_mu_slope_smoke.R",
    "sim/run/sim_write_spatial_mu_slope_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("spatial_mu_slope"),
    paths
  )
})

test_that("Phase 18 Actions runner dispatches spatial mu-slope task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  env$phase18_actions_load_package <- function() {
    invisible(TRUE)
  }
  env$phase18_actions_source_dependencies <- function(task) {
    invisible(task)
  }
  env$phase18_write_spatial_mu_slope_grid_outputs <- function(...) {
    args <- list(...)
    list(
      ok = TRUE,
      output_dir = args$output_dir,
      n_rep = args$n_rep,
      master_seed = args$master_seed,
      backend = args$backend,
      cores = args$cores
    )
  }

  output_dir <- tempfile("phase18-actions-spatial-mu-slope-run-")
  out <- capture.output(
    env$phase18_actions_main(
      c(
        "--task=spatial_mu_slope",
        paste0("--output-dir=", output_dir),
        "--n-reps=1",
        "--master-seed=239",
        "--backend=none",
        "--cores=1"
      )
    )
  )
  out <- paste(out, collapse = "\n")
  result <- readRDS(file.path(output_dir, "phase18-actions-result.rds"))

  expect_match(out, "task=spatial_mu_slope", fixed = TRUE)
  expect_true(result$ok)
  expect_equal(result$n_rep, 1L)
  expect_equal(result$master_seed, 239L)
  expect_equal(result$backend, "none")
  expect_equal(result$cores, 1L)
})

test_that("Phase 18 Actions runner accepts non-spatial structured mu-slope tasks", {
  script <- phase18_actions_runner_script()
  tasks <- c("phylo_mu_slope", "animal_mu_slope", "relmat_mu_slope")

  for (task in tasks) {
    output_dir <- tempfile(paste0("phase18-actions-", task, "-dry-run-"))
    out <- system2(
      file.path(R.home("bin"), "Rscript"),
      c(
        "--vanilla",
        shQuote(script),
        paste0("--task=", task),
        paste0("--output-dir=", output_dir),
        "--n-reps=2",
        "--master-seed=123",
        "--dry-run=true"
      ),
      stdout = TRUE,
      stderr = TRUE
    )
    out <- paste(out, collapse = "\n")

    expect_match(out, paste0("task=", task), fixed = TRUE)
    expect_match(out, "n_rep=2", fixed = TRUE)
  }
})

test_that("Phase 18 Actions runner sources non-spatial structured mu-slope tasks", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  expected <- list(
    phylo_mu_slope = c(
      "sim/dgp/sim_dgp_phylo_mu_slope.R",
      "sim/fit/sim_summarise_phylo_mu_slope.R",
      "sim/run/sim_run_phylo_mu_slope_smoke.R",
      "sim/run/sim_summary_phylo_mu_slope_smoke.R",
      "sim/run/sim_write_phylo_mu_slope_grid.R"
    ),
    animal_mu_slope = c(
      "sim/dgp/sim_dgp_animal_mu_slope.R",
      "sim/fit/sim_summarise_animal_mu_slope.R",
      "sim/run/sim_run_animal_mu_slope_smoke.R",
      "sim/run/sim_summary_animal_mu_slope_smoke.R",
      "sim/run/sim_write_animal_mu_slope_grid.R"
    ),
    relmat_mu_slope = c(
      "sim/dgp/sim_dgp_relmat_mu_slope.R",
      "sim/fit/sim_summarise_relmat_mu_slope.R",
      "sim/run/sim_run_relmat_mu_slope_smoke.R",
      "sim/run/sim_summary_relmat_mu_slope_smoke.R",
      "sim/run/sim_write_relmat_mu_slope_grid.R"
    )
  )

  for (task in names(expected)) {
    expect_equal(env$phase18_actions_task_paths(task), expected[[task]])
  }
})

test_that("Phase 18 Actions runner dispatches non-spatial structured mu-slope tasks", {
  script <- phase18_actions_runner_script()
  writers <- c(
    phylo_mu_slope = "phase18_write_phylo_mu_slope_grid_outputs",
    animal_mu_slope = "phase18_write_animal_mu_slope_grid_outputs",
    relmat_mu_slope = "phase18_write_relmat_mu_slope_grid_outputs"
  )

  for (task in names(writers)) {
    env <- new.env(parent = globalenv())
    source(script, local = env)
    env$phase18_actions_load_package <- function() {
      invisible(TRUE)
    }
    env$phase18_actions_source_dependencies <- function(task) {
      invisible(task)
    }
    env[[writers[[task]]]] <- function(...) {
      args <- list(...)
      list(
        ok = TRUE,
        task = task,
        output_dir = args$output_dir,
        n_rep = args$n_rep,
        master_seed = args$master_seed,
        backend = args$backend,
        cores = args$cores
      )
    }

    output_dir <- tempfile(paste0("phase18-actions-", task, "-run-"))
    out <- capture.output(
      env$phase18_actions_main(
        c(
          paste0("--task=", task),
          paste0("--output-dir=", output_dir),
          "--n-reps=1",
          "--master-seed=241",
          "--backend=none",
          "--cores=1"
        )
      )
    )
    out <- paste(out, collapse = "\n")
    result <- readRDS(file.path(output_dir, "phase18-actions-result.rds"))

    expect_match(out, paste0("task=", task), fixed = TRUE)
    expect_true(result$ok)
    expect_equal(result$task, task)
    expect_equal(result$n_rep, 1L)
    expect_equal(result$master_seed, 241L)
    expect_equal(result$backend, "none")
    expect_equal(result$cores, 1L)
  }
})

test_that("Phase 18 Actions runner accepts correlation-block status task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-correlation-block-status-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=correlation_block_status",
      paste0("--output-dir=", output_dir),
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=correlation_block_status", fixed = TRUE)
})

test_that("Phase 18 Actions runner sources correlation-block status task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  expect_equal(
    env$phase18_actions_task_paths("correlation_block_status"),
    c(
      "sim/run/sim_phase18_structured_workflow_registry.R",
      "sim/run/sim_write_correlation_block_status.R"
    )
  )
})

test_that("Phase 18 Actions runner dispatches correlation-block status task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  env$phase18_actions_load_package <- function() {
    invisible(TRUE)
  }
  env$phase18_actions_source_dependencies <- function(task) {
    invisible(task)
  }
  env$phase18_write_correlation_block_status_outputs <- function(...) {
    args <- list(...)
    list(
      ok = TRUE,
      output_dir = args$output_dir,
      overwrite = args$overwrite
    )
  }

  output_dir <- tempfile("phase18-actions-correlation-block-status-run-")
  out <- capture.output(
    env$phase18_actions_main(
      c(
        "--task=correlation_block_status",
        paste0("--output-dir=", output_dir),
        "--overwrite=true"
      )
    )
  )
  out <- paste(out, collapse = "\n")
  result <- readRDS(file.path(output_dir, "phase18-actions-result.rds"))

  expect_match(out, "task=correlation_block_status", fixed = TRUE)
  expect_true(result$ok)
  expect_true(result$overwrite)
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

test_that("Phase 18 Actions runner restricts count condition sets", {
  script <- phase18_actions_runner_script()
  rejected <- suppressWarnings(
    system2(
      file.path(R.home("bin"), "Rscript"),
      c(
        "--vanilla",
        shQuote(script),
        "--task=tweedie_fixed_effect",
        "--dry-run=true",
        "--condition-set=stable"
      ),
      stdout = TRUE,
      stderr = TRUE
    )
  )

  expect_true(!is.null(attr(rejected, "status")))
  expect_match(
    paste(rejected, collapse = "\n"),
    "`condition-set` is only available for count_structured_q1",
    fixed = TRUE
  )
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
  expect_match(
    text,
    "inputs.condition_set",
    fixed = TRUE
  )
})

test_that("Phase 18 workflow exposes Tweedie fixed-effect task", {
  workflow <- testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
  testthat::skip_if_not(file.exists(workflow))
  text <- paste(readLines(workflow, warn = FALSE), collapse = "\n")

  expect_match(text, "tweedie_fixed_effect", fixed = TRUE)
  expect_match(text, "20260542", fixed = TRUE)
})

test_that("Phase 18 workflow exposes count structured q1 task", {
  workflow <- testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
  testthat::skip_if_not(file.exists(workflow))
  text <- paste(readLines(workflow, warn = FALSE), collapse = "\n")

  expect_match(text, "count_structured_q1", fixed = TRUE)
  expect_match(text, "20260543", fixed = TRUE)
  expect_match(text, "condition_set:", fixed = TRUE)
  expect_match(text, "--condition-set=", fixed = TRUE)
  expect_match(text, "profile_level:", fixed = TRUE)
  expect_match(text, "--profile-level=", fixed = TRUE)
  expect_match(text, "inputs.profile_level", fixed = TRUE)
  expect_match(text, "require_complete:", fixed = TRUE)
  expect_match(text, "--require-complete=", fixed = TRUE)
  expect_match(text, "inputs.require_complete", fixed = TRUE)
  expect_match(
    text,
    paste(
      "task: count_structured_q1",
      "seed: 20260543",
      "include_in_all: false",
      sep = "\n            "
    ),
    fixed = TRUE
  )
})

test_that("Phase 18 workflow exposes bivariate Gaussian mu-slope task", {
  workflow <- testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
  testthat::skip_if_not(file.exists(workflow))
  text <- paste(readLines(workflow, warn = FALSE), collapse = "\n")

  expect_match(text, "biv_gaussian_mu_slope", fixed = TRUE)
  expect_match(text, "20260603", fixed = TRUE)
  expect_match(
    text,
    paste(
      "task: biv_gaussian_mu_slope",
      "seed: 20260603",
      "include_in_all: false",
      sep = "\n            "
    ),
    fixed = TRUE
  )
})

test_that("Phase 18 workflow exposes bivariate Gaussian q4 location task", {
  workflow <- testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
  testthat::skip_if_not(file.exists(workflow))
  text <- paste(readLines(workflow, warn = FALSE), collapse = "\n")

  expect_match(text, "biv_gaussian_q4_location", fixed = TRUE)
  expect_match(text, "20260609", fixed = TRUE)
  expect_match(
    text,
    paste(
      "task: biv_gaussian_q4_location",
      "seed: 20260609",
      "include_in_all: false",
      sep = "\n            "
    ),
    fixed = TRUE
  )
})

test_that("Phase 18 workflow exposes spatial mu-slope task", {
  workflow <- testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
  testthat::skip_if_not(file.exists(workflow))
  text <- paste(readLines(workflow, warn = FALSE), collapse = "\n")

  expect_match(text, "spatial_mu_slope", fixed = TRUE)
  expect_match(text, "20260604", fixed = TRUE)
  expect_match(
    text,
    paste(
      "task: spatial_mu_slope",
      "seed: 20260604",
      "include_in_all: false",
      sep = "\n            "
    ),
    fixed = TRUE
  )
})

test_that("Phase 18 workflow exposes non-spatial structured mu-slope tasks", {
  workflow <- testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
  testthat::skip_if_not(file.exists(workflow))
  text <- paste(readLines(workflow, warn = FALSE), collapse = "\n")

  expected <- c(
    phylo_mu_slope = "20260605",
    animal_mu_slope = "20260606",
    relmat_mu_slope = "20260607"
  )
  for (task in names(expected)) {
    expect_match(text, task, fixed = TRUE)
    expect_match(text, expected[[task]], fixed = TRUE)
    expect_match(
      text,
      paste(
        paste0("task: ", task),
        paste0("seed: ", expected[[task]]),
        "include_in_all: false",
        sep = "\n            "
      ),
      fixed = TRUE
    )
  }
})

test_that("Phase 18 workflow exposes correlation-block status task", {
  workflow <- testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
  testthat::skip_if_not(file.exists(workflow))
  text <- paste(readLines(workflow, warn = FALSE), collapse = "\n")

  expect_match(text, "correlation_block_status", fixed = TRUE)
  expect_match(text, "20260608", fixed = TRUE)
  expect_match(
    text,
    paste(
      "task: correlation_block_status",
      "seed: 20260608",
      "include_in_all: false",
      sep = "\n            "
    ),
    fixed = TRUE
  )
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
