source_phase18_animal_relmat_q4_grid_writer <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_animal_relmat_q4.R",
    "sim/fit/sim_summarise_animal_relmat_q4.R",
    "sim/run/sim_run_animal_relmat_q4_smoke.R",
    "sim/run/sim_summary_animal_relmat_q4_smoke.R",
    "sim/run/sim_write_animal_relmat_q4_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 animal/relmat q4 grid writer creates artifacts", {
  skip_on_cran()
  source_phase18_animal_relmat_q4_grid_writer()
  output_dir <- tempfile("phase18-animal-relmat-q4-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_animal_relmat_q4_conditions(
    structured_surface = "relmat",
    matrix_argument = "precision",
    n_level = 12L,
    n_per_level = 7L
  )

  out <- phase18_write_animal_relmat_q4_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 261L,
    profile_parameters = "relmat:cor_mu1_mu2",
    cores = 10L
  )

  expect_equal(out$surface, "animal_relmat_q4_grid")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(all(out$artifact_manifest$exists))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 19L)
  expect_equal(nrow(out$summary$aggregate), 19L)
  expect_equal(nrow(out$summary$manifest), 1L)
  expect_equal(nrow(out$summary$failures), 0L)
  expect_equal(nrow(out$summary$wald_intervals), 0L)
  expect_equal(nrow(out$summary$wald_coverage), 0L)
  expect_equal(nrow(out$summary$profile_intervals), 19L)
  expect_equal(nrow(out$summary$profile_coverage), 1L)
  expect_equal(nrow(out$summary$interval_evidence), 19L)
  expect_equal(nrow(out$summary$interval_diagnostics), 19L)
  expect_equal(nrow(out$summary$interval_failures), 19L)
  expect_equal(
    out$summary$profile_intervals$profile.status[
      out$summary$profile_intervals$parameter == "relmat:cor_mu1_mu2"
    ],
    "derived_interval_unavailable"
  )
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 19L)
  expect_equal(nrow(utils::read.csv(out$paths$aggregate_csv)), 19L)
  expect_equal(nrow(utils::read.csv(out$paths$manifest_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$failures_csv)), 0L)
  expect_true(file.exists(out$paths$wald_intervals_csv))
  expect_equal(nrow(utils::read.csv(out$paths$profile_intervals_csv)), 19L)
  expect_equal(nrow(utils::read.csv(out$paths$interval_evidence_csv)), 19L)
  expect_error(
    phase18_write_animal_relmat_q4_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 261L
    ),
    "already exists"
  )
})

test_that("Phase 18 animal/relmat q4 grid writer validates inputs", {
  source_phase18_animal_relmat_q4_grid_writer()

  expect_error(
    phase18_write_animal_relmat_q4_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_animal_relmat_q4_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})
