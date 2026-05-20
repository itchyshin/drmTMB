source_phase18_random_slope_grid_writers <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_gaussian_mu_random_slope.R",
    "sim/dgp/sim_dgp_gaussian_sigma_random_slope.R",
    "sim/dgp/sim_dgp_spatial_mu_slope.R",
    "sim/fit/sim_summarise_gaussian_mu_random_slope.R",
    "sim/fit/sim_summarise_gaussian_sigma_random_slope.R",
    "sim/fit/sim_summarise_spatial_mu_slope.R",
    "sim/run/sim_run_gaussian_mu_random_slope_smoke.R",
    "sim/run/sim_run_gaussian_sigma_random_slope_smoke.R",
    "sim/run/sim_run_spatial_mu_slope_smoke.R",
    "sim/run/sim_summary_gaussian_mu_random_slope_smoke.R",
    "sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R",
    "sim/run/sim_summary_spatial_mu_slope_smoke.R",
    "sim/run/sim_write_gaussian_mu_random_slope_grid.R",
    "sim/run/sim_write_gaussian_sigma_random_slope_grid.R",
    "sim/run/sim_write_spatial_mu_slope_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 simple random-slope grid writers create artifacts", {
  source_phase18_random_slope_grid_writers()
  mu_dir <- tempfile("phase18-gaussian-mu-rs-grid-")
  sigma_dir <- tempfile("phase18-gaussian-sigma-rs-grid-")
  spatial_dir <- tempfile("phase18-spatial-mu-slope-grid-")
  withr::defer(unlink(mu_dir, recursive = TRUE))
  withr::defer(unlink(sigma_dir, recursive = TRUE))
  withr::defer(unlink(spatial_dir, recursive = TRUE))

  mu <- phase18_write_gaussian_mu_rs_grid_outputs(
    output_dir = mu_dir,
    conditions = phase18_gaussian_mu_rs_conditions(
      n_group = 24L,
      n_per_group = 7L
    ),
    n_rep = 1L,
    master_seed = 231L,
    cores = 10L
  )
  sigma <- phase18_write_gaussian_sigma_rs_grid_outputs(
    output_dir = sigma_dir,
    conditions = phase18_gaussian_sigma_rs_conditions(
      n_group = 32L,
      n_per_group = 8L
    ),
    n_rep = 1L,
    master_seed = 232L,
    cores = 10L
  )
  spatial <- phase18_write_spatial_mu_slope_grid_outputs(
    output_dir = spatial_dir,
    conditions = phase18_spatial_mu_slope_conditions(
      n_site = 12L,
      n_each = 8L
    ),
    n_rep = 1L,
    master_seed = 233L,
    cores = 10L
  )

  expect_equal(mu$surface, "gaussian_mu_random_slope_grid")
  expect_equal(sigma$surface, "gaussian_sigma_random_slope_grid")
  expect_equal(spatial$surface, "spatial_mu_slope_grid")
  expect_equal(mu$summary$run$parallel$requested_cores, 10L)
  expect_equal(sigma$summary$run$parallel$requested_cores, 10L)
  expect_equal(spatial$summary$run$parallel$requested_cores, 10L)
  expect_equal(mu$summary$run$parallel$cores, 1L)
  expect_equal(sigma$summary$run$parallel$cores, 1L)
  expect_equal(spatial$summary$run$parallel$cores, 1L)
  expect_true(all(mu$artifact_manifest$exists))
  expect_true(all(sigma$artifact_manifest$exists))
  expect_true(all(spatial$artifact_manifest$exists))
  expect_true(all(file.exists(unlist(mu$paths, use.names = FALSE))))
  expect_true(all(file.exists(unlist(sigma$paths, use.names = FALSE))))
  expect_true(all(file.exists(unlist(spatial$paths, use.names = FALSE))))
  expect_equal(nrow(mu$summary$replicates), 10L)
  expect_equal(nrow(sigma$summary$replicates), 5L)
  expect_equal(nrow(spatial$summary$replicates), 5L)
  expect_equal(nrow(utils::read.csv(mu$paths$replicate_csv)), 10L)
  expect_equal(nrow(utils::read.csv(sigma$paths$replicate_csv)), 5L)
  expect_equal(nrow(utils::read.csv(spatial$paths$replicate_csv)), 5L)
  expect_error(
    phase18_write_gaussian_mu_rs_grid_outputs(
      output_dir = mu_dir,
      conditions = phase18_gaussian_mu_rs_conditions(
        n_group = 24L,
        n_per_group = 7L
      ),
      n_rep = 1L,
      master_seed = 231L
    ),
    "already exists"
  )
})

test_that("Phase 18 simple random-slope grid writers validate inputs", {
  source_phase18_random_slope_grid_writers()

  expect_error(
    phase18_write_gaussian_mu_rs_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_gaussian_sigma_rs_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
  expect_error(
    phase18_write_spatial_mu_slope_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})
