source_phase18_student_shape_grid_writer <- function(env = parent.frame()) {
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
      "sim/dgp/sim_dgp_student_shape.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_student_shape.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_student_shape_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_summary_student_shape_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_student_shape_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 Student-t shape grid writer creates table artifacts", {
  source_phase18_student_shape_grid_writer()
  output_dir <- tempfile("phase18-student-shape-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_student_shape_conditions(
    n = 240L,
    nu_intercept = log(6),
    nu_slope = 0.20,
    sigma_slope = 0.20,
    rho_xw = 0.1
  )

  out <- phase18_write_student_shape_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 221L
  )

  expect_equal(out$surface, "student_shape_grid")
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 6L)
  expect_equal(nrow(out$summary$aggregate), 6L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 6L)
  expect_error(
    phase18_write_student_shape_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 221L
    ),
    "already exists"
  )
  expect_silent(phase18_write_student_shape_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 221L,
    overwrite = TRUE
  ))
})
