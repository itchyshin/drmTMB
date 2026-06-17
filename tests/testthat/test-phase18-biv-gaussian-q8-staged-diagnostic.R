source_phase18_biv_gaussian_q8_staged_diagnostic <- function() {
  env <- parent.frame()
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R",
    "sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

phase18_fake_q8_staged_source_fit <- function(formula, family, data, control) {
  list(
    formula = formula,
    family = family,
    control = control,
    model = list(model_type = "biv_gaussian_q4_fake"),
    nobs = nrow(data)
  )
}

phase18_fake_q8_staged_diagnostic <- function(
  source_fit,
  target_spec,
  formula,
  family,
  control,
  copy_theta_re_cov = FALSE,
  theta_re_cov_shrink = 0.85
) {
  metrics <- data.frame(
    label = c("cold", "staged"),
    ok = c(TRUE, TRUE),
    convergence = c(0L, 0L),
    pdHess = c(FALSE, TRUE),
    objective = c(10, 8),
    logLik = c(-10, -8),
    df = c(3, 3),
    nobs = c(target_spec$nobs, target_spec$nobs),
    elapsed_sec = c(0.20, 0.12),
    optimizer_preset = c("fake", "fake"),
    warning_count = c(0L, 0L),
    warnings = c("", ""),
    error = c(NA_character_, NA_character_),
    stringsAsFactors = FALSE
  )
  deltas <- data.frame(
    metric = c("objective", "logLik", "elapsed_sec"),
    cold = c(10, -10, 0.20),
    staged = c(8, -8, 0.12),
    staged_minus_cold = c(-2, 2, -0.08),
    stringsAsFactors = FALSE
  )
  list(
    strategy = "qgt2-staged-fit-diagnostic",
    provenance = list(
      source_model_type = source_fit$model$model_type,
      target_model_type = target_spec$model_type,
      fixed_effect_matches = data.frame(parameter = paste0("b", 1:5)),
      qgt2_sd_matches = data.frame(parameter = paste0("sd", 1:8)),
      qgt2_theta_matches = data.frame(parameter = paste0("theta", 1:4)),
      theta_re_cov = if (copy_theta_re_cov) "copied" else "not_requested",
      theta_re_cov_shrink = if (copy_theta_re_cov) {
        theta_re_cov_shrink
      } else {
        NA_real_
      }
    ),
    fits = list(),
    comparison = list(metrics = metrics, deltas = deltas)
  )
}

test_that("Phase 18 q8 staged diagnostic summarises cold and staged fits", {
  source_phase18_biv_gaussian_q8_staged_diagnostic()

  result_dir <- tempfile("phase18-q8-staged-diagnostic-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  out <- phase18_summarise_biv_gaussian_q8_endpoint_staged_diagnostic(
    conditions = phase18_biv_gaussian_q8_endpoint_conditions(
      n_id = 10L,
      n_each = 4L
    ),
    n_rep = 1L,
    master_seed = 20260636L,
    result_dir = result_dir,
    source_fit_fun = phase18_fake_q8_staged_source_fit,
    diagnostic_fun = phase18_fake_q8_staged_diagnostic
  )

  expect_identical(out$surface, "biv_gaussian_q8_endpoint_staged_diagnostic")
  expect_equal(nrow(out$metrics), 2L)
  expect_equal(out$metrics$fit_label, c("cold", "staged"))
  expect_equal(nrow(out$deltas), 3L)
  expect_equal(
    out$deltas$staged_minus_cold[out$deltas$delta_metric == "objective"],
    -2
  )
  expect_equal(nrow(out$provenance), 1L)
  expect_equal(out$provenance$fixed_effect_match_count, 5L)
  expect_equal(out$provenance$qgt2_sd_match_count, 8L)
  expect_equal(out$provenance$qgt2_theta_match_count, 4L)
  expect_equal(nrow(out$scope), 1L)
  expect_match(out$scope$diagnostic_scope, "diagnostic_only")
  expect_match(out$scope$unsupported_claims, "numerical guards")
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
})

test_that("Phase 18 q8 staged diagnostic grid writer saves split tables", {
  source_phase18_biv_gaussian_q8_staged_diagnostic()

  output_dir <- tempfile("phase18-q8-staged-diagnostic-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_biv_gaussian_q8_endpoint_conditions(
      n_id = 10L,
      n_each = 4L
    ),
    n_rep = 1L,
    master_seed = 20260636L,
    source_fit_fun = phase18_fake_q8_staged_source_fit,
    diagnostic_fun = phase18_fake_q8_staged_diagnostic
  )

  expect_identical(
    out$surface,
    "biv_gaussian_q8_endpoint_staged_diagnostic_grid"
  )
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_equal(nrow(utils::read.csv(out$paths$metrics_csv)), 2L)
  expect_equal(nrow(utils::read.csv(out$paths$deltas_csv)), 3L)
  expect_equal(nrow(utils::read.csv(out$paths$provenance_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$scope_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$manifest_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$failures_csv)), 0L)
  expect_error(
    phase18_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid_outputs(
      output_dir = output_dir,
      n_rep = 1L,
      master_seed = 20260636L,
      source_fit_fun = phase18_fake_q8_staged_source_fit,
      diagnostic_fun = phase18_fake_q8_staged_diagnostic
    ),
    "already exists"
  )
})
