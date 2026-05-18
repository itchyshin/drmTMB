test_that("Phase 18 meta_V summary smoke run aggregates vector and dense output", {
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
      "sim/dgp/sim_dgp_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_meta_v_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_meta_v_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  result_dir <- tempfile("phase18-meta-v-summary-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_meta_v_smoke(
    conditions = phase18_meta_v_conditions(
      n_study = 32L,
      known_v_type = c("vector", "dense"),
      sigma = 0.25,
      sampling_sd = 0.14,
      sampling_rho = c(0, 0.20)
    ),
    n_rep = 2L,
    master_seed = 219L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "meta_v")
  expect_equal(nrow(out$run$summary), 18L)
  expect_equal(nrow(out$aggregate), 9L)
  expect_equal(nrow(out$manifest), length(out$run$results))
  expect_equal(
    nrow(out$failures),
    sum(out$manifest$status != "ok") + sum(out$manifest$warning_count)
  )
  expect_equal(out$aggregate$n_replicate, rep(2L, 9L))
  expect_setequal(unique(out$aggregate$known_v_type), c("vector", "dense"))
  expect_setequal(out$aggregate$parameter, c("mu:(Intercept)", "mu:x", "sigma"))
  expect_true(all(is.finite(out$aggregate$bias)))
  expect_true(all(is.finite(out$aggregate$rmse)))
  expect_true(all(is.finite(out$aggregate$bias_mcse)))
  expect_true(all(is.finite(out$aggregate$rmse_mcse)))
})

test_that("Phase 18 meta_V summary smoke validates empty summaries", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_meta_v_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  phase18_meta_v_conditions <- function(...) {
    data.frame()
  }
  phase18_run_meta_v_smoke <- function(...) {
    list(summary = data.frame())
  }
  expect_error(
    phase18_summarise_meta_v_smoke(),
    "produced no summaries"
  )
})
