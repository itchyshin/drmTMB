test_that("Phase 18 meta_V smoke runner completes vector and dense surfaces", {
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

  result_dir <- tempfile("phase18-meta-v-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_meta_v_conditions(
    n_study = 36L,
    known_v_type = c("vector", "dense"),
    sigma = 0.25,
    sampling_sd = 0.14,
    sampling_rho = c(0, 0.20)
  )

  out <- phase18_run_meta_v_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 215L,
    result_dir = result_dir
  )
  again <- phase18_run_meta_v_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 215L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "meta_v")
  expect_equal(nrow(out$registry$cells), 3L)
  expect_equal(length(out$results), 3L)
  expect_equal(
    unname(vapply(out$results, function(result) result$status, character(1))),
    rep("ok", 3L)
  )
  expect_true(all(vapply(again$results, function(result) result$skipped, TRUE)))
  expect_equal(nrow(out$summary), 9L)
  expect_equal(unique(out$summary$surface), "meta_v")
  expect_setequal(unique(out$summary$known_v_type), c("vector", "dense"))
  expect_setequal(
    out$summary$parameter,
    c("mu:(Intercept)", "mu:x", "sigma")
  )
  expect_true(all(is.finite(out$summary$estimate)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "meta_v_001",
    1L
  )))
  expect_equal(again$summary, out$summary)
})

test_that("Phase 18 meta_V smoke runner validates cells and known V", {
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
      "sim/dgp/sim_dgp_meta_v.R",
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

  bad_cell <- data.frame(cell_id = "meta_v_bad")
  expect_error(
    phase18_dgp_meta_v_cell(
      cell = bad_cell,
      seed = 215L,
      cell_id = "meta_v_bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_fit_meta_v(data.frame(yi = 1, x = 0), data.frame(cell_id = "x")),
    "known sampling covariance"
  )
  expect_error(
    phase18_run_meta_v_smoke(
      conditions = phase18_meta_v_conditions(n_study = 20L),
      n_rep = 0L
    ),
    "positive whole number"
  )
})
