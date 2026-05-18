test_that("Phase 18 Gaussian location-scale summary smoke run aggregates output", {
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
      "sim/dgp/sim_dgp_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_run_gaussian_ls_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_gaussian_ls_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  result_dir <- tempfile("phase18-gaussian-ls-summary-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_gaussian_ls_smoke(
    conditions = phase18_gaussian_ls_conditions(
      n = 100L,
      sigma_slope = 0.20,
      collinearity = 0.10
    ),
    n_rep = 2L,
    master_seed = 218L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "gaussian_ls")
  expect_equal(nrow(out$run$summary), 8L)
  expect_equal(nrow(out$aggregate), 4L)
  expect_equal(nrow(out$manifest), length(out$run$results))
  expect_equal(
    nrow(out$failures),
    sum(out$manifest$status != "ok") + sum(out$manifest$warning_count)
  )
  expect_equal(nrow(out$wald_coverage), 4L)
  expect_equal(out$wald_coverage$n_replicate, rep(2L, 4L))
  expect_equal(out$wald_coverage$n_interval, rep(2L, 4L))
  expect_true(all(out$wald_intervals$interval_status == "ok"))
  expect_true(all(out$wald_intervals$interval_scale == "formula_coefficient"))
  expect_equal(out$aggregate$n_replicate, rep(2L, 4L))
  expect_setequal(
    out$aggregate$parameter,
    c("mu:(Intercept)", "mu:x", "sigma:(Intercept)", "sigma:z")
  )
  expect_true(all(is.finite(out$aggregate$bias)))
  expect_true(all(is.finite(out$aggregate$rmse)))
  expect_true(all(is.finite(out$aggregate$bias_mcse)))
  expect_true(all(is.finite(out$aggregate$rmse_mcse)))
})

test_that("Phase 18 Gaussian location-scale summary smoke validates empty summaries", {
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/run/sim_summary_gaussian_ls_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  phase18_gaussian_ls_conditions <- function(...) {
    data.frame()
  }
  phase18_run_gaussian_ls_smoke <- function(...) {
    list(summary = data.frame())
  }
  expect_error(
    phase18_summarise_gaussian_ls_smoke(),
    "produced no summaries"
  )
})
