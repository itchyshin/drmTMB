source_phase18_animal_relmat_q2_grid_writer <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_animal_relmat_q2.R",
    "sim/fit/sim_summarise_animal_relmat_q2.R",
    "sim/run/sim_run_animal_relmat_q2_smoke.R",
    "sim/run/sim_summary_animal_relmat_q2_smoke.R",
    "sim/run/sim_write_animal_relmat_q2_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 animal/relmat q2 grid writer creates artifacts", {
  source_phase18_animal_relmat_q2_grid_writer()
  output_dir <- tempfile("phase18-animal-relmat-q2-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_animal_relmat_q2_conditions(
    structured_surface = c("animal", "relmat"),
    matrix_argument = c("precision", "pedigree"),
    n_level = 10L,
    n_per_level = 6L
  )

  out <- phase18_write_animal_relmat_q2_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 241L,
    cores = 10L
  )

  expect_equal(out$surface, "animal_relmat_q2_grid")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(all(out$artifact_manifest$exists))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 30L)
  expect_equal(nrow(out$summary$aggregate), 30L)
  expect_equal(nrow(out$summary$manifest), 3L)
  expect_equal(nrow(out$summary$failures), 0L)
  expect_equal(nrow(out$summary$wald_intervals), 12L)
  expect_equal(nrow(out$summary$wald_coverage), 12L)
  expect_equal(nrow(out$summary$profile_intervals), 18L)
  expect_equal(nrow(out$summary$profile_coverage), 0L)
  expect_equal(nrow(out$summary$interval_evidence), 30L)
  expect_equal(nrow(out$summary$interval_diagnostics), 30L)
  expect_equal(nrow(out$summary$interval_failures), 18L)
  expect_setequal(
    unique(out$summary$replicates$matrix_argument),
    c("pedigree", "precision")
  )
  expect_true(all(out$summary$wald_intervals$interval_status == "ok"))
  expect_true(
    all(out$summary$profile_intervals$interval_status == "not_requested")
  )
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 30L)
  expect_equal(nrow(utils::read.csv(out$paths$aggregate_csv)), 30L)
  expect_equal(nrow(utils::read.csv(out$paths$manifest_csv)), 3L)
  expect_equal(nrow(utils::read.csv(out$paths$failures_csv)), 0L)
  expect_equal(nrow(utils::read.csv(out$paths$wald_intervals_csv)), 12L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_intervals_csv)), 18L)
  expect_equal(nrow(utils::read.csv(out$paths$interval_evidence_csv)), 30L)
  expect_error(
    phase18_write_animal_relmat_q2_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 241L
    ),
    "already exists"
  )
})

test_that("Phase 18 animal/relmat q2 grid writer records opt-in profile evidence", {
  skip_on_cran()
  source_phase18_animal_relmat_q2_grid_writer()
  output_dir <- tempfile("phase18-animal-relmat-q2-profile-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_animal_relmat_q2_conditions(
    structured_surface = "animal",
    matrix_argument = "precision",
    n_level = 10L,
    n_per_level = 6L
  )

  out <- phase18_write_animal_relmat_q2_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 251L,
    profile_parameters = c("animal:sd1", "animal:cor", "rho12"),
    profile_level = 0.70,
    profile_args = list(ystep = 1.00)
  )

  requested <- out$summary$profile_intervals[
    out$summary$profile_intervals$parameter %in%
      c("animal:sd1", "animal:cor", "rho12"),
    ,
    drop = FALSE
  ]

  expect_equal(nrow(out$summary$replicates), 10L)
  expect_equal(nrow(out$summary$wald_intervals), 4L)
  expect_equal(nrow(out$summary$profile_intervals), 6L)
  expect_equal(nrow(requested), 3L)
  expect_true(
    all(requested$interval_status %in% c("ok", "failed"))
  )
  expect_equal(
    unique(requested$interval_method),
    "profile"
  )
  expect_equal(nrow(out$summary$profile_coverage), 3L)
  expect_setequal(
    unique(out$summary$interval_evidence$interval_method),
    c("wald", "profile")
  )
})

test_that("Phase 18 animal/relmat q2 grid writer validates inputs", {
  source_phase18_animal_relmat_q2_grid_writer()

  expect_error(
    phase18_write_animal_relmat_q2_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_animal_relmat_q2_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})
