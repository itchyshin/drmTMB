test_that("Phase 18 Gaussian location-scale smoke runner completes and resumes", {
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

  result_dir <- tempfile("phase18-gaussian-ls-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_gaussian_ls_conditions(
    n = 120L,
    sigma_slope = 0.20,
    collinearity = 0.10
  )

  first <- phase18_run_gaussian_ls_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 214L,
    result_dir = result_dir
  )
  second <- phase18_run_gaussian_ls_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 214L,
    result_dir = result_dir
  )

  expect_identical(first$surface, "gaussian_ls")
  expect_equal(nrow(first$registry$cells), 1L)
  expect_equal(length(first$results), 1L)
  expect_equal(first$parallel$backend, "none")
  expect_equal(first$parallel$cores, 1L)
  expect_identical(first$results[[1L]]$status, "ok")
  expect_false(first$results[[1L]]$skipped)
  expect_true(second$results[[1L]]$skipped)
  expect_equal(nrow(first$summary), 4L)
  expect_equal(first$summary$surface, rep("gaussian_ls", 4L))
  expect_equal(first$summary$artifact_grain, rep("replicate", 4L))
  expect_equal(
    first$summary$parameter,
    c("mu:(Intercept)", "mu:x", "sigma:(Intercept)", "sigma:z")
  )
  expect_true(all(is.finite(first$summary$estimate)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "gaussian_ls_001",
    1L
  )))
  expect_equal(second$summary, first$summary)
})

test_that("Phase 18 Gaussian location-scale smoke runner validates cells", {
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
    system.file(
      "sim/dgp/sim_dgp_gaussian_ls.R",
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

  bad_cell <- data.frame(cell_id = "gaussian_ls_bad")
  expect_error(
    phase18_dgp_gaussian_ls_cell(
      cell = bad_cell,
      seed = 214L,
      cell_id = "gaussian_ls_bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_run_gaussian_ls_smoke(
      conditions = phase18_gaussian_ls_conditions(n = 20L),
      n_rep = 0L
    ),
    "positive whole number"
  )
})
