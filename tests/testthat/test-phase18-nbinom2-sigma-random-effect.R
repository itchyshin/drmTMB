source_phase18_nbinom2_sigma_re <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_nbinom2_sigma_random_effect.R",
    "sim/fit/sim_summarise_nbinom2_sigma_random_effect.R",
    "sim/run/sim_run_nbinom2_sigma_random_effect_smoke.R",
    "sim/run/sim_summary_nbinom2_sigma_random_effect_smoke.R",
    "sim/run/sim_write_nbinom2_sigma_random_effect_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 NB2 sigma random-effect DGP is seeded and self-describing", {
  source_phase18_nbinom2_sigma_re()

  conditions <- phase18_nbinom2_sigma_re_conditions(
    n_group = c(8L, 10L),
    n_per_group = 5L,
    mean_count = c(2.0, 3.0),
    sigma_baseline = 0.55,
    sd_sigma_intercept = c(0.20, 0.35)
  )
  dat <- phase18_dgp_nbinom2_sigma_re(
    n_group = 10L,
    n_per_group = 6L,
    seed = 511L,
    cell_id = "nbinom2_sigma_random_effect_001",
    replicate = 1L
  )
  again <- phase18_dgp_nbinom2_sigma_re(
    n_group = 10L,
    n_per_group = 6L,
    seed = 511L,
    cell_id = "nbinom2_sigma_random_effect_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 8L)
  expect_named(
    conditions,
    c(
      "n_group",
      "n_per_group",
      "mean_count",
      "sigma_baseline",
      "sd_sigma_intercept",
      "beta_mu_x",
      "beta_sigma_z"
    )
  )
  expect_equal(dat, again)
  expect_equal(nrow(dat), 60L)
  expect_named(
    dat,
    c(
      "count",
      "x",
      "z",
      "id",
      "eta_mu",
      "eta_sigma",
      "mu",
      "sigma",
      "cell_id",
      "replicate"
    )
  )
  expect_type(dat$count, "integer")
  expect_true(all(dat$count >= 0))
  expect_true(all(dat$sigma > 0))
  expect_identical(truth$surface, "nbinom2_sigma_random_effect")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma, c("(Intercept)", "z"))
  expect_named(truth$sd, "(1 | id)")
})

test_that("Phase 18 NB2 sigma random-effect smoke runner summarises output", {
  source_phase18_nbinom2_sigma_re()
  result_dir <- tempfile("phase18-nbinom2-sigma-re-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_nbinom2_sigma_re_conditions(
    n_group = 36L,
    n_per_group = 18L,
    mean_count = 2.8,
    sigma_baseline = 0.55,
    sd_sigma_intercept = 0.35
  )

  out <- phase18_summarise_nbinom2_sigma_re_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 512L,
    result_dir = result_dir,
    cores = 10L
  )

  expect_identical(out$surface, "nbinom2_sigma_random_effect")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$requested_cores, 10L)
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 5L)
  expect_equal(nrow(out$aggregate), 5L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_equal(nrow(out$wald_intervals), 5L)
  expect_equal(nrow(out$wald_coverage), 4L)
  expect_equal(nrow(out$profile_targets), 1L)
  expect_equal(nrow(out$profile_intervals), 1L)
  expect_equal(nrow(out$profile_coverage), 0L)
  expect_equal(nrow(out$interval_evidence), 6L)
  expect_equal(out$aggregate$n_replicate, rep(1L, 5L))
  expect_equal(
    out$wald_intervals$interval_status,
    c("ok", "ok", "ok", "ok", "failed")
  )
  expect_equal(
    out$wald_intervals$interval_scale,
    c(
      "formula_coefficient",
      "formula_coefficient",
      "formula_coefficient",
      "formula_coefficient",
      "public_sd"
    )
  )
  expect_equal(out$profile_targets$profile_target_status, "ready")
  expect_equal(out$profile_targets$profile_target_parameter, "log_sd_sigma")
  expect_equal(out$profile_targets$artifact_grain, "profile_target")
  expect_equal(out$profile_intervals$interval_status, "not_requested")
  expect_setequal(
    out$run$summary$parameter_class,
    c("fixed_mu", "fixed_sigma", "random_sd")
  )
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma:(Intercept)",
      "sigma:z",
      "sd:sigma:(1 | id)"
    )
  )
  expect_true(all(out$run$summary$converged))
  expect_type(out$run$summary$pdHess, "logical")
  expect_false(anyNA(out$run$summary$pdHess))
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
  expect_true(all(
    is.na(out$run$summary$std.error) | out$run$summary$std.error > 0
  ))
  expect_equal(
    phase18_nbinom2_sigma_re_profile_parameter_map("log_sd_sigma"),
    c("sd:sigma:(1 | id)" = "sd:sigma:(1 | id)")
  )
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "nbinom2_sigma_random_effect_001",
    1L
  )))
})

test_that("Phase 18 NB2 sigma random-effect grid writer creates artifacts", {
  source_phase18_nbinom2_sigma_re()
  output_dir <- tempfile("phase18-nbinom2-sigma-re-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_nbinom2_sigma_re_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_nbinom2_sigma_re_conditions(
      n_group = 36L,
      n_per_group = 18L,
      mean_count = 2.8,
      sigma_baseline = 0.55,
      sd_sigma_intercept = 0.35
    ),
    n_rep = 1L,
    master_seed = 513L,
    cores = 10L
  )

  expect_equal(out$surface, "nbinom2_sigma_random_effect_grid")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$aggregate), 5L)
  expect_equal(nrow(out$summary$replicates), 5L)
  expect_equal(nrow(out$summary$manifest), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_targets_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$profile_intervals_csv)), 1L)
  expect_equal(
    unique(out$summary$aggregate$surface),
    "nbinom2_sigma_random_effect"
  )
  expect_error(
    phase18_write_nbinom2_sigma_re_grid_outputs(
      output_dir = output_dir,
      conditions = phase18_nbinom2_sigma_re_conditions(
        n_group = 36L,
        n_per_group = 18L,
        mean_count = 2.8,
        sigma_baseline = 0.55,
        sd_sigma_intercept = 0.35
      ),
      n_rep = 1L,
      master_seed = 513L
    ),
    "already exists"
  )
})

test_that("Phase 18 NB2 sigma random-effect helpers reject malformed inputs", {
  source_phase18_nbinom2_sigma_re()

  expect_error(
    phase18_dgp_nbinom2_sigma_re(0L, 5L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_nbinom2_sigma_re(8L, 5L, sd_sigma = -0.2),
    "positive finite"
  )
  expect_error(
    phase18_dgp_nbinom2_sigma_re_cell(
      data.frame(cell_id = "bad"),
      seed = 246L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_write_nbinom2_sigma_re_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_nbinom2_sigma_re_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
  expect_error(
    phase18_nbinom2_sigma_re_profile_parameter_map(c("log_sd_sigma", "")),
    "parameters"
  )
})
