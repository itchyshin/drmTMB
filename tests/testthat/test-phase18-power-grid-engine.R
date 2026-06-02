phase18_source_power_engine <- function(envir = parent.frame()) {
  for (path in c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_uncertainty.R",
    "sim/R/sim_power.R",
    "sim/run/sim_run_power_grid.R",
    "sim/run/sim_write_power_grid.R"
  )) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = envir)
  }
}

# Mock adapters: drive the real engine without fitting a model.
phase18_power_mock_dgp <- function(cell, seed, cell_id, replicate) {
  dat <- data.frame(cell_id = cell_id, replicate = replicate)
  attr(dat, "truth") <- list(
    effect_size = cell$effect_size[[1L]],
    n = cell$n[[1L]]
  )
  dat
}
phase18_power_mock_fit <- function(data, cell) list(ok = TRUE)
phase18_power_mock_summarise <- function(
  fit, truth, cell_id, replicate, elapsed = NA_real_, warnings = character()
) {
  tr <- attr(truth, "truth")
  set.seed(replicate * 7L + as.integer(tr$n))
  est <- tr$effect_size + stats::rnorm(1L, 0, 0.05)
  data.frame(
    surface = "mock", cell_id = cell_id, replicate = replicate,
    parameter = "mu:x", truth = tr$effect_size, estimate = est,
    std.error = 0.08, error = est - tr$effect_size, converged = TRUE,
    pdHess = TRUE, nobs = tr$n, elapsed = elapsed, warning_count = 0L,
    warnings = "", stringsAsFactors = FALSE
  )
}

test_that("generic power engine assembles power, curve, and target sample size", {
  phase18_source_power_engine()

  base <- data.frame(n = c(120L, 480L), beta_mu_x = 0.5)
  result <- phase18_run_power_grid(
    surface = "mock_power",
    base_conditions = base,
    dgp_fun = phase18_power_mock_dgp,
    fit_fun = phase18_power_mock_fit,
    summarise_fun = phase18_power_mock_summarise,
    effect_name = "beta_mu_x",
    target_parameter = "mu:x",
    effect_values = c(0, 0.4),
    n_rep = 3L,
    master_seed = 1L
  )

  expect_identical(result$surface, "mock_power")
  expect_equal(nrow(result$registry$cells), 4L) # 2 effects x 2 sample sizes
  power <- result$power[order(result$power$effect_size, result$power$n), ]
  expect_equal(nrow(power), 4L)
  expect_true(all(power$n_interval == 3L))
  expect_identical(
    power$inference[power$effect_size == 0],
    rep("type_i_error", 2L)
  )
  expect_identical(
    power$inference[power$effect_size == 0.4],
    rep("power", 2L)
  )
  expect_true(all(c("power_low", "power_high") %in% names(result$curve)))
  expect_true(all(c("n_target", "status") %in% names(result$sample_size)))
})

test_that("engine threads a non-default sample_size column (e.g. n_group)", {
  phase18_source_power_engine()

  # Meta-analysis and Poisson surfaces name their sample-size column n_study /
  # n_group, not n. The engine must thread that name into the curve and the
  # target-sample-size read instead of assuming "n".
  mock_dgp <- function(cell, seed, cell_id, replicate) {
    dat <- data.frame(cell_id = cell_id, replicate = replicate)
    attr(dat, "truth") <- list(
      effect_size = cell$effect_size[[1L]],
      n = cell$n_group[[1L]]
    )
    dat
  }

  result <- phase18_run_power_grid(
    surface = "mock_power",
    base_conditions = data.frame(n_group = c(24L, 96L), beta_mu_x = 0.5),
    dgp_fun = mock_dgp,
    fit_fun = phase18_power_mock_fit,
    summarise_fun = phase18_power_mock_summarise,
    effect_name = "beta_mu_x",
    target_parameter = "mu:x",
    effect_values = c(0, 0.4),
    sample_size = "n_group",
    n_rep = 2L,
    master_seed = 1L
  )

  expect_identical(result$sample_size_column, "n_group")
  expect_true("n_group" %in% names(result$curve))
  expect_true(all(c("power_low", "power_high") %in% names(result$curve)))
  expect_true(all(c("n_target", "status") %in% names(result$sample_size)))
})

