source_phase18_biv_rho12_grid_writer <- function(env = parent.frame()) {
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
    system.file(
      "sim/R/sim_uncertainty.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_biv_rho12.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_biv_rho12.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_biv_rho12_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_summary_biv_rho12_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_biv_rho12_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 bivariate rho12 grid writer creates table artifacts", {
  source_phase18_biv_rho12_grid_writer()
  output_dir <- tempfile("phase18-biv-rho12-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_biv_rho12_conditions(
    n = 180L,
    delta0 = atanh(0.20),
    delta1 = 0.20,
    sigma_ratio = 1.1,
    rho_xw = 0.1
  )

  out <- phase18_write_biv_rho12_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 218L
  )

  expect_equal(out$surface, "biv_rho12_grid")
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 10L)
  expect_equal(nrow(out$summary$aggregate), 10L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 10L)
  expect_error(
    phase18_write_biv_rho12_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 218L
    ),
    "already exists"
  )
  expect_silent(phase18_write_biv_rho12_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 218L,
    overwrite = TRUE
  ))
})
