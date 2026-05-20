source_phase18_count_mu_re_grid_writer <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
    "sim/dgp/sim_dgp_nbinom2_mu_random_effect.R",
    "sim/fit/sim_summarise_poisson_mu_random_effect.R",
    "sim/fit/sim_summarise_nbinom2_mu_random_effect.R",
    "sim/run/sim_run_poisson_mu_random_effect_smoke.R",
    "sim/run/sim_run_nbinom2_mu_random_effect_smoke.R",
    "sim/run/sim_summary_poisson_mu_random_effect_smoke.R",
    "sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R",
    "sim/run/sim_summary_count_mu_random_effect_pilot.R",
    "sim/run/sim_write_count_mu_random_effect_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 count mu random-effect grid writer creates artifacts", {
  source_phase18_count_mu_re_grid_writer()
  output_dir <- tempfile("phase18-count-mu-re-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_count_mu_re_grid_outputs(
    output_dir = output_dir,
    poisson_conditions = phase18_poisson_mu_re_conditions(
      n_group = 36L,
      n_per_group = 9L
    ),
    nbinom2_conditions = phase18_nbinom2_mu_re_conditions(
      n_group = 44L,
      n_per_group = 10L
    ),
    n_rep = 1L,
    master_seed = 230L,
    cores = 10L
  )

  expect_equal(out$surface, "count_mu_random_effect_grid")
  expect_equal(out$summary$poisson$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$poisson$run$parallel$cores, 1L)
  expect_equal(out$summary$nbinom2$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$nbinom2$run$parallel$cores, 1L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$aggregate), 10L)
  expect_equal(nrow(out$summary$replicates), 10L)
  expect_equal(nrow(out$summary$manifest), 2L)
  expect_equal(nrow(utils::read.csv(out$paths$wald_intervals_csv)), 10L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_intervals_csv)), 4L)
  expect_setequal(
    unique(out$summary$aggregate$surface),
    c("poisson_mu_random_effect", "nbinom2_mu_random_effect")
  )
  expect_error(
    phase18_write_count_mu_re_grid_outputs(
      output_dir = output_dir,
      poisson_conditions = phase18_poisson_mu_re_conditions(
        n_group = 36L,
        n_per_group = 9L
      ),
      nbinom2_conditions = phase18_nbinom2_mu_re_conditions(
        n_group = 44L,
        n_per_group = 10L
      ),
      n_rep = 1L,
      master_seed = 230L
    ),
    "already exists"
  )
})

test_that("Phase 18 count mu random-effect grid writer validates inputs", {
  source_phase18_count_mu_re_grid_writer()

  expect_error(
    phase18_write_count_mu_re_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_count_mu_re_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})
