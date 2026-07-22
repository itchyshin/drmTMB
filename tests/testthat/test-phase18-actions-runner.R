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

test_that("Phase 18 Actions runner accepts binomial fixed-effect task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-binomial-fe-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=binomial_fixed_effect",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=binomial_fixed_effect", fixed = TRUE)
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

test_that("Phase 18 Actions runner accepts skew-normal fixed-effect task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-skew-normal-fe-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=skew_normal_fixed_effect",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--profile-parameters=nu:w",
      "--bootstrap-nsim=2",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=skew_normal_fixed_effect", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
  expect_match(out, "profile_parameters=nu:w", fixed = TRUE)
  expect_match(out, "bootstrap_nsim=2", fixed = TRUE)
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

test_that("Phase 18 Actions runner sources binomial task dependencies", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  binomial_paths <- c(
    "sim/dgp/sim_dgp_binomial_fixed_effect.R",
    "sim/fit/sim_summarise_binomial_fixed_effect.R",
    "sim/run/sim_run_binomial_fixed_effect_smoke.R",
    "sim/run/sim_summary_binomial_fixed_effect_smoke.R",
    "sim/run/sim_write_binomial_fixed_effect_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("binomial_fixed_effect"),
    binomial_paths
  )
})

test_that("Phase 18 Actions runner sources skew-normal task dependencies", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  skew_normal_paths <- c(
    "sim/dgp/sim_dgp_skew_normal_fixed_effect.R",
    "sim/fit/sim_summarise_skew_normal_fixed_effect.R",
    "sim/run/sim_run_skew_normal_fixed_effect_smoke.R",
    "sim/run/sim_summary_skew_normal_fixed_effect_smoke.R",
    "sim/run/sim_write_skew_normal_fixed_effect_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("skew_normal_fixed_effect"),
    skew_normal_paths
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

test_that("Phase 18 Actions runner accepts bivariate Gaussian q6 location task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-biv-gaussian-q6-location-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=biv_gaussian_q6_location",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=biv_gaussian_q6_location", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner sources bivariate Gaussian q6 location task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  paths <- c(
    "sim/dgp/sim_dgp_biv_gaussian_q6_location.R",
    "sim/fit/sim_summarise_biv_gaussian_q6_location.R",
    "sim/run/sim_run_biv_gaussian_q6_location_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q6_location_smoke.R",
    "sim/run/sim_write_biv_gaussian_q6_location_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("biv_gaussian_q6_location"),
    paths
  )
})

test_that("Phase 18 Actions runner dispatches bivariate Gaussian q6 location task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  env$phase18_actions_load_package <- function() {
    invisible(TRUE)
  }
  env$phase18_actions_source_dependencies <- function(task) {
    invisible(task)
  }
  env$phase18_write_biv_gaussian_q6_location_grid_outputs <- function(...) {
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

  output_dir <- tempfile("phase18-actions-biv-gaussian-q6-location-run-")
  out <- capture.output(
    env$phase18_actions_main(
      c(
        "--task=biv_gaussian_q6_location",
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

  expect_match(out, "task=biv_gaussian_q6_location", fixed = TRUE)
  expect_true(result$ok)
  expect_equal(result$n_rep, 1L)
  expect_equal(result$master_seed, 241L)
  expect_equal(result$backend, "none")
  expect_equal(result$cores, 1L)
})

test_that("Phase 18 Actions runner accepts bivariate Gaussian q8 endpoint tasks", {
  script <- phase18_actions_runner_script()
  tasks <- c(
    "biv_gaussian_q8_endpoint",
    "biv_gaussian_q8_endpoint_recovery",
    "biv_gaussian_q8_endpoint_staged_diagnostic"
  )

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

test_that("Phase 18 Actions runner sources bivariate Gaussian q8 endpoint tasks", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  smoke_paths <- c(
    "sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R",
    "sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R",
    "sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_write_biv_gaussian_q8_endpoint_grid.R"
  )
  recovery_paths <- c(
    "sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R",
    "sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R",
    "sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q8_endpoint_recovery.R",
    "sim/run/sim_write_biv_gaussian_q8_endpoint_recovery_grid.R"
  )
  staged_paths <- c(
    "sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R",
    "sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("biv_gaussian_q8_endpoint"),
    smoke_paths
  )
  expect_equal(
    env$phase18_actions_task_paths("biv_gaussian_q8_endpoint_recovery"),
    recovery_paths
  )
  expect_equal(
    env$phase18_actions_task_paths(
      "biv_gaussian_q8_endpoint_staged_diagnostic"
    ),
    staged_paths
  )
})

test_that("Phase 18 Actions runner dispatches bivariate Gaussian q8 endpoint tasks", {
  script <- phase18_actions_runner_script()
  writers <- c(
    biv_gaussian_q8_endpoint = "phase18_write_biv_gaussian_q8_endpoint_grid_outputs",
    biv_gaussian_q8_endpoint_recovery = "phase18_write_biv_gaussian_q8_endpoint_recovery_grid_outputs",
    biv_gaussian_q8_endpoint_staged_diagnostic = "phase18_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid_outputs"
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
          "--master-seed=243",
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
    expect_equal(result$master_seed, 243L)
    expect_equal(result$backend, "none")
    expect_equal(result$cores, 1L)
  }
})

test_that("Phase 18 Actions runner accepts bivariate Gaussian q2 scale task", {
  script <- phase18_actions_runner_script()
  output_dir <- tempfile("phase18-actions-biv-gaussian-q2-scale-dry-run-")
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      "--vanilla",
      shQuote(script),
      "--task=biv_gaussian_q2_scale",
      paste0("--output-dir=", output_dir),
      "--n-reps=2",
      "--master-seed=123",
      "--dry-run=true"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  out <- paste(out, collapse = "\n")

  expect_match(out, "task=biv_gaussian_q2_scale", fixed = TRUE)
  expect_match(out, "n_rep=2", fixed = TRUE)
})

test_that("Phase 18 Actions runner sources bivariate Gaussian q2 scale task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  paths <- c(
    "sim/dgp/sim_dgp_biv_gaussian_q2_scale.R",
    "sim/fit/sim_summarise_biv_gaussian_q2_scale.R",
    "sim/run/sim_run_biv_gaussian_q2_scale_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q2_scale_smoke.R",
    "sim/run/sim_write_biv_gaussian_q2_scale_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("biv_gaussian_q2_scale"),
    paths
  )
  slope_paths <- c(
    "sim/dgp/sim_dgp_biv_gaussian_q2_scale_slope.R",
    "sim/fit/sim_summarise_biv_gaussian_q2_scale_slope.R",
    "sim/run/sim_run_biv_gaussian_q2_scale_slope_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q2_scale_slope_smoke.R",
    "sim/run/sim_write_biv_gaussian_q2_scale_slope_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("biv_gaussian_q2_scale_slope"),
    slope_paths
  )
  slope_recovery_paths <- c(
    "sim/dgp/sim_dgp_biv_gaussian_q2_scale_slope.R",
    "sim/fit/sim_summarise_biv_gaussian_q2_scale_slope.R",
    "sim/run/sim_run_biv_gaussian_q2_scale_slope_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q2_scale_slope_recovery.R",
    "sim/run/sim_write_biv_gaussian_q2_scale_slope_recovery_grid.R"
  )
  expect_equal(
    env$phase18_actions_task_paths("biv_gaussian_q2_scale_slope_recovery"),
    slope_recovery_paths
  )
})

test_that("Phase 18 Actions runner dispatches bivariate Gaussian q2 scale task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  env$phase18_actions_load_package <- function() {
    invisible(TRUE)
  }
  env$phase18_actions_source_dependencies <- function(task) {
    invisible(task)
  }
  env$phase18_write_biv_gaussian_q2_scale_grid_outputs <- function(...) {
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

  output_dir <- tempfile("phase18-actions-biv-gaussian-q2-scale-run-")
  out <- capture.output(
    env$phase18_actions_main(
      c(
        "--task=biv_gaussian_q2_scale",
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

  expect_match(out, "task=biv_gaussian_q2_scale", fixed = TRUE)
  expect_true(result$ok)
  expect_equal(result$n_rep, 1L)
  expect_equal(result$master_seed, 241L)
  expect_equal(result$backend, "none")
  expect_equal(result$cores, 1L)
})

test_that("Phase 18 Actions runner dispatches bivariate Gaussian q2 scale-slope task", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  env$phase18_actions_load_package <- function() {
    invisible(TRUE)
  }
  env$phase18_actions_source_dependencies <- function(task) {
    invisible(task)
  }
  env$phase18_write_biv_gaussian_q2_scale_slope_grid_outputs <- function(...) {
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

  output_dir <- tempfile("phase18-actions-biv-gaussian-q2-scale-slope-run-")
  out <- capture.output(
    env$phase18_actions_main(
      c(
        "--task=biv_gaussian_q2_scale_slope",
        paste0("--output-dir=", output_dir),
        "--n-reps=1",
        "--master-seed=242",
        "--backend=none",
        "--cores=1"
      )
    )
  )
  out <- paste(out, collapse = "\n")
  result <- readRDS(file.path(output_dir, "phase18-actions-result.rds"))

  expect_match(out, "task=biv_gaussian_q2_scale_slope", fixed = TRUE)
  expect_true(result$ok)
  expect_equal(result$n_rep, 1L)
  expect_equal(result$master_seed, 242L)
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

# The campaign matrix these tests used to assert was removed by commit e159959b
# under decision D-50: simulation / recovery / power / coverage campaigns run on
# Totoro or the DRAC clusters, never on GitHub Actions, and campaign outputs are
# never stored as Actions artifacts. The workflow was deliberately kept as a
# documented stub rather than deleted, so `skip_if_not(file.exists())` never
# fires and the old content assertions could not pass.
#
# They are INVERTED rather than deleted: each guard below fails if campaign
# compute returns to Actions. Substrings are ASCII-only on purpose -- the stub
# contains U+2014 em dashes, and asserting on those would couple the suite to
# locale and encoding under R CMD check.

phase18_workflow_path <- function() {
  testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
}

test_that("Phase 18 simulation workflow remains a disabled stub (D-50)", {
  workflow <- phase18_workflow_path()
  testthat::skip_if_not(file.exists(workflow))
  text <- paste(readLines(workflow, warn = FALSE), collapse = "\n")

  # The stub still declares itself.
  for (marker in c(
    "DISABLED STUB",
    "D-50",
    "name: phase18-simulation-grid (disabled",
    "Totoro",
    "DRAC",
    "workflow_dispatch:"
  )) {
    expect_true(grepl(marker, text, fixed = TRUE), info = marker)
  }

  # The campaign dispatch surface is gone.
  for (needle in c(
    "inputs.condition_shard",
    "inputs.condition_shards",
    "inputs.condition_set",
    "inputs.profile_level",
    "inputs.require_complete",
    "--condition-set=",
    "--profile-level=",
    "--require-complete=",
    "condition_set:",
    "profile_level:",
    "require_complete:",
    "n_reps:",
    "include_in_all:"
  )) {
    expect_false(grepl(needle, text, fixed = TRUE), info = needle)
  }

  # No compute and no artifact storage -- the substantive half of D-50.
  for (needle in c(
    "strategy:",
    "matrix:",
    "actions/upload-artifact",
    "Rscript",
    "sim_run_actions_cell.R",
    "inst/sim/results"
  )) {
    expect_false(grepl(needle, text, fixed = TRUE), info = needle)
  }

  # The pinned campaign seeds are gone from Actions. Note this asserts only
  # their ABSENCE here; the authoritative task-to-seed bindings live in
  # inst/sim/registry/ and are guarded separately.
  for (seed in c(
    "20260542",
    "20260543",
    "20260603",
    "20260604",
    "20260605",
    "20260606",
    "20260607",
    "20260608",
    "20260609",
    "20260624",
    "20260625",
    "20260627"
  )) {
    expect_false(grepl(seed, text, fixed = TRUE), info = seed)
  }

  # No task is dispatchable. Driven off the runner rather than hardcoded, so a
  # task added to the runner later is covered automatically -- unlike the ten
  # per-task blocks this replaces.
  env <- new.env(parent = globalenv())
  source(phase18_actions_runner_script(), local = env)
  for (task in env$phase18_actions_task_choices()) {
    expect_false(grepl(paste0("task: ", task), text, fixed = TRUE), info = task)
  }
})

test_that("No GitHub Actions workflow runs simulation campaigns (D-50)", {
  # Filename-independent. A well-meaning restoration would most likely arrive as
  # a NEW workflow file, which a guard keyed to one filename would never see.
  dir <- testthat::test_path("..", "..", ".github", "workflows")
  testthat::skip_if_not(dir.exists(dir))
  files <- list.files(dir, pattern = "\\.ya?ml$", full.names = TRUE)
  expect_gt(length(files), 0L)

  for (f in files) {
    text <- paste(readLines(f, warn = FALSE), collapse = "\n")
    for (needle in c(
      "sim_run_actions_cell.R",
      "inst/sim/run/",
      "inst/sim/results"
    )) {
      expect_false(
        grepl(needle, text, fixed = TRUE),
        info = paste(basename(f), needle)
      )
    }
  }
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

test_that("Phase 18 workflow dispatch options match the runner task choices", {
  workflow <- testthat::test_path(
    "..",
    "..",
    ".github",
    "workflows",
    "phase18-simulation-grid.yaml"
  )
  testthat::skip_if_not(file.exists(workflow))
  lines <- readLines(workflow, warn = FALSE)

  # Dormant, not wrong. While the workflow is a D-50 disabled stub there is no
  # dispatch surface to couple to the runner, so this guard has nothing to
  # check. It is preserved rather than inverted or deleted: it re-arms by
  # itself the day the stub marker goes away, which is exactly when the
  # coupling matters again.
  testthat::skip_if(
    any(grepl("DISABLED STUB", lines, fixed = TRUE)),
    "phase18 workflow is a D-50 disabled stub; no dispatch surface to couple"
  )

  # Extract the `task:` choice input's options block (the indented list items
  # immediately under the first `options:` after the `task:` input key).
  task_line <- grep("^      task:\\s*$", lines)[[1L]]
  options_lines <- grep("^        options:\\s*$", lines)
  options_start <- options_lines[options_lines > task_line][[1L]]
  i <- options_start + 1L
  opts <- character()
  while (i <= length(lines) && grepl("^          - ", lines[[i]])) {
    opts <- c(opts, trimws(sub("^          - ", "", lines[[i]])))
    i <- i + 1L
  }

  env <- new.env(parent = globalenv())
  source(phase18_actions_runner_script(), local = env)

  # Every dispatchable task (other than the aggregate "all") must be a
  # selectable workflow_dispatch option, and vice versa. This guards against a
  # task being added to the runner/matrix but left unselectable in the workflow
  # (which is exactly how the recovery lanes were briefly undispatchable).
  expect_setequal(setdiff(opts, "all"), env$phase18_actions_task_choices())
})

test_that("Phase 18 Actions runner accepts the power tasks via dry-run", {
  script <- phase18_actions_runner_script()
  for (task in c("gaussian_ls_power", "meta_v_power", "poisson_mu_re_power")) {
    output_dir <- tempfile(paste0("phase18-actions-", task, "-dry-run-"))
    out <- system2(
      file.path(R.home("bin"), "Rscript"),
      c(
        "--vanilla",
        shQuote(script),
        paste0("--task=", task),
        paste0("--output-dir=", output_dir),
        "--n-reps=5",
        "--master-seed=20260610",
        "--dry-run=true"
      ),
      stdout = TRUE,
      stderr = TRUE
    )
    out <- paste(out, collapse = "\n")
    expect_match(out, paste0("task=", task), fixed = TRUE)
    expect_match(out, "n_rep=5", fixed = TRUE)
  }
})

test_that("Phase 18 Actions runner sources power task dependencies", {
  script <- phase18_actions_runner_script()
  env <- new.env(parent = globalenv())
  source(script, local = env)

  expect_true(all(
    c("gaussian_ls_power", "meta_v_power", "poisson_mu_re_power") %in%
      env$phase18_actions_task_choices()
  ))
  expect_equal(
    env$phase18_actions_task_paths("gaussian_ls_power"),
    c(
      "sim/R/sim_power.R",
      "sim/dgp/sim_dgp_gaussian_ls.R",
      "sim/fit/sim_summarise_gaussian_ls.R",
      "sim/run/sim_run_gaussian_ls_smoke.R",
      "sim/run/sim_run_power_grid.R",
      "sim/run/sim_run_gaussian_ls_power_smoke.R",
      "sim/run/sim_write_power_grid.R"
    )
  )
  expect_equal(
    env$phase18_actions_task_paths("meta_v_power"),
    c(
      "sim/R/sim_power.R",
      "sim/dgp/sim_dgp_meta_v.R",
      "sim/fit/sim_summarise_meta_v.R",
      "sim/run/sim_run_meta_v_smoke.R",
      "sim/run/sim_run_power_grid.R",
      "sim/run/sim_run_meta_v_power_smoke.R",
      "sim/run/sim_write_power_grid.R"
    )
  )
})
