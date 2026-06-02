phase18_source_power_helpers <- function(envir = parent.frame()) {
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = envir
  )
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = envir
  )
  source(
    system.file("sim/R/sim_power.R", package = "drmTMB", mustWork = TRUE),
    local = envir
  )
}

test_that("power grid factory sweeps an effect and marks the null cell", {
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
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

  base <- phase18_gaussian_ls_conditions(
    n = c(120L, 240L),
    sigma_slope = 0,
    collinearity = 0
  )
  grid <- phase18_power_grid_conditions(
    base,
    effect_name = "beta_mu_x",
    effect_values = c(0, 0.2, 0.5)
  )

  expect_equal(nrow(grid), nrow(base) * 3L)
  expect_true(all(c("effect_size", "is_null", "null_value") %in% names(grid)))
  expect_equal(grid$beta_mu_x, grid$effect_size)
  expect_equal(grid$is_null, grid$effect_size == 0)
  expect_true(all(grid$null_value == 0))
  expect_equal(sort(unique(grid$effect_size)), c(0, 0.2, 0.5))
})

test_that("power summary counts interval rejections with binomial MCSE", {
  phase18_source_power_helpers()

  # Two synthetic cells, 4 replicates each, one parameter (mu:x), null = 0.
  # alt cell: every interval excludes 0 -> power 1. null cell: every interval
  # contains 0 -> rejection rate 0 (a Type I error cell at truth 0).
  alt <- data.frame(
    surface = "gaussian_ls",
    cell_id = "alt",
    parameter = "mu:x",
    truth = 0.5,
    conf.low = c(0.2, 0.3, 0.25, 0.35),
    conf.high = c(0.8, 0.9, 0.7, 0.95),
    interval_status = "ok",
    is_null = FALSE,
    stringsAsFactors = FALSE
  )
  null <- data.frame(
    surface = "gaussian_ls",
    cell_id = "null",
    parameter = "mu:x",
    truth = 0,
    conf.low = c(-0.4, -0.3, -0.5, -0.2),
    conf.high = c(0.4, 0.5, 0.3, 0.6),
    interval_status = "ok",
    is_null = TRUE,
    stringsAsFactors = FALSE
  )
  summary <- rbind(alt, null)

  power <- phase18_summarise_power(
    summary,
    by = c("cell_id", "parameter"),
    null_value = 0
  )

  alt_row <- power[power$cell_id == "alt", ]
  null_row <- power[power$cell_id == "null", ]

  expect_equal(alt_row$power, 1)
  expect_equal(alt_row$power_mcse, 0)
  expect_equal(alt_row$n_interval, 4L)
  expect_equal(alt_row$n_reject, 4L)
  expect_identical(alt_row$inference, "power")

  expect_equal(null_row$power, 0)
  expect_equal(null_row$power_mcse, 0)
  expect_identical(null_row$inference, "type_i_error")
})

test_that("power summary drops failed and non-finite intervals", {
  phase18_source_power_helpers()

  summary <- data.frame(
    surface = "gaussian_ls",
    cell_id = "mixed",
    parameter = "mu:x",
    truth = 0.5,
    conf.low = c(0.2, NA, 0.3, 0.25),
    conf.high = c(0.8, 0.9, 0.7, 0.6),
    interval_status = c("ok", "ok", "failed", "ok"),
    stringsAsFactors = FALSE
  )

  power <- phase18_summarise_power(
    summary,
    by = c("cell_id", "parameter"),
    null_value = 0
  )

  # Only rows 1 and 4 are usable (row 2 non-finite, row 3 failed); both reject 0.
  expect_equal(power$n_interval, 2L)
  expect_equal(power$n_reject, 2L)
  expect_equal(power$power, 1)
})

test_that("named null_value targets one parameter and ignores the rest", {
  phase18_source_power_helpers()

  summary <- data.frame(
    surface = "gaussian_ls",
    cell_id = "c1",
    parameter = c("mu:x", "mu:(Intercept)"),
    truth = c(0.5, 0.25),
    conf.low = c(0.2, 0.1),
    conf.high = c(0.8, 0.4),
    interval_status = "ok",
    stringsAsFactors = FALSE
  )

  power <- phase18_summarise_power(
    summary,
    by = c("cell_id", "parameter"),
    null_value = c("mu:x" = 0)
  )

  x_row <- power[power$parameter == "mu:x", ]
  intercept_row <- power[power$parameter == "mu:(Intercept)", ]

  expect_equal(x_row$n_interval, 1L)
  expect_equal(x_row$power, 1)
  # The intercept has no matching null, so it contributes no usable interval.
  expect_equal(intercept_row$n_interval, 0L)
  expect_true(is.na(intercept_row$power))
})

