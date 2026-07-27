source_phase18_meta_v_lss_runner <- function(env = parent.frame()) {
  for (path in c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/dgp/sim_dgp_meta_v.R",
    "sim/dgp/sim_dgp_meta_v_lss.R",
    "sim/fit/sim_summarise_meta_v_lss.R",
    "sim/run/sim_run_meta_v_lss_smoke.R"
  )) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Arc 7B smoke registry retains every scheduled layer and attempt", {
  source_phase18_meta_v_lss_runner()
  conditions <- phase18_meta_v_lss_smoke_conditions()
  expect_setequal(unique(conditions$layer), c("LS", "LSS", "LSSS", "DH"))
  expect_true(any(conditions$design_role == "weak_boundary"))
  expect_true(any(conditions$known_v_type == "dense"))
  registry <- phase18_cell_registry("meta_v_lss", conditions, n_rep = 2L, master_seed = 11L)
  expect_equal(nrow(registry$seeds), 2L * nrow(conditions))
})

test_that("Arc 8 dense ladder retains the historical failure fixture", {
  source_phase18_meta_v_lss_runner()
  conditions <- phase18_meta_v_lss_arc8_conditions()
  expect_equal(nrow(conditions), 4L)
  historical <- conditions[conditions$design_role == "dense_k12_historical_failure_control", ]
  expect_equal(historical$n_study, 12L)
  expect_equal(historical$sampling_rho, 0.25)
  expect_equal(historical$source_seed, 1592943833L)
  expect_true(all(conditions$layer == "LSS"))
  expect_true(all(conditions$known_v_type == "dense"))
})

test_that("Arc 8 registry restores the historical dense-control seed", {
  source_phase18_meta_v_lss_runner()
  registry <- phase18_cell_registry(
    "meta_v_lss_arc8", phase18_meta_v_lss_arc8_conditions()[1L, , drop = FALSE],
    1L, 2026072508L
  )
  out <- phase18_meta_v_lss_apply_source_seed(registry, 1L)
  expect_equal(out$seeds$seed, 1592943833L)
})

test_that("Arc 7B all-attempt summary keeps failed fits in its denominator", {
  source_phase18_meta_v_lss_runner()
  conditions <- phase18_meta_v_lss_smoke_conditions()[1L, , drop = FALSE]
  registry <- phase18_cell_registry("meta_v_lss", conditions, n_rep = 1L, master_seed = 12L)
  result <- list(
    cell_id = registry$cells$cell_id[[1L]], replicate = 1L,
    seed = registry$seeds$seed[[1L]], status = "error", warnings = character(),
    error = "deliberate retained failure", elapsed = 0.1, summary = NULL, skipped = FALSE
  )
  out <- phase18_meta_v_lss_all_attempt_summary(list(result), registry$cells, data.frame())
  expect_true(nrow(out) > 0L)
  expect_true(all(out$result_status == "error"))
  expect_true(all(is.na(out$estimate)))
  expect_true(all(out$interval_status[out$profile_eligible] == "outer_fit_failed"))
  reduction <- phase18_meta_v_lss_all_attempt_profile_reduction(out)
  expect_true(all(reduction$attempted == 1L))
  expect_true(all(reduction$usable_and_covering == 0L))
})

test_that("Arc 7B dense LSS sentinel retains incomplete direct-SD profiles", {
  source_phase18_meta_v_lss_runner()
  dense <- phase18_meta_v_lss_smoke_conditions()[5L, , drop = FALSE]
  run <- phase18_run_meta_v_lss_smoke(
    conditions = dense, n_rep = 1L, master_seed = 2026072407L
  )
  expect_equal(run$manifest$status, "ok")
  direct_sd <- run$summary[grepl("^sd:study:", run$summary$parameter), , drop = FALSE]
  expect_equal(nrow(direct_sd), 2L)
  expect_true(all(direct_sd$interval_status == "incomplete"))
  # K = 12 remains negative evidence whether profiling runs non-finite or
  # the trace-first guard detects clamp contact. Neither is a usable interval.
  expect_true(all(direct_sd$interval_message %in% c(
    "nonfinite_interval", "clamp_limited", "trace_incomplete"
  )))
  expect_true(all(direct_sd$result_status == "ok"))
  reduction <- phase18_meta_v_lss_all_attempt_profile_reduction(run$summary)
  direct_sd_reduction <- reduction[grepl("^sd:study:", reduction$parameter), , drop = FALSE]
  expect_true(all(direct_sd_reduction$complete_profile == 0L))
  expect_true(all(direct_sd_reduction$usable_and_covering == 0L))
})

