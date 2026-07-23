test_that("Phase 18 meta_V conditions separate vector and dense V cells", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
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

  conditions <- phase18_meta_v_conditions(
    n_study = c(24L, 48L),
    known_v_type = c("vector", "dense"),
    sigma = 0.2,
    sampling_sd = 0.15,
    sampling_rho = c(0, 0.3)
  )

  expect_true(all(conditions$known_v_type %in% c("vector", "dense")))
  expect_true(all(
    conditions$sampling_rho[conditions$known_v_type == "vector"] == 0
  ))
  expect_true(any(
    conditions$known_v_type == "dense" & conditions$sampling_rho == 0.3
  ))
})

test_that("Phase 18 meta_V B3 conditions retain the K = 12 boundary cell", {
  source(
    system.file("sim/dgp/sim_dgp_meta_v.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  conditions <- phase18_meta_v_b3_conditions()
  key <- do.call(paste, c(conditions[c(
    "n_study", "known_v_type", "sigma", "sampling_sd", "sampling_rho"
  )], sep = "\r"))
  expect_equal(nrow(conditions), 14L)
  expect_equal(anyDuplicated(key), 0L)
  expect_true(any(
    conditions$n_study == 12L &
      conditions$known_v_type == "vector" &
      conditions$sigma == 0.10 &
      conditions$sampling_sd == 0.12 &
      conditions$sampling_rho == 0
  ))
  expect_setequal(
    unique(conditions$design_role),
    c("boundary_ladder", "known_v_stress", "interior_control")
  )
})

test_that("Phase 18 meta_V DGP returns vector and dense known covariance", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
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

  dat_vec <- phase18_dgp_meta_v(
    n_study = 18,
    known_v_type = "vector",
    seed = 212,
    cell_id = "meta_v_001",
    replicate = 1L
  )
  dat_vec_again <- phase18_dgp_meta_v(
    n_study = 18,
    known_v_type = "vector",
    seed = 212,
    cell_id = "meta_v_001",
    replicate = 1L
  )
  V_vec <- attr(dat_vec, "V")
  truth_vec <- attr(dat_vec, "truth")

  dat_dense <- phase18_dgp_meta_v(
    n_study = 18,
    known_v_type = "dense",
    sampling_rho = 0.25,
    seed = 213
  )
  V_dense <- attr(dat_dense, "V")
  truth_dense <- attr(dat_dense, "truth")

  expect_equal(dat_vec, dat_vec_again)
  expect_equal(nrow(dat_vec), 18L)
  expect_equal(length(V_vec), 18L)
  expect_false(is.matrix(V_vec))
  expect_true(all(V_vec > 0))
  expect_identical(truth_vec$surface, "meta_v")
  expect_identical(truth_vec$known_v_type, "vector")

  expect_true(is.matrix(V_dense))
  expect_equal(dim(V_dense), c(18L, 18L))
  expect_true(all(
    eigen(V_dense, symmetric = TRUE, only.values = TRUE)$values > 0
  ))
  expect_equal(dat_dense$sampling_var, diag(V_dense))
  expect_identical(truth_dense$known_v_type, "dense")
})

test_that("Phase 18 meta_V pilot fits keep V out of interval targets", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
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

  dat_vec <- phase18_dgp_meta_v(
    n_study = 64,
    known_v_type = "vector",
    beta_mu = c("(Intercept)" = 0.10, x = 0.35),
    sigma = 0.30,
    sampling_sd = 0.15,
    seed = 2026212,
    cell_id = "meta_v_001",
    replicate = 1L
  )
  V_vec <- attr(dat_vec, "V")
  fit_vec <- drmTMB(
    bf(yi ~ x + meta_V(V = V_vec), sigma ~ 1),
    family = gaussian(),
    data = dat_vec
  )
  targets_vec <- profile_targets(fit_vec)
  summary_vec <- phase18_summarise_meta_v_fit(
    fit_vec,
    attr(dat_vec, "truth"),
    cell_id = "meta_v_001",
    replicate = 1L
  )

  dat_dense <- phase18_dgp_meta_v(
    n_study = 48,
    known_v_type = "dense",
    beta_mu = c("(Intercept)" = 0.10, x = 0.35),
    sigma = 0.25,
    sampling_sd = 0.13,
    sampling_rho = 0.20,
    seed = 2026213,
    cell_id = "meta_v_002",
    replicate = 1L
  )
  V_dense <- attr(dat_dense, "V")
  fit_dense <- drmTMB(
    bf(yi ~ x + meta_V(V = V_dense), sigma ~ 1),
    family = gaussian(),
    data = dat_dense
  )
  targets_dense <- profile_targets(fit_dense)
  summary_dense <- phase18_summarise_meta_v_fit(
    fit_dense,
    attr(dat_dense, "truth"),
    cell_id = "meta_v_002",
    replicate = 1L
  )

  expect_equal(fit_vec$opt$convergence, 0)
  expect_equal(fit_dense$opt$convergence, 0)
  expect_true(fit_vec$sdr$pdHess)
  expect_true(fit_dense$sdr$pdHess)
  expect_true("sigma" %in% targets_vec$parm)
  expect_true("sigma" %in% targets_dense$parm)
  expect_false(any(grepl("V_known|meta", targets_vec$parm)))
  expect_false(any(grepl("V_known|meta", targets_dense$parm)))
  expect_equal(summary_vec$parameter, c("mu:(Intercept)", "mu:x", "sigma"))
  expect_equal(summary_dense$parameter, c("mu:(Intercept)", "mu:x", "sigma"))
  expect_true(all(summary_vec$converged))
  expect_true(all(summary_dense$converged))
  expect_true(all(is.finite(summary_vec$std.error)))
  expect_true(all(is.finite(summary_dense$std.error)))
  expect_true(all(summary_vec$std.error > 0))
  expect_true(all(summary_dense$std.error > 0))
  expect_lt(max(abs(summary_vec$error)), 0.35)
  expect_lt(max(abs(summary_dense$error)), 0.35)
})