test_that("target sample size interpolates the simulated power curve", {
  phase18_source_power_helpers()

  power_table <- data.frame(
    surface = "gaussian_ls",
    parameter = "mu:x",
    effect_size = c(rep(0.3, 4L), rep(0.1, 3L)),
    n = c(50, 100, 200, 400, 100, 200, 400),
    power = c(0.20, 0.50, 0.75, 0.90, 0.10, 0.20, 0.40),
    stringsAsFactors = FALSE
  )

  solved <- phase18_power_target_sample_size(power_table, target_power = 0.8)

  big <- solved[solved$effect_size == 0.3, ]
  small <- solved[solved$effect_size == 0.1, ]

  # 0.8 falls between n=200 (0.75) and n=400 (0.90):
  # 200 + (0.8 - 0.75) / (0.90 - 0.75) * (400 - 200) = 266.667
  expect_equal(big$status, "interpolated")
  expect_equal(big$n_target, 200 + (0.05 / 0.15) * 200, tolerance = 1e-6)

  # The weak effect never reaches 0.8 within the grid.
  expect_equal(small$status, "below_grid")
  expect_true(is.na(small$n_target))
})

test_that("target sample size flags a curve already above target", {
  phase18_source_power_helpers()

  power_table <- data.frame(
    effect_size = 0.6,
    n = c(50, 100, 200),
    power = c(0.85, 0.92, 0.97),
    stringsAsFactors = FALSE
  )

  solved <- phase18_power_target_sample_size(
    power_table,
    target_power = 0.8,
    by = "effect_size"
  )

  expect_equal(solved$status, "achieved_at_min")
  expect_equal(solved$n_target, 50)
})

test_that("power helpers reject malformed inputs", {
  phase18_source_power_helpers()

  base <- data.frame(n = c(100L, 200L), beta_mu_x = 0.5)
  expect_error(
    phase18_power_grid_conditions(base, "absent", c(0, 0.3)),
    "not a column"
  )
  expect_error(
    phase18_power_grid_conditions(base, "beta_mu_x", numeric(0)),
    "non-empty finite numeric"
  )
  expect_error(
    phase18_power_grid_conditions(base, "beta_mu_x", c(0, 0.3), null_value = NA),
    "one finite number"
  )

  summary <- data.frame(
    parameter = "mu:x",
    conf.low = 0.2,
    conf.high = 0.8,
    stringsAsFactors = FALSE
  )
  expect_error(
    phase18_summarise_power(summary, null_value = "zero"),
    "named numeric vector"
  )

  power_table <- data.frame(effect_size = 0.3, n = 100, power = 0.5)
  expect_error(
    phase18_power_target_sample_size(power_table, target_power = 1.5),
    "between 0 and 1"
  )
})

test_that("assemble_power_table builds intervals, power, and joins conditions", {
  phase18_source_power_helpers()

  # Synthetic recovery summary: three effect cells, two replicates each, one
  # parameter, with estimate + std.error (no fit needed). Wald intervals are
  # derived inside the assembler.
  summary <- data.frame(
    surface = "gaussian_ls",
    cell_id = rep(c("g_001", "g_002", "g_003"), each = 2L),
    parameter = "mu:x",
    truth = rep(c(0, 0.3, 0.6), each = 2L),
    estimate = c(0.02, -0.03, 0.30, 0.05, 0.60, 0.55),
    std.error = c(0.2, 0.2, 0.1, 0.1, 0.1, 0.1),
    stringsAsFactors = FALSE
  )
  conditions <- data.frame(
    cell_id = c("g_001", "g_002", "g_003"),
    surface = "gaussian_ls",
    effect_size = c(0, 0.3, 0.6),
    is_null = c(TRUE, FALSE, FALSE),
    n = c(200L, 200L, 200L),
    stringsAsFactors = FALSE
  )

  power <- phase18_assemble_power_table(
    summary,
    conditions = conditions,
    null_value = 0,
    by = c("surface", "cell_id", "parameter")
  )

  power <- power[order(power$cell_id), ]
  expect_equal(power$effect_size, c(0, 0.3, 0.6))
  expect_equal(power$n, c(200L, 200L, 200L))
  # g_001: both intervals straddle 0 -> 0. g_002: one excludes 0 -> 0.5.
  # g_003: both exclude 0 -> 1.
  expect_equal(power$power, c(0, 0.5, 1))
  expect_identical(
    power$inference,
    c("type_i_error", "power", "power")
  )
})

