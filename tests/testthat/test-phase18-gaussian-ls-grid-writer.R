test_that("Phase 18 Gaussian location-scale grid writer saves all table grains", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_gaussian_ls_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_gaussian_ls_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_write_gaussian_ls_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  output_dir <- tempfile("phase18-gaussian-ls-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_gaussian_ls_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_gaussian_ls_conditions(
      n = 100L,
      sigma_slope = 0.20,
      collinearity = 0.10
    ),
    n_rep = 1L,
    master_seed = 307L,
    cores = 10L
  )

  expect_identical(out$surface, "gaussian_ls_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_equal(out$artifact_manifest$surface, rep(out$surface, length(out$paths)))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(read.csv(out$paths$aggregate_csv)), 4L)
  expect_equal(nrow(read.csv(out$paths$replicate_csv)), 4L)
  expect_equal(nrow(read.csv(out$paths$manifest_csv)), 1L)
  expect_equal(nrow(read.csv(out$paths$wald_intervals_csv)), 4L)
  expect_equal(nrow(read.csv(out$paths$wald_coverage_csv)), 4L)
  expect_equal(
    read.csv(out$paths$aggregate_csv)$artifact_grain,
    rep("aggregate", 4L)
  )
  expect_equal(
    read.csv(out$paths$replicate_csv)$artifact_grain,
    rep("replicate", 4L)
  )
  expect_error(
    phase18_write_gaussian_ls_grid_outputs(
      output_dir = output_dir,
      conditions = phase18_gaussian_ls_conditions(
        n = 100L,
        sigma_slope = 0.20,
        collinearity = 0.10
      ),
      n_rep = 1L,
      master_seed = 307L
    ),
    "already exists"
  )
})

test_that("Phase 18 Gaussian location-scale grid writer validates output inputs", {
  source(
    system.file(
      "sim/run/sim_write_gaussian_ls_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(
    phase18_write_gaussian_ls_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_gaussian_ls_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})
