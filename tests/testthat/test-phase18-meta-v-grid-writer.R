source_phase18_meta_v_grid_writer <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_meta_v_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_summary_meta_v_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_meta_v_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 meta_V grid writer creates table artifacts", {
  source_phase18_meta_v_grid_writer()
  output_dir <- tempfile("phase18-meta-v-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_meta_v_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_meta_v_conditions(
      n_study = 32L,
      known_v_type = c("vector", "dense"),
      sigma = 0.25,
      sampling_sd = 0.14,
      sampling_rho = c(0, 0.20)
    ),
    n_rep = 1L,
    master_seed = 229L,
    cores = 10L
  )

  expect_equal(out$surface, "meta_v_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 9L)
  expect_equal(nrow(out$summary$aggregate), 9L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 9L)
  expect_equal(nrow(utils::read.csv(out$paths$wald_intervals_csv)), 9L)
  expect_equal(
    nrow(utils::read.csv(out$paths$finite_and_covering_rate_all_attempt_csv)),
    9L
  )
  expect_equal(
    nrow(utils::read.csv(out$paths$conditional_finite_interval_coverage_csv)),
    9L
  )
  expect_setequal(
    unique(out$summary$replicates$known_v_type),
    c("vector", "dense")
  )
  expect_error(
    phase18_write_meta_v_grid_outputs(
      output_dir = output_dir,
      conditions = phase18_meta_v_conditions(
        n_study = 32L,
        known_v_type = c("vector", "dense"),
        sigma = 0.25,
        sampling_sd = 0.14,
        sampling_rho = c(0, 0.20)
      ),
      n_rep = 1L,
      master_seed = 229L
    ),
    "already exists"
  )
  expect_silent(phase18_write_meta_v_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_meta_v_conditions(
      n_study = 32L,
      known_v_type = c("vector", "dense"),
      sigma = 0.25,
      sampling_sd = 0.14,
      sampling_rho = c(0, 0.20)
    ),
    n_rep = 1L,
    master_seed = 229L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 meta_V grid writer validates output inputs", {
  source_phase18_meta_v_grid_writer()

  expect_error(
    phase18_write_meta_v_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_meta_v_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})
