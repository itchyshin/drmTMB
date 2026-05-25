source_phase18_ordinal_fe <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_ordinal_fixed_effect.R",
    "sim/fit/sim_summarise_ordinal_fixed_effect.R",
    "sim/run/sim_run_ordinal_fixed_effect_smoke.R",
    "sim/run/sim_summary_ordinal_fixed_effect_smoke.R",
    "sim/run/sim_write_ordinal_fixed_effect_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 ordinal DGP creates ordered categories and truth", {
  source_phase18_ordinal_fe()

  dat <- phase18_dgp_ordinal_fe(
    n = 120L,
    n_category = 5L,
    beta_mu = c(x = 0.65),
    cutpoint_pattern = "balanced",
    seed = 1309L
  )

  expect_true(is.ordered(dat$score))
  expect_equal(nlevels(dat$score), 5L)
  expect_true(all(dat$expected_score >= 1))
  expect_true(all(dat$expected_score <= 5))
  expect_equal(attr(dat, "truth")$surface, "ordinal_fixed_effect")
  expect_equal(length(attr(dat, "truth")$cutpoints), 4L)
  expect_true(all(diff(attr(dat, "truth")$cutpoints) > 0))
})

test_that("Phase 18 ordinal smoke returns cutpoint and Wald artifacts", {
  source_phase18_ordinal_fe()
  conditions <- phase18_ordinal_fe_conditions(
    n = 360L,
    n_category = c(3L, 5L),
    beta_mu_x = 0.65,
    cutpoint_pattern = "balanced"
  )

  summary <- phase18_summarise_ordinal_fe_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2035L
  )

  expect_equal(summary$surface, "ordinal_fixed_effect")
  expect_equal(nrow(summary$replicates), 8L)
  expect_equal(nrow(summary$aggregate), 8L)
  expect_equal(nrow(summary$manifest), 2L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$wald_intervals), 2L)
  expect_equal(nrow(summary$wald_coverage), 2L)
  expect_setequal(summary$replicates$n_category, c(3L, 5L))
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 8L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 8L))
  expect_equal(
    summary$wald_intervals$parameter_class,
    rep("fixef", 2L)
  )
  expect_true(all(summary$wald_intervals$interval_status == "ok"))
  expect_true(all(summary$replicates$cutpoints_ordered))
})

test_that("Phase 18 ordinal grid writer creates table artifacts", {
  source_phase18_ordinal_fe()
  output_dir <- tempfile("phase18-ordinal-fe-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_ordinal_fe_conditions(
    n = 360L,
    n_category = c(3L, 5L),
    beta_mu_x = 0.65,
    cutpoint_pattern = "balanced"
  )

  out <- phase18_write_ordinal_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2036L,
    cores = 10L
  )

  expect_equal(out$surface, "ordinal_fixed_effect_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 8L)
  expect_equal(nrow(out$summary$aggregate), 8L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 8L)
  expect_error(
    phase18_write_ordinal_fe_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 2036L
    ),
    "already exists"
  )
  expect_silent(phase18_write_ordinal_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 2036L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 ordinal helpers reject malformed inputs", {
  source_phase18_ordinal_fe()

  expect_error(
    phase18_ordinal_fe_conditions(n_category = 2L),
    "n_category"
  )
  expect_error(
    phase18_ordinal_fe_conditions(cutpoint_pattern = "sparse"),
    "cutpoint_pattern"
  )
  expect_error(
    phase18_dgp_ordinal_fe(n = 0L),
    "n"
  )
  expect_error(
    phase18_write_ordinal_fe_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
