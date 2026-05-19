test_that("Phase 18 count mu random-effect pilot combines Poisson and NB2", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_nbinom2_mu_random_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_poisson_mu_random_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_nbinom2_mu_random_effect.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_poisson_mu_random_effect_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_nbinom2_mu_random_effect_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_poisson_mu_random_effect_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_count_mu_random_effect_pilot.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  result_dir <- tempfile("phase18-count-mu-re-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_count_mu_re_pilot(
    poisson_conditions = phase18_poisson_mu_re_conditions(
      n_group = 36L,
      n_per_group = 9L
    ),
    nbinom2_conditions = phase18_nbinom2_mu_re_conditions(
      n_group = 44L,
      n_per_group = 10L
    ),
    n_rep = 1L,
    master_seed = 251L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "count_mu_random_effect_pilot")
  expect_setequal(
    unique(out$aggregate$surface),
    c("poisson_mu_random_effect", "nbinom2_mu_random_effect")
  )
  expect_equal(nrow(out$aggregate), 10L)
  expect_equal(nrow(out$replicates), 10L)
  expect_equal(nrow(out$manifest), 2L)
  expect_equal(nrow(out$failures), 0L)
  expect_equal(nrow(out$wald_intervals), 10L)
  expect_equal(nrow(out$wald_coverage), 6L)
  expect_equal(nrow(out$profile_intervals), 4L)
  expect_equal(nrow(out$profile_coverage), 4L)
  expect_true(all(out$manifest$status == "ok"))
  expect_true(all(out$aggregate$n_replicate == 1L))
  expect_true(all(out$replicates$artifact_grain == "replicate"))
  expect_true(all(out$wald_coverage$n_interval == 1L))
  expect_true(all(out$profile_coverage$n_interval == 1L))
  expect_true(dir.exists(file.path(result_dir, "poisson_mu_random_effect")))
  expect_true(dir.exists(file.path(result_dir, "nbinom2_mu_random_effect")))
})

test_that("Phase 18 count mu random-effect pilot validates inputs", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_count_mu_random_effect_pilot.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(
    phase18_summarise_count_mu_re_pilot(
      poisson_conditions = data.frame(),
      nbinom2_conditions = data.frame(x = 1)
    ),
    "non-empty data frame"
  )
  expect_error(
    phase18_summarise_count_mu_re_pilot(
      poisson_conditions = data.frame(x = 1),
      nbinom2_conditions = data.frame(x = 1),
      result_dir = c("a", "b")
    ),
    "path string"
  )
})
