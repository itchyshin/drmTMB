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

phase18_fake_q8_staged_target_fit <- function(shift = 0) {
  sd_mu_names <- c(
    "mu1:(1 + x | p | id):(Intercept)",
    "mu1:(1 + x | p | id):x",
    "mu2:(1 + x | p | id):(Intercept)",
    "mu2:(1 + x | p | id):x"
  )
  sd_sigma_names <- c(
    "sigma1:(1 + x | p | id):(Intercept)",
    "sigma1:(1 + x | p | id):x",
    "sigma2:(1 + x | p | id):(Intercept)",
    "sigma2:(1 + x | p | id):x"
  )
  sd_mu <- stats::setNames(
    c(0.34, 0.16, 0.36, 0.15) + shift,
    sd_mu_names
  )
  sd_sigma <- stats::setNames(
    c(0.16, 0.07, 0.17, 0.06) + shift,
    sd_sigma_names
  )
  dpar <- rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 2L)
  coef <- rep(c("(Intercept)", "x"), 4L)
  pairs <- utils::combn(seq_along(dpar), 2L)
  cor_names <- vapply(
    seq_len(ncol(pairs)),
    function(j) {
      pair <- pairs[, j]
      paste0(
        "cor(",
        dpar[[pair[[1L]]]],
        ":",
        coef[[pair[[1L]]]],
        ",",
        dpar[[pair[[2L]]]],
        ":",
        coef[[pair[[2L]]]],
        " | p | id)"
      )
    },
    character(1L)
  )
  cor_re_cov <- stats::setNames(
    rep(0.02, 28L),
    cor_names
  )
  list(
    sdpars = list(mu = sd_mu, sigma = sd_sigma),
    corpars = list(re_cov = cor_re_cov),
    rho12 = c(rho12 = 0.08 + shift)
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
    max_abs_gradient = c(0.02, 0.01),
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
  out <- list(
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
  out$fits <- list(
    cold = list(
      label = "cold",
      ok = TRUE,
      fit = phase18_fake_q8_staged_target_fit(shift = 0.001),
      metrics = metrics[1L, , drop = FALSE]
    ),
    staged = list(
      label = "staged",
      ok = TRUE,
      fit = phase18_fake_q8_staged_target_fit(shift = 0),
      metrics = metrics[2L, , drop = FALSE]
    )
  )
  out
}

test_that("Phase 18 q8 staged metrics tolerate unnamed fixed gradients", {
  fit <- list(
    opt = list(
      convergence = 0L,
      objective = 1.25,
      par = c(0.1, 0.2, 0.3),
      message = "relative convergence",
      iterations = 4L,
      evaluations = c("function" = 8, gradient = 5)
    ),
    sdr = list(pdHess = TRUE, message = "ok"),
    df = 3,
    nobs = 24,
    optimizer_used = list(optimizer_preset = "fake"),
    control = list(optimizer = c(iter.max = 100, eval.max = 200), se = FALSE),
    obj = list(gr = function(par) c(0.01, -0.20, 0.03))
  )

  metrics <- drm_qgt2_staged_fit_metrics(
    fit = fit,
    label = "unnamed-gradient",
    ok = TRUE,
    elapsed = 0.01,
    warnings = character(),
    error = NA_character_
  )

  expect_equal(metrics$max_abs_gradient, 0.20)
  expect_identical(metrics$max_gradient_component, "2")
  expect_identical(metrics$fixed_gradient_status, "warning")
  expect_identical(metrics$failure_mode, "fixed_gradient_warning")
})

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
  expect_equal(nrow(out$endpoint_status), 74L)
  endpoint_counts <- table(out$endpoint_status$endpoint_scope)
  expect_equal(
    as.integer(endpoint_counts),
    c(56L, 16L, 2L)
  )
  expect_equal(
    names(endpoint_counts),
    c("q8_derived_correlation", "q8_direct_sd", "residual_rho12_separate")
  )
  expect_true(all(out$endpoint_status$availability_status == "estimated"))
  expect_true(
    all(
      out$endpoint_status$point_status ==
        "diagnostic_estimate_with_fit_warnings"
    )
  )
  expect_true(all(out$endpoint_status$se_status == "not_requested"))
  expect_true(all(grepl(
    "failure_mode=",
    out$endpoint_status$availability_reason
  )))
  expect_true(all(out$endpoint_status$interval_status == "not_requested"))
  expect_equal(
    out$endpoint_status$endpoint_index[
      out$endpoint_status$endpoint_scope == "q8_direct_sd"
    ],
    rep(seq_len(8L), times = 2L)
  )
  expect_equal(
    unique(out$endpoint_status$endpoint_role),
    c(
      "intercept",
      "slope",
      "derived_correlation",
      "residual_correlation"
    )
  )
  expect_equal(
    unique(out$endpoint_status$max_abs_gradient),
    c(0.02, 0.01)
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
  expect_equal(nrow(utils::read.csv(out$paths$endpoint_status_csv)), 74L)
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