test_that("join_power_conditions keeps power rows and adds new columns only", {
  phase18_source_power_helpers()

  power <- data.frame(
    cell_id = c("c1", "c2"),
    parameter = "mu:x",
    power = c(0.4, 0.9),
    stringsAsFactors = FALSE
  )
  conditions <- data.frame(
    cell_id = c("c1", "c2"),
    parameter = "ignored",
    effect_size = c(0.2, 0.5),
    n = c(120L, 360L),
    stringsAsFactors = FALSE
  )

  joined <- phase18_join_power_conditions(power, conditions)

  expect_equal(nrow(joined), 2L)
  # parameter already exists in `power`, so the conditions copy is not merged in.
  expect_equal(joined$parameter, c("mu:x", "mu:x"))
  expect_true(all(c("effect_size", "n") %in% names(joined)))
  expect_equal(joined$effect_size[joined$cell_id == "c2"], 0.5)
})

test_that("power_curve_data adds an MCSE band and orders by sample size", {
  phase18_source_power_helpers()

  power_table <- data.frame(
    surface = "gaussian_ls",
    parameter = "mu:x",
    effect_size = 0.3,
    n = c(400L, 100L, 200L),
    power = c(0.90, 0.50, 0.75),
    power_mcse = c(0.02, 0.05, 0.03),
    stringsAsFactors = FALSE
  )

  curve <- phase18_power_curve_data(power_table)

  expect_equal(curve$n, c(100L, 200L, 400L))
  expect_true(all(c("power_low", "power_high") %in% names(curve)))
  expect_true(all(curve$power_low >= 0 & curve$power_high <= 1))
  expect_equal(
    curve$power_high,
    pmin(1, curve$power + stats::qnorm(0.975) * curve$power_mcse)
  )
})

test_that("power helpers extend to a sigma effect via named nulls", {
  phase18_source_power_helpers()

  # The same extraction works for sigma:z; only the null target changes.
  summary <- data.frame(
    surface = "gaussian_ls",
    cell_id = "g_sigma",
    parameter = c("mu:x", "sigma:z"),
    truth = c(0.5, 0.35),
    conf.low = c(0.2, 0.10),
    conf.high = c(0.8, 0.60),
    interval_status = "ok",
    stringsAsFactors = FALSE
  )

  power <- phase18_summarise_power(
    summary,
    by = c("cell_id", "parameter"),
    null_value = c("sigma:z" = 0)
  )

  sigma_row <- power[power$parameter == "sigma:z", ]
  mu_row <- power[power$parameter == "mu:x", ]
  expect_equal(sigma_row$power, 1)
  expect_equal(sigma_row$n_interval, 1L)
  # mu:x has no matching null target, so it contributes no usable interval.
  expect_equal(mu_row$n_interval, 0L)
})

test_that("power pipeline composes from DGP, fit, intervals, and summary", {
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

  # Two replicates of a clear mu slope at n = 200: both intervals should
  # exclude zero, so the power pipeline returns a finite power tagged "power".
  replicate_summary <- function(replicate, seed) {
    dat <- phase18_dgp_gaussian_ls(
      n = 200,
      beta_mu = c("(Intercept)" = 0.15, x = 0.6),
      beta_sigma = c("(Intercept)" = -0.2, z = 0.3),
      collinearity = 0.1,
      seed = seed,
      cell_id = "gaussian_ls_power_alt",
      replicate = replicate
    )
    fit <- drmTMB(bf(y ~ x, sigma ~ z), family = gaussian(), data = dat)
    phase18_summarise_gaussian_ls_fit(
      fit,
      attr(dat, "truth"),
      cell_id = "gaussian_ls_power_alt",
      replicate = replicate
    )
  }

  summary <- rbind(
    replicate_summary(1L, 20260601L),
    replicate_summary(2L, 20260602L)
  )
  summary <- summary[summary$parameter == "mu:x", ]
  intervals <- phase18_add_wald_intervals(summary, conf.level = 0.95)

  power <- phase18_summarise_power(
    intervals,
    by = c("surface", "cell_id", "parameter"),
    null_value = 0
  )

  expect_equal(nrow(power), 1L)
  expect_equal(power$n_interval, 2L)
  expect_true(is.finite(power$power))
  expect_equal(power$power, 1)
  expect_identical(power$inference, "power")
})
