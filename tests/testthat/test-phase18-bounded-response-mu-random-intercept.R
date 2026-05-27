source_phase18_bounded_response_mu_ri <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_proportion_fixed_effect.R",
    "sim/dgp/sim_dgp_bounded_response_mu_random_intercept.R",
    "sim/fit/sim_summarise_bounded_response_mu_random_intercept.R",
    "sim/run/sim_run_bounded_response_mu_random_intercept_smoke.R",
    "sim/run/sim_summary_bounded_response_mu_random_intercept_smoke.R",
    "sim/run/sim_write_bounded_response_mu_random_intercept_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 bounded-response mu random-intercept DGP separates families", {
  source_phase18_bounded_response_mu_ri()

  beta_dat <- phase18_dgp_bounded_response_mu_ri(
    n_group = 16L,
    n_per_group = 5L,
    family = "beta",
    seed = 1201L
  )
  beta_binomial_dat <- phase18_dgp_bounded_response_mu_ri(
    n_group = 16L,
    n_per_group = 5L,
    family = "beta_binomial",
    trial_min = 12L,
    trial_max = 20L,
    seed = 1202L
  )

  expect_true(all(beta_dat$prop > 0))
  expect_true(all(beta_dat$prop < 1))
  expect_false("success" %in% names(beta_dat))
  expect_equal(length(unique(beta_dat$id)), 16L)
  expect_true(all(beta_binomial_dat$success >= 0L))
  expect_equal(
    beta_binomial_dat$success + beta_binomial_dat$failure,
    beta_binomial_dat$trials
  )
  expect_equal(length(unique(beta_binomial_dat$id)), 16L)
  expect_equal(
    attr(beta_dat, "truth")$surface,
    "bounded_response_mu_random_intercept"
  )
  expect_equal(attr(beta_binomial_dat, "truth")$family, "beta_binomial")
})

test_that("Phase 18 bounded-response mu random-intercept smoke returns artifacts", {
  source_phase18_bounded_response_mu_ri()
  conditions <- phase18_bounded_response_mu_ri_conditions(
    family = c("beta", "beta_binomial"),
    n_group = 24L,
    n_per_group = 7L,
    trial_min = 14L,
    trial_max = 24L,
    beta_sigma_intercept = -0.95,
    beta_sigma_z = 0.15,
    sd_intercept = 0.45,
    rho_xz = 0.20
  )

  summary <- phase18_summarise_bounded_response_mu_ri_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2041L
  )

  expect_equal(summary$surface, "bounded_response_mu_random_intercept")
  expect_equal(nrow(summary$replicates), 10L)
  expect_equal(nrow(summary$aggregate), 10L)
  expect_equal(nrow(summary$manifest), 2L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 10L)
  expect_equal(nrow(summary$wald_coverage), 8L)
  expect_equal(nrow(summary$profile_intervals), 2L)
  expect_setequal(summary$replicates$family, c("beta", "beta_binomial"))
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 10L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 10L))
  expect_setequal(
    unique(summary$wald_intervals$interval_scale),
    c("formula_coefficient", "public_sd")
  )
  expect_true(all(summary$manifest$status == "ok"))
})

test_that("Phase 18 bounded-response mu random-intercept grid writer creates artifacts", {
  source_phase18_bounded_response_mu_ri()
  output_dir <- tempfile("phase18-bounded-response-mu-ri-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_bounded_response_mu_ri_conditions(
    family = c("beta", "beta_binomial"),
    n_group = 24L,
    n_per_group = 7L,
    trial_min = 14L,
    trial_max = 24L,
    beta_sigma_intercept = -0.95,
    beta_sigma_z = 0.15,
    sd_intercept = 0.45,
    rho_xz = 0.20
  )

  out <- phase18_write_bounded_response_mu_ri_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2042L,
    cores = 10L
  )

  expect_equal(out$surface, "bounded_response_mu_random_intercept_grid")
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
    phase18_write_bounded_response_mu_ri_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 2042L
    ),
    "already exists"
  )
  expect_silent(phase18_write_bounded_response_mu_ri_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2042L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 bounded-response mu random-intercept helpers reject malformed inputs", {
  source_phase18_bounded_response_mu_ri()

  expect_error(
    phase18_bounded_response_mu_ri_conditions(family = "ordinal"),
    "family"
  )
  expect_error(
    phase18_bounded_response_mu_ri_conditions(
      trial_min = 12L,
      trial_max = 8L
    ),
    "trial_min"
  )
  expect_error(
    phase18_dgp_bounded_response_mu_ri(
      n_group = 10L,
      n_per_group = 5L,
      family = "beta",
      sd = c("(1 | id)" = 0)
    ),
    "sd"
  )
  expect_error(
    phase18_write_bounded_response_mu_ri_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
