source_phase18_tweedie_fe <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_tweedie_fixed_effect.R",
    "sim/fit/sim_summarise_tweedie_fixed_effect.R",
    "sim/run/sim_run_tweedie_fixed_effect_smoke.R",
    "sim/run/sim_summary_tweedie_fixed_effect_smoke.R",
    "sim/run/sim_write_tweedie_fixed_effect_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 Tweedie DGP records public sigma and exact-zero regimes", {
  source_phase18_tweedie_fe()

  low <- phase18_dgp_tweedie_fe(
    n = 500L,
    power = 1.30,
    target_zero_fraction = 0.03,
    zero_regime = "low",
    seed = 17051L
  )
  high <- phase18_dgp_tweedie_fe(
    n = 500L,
    beta_mu = c("(Intercept)" = -0.65, x = 0.30),
    beta_sigma = c("(Intercept)" = 0.20, z = 0.12),
    power = 1.55,
    target_zero_fraction = 0.25,
    zero_regime = "high",
    seed = 17052L
  )

  expect_true(all(low$y >= 0))
  expect_true(all(high$y >= 0))
  expect_true(any(high$y == 0))
  expect_lt(mean(low$y == 0), mean(high$y == 0))
  expect_gt(mean(high$y == 0), 0.20)
  expect_equal(low$phi, low$sigma^2, tolerance = 1e-12)
  expect_equal(low$response_mean, low$mu, tolerance = 1e-12)
  expect_equal(attr(low, "truth")$surface, "tweedie_fixed_effect")
  expect_named(attr(low, "truth")$beta_mu, c("(Intercept)", "x"))
  expect_named(attr(low, "truth")$beta_sigma, c("(Intercept)", "z"))
  expect_equal(
    attr(low, "truth")$beta_nu[["(Intercept)"]],
    stats::qlogis(attr(low, "truth")$power - 1),
    tolerance = 1e-12
  )
})

test_that("Phase 18 Tweedie smoke returns Wald artifacts", {
  source_phase18_tweedie_fe()
  conditions <- phase18_tweedie_fe_conditions(
    n = 320L,
    zero_regime = "low",
    rho_xz = 0.10
  )

  summary <- phase18_summarise_tweedie_fe_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 17053L
  )

  expect_equal(summary$surface, "tweedie_fixed_effect")
  expect_equal(nrow(summary$replicates), 5L)
  expect_equal(nrow(summary$aggregate), 5L)
  expect_equal(nrow(summary$manifest), 1L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 5L)
  expect_equal(nrow(summary$wald_coverage), 5L)
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 5L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 5L))
  expect_equal(
    unique(summary$wald_intervals$interval_scale),
    "formula_coefficient"
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
  expect_equal(
    summary$replicates$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma:(Intercept)",
      "sigma:z",
      "nu:(Intercept)"
    )
  )
  expect_true(all(summary$replicates$power_estimate > 1))
  expect_true(all(summary$replicates$power_estimate < 2))
  expect_true(all(summary$replicates$observed_zero_fraction >= 0))
})

test_that("Phase 18 Tweedie smoke runner resumes saved replicate results", {
  source_phase18_tweedie_fe()
  result_dir <- tempfile("phase18-tweedie-fe-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_tweedie_fe_conditions(
    n = 320L,
    zero_regime = "low",
    rho_xz = 0.10
  )

  first <- phase18_run_tweedie_fe_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 17054L,
    result_dir = result_dir
  )
  second <- phase18_run_tweedie_fe_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 17054L,
    result_dir = result_dir
  )

  expect_identical(first$surface, "tweedie_fixed_effect")
  expect_equal(first$parallel$backend, "none")
  expect_equal(first$parallel$cores, 1L)
  expect_identical(first$results[[1L]]$status, "ok")
  expect_false(first$results[[1L]]$skipped)
  expect_true(second$results[[1L]]$skipped)
  expect_equal(nrow(first$summary), 5L)
  expect_equal(second$summary, first$summary)
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "tweedie_fixed_effect_001",
    1L
  )))
})

test_that("Phase 18 Tweedie grid writer creates table artifacts", {
  source_phase18_tweedie_fe()
  output_dir <- tempfile("phase18-tweedie-fe-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_tweedie_fe_conditions(
    n = 320L,
    zero_regime = "low",
    rho_xz = 0.10
  )

  out <- phase18_write_tweedie_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 17056L,
    cores = 10L
  )

  expect_equal(out$surface, "tweedie_fixed_effect_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 5L)
  expect_equal(nrow(out$summary$aggregate), 5L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 5L)
  expect_equal(nrow(utils::read.csv(out$paths$wald_intervals_csv)), 5L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_error(
    phase18_write_tweedie_fe_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 17056L
    ),
    "already exists"
  )
  expect_silent(phase18_write_tweedie_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 17056L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 Tweedie helpers reject malformed inputs", {
  source_phase18_tweedie_fe()

  expect_error(
    phase18_tweedie_fe_conditions(zero_regime = "middle"),
    "zero_regime"
  )
  expect_error(
    phase18_dgp_tweedie_fe(n = 0L),
    "n"
  )
  expect_error(
    phase18_dgp_tweedie_fe(n = 80L, power = 2.1),
    "power"
  )
  expect_error(
    phase18_dgp_tweedie_fe(n = 80L, rho_xz = 2),
    "rho_xz"
  )
  expect_error(
    phase18_dgp_tweedie_fe_cell(
      cell = data.frame(cell_id = "tweedie_bad"),
      seed = 17055L,
      cell_id = "tweedie_bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_write_tweedie_fe_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