test_that("Arc 8 bootstrap completion is target-wise and fail-closed", {
  source_phase18_meta_v_lss_runner()
  interval <- data.frame(
    parm = c("fixef:sd(study):(Intercept)", "fixef:sd(study):z_study"),
    bootstrap.n = c(190L, 188L),
    bootstrap.failed = c(9L, 11L),
    conf.status = c("bootstrap", "bootstrap_unavailable"),
    stringsAsFactors = FALSE
  )
  out <- phase18_meta_v_lss_bootstrap_completion(interval)
  expect_equal(out$bootstrap_requested, c(199L, 199L))
  expect_equal(out$bootstrap_completion_rate, c(190 / 199, 188 / 199))
  expect_identical(out$bootstrap_complete, c(TRUE, FALSE))
  expect_error(phase18_meta_v_lss_bootstrap_completion(interval, 0), "minimum_rate")
})

test_that("Arc 8 runner exposes bootstrap accounting for both direct-SD targets", {
  source_phase18_meta_v_lss_runner()
  conditions <- phase18_meta_v_lss_arc8_conditions()[2L, , drop = FALSE]
  run <- phase18_run_meta_v_lss_arc8(
    conditions = conditions, n_rep = 1L, master_seed = 2026072508L,
    bootstrap_R = 2L
  )
  direct <- run$summary[grepl("^sd:study:", run$summary$parameter), , drop = FALSE]
  expect_equal(nrow(direct), 2L)
  expect_true(all(direct$bootstrap_requested == 2L))
  expect_true(all(direct$bootstrap_finite_success +
    (direct$bootstrap_requested - direct$bootstrap_finite_success) == 2L))
  expect_true(all(!is.na(direct$bootstrap_status)))
  expect_true(all(run$summary$surface == "meta_v_lss_arc8"))
  expect_equal(nrow(run$bootstrap_diagnostics), 4L)
  expect_true(all(c("outer_seed", "refit_status", "draw_used") %in%
    names(run$bootstrap_diagnostics)))
  expect_equal(nrow(run$gate), 2L)
  expect_true(all(run$gate$profile_complete ==
    (run$gate$interval_status == "ok")))
})

test_that("Arc 8 gate requires both target-wise profile containment and bootstrap completion", {
  source_phase18_meta_v_lss_runner()
  summary <- data.frame(
    surface = "meta_v_lss_arc8", cell_id = "cell", replicate = 1L,
    design_role = "dense_k36_interior",
    parameter = c("sd:study:(Intercept)", "sd:study:z_study"),
    estimate = c(-0.6, 0.2), conf.low = c(-1, -0.1), conf.high = c(-0.2, 0.5),
    interval_status = "ok", bootstrap_complete = c(TRUE, FALSE),
    result_status = "ok", stringsAsFactors = FALSE
  )
  gate <- phase18_meta_v_lss_arc8_gate(summary)
  expect_true(all(gate$profile_complete))
  expect_identical(gate$target_complete, c(TRUE, FALSE))
  expect_false(any(gate$arc8_complete))
  expect_true(all(gate$gate_role == "interior_feasibility"))
  expect_false(any(gate$gate_pass))
  summary$estimate[[2L]] <- 0.8
  gate <- phase18_meta_v_lss_arc8_gate(summary)
  expect_false(gate$profile_complete[[2L]])
})

test_that("Arc 8 historical control passes only by retaining the expected failure", {
  source_phase18_meta_v_lss_runner()
  summary <- data.frame(
    surface = "meta_v_lss_arc8", cell_id = "control", replicate = 1L,
    design_role = "dense_k12_historical_failure_control",
    parameter = c("sd:study:(Intercept)", "sd:study:z_study"),
    estimate = c(-0.6, 0.2), conf.low = NA_real_, conf.high = NA_real_,
    interval_status = "incomplete", bootstrap_complete = FALSE,
    result_status = "ok", stringsAsFactors = FALSE
  )
  gate <- phase18_meta_v_lss_arc8_gate(summary)
  expect_false(any(gate$arc8_complete))
  expect_true(all(gate$expected_control_reproduced))
  expect_true(all(gate$gate_role == "negative_control"))
  expect_true(all(gate$gate_pass))
})