test_that("power grid writer persists CSV artifacts and a manifest", {
  phase18_source_power_engine()

  # Minimal in-memory result shaped like phase18_run_power_grid() output.
  result <- list(
    surface = "mock_power",
    power = data.frame(
      surface = "mock_power", cell_id = c("c1", "c2"), parameter = "mu:x",
      effect_size = c(0, 0.4), n = c(120L, 120L), power = c(0.04, 0.8),
      power_mcse = c(0.02, 0.04), inference = c("type_i_error", "power"),
      stringsAsFactors = FALSE
    ),
    curve = data.frame(
      effect_size = c(0, 0.4), n = c(120L, 120L), power = c(0.04, 0.8),
      power_low = c(0, 0.72), power_high = c(0.08, 0.88), stringsAsFactors = FALSE
    ),
    sample_size = data.frame(
      effect_size = 0.4, n_target = 120, status = "achieved_at_min",
      stringsAsFactors = FALSE
    ),
    registry = list(cells = data.frame(
      cell_id = c("c1", "c2"), surface = "mock_power",
      effect_size = c(0, 0.4), n = c(120L, 120L), stringsAsFactors = FALSE
    )),
    summary = data.frame(
      cell_id = c("c1", "c2"), parameter = "mu:x", estimate = c(0.01, 0.4),
      stringsAsFactors = FALSE
    )
  )

  output_dir <- tempfile("phase18-power-write-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  written <- phase18_write_power_grid_tables(
    result, output_dir = output_dir, prefix = "mock-power"
  )

  expect_true(file.exists(written$paths$power_csv))
  expect_true(file.exists(written$paths$curve_csv))
  expect_true(file.exists(written$paths$sample_size_csv))
  expect_true(file.exists(written$manifest_csv))
  expect_true(all(written$manifest$exists))
  back <- utils::read.csv(written$paths$power_csv, stringsAsFactors = FALSE)
  expect_equal(nrow(back), 2L)
  expect_equal(back$power, c(0.04, 0.8))

  # Refuses to clobber without overwrite.
  expect_error(
    phase18_write_power_grid_tables(
      result, output_dir = output_dir, prefix = "mock-power"
    ),
    "already exists"
  )
})

test_that("run-and-write composes a runner with the writer", {
  phase18_source_power_engine()

  fake_run <- function(n_rep, master_seed, cores, backend, ...) {
    list(
      surface = "fake",
      power = data.frame(power = 0.5, stringsAsFactors = FALSE),
      curve = data.frame(n = 1L, power = 0.5, stringsAsFactors = FALSE),
      sample_size = data.frame(status = "no_data", stringsAsFactors = FALSE),
      registry = list(cells = data.frame(cell_id = "c1", stringsAsFactors = FALSE)),
      summary = data.frame(cell_id = "c1", stringsAsFactors = FALSE)
    )
  }
  output_dir <- tempfile("phase18-power-run-write-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  written <- phase18_run_and_write_power_grid(
    run_fun = fake_run, output_dir = output_dir, prefix = "fake-power",
    n_rep = 2L
  )
  expect_identical(written$surface, "fake")
  expect_true(file.exists(written$paths$power_csv))
})

test_that("meta-analysis power runner composes end to end", {
  skip_on_cran()
  for (path in c(
    "sim/R/sim_registry.R", "sim/R/sim_utils.R", "sim/R/sim_runner.R",
    "sim/R/sim_uncertainty.R", "sim/R/sim_power.R",
    "sim/dgp/sim_dgp_meta_v.R", "sim/fit/sim_summarise_meta_v.R",
    "sim/run/sim_run_meta_v_smoke.R", "sim/run/sim_run_power_grid.R",
    "sim/run/sim_run_meta_v_power_smoke.R"
  )) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = TRUE)
  }

  result <- phase18_run_meta_v_power(
    base_conditions = phase18_meta_v_conditions(
      n_study = 40L, known_v_type = "vector", sigma = 0.25,
      sampling_sd = 0.14, sampling_rho = 0
    ),
    effect_values = c(0, 0.5),
    n_rep = 1L,
    master_seed = 20260602L
  )

  expect_identical(result$surface, "meta_v_power")
  target <- result$power[result$power$parameter == "mu:x", ]
  target <- target[order(target$effect_size), ]
  expect_equal(nrow(target), 2L)
  expect_identical(target$inference, c("type_i_error", "power"))
})

test_that("Poisson mu random-effect power runner composes end to end", {
  skip_on_cran()
  for (path in c(
    "sim/R/sim_registry.R", "sim/R/sim_utils.R", "sim/R/sim_runner.R",
    "sim/R/sim_uncertainty.R", "sim/R/sim_power.R",
    "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
    "sim/fit/sim_summarise_poisson_mu_random_effect.R",
    "sim/run/sim_run_poisson_mu_random_effect_smoke.R",
    "sim/run/sim_run_power_grid.R",
    "sim/run/sim_run_poisson_mu_re_power_smoke.R"
  )) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = TRUE)
  }

  result <- phase18_run_poisson_mu_re_power(
    base_conditions = phase18_poisson_mu_re_conditions(
      n_group = 30L, n_per_group = 8L
    ),
    effect_values = c(0, 0.5),
    n_rep = 1L,
    master_seed = 20260602L
  )

  expect_identical(result$surface, "poisson_mu_re_power")
  target <- result$power[result$power$parameter == "mu:x", ]
  target <- target[order(target$effect_size), ]
  expect_equal(nrow(target), 2L)
  expect_identical(target$inference, c("type_i_error", "power"))
})
