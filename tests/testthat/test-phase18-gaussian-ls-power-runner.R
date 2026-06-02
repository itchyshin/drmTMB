test_that("Gaussian location-scale power runner returns power, curve, and target", {
  skip_on_cran()
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
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_power.R", package = "drmTMB", mustWork = TRUE),
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
  # Reuse the DGP/fit cell adapters defined by the recovery smoke runner.
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
      "sim/run/sim_run_gaussian_ls_power_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  # Tiny grid: one null cell (delta = 0) and one clear-signal cell, one
  # replicate each. This exercises the whole pipeline cheaply; it is not a
  # power claim.
  result <- phase18_run_gaussian_ls_power(
    base_conditions = phase18_gaussian_ls_conditions(
      n = 200L,
      sigma_slope = 0,
      collinearity = 0
    ),
    effect_values = c(0, 0.6),
    n_rep = 1L,
    master_seed = 20260602L
  )

  expect_identical(result$surface, "gaussian_ls_power")
  expect_identical(result$target_parameter, "mu:x")
  expect_equal(nrow(result$registry$cells), 2L)
  expect_true(all(c("effect_size", "is_null") %in% names(result$registry$cells)))

  power <- result$power
  target <- power[power$parameter == "mu:x", ]
  target <- target[order(target$effect_size), ]
  expect_equal(nrow(target), 2L)
  expect_true(all(c("power", "power_mcse", "effect_size", "n") %in% names(target)))
  # The inference label comes from the truth/null, not the fit, so it is stable.
  expect_identical(target$inference, c("type_i_error", "power"))
  expect_true(all(target$n == 200L))

  expect_true(all(c("power_low", "power_high") %in% names(result$curve)))
  expect_true(all(c("n_target", "status") %in% names(result$sample_size)))
})
