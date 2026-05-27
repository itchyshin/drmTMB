source_phase18_truncated_nbinom2_mu_ri <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_truncated_nbinom2_mu_random_intercept.R",
    "sim/fit/sim_summarise_truncated_nbinom2_mu_random_intercept.R",
    "sim/run/sim_run_truncated_nbinom2_mu_random_intercept_smoke.R",
    "sim/run/sim_summary_truncated_nbinom2_mu_random_intercept_smoke.R",
    "sim/run/sim_write_truncated_nbinom2_mu_random_intercept_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 truncated NB2 mu random-intercept DGP is positive", {
  source_phase18_truncated_nbinom2_mu_ri()

  dat <- phase18_dgp_truncated_nbinom2_mu_ri(
    n_group = 16L,
    n_per_group = 5L,
    seed = 1389L
  )

  expect_equal(length(unique(dat$id)), 16L)
  expect_type(dat$count, "integer")
  expect_true(all(dat$count > 0))
  expect_true(all(dat$mu > 0))
  expect_true(all(dat$sigma > 0))
  expect_equal(dat$fitted_mean, dat$mu / (1 - dat$p0))
  expect_equal(
    attr(dat, "truth")$surface,
    "truncated_nbinom2_mu_random_intercept"
  )
  expect_named(attr(dat, "truth")$sd, "(1 | id)")
})

test_that("Phase 18 truncated NB2 mu random-intercept smoke returns artifacts", {
  source_phase18_truncated_nbinom2_mu_ri()
  conditions <- phase18_truncated_nbinom2_mu_ri_conditions(
    n_group = 28L,
    n_per_group = 8L,
    beta_sigma_intercept = -0.65,
    beta_sigma_z = 0.15,
    sd_intercept = c(0.30, 0.45)
  )

  summary <- phase18_summarise_truncated_nbinom2_mu_ri_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2071L
  )

  expect_equal(summary$surface, "truncated_nbinom2_mu_random_intercept")
  expect_equal(nrow(summary$replicates), 10L)
  expect_equal(nrow(summary$aggregate), 10L)
  expect_equal(nrow(summary$manifest), 2L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 10L)
  expect_equal(nrow(summary$wald_coverage), 8L)
  expect_equal(nrow(summary$profile_intervals), 2L)
  expect_setequal(
    unique(summary$replicates$parameter_class),
    c("fixed_mu", "fixed_sigma", "random_sd")
  )
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 10L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 10L))
  expect_true(all(summary$manifest$status == "ok"))
  expect_equal(summary$profile_intervals$interval_scale, rep("public_sd", 2L))
})

test_that("Phase 18 truncated NB2 mu random-intercept grid writer creates artifacts", {
  source_phase18_truncated_nbinom2_mu_ri()
  output_dir <- tempfile("phase18-truncated-nb2-mu-ri-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_truncated_nbinom2_mu_ri_conditions(
    n_group = 28L,
    n_per_group = 8L,
    beta_sigma_intercept = -0.65,
    beta_sigma_z = 0.15,
    sd_intercept = c(0.30, 0.45)
  )

  out <- phase18_write_truncated_nbinom2_mu_ri_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2072L,
    cores = 10L
  )

  expect_equal(out$surface, "truncated_nbinom2_mu_random_intercept_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 10L)
  expect_equal(nrow(out$summary$aggregate), 10L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_intervals_csv)), 2L)
  expect_error(
    phase18_write_truncated_nbinom2_mu_ri_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 2072L
    ),
    "already exists"
  )
  expect_silent(phase18_write_truncated_nbinom2_mu_ri_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2072L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 truncated NB2 mu random-intercept helpers reject malformed inputs", {
  source_phase18_truncated_nbinom2_mu_ri()

  expect_error(
    phase18_dgp_truncated_nbinom2_mu_ri(
      n_group = 0L,
      n_per_group = 5L
    ),
    "n_group"
  )
  expect_error(
    phase18_dgp_truncated_nbinom2_mu_ri(
      n_group = 10L,
      n_per_group = 5L,
      sd = c("(1 | id)" = 0)
    ),
    "sd"
  )
  expect_error(
    phase18_dgp_truncated_nbinom2_mu_ri_cell(
      data.frame(cell_id = "bad"),
      seed = 2073L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_write_truncated_nbinom2_mu_ri_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