test_that("Phase 18 meta_V keeps the K = 12 zero-infinite sigma interval", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/dgp/sim_dgp_meta_v.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/fit/sim_summarise_meta_v.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  dat <- phase18_dgp_meta_v(
    n_study = 12L,
    known_v_type = "vector",
    sigma = 0.10,
    sampling_sd = 0.12,
    seed = 4L,
    cell_id = "meta_v_boundary",
    replicate = 1L
  )
  V <- attr(dat, "V")
  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = V), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  summary <- phase18_summarise_meta_v_fit(
    fit,
    attr(dat, "truth"),
    cell_id = "meta_v_boundary",
    replicate = 1L
  )
  sigma_row <- summary[summary$parameter == "sigma", , drop = FALSE]

  expect_equal(sigma_row$conf.low, 0)
  expect_true(is.infinite(sigma_row$conf.high))
  expect_identical(sigma_row$conf.status, "wald")
  expect_identical(sigma_row$interval_status, "degenerate_zero_infinite")
})

test_that("Phase 18 meta_V DGP rejects malformed known-V inputs", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
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

  expect_error(phase18_dgp_meta_v(0), "positive whole number")
  expect_error(phase18_dgp_meta_v(10, sigma = 0), "positive finite")
  expect_error(
    phase18_dgp_meta_v(10, known_v_type = "vector", sampling_rho = 0.2),
    "sampling_rho"
  )
  expect_error(
    phase18_summarise_meta_v_fit(list(), list(surface = "gaussian_ls")),
    "meta_V truth"
  )
})

test_that("Phase 18 meta_V keeps every attempted fit in primary accounting", {
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/R/sim_uncertainty.R",
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

  cell <- data.frame(
    cell_id = "meta_v_001",
    surface = "meta_v",
    n_study = 12L,
    known_v_type = "vector",
    beta_mu_intercept = 0.20,
    beta_mu_x = 0.45,
    sigma = 0.10,
    sampling_sd = 0.12,
    sampling_rho = 0,
    stringsAsFactors = FALSE
  )
  successful_summary <- data.frame(
    surface = "meta_v",
    known_v_type = "vector",
    cell_id = "meta_v_001",
    replicate = rep(1L, 3L),
    parameter = c("mu:(Intercept)", "mu:x", "sigma"),
    truth = c(0.20, 0.45, 0.10),
    estimate = c(0.20, 0.45, 0.001),
    std.error = c(0.10, 0.10, 0.20),
    error = c(0, 0, -0.099),
    converged = TRUE,
    pdHess = TRUE,
    nobs = 12L,
    elapsed = 0.1,
    warning_count = 0L,
    warnings = "",
    conf.low = c(NA_real_, NA_real_, 0),
    conf.high = c(NA_real_, NA_real_, Inf),
    interval_method = c(NA_character_, NA_character_, "wald"),
    interval_status = c(
      "not_requested", "not_requested", "degenerate_zero_infinite"
    ),
    conf.status = c(NA_character_, NA_character_, "wald"),
    interval_message = c(NA_character_, NA_character_, ""),
    stringsAsFactors = FALSE
  )
  results <- list(
    list(
      cell_id = "meta_v_001",
      replicate = 1L,
      seed = 101L,
      status = "ok",
      summary = successful_summary,
      warnings = character(),
      error = NULL,
      elapsed = 0.1,
      skipped = FALSE
    ),
    list(
      cell_id = "meta_v_001",
      replicate = 2L,
      seed = 102L,
      status = "error",
      summary = NULL,
      warnings = character(),
      error = "fit failed",
      elapsed = 0.2,
      skipped = FALSE
    )
  )
  all_attempts <- phase18_meta_v_all_attempt_summary(
    results = results,
    cells = cell,
    successful_summary = successful_summary
  )
  intervals <- phase18_add_wald_intervals(
    all_attempts,
    interval_scale = ifelse(
      all_attempts$parameter == "sigma",
      "public",
      "formula_coefficient"
    )
  )
  sigma_rows <- intervals$parameter == "sigma"
  intervals$conf.low[sigma_rows] <- all_attempts$conf.low[sigma_rows]
  intervals$conf.high[sigma_rows] <- all_attempts$conf.high[sigma_rows]
  intervals$interval_status[sigma_rows] <- all_attempts$interval_status[sigma_rows]
  intervals <- phase18_meta_v_classify_attempts(intervals)
  aggregate <- phase18_meta_v_aggregate_all_attempts(
    intervals,
    by = c("surface", "known_v_type", "cell_id", "parameter")
  )
  manifest <- phase18_meta_v_attempt_manifest(intervals)
  all_attempt_coverage <- phase18_meta_v_all_attempt_coverage(
    intervals,
    by = c("surface", "known_v_type", "cell_id", "parameter")
  )
  conditional_coverage <- phase18_meta_v_conditional_finite_coverage(
    intervals,
    by = c("surface", "known_v_type", "cell_id", "parameter")
  )

  expect_equal(nrow(all_attempts), 6L)
  expect_equal(sum(all_attempts$result_status == "error"), 3L)
  expect_true(all(is.na(all_attempts$estimate[all_attempts$replicate == 2L])))
  expect_equal(nrow(manifest), 2L)
  expect_equal(manifest$n_fit_error[manifest$replicate == 2L], 3L)
  expect_equal(manifest$n_interval_degenerate[manifest$replicate == 1L], 1L)
  expect_equal(aggregate$n_attempt, rep(2L, 3L))
  expect_equal(aggregate$n_fit_error, rep(1L, 3L))
  expect_false(any(c(
    "bias", "rmse", "mean_estimate", "convergence_rate", "pdHess_rate"
  ) %in% names(aggregate)))
  expect_true(all(c(
    "bias_finite_estimate_only", "rmse_finite_estimate_only",
    "n_finite_estimate_only"
  ) %in% names(aggregate)))
  expect_equal(
    all_attempt_coverage$rate_definition,
    rep("finite_and_covering_interval_over_all_attempts", 3L)
  )
  expect_equal(
    all_attempt_coverage$finite_and_covering_interval_rate_all_attempt[
      all_attempt_coverage$parameter == "sigma"
    ],
    0
  )
  expect_equal(
    all_attempt_coverage$finite_interval_rate_all_attempt[
      all_attempt_coverage$parameter == "sigma"
    ],
    0
  )
  expect_equal(
    conditional_coverage$rate_definition,
    rep("set_coverage_given_finite_interval", 3L)
  )
  expect_true(is.na(
    conditional_coverage$conditional_finite_interval_set_coverage[
      conditional_coverage$parameter == "sigma"
    ]
  ))
  sigma_interval <- intervals[intervals$parameter == "sigma" & intervals$replicate == 1L, ]
  expect_equal(sigma_interval$conf.low, 0)
  expect_true(is.infinite(sigma_interval$conf.high))
  expect_identical(sigma_interval$attempt_status, "degenerate_interval")

  status_probe <- intervals[rep(1L, 4L), , drop = FALSE]
  status_probe$result_status <- "ok"
  status_probe$converged <- c(FALSE, TRUE, TRUE, TRUE)
  status_probe$pdHess <- c(TRUE, FALSE, TRUE, TRUE)
  status_probe$estimate <- c(0.20, 0.20, NA_real_, 0.20)
  status_probe$interval_status <- c("ok", "ok", "ok", "failed")
  status_probe$conf.low <- c(0.10, 0.10, NA_real_, NA_real_)
  status_probe$conf.high <- c(0.30, 0.30, NA_real_, NA_real_)
  status_probe <- phase18_meta_v_classify_attempts(status_probe)
  expect_identical(
    status_probe$attempt_status,
    c("nonconverged", "pdHess_false", "nonfinite_estimate", "interval_failed")
  )
  expect_false(any(status_probe$finite_interval))
  probe_coverage <- phase18_meta_v_all_attempt_coverage(
    status_probe,
    by = c("surface", "known_v_type", "cell_id", "parameter")
  )
  probe_conditional <- phase18_meta_v_conditional_finite_coverage(
    status_probe,
    by = c("surface", "known_v_type", "cell_id", "parameter")
  )
  expect_equal(probe_coverage$n_finite_interval, 0L)
  expect_equal(probe_coverage$finite_and_covering_interval_rate_all_attempt, 0)
  expect_equal(probe_conditional$n_finite_interval, 0L)
})
