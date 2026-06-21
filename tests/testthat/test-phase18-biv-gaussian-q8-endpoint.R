source_phase18_biv_gaussian_q8_endpoint <- function() {
  env <- parent.frame()
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/R/sim_bootstrap.R",
    "sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R",
    "sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R",
    "sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_write_biv_gaussian_q8_endpoint_grid.R",
    "sim/run/sim_write_biv_gaussian_q8_endpoint_diagnostic_grid.R",
    "sim/run/sim_run_biv_gaussian_q8_usability_pilot.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 bivariate Gaussian q8 endpoint DGP is seeded", {
  source_phase18_biv_gaussian_q8_endpoint()

  conditions <- phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 12L,
    n_each = 6L
  )
  dat <- phase18_dgp_biv_gaussian_q8_endpoint(
    n_id = 12L,
    n_each = 6L,
    seed = 241L,
    cell_id = "biv_gaussian_q8_endpoint_001",
    replicate = 1L
  )
  again <- phase18_dgp_biv_gaussian_q8_endpoint(
    n_id = 12L,
    n_each = 6L,
    seed = 241L,
    cell_id = "biv_gaussian_q8_endpoint_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 1L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 72L)
  expect_named(
    dat,
    c(
      "y1",
      "y2",
      "x",
      "id",
      "mu1",
      "mu2",
      "sigma1",
      "sigma2",
      "cell_id",
      "replicate"
    )
  )
  expect_identical(truth$surface, "biv_gaussian_q8_endpoint")
  expect_named(truth$beta_mu1, c("(Intercept)", "x"))
  expect_named(truth$beta_mu2, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma1, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma2, c("(Intercept)", "x"))
  expect_named(truth$sd_mu, phase18_biv_gaussian_q8_endpoint_sd_mu_names())
  expect_named(
    truth$sd_sigma,
    phase18_biv_gaussian_q8_endpoint_sd_sigma_names()
  )
  expect_named(truth$cor_re_cov, phase18_biv_gaussian_q8_endpoint_cor_names())
})

test_that("Phase 18 bivariate Gaussian q8 endpoint diagnostic presets are bounded", {
  source_phase18_biv_gaussian_q8_endpoint()

  grid <- phase18_biv_gaussian_q8_endpoint_diagnostic_conditions("all")
  expect_equal(nrow(grid), 12L)
  expect_equal(
    names(grid)[seq_len(4L)],
    c(
      "diagnostic_id",
      "diagnostic_preset",
      "diagnostic_level",
      "diagnostic_note"
    )
  )
  expect_equal(grid$diagnostic_id, sprintf("q8_diag_%03d", seq_len(12L)))
  expect_setequal(
    grid$diagnostic_preset,
    c("replication", "sd_ratio", "rho12", "correlation")
  )
  expect_equal(
    as.integer(table(grid$diagnostic_preset)[
      c("replication", "sd_ratio", "rho12", "correlation")
    ]),
    rep(3L, 4L)
  )
  expect_true(all(nzchar(grid$diagnostic_note)))

  replication <- grid[grid$diagnostic_preset == "replication", , drop = FALSE]
  expect_equal(replication$diagnostic_level, c("low", "baseline", "high"))
  expect_true(all(diff(replication$n_id) > 0))
  expect_true(all(diff(replication$n_each) > 0))

  sd_grid <- grid[grid$diagnostic_preset == "sd_ratio", , drop = FALSE]
  sd_cols <- c(
    "sd_mu1_intercept",
    "sd_mu1_x",
    "sd_mu2_intercept",
    "sd_mu2_x",
    "sd_sigma1_intercept",
    "sd_sigma1_x",
    "sd_sigma2_intercept",
    "sd_sigma2_x"
  )
  weak <- sd_grid[sd_grid$diagnostic_level == "weak", sd_cols, drop = FALSE]
  baseline <- sd_grid[
    sd_grid$diagnostic_level == "baseline",
    sd_cols,
    drop = FALSE
  ]
  strong <- sd_grid[sd_grid$diagnostic_level == "strong", sd_cols, drop = FALSE]
  expect_true(all(unlist(weak, use.names = FALSE) < unlist(baseline)))
  expect_true(all(unlist(strong, use.names = FALSE) > unlist(baseline)))

  rho <- grid[grid$diagnostic_preset == "rho12", , drop = FALSE]
  expect_equal(
    stats::setNames(rho$residual_rho, rho$diagnostic_level),
    c(negative = -0.65, zero = 0, positive = 0.65)
  )

  correlation <- grid[
    grid$diagnostic_preset == "correlation", ,
    drop = FALSE
  ]
  cor_cols <- c(
    "cor_base",
    "cor_mu_intercept",
    "cor_mu_x",
    "cor_sigma_intercept",
    "cor_sigma_x",
    "cor_mu1_sigma1_intercept",
    "cor_mu1_sigma1_x"
  )
  zero <- correlation[
    correlation$diagnostic_level == "zero",
    cor_cols,
    drop = FALSE
  ]
  expect_equal(unlist(zero, use.names = FALSE), rep(0, length(cor_cols)))
  min_eigen <- vapply(
    seq_len(nrow(correlation)),
    function(i) {
      row <- correlation[i, , drop = FALSE]
      corr <- phase18_biv_gaussian_q8_endpoint_cor_matrix(
        phase18_biv_gaussian_q8_endpoint_correlations(
          cor_base = row$cor_base[[1L]],
          cor_mu_intercept = row$cor_mu_intercept[[1L]],
          cor_mu_x = row$cor_mu_x[[1L]],
          cor_sigma_intercept = row$cor_sigma_intercept[[1L]],
          cor_sigma_x = row$cor_sigma_x[[1L]],
          cor_mu1_sigma1_intercept = row$cor_mu1_sigma1_intercept[[1L]],
          cor_mu1_sigma1_x = row$cor_mu1_sigma1_x[[1L]]
        )
      )
      min(eigen(corr, symmetric = TRUE, only.values = TRUE)$values)
    },
    numeric(1L)
  )
  expect_true(all(min_eigen > 0))

  positive_rho <- rho[rho$diagnostic_level == "positive", , drop = FALSE]
  dat <- phase18_dgp_biv_gaussian_q8_endpoint_cell(
    cell = positive_rho,
    seed = 241L,
    cell_id = positive_rho$diagnostic_id[[1L]],
    replicate = 1L
  )
  expect_equal(attr(dat, "truth")$residual_rho, c(rho12 = 0.65))
  expect_equal(attr(dat, "truth")$diagnostic_id, "q8_diag_009")
  expect_equal(attr(dat, "truth")$diagnostic_preset, "rho12")
  expect_equal(attr(dat, "truth")$diagnostic_level, "positive")
  expect_equal(unique(dat$cell_id), positive_rho$diagnostic_id[[1L]])

  expect_equal(
    phase18_biv_gaussian_q8_endpoint_diagnostic_conditions("rho12")[[
      "diagnostic_preset"
    ]],
    rep("rho12", 3L)
  )
  expect_error(
    phase18_biv_gaussian_q8_endpoint_diagnostic_conditions("missing"),
    "should be one of"
  )

  audit <- phase18_biv_gaussian_q8_endpoint_diagnostic_audit_conditions()
  expect_equal(nrow(audit), 5L)
  expect_equal(
    paste(audit$diagnostic_preset, audit$diagnostic_level, sep = ":"),
    c(
      "replication:low",
      "sd_ratio:weak",
      "rho12:negative",
      "rho12:positive",
      "correlation:high"
    )
  )
  expect_equal(
    phase18_biv_gaussian_q8_endpoint_diagnostic_audit_conditions("all"),
    grid
  )
})

test_that("Phase 18 q8 usability conditions include sample-size ladder", {
  source_phase18_biv_gaussian_q8_endpoint()

  conditions <- phase18_biv_gaussian_q8_usability_conditions()
  sample_size <- conditions[
    conditions$usability_axis == "sample_size", ,
    drop = FALSE
  ]

  expect_equal(nrow(sample_size), 3L)
  expect_equal(sample_size$diagnostic_level, c("low", "baseline", "high"))
  expect_equal(sample_size$n_id, c(24L, 48L, 96L))
  expect_equal(sample_size$n_each, c(6L, 10L, 12L))
  expect_equal(
    paste(
      conditions$diagnostic_preset,
      conditions$diagnostic_level,
      sep = ":"
    )[seq_len(5L)],
    c(
      "replication:low",
      "sd_ratio:weak",
      "rho12:negative",
      "rho12:positive",
      "correlation:high"
    )
  )
})

test_that("Phase 18 q8 optimizer-budget helpers preserve audit metadata", {
  source_phase18_biv_gaussian_q8_endpoint()

  budgets <- phase18_biv_gaussian_q8_optimizer_budgets()
  rows <- phase18_q8_optimizer_budget_rows(budgets)
  condition <- phase18_biv_gaussian_q8_usability_sample_size_conditions()[
    3L, ,
    drop = FALSE
  ]
  fit_row <- phase18_q8_usability_fit_row(
    fit = simpleError("synthetic failure"),
    truth = list(),
    condition = condition,
    strategy = "cold",
    se = TRUE,
    optimizer_label = "budget_1600",
    optimizer = budgets$budget_1600,
    elapsed = 0.1,
    warnings = "synthetic warning"
  )
  mapping_rows <- phase18_q8_mapping_rows(
    mapping = list(
      provenance = list(
        qgt2_sd_matches = data.frame(
          target_name = "log_sd_re_cov",
          source_name = "log_sd_re_cov",
          stringsAsFactors = FALSE
        ),
        qgt2_theta_matches = data.frame()
      )
    ),
    condition = condition,
    strategy = "q4_sd_staged",
    se = FALSE,
    optimizer_label = "budget_1600",
    optimizer = budgets$budget_1600
  )

  expect_equal(names(budgets), c("baseline_800", "budget_1600"))
  expect_equal(rows$optimizer_label, names(budgets))
  expect_equal(rows$eval_max, c(800L, 1600L))
  expect_equal(rows$iter_max, c(800L, 1600L))
  expect_error(
    phase18_q8_optimizer_budget_rows(list(list(eval.max = 1L))),
    "`optimizer_budgets` must be a named list"
  )
  expect_equal(fit_row$optimizer_label, "budget_1600")
  expect_equal(fit_row$eval_max, 1600L)
  expect_equal(fit_row$iter_max, 1600L)
  expect_equal(fit_row$status, "error")
  expect_equal(fit_row$warning_count, 1L)
  expect_equal(length(mapping_rows), 1L)
  expect_equal(mapping_rows[[1L]]$optimizer_label, "budget_1600")
  expect_equal(mapping_rows[[1L]]$eval_max, 1600L)
  expect_equal(mapping_rows[[1L]]$mapping_type, "sd")
})

test_that("Phase 18 q8 derived-correlation bootstrap intervals keep failures explicit", {
  source_phase18_biv_gaussian_q8_endpoint()

  draws <- data.frame(
    parameter = c("a", "a", "a", "b", "b"),
    estimate = c(0.1, 0.2, NA, -0.1, 0.4),
    status = c("ok", "ok", "nonconverged", "ok", "error"),
    stringsAsFactors = FALSE
  )
  intervals <- phase18_bootstrap_percentile_intervals(
    draws,
    conf.level = 0.70
  )

  expect_equal(intervals$parameter, c("a", "b"))
  expect_equal(intervals$n_bootstrap, c(2L, 1L))
  expect_equal(intervals$interval_status, c("ok", "failed"))
  expect_true(is.finite(intervals$conf.low[[1L]]))
  expect_true(is.finite(intervals$conf.high[[1L]]))
  expect_equal(intervals$interval_message[[2L]], "fewer than two finite bootstrap estimates")
})

test_that("Phase 18 q8 usability helpers preserve audit rows", {
  source_phase18_biv_gaussian_q8_endpoint()

  x <- 2
  captured <- phase18_capture_q8_usability_expr(
    quote(x + 1),
    envir = environment(),
    elapsed_limit = 10
  )
  expect_equal(captured$value, 3)
  expect_error(
    phase18_capture_q8_usability_expr(quote(1), elapsed_limit = -1),
    "`elapsed_limit` must be one positive finite number"
  )

  filled <- phase18_q8_rbind_fill(list(
    data.frame(a = 1, stringsAsFactors = FALSE),
    data.frame(b = 2, stringsAsFactors = FALSE)
  ))
  expect_named(filled, c("a", "b"))
  expect_equal(nrow(filled), 2L)
  expect_equal(filled$a[[1L]], 1)
  expect_true(is.na(filled$a[[2L]]))

  output_dir <- tempfile("phase18-q8-write-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  dir.create(output_dir)
  manifest <- phase18_q8_write_csv(data.frame(), output_dir, "empty.csv")
  expect_equal(manifest$artifact, "empty")
  expect_true(manifest$exists)
  expect_equal(manifest$rows, 0L)
  expect_true(file.exists(file.path(output_dir, "empty.csv")))
})

test_that("Phase 18 bivariate Gaussian q8 endpoint diagnostic summaries deduplicate fits", {
  source_phase18_biv_gaussian_q8_endpoint()

  fit_rows <- data.frame(
    surface = "biv_gaussian_q8_endpoint",
    diagnostic_preset = c("replication", "replication", "rho12"),
    diagnostic_level = c("low", "low", "positive"),
    cell_id = c("q8_diag_001", "q8_diag_002", "q8_diag_008"),
    replicate = c(1L, 1L, 1L),
    converged = c(TRUE, FALSE, TRUE),
    pdHess = c(FALSE, FALSE, TRUE),
    warning_count = c(0L, 2L, 0L),
    optimizer_code = c(0L, 1L, 0L),
    max_gradient = c(0.01, 0.30, 0.02),
    qgt2_blocks = c(1L, 1L, 1L),
    max_q = c(8L, 8L, 8L),
    max_pairs = c(28L, 28L, 28L),
    min_group_n = c(6L, 6L, 10L),
    min_sd_mu = c(0.05, 0.01, 0.08),
    min_sd_sigma = c(0.04, 0.03, 0.07),
    max_abs_cor = c(0.80, 0.98, 0.45),
    min_cor_eigen = c(0.10, 1e-7, 0.30),
    max_cor_condition = c(10, 1e7, 4),
    stringsAsFactors = FALSE
  )
  summary <- fit_rows[rep(seq_len(nrow(fit_rows)), each = 2L), ]
  summary$parameter <- rep(
    c("mu1:(Intercept)", "rho12"),
    times = nrow(fit_rows)
  )

  diagnostic <- phase18_summarise_biv_gaussian_q8_endpoint_fit_diagnostics(
    summary
  )
  groups <- phase18_biv_gaussian_q8_endpoint_diagnostic_groups(summary)

  expect_equal(
    groups,
    c("surface", "diagnostic_preset", "diagnostic_level", "parameter")
  )
  expect_equal(nrow(diagnostic), 2L)
  replication <- diagnostic[
    diagnostic$diagnostic_preset == "replication", ,
    drop = FALSE
  ]
  expect_equal(replication$n_fit, 2L)
  expect_equal(replication$convergence_rate, 0.5)
  expect_equal(replication$pdHess_rate, 0)
  expect_equal(replication$warning_rate, 0.5)
  expect_equal(replication$optimizer_ok_rate, 0.5)
  expect_equal(replication$qgt2_rate, 1)
  expect_equal(replication$sd_boundary_rate, 0.5)
  expect_equal(replication$high_correlation_rate, 0.5)
  expect_equal(replication$ill_conditioned_rate, 0.5)
  expect_equal(replication$max_q, 8)
  expect_equal(replication$max_pairs, 28)
  expect_equal(replication$min_group_n, 6)

  expect_error(
    phase18_summarise_biv_gaussian_q8_endpoint_fit_diagnostics(
      summary[, setdiff(names(summary), "max_q"), drop = FALSE]
    ),
    "must contain"
  )
  expect_error(
    phase18_biv_gaussian_q8_endpoint_diagnostic_groups(
      data.frame(diagnostic_preset = "replication")
    ),
    "must contain"
  )

  smoke_summary <- list(
    surface = "biv_gaussian_q8_endpoint",
    run = list(
      surface = "biv_gaussian_q8_endpoint",
      summary = summary
    ),
    aggregate = summary[
      1L,
      c(
        "surface",
        "diagnostic_preset",
        "diagnostic_level",
        "parameter"
      )
    ],
    replicates = summary,
    manifest = data.frame(),
    failures = data.frame()
  )
  phase18_summarise_biv_gaussian_q8_endpoint_smoke <- function(...) {
    smoke_summary
  }
  wrapped <- phase18_summarise_biv_gaussian_q8_endpoint_diagnostic_presets(
    conditions = summary[1L, , drop = FALSE],
    n_rep = 1L
  )
  expect_equal(wrapped$surface, "biv_gaussian_q8_endpoint_diagnostic")
  expect_equal(
    unique(wrapped$replicates$surface),
    "biv_gaussian_q8_endpoint_diagnostic"
  )
  expect_equal(nrow(wrapped$diagnostic_summary), 2L)
})

test_that("Phase 18 bivariate Gaussian q8 endpoint diagnostic writer saves artifacts", {
  source_phase18_biv_gaussian_q8_endpoint()

  output_dir <- tempfile("phase18-biv-gaussian-q8-endpoint-diagnostic-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_q8_endpoint_diagnostic_audit_conditions()
  replicates <- data.frame(
    surface = "biv_gaussian_q8_endpoint_diagnostic",
    diagnostic_preset = c("replication", "sd_ratio"),
    diagnostic_level = c("low", "weak"),
    cell_id = c("q8_diag_001", "q8_diag_004"),
    replicate = c(1L, 1L),
    parameter = c("rho12", "rho12"),
    truth = c(0.08, 0.08),
    estimate = c(0.05, 0.10),
    error = c(-0.03, 0.02),
    converged = c(TRUE, FALSE),
    pdHess = c(FALSE, FALSE),
    elapsed = c(1, 2),
    warning_count = c(0L, 1L),
    stringsAsFactors = FALSE
  )
  aggregate <- phase18_aggregate_parameters(
    replicates,
    by = c("surface", "diagnostic_preset", "diagnostic_level", "parameter")
  )
  manifest <- data.frame(
    cell_id = c("q8_diag_001", "q8_diag_004"),
    replicate = c(1L, 1L),
    seed = c(11L, 12L),
    status = c("ok", "ok"),
    skipped = c(FALSE, FALSE),
    warning_count = c(0L, 1L),
    error = c(NA_character_, NA_character_),
    elapsed = c(1, 2),
    stringsAsFactors = FALSE
  )
  diagnostic_summary <- data.frame(
    surface = "biv_gaussian_q8_endpoint_diagnostic",
    diagnostic_preset = c("replication", "sd_ratio"),
    diagnostic_level = c("low", "weak"),
    n_fit = c(1L, 1L),
    convergence_rate = c(1, 0),
    pdHess_rate = c(0, 0),
    stringsAsFactors = FALSE
  )
  phase18_summarise_biv_gaussian_q8_endpoint_diagnostic_presets <- function(
      ...) {
    list(
      surface = "biv_gaussian_q8_endpoint_diagnostic",
      aggregate = aggregate,
      replicates = replicates,
      manifest = manifest,
      failures = data.frame(
        cell_id = character(),
        replicate = integer(),
        seed = integer(),
        status = character(),
        severity = character(),
        message = character(),
        skipped = logical(),
        stringsAsFactors = FALSE
      ),
      diagnostic_summary = diagnostic_summary
    )
  }

  out <- phase18_write_biv_gaussian_q8_endpoint_diagnostic_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260639L
  )

  expect_equal(out$surface, "biv_gaussian_q8_endpoint_diagnostic_grid")
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 2L)
  expect_equal(nrow(utils::read.csv(out$paths$diagnostic_summary_csv)), 2L)
  expect_error(
    phase18_write_biv_gaussian_q8_endpoint_diagnostic_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 20260639L
    ),
    "already exists"
  )
})

test_that("Phase 18 bivariate Gaussian q8 endpoint smoke runner summarises output", {
  source_phase18_biv_gaussian_q8_endpoint()

  result_dir <- tempfile("phase18-biv-gaussian-q8-endpoint-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 24L,
    n_each = 6L
  )

  out <- phase18_summarise_biv_gaussian_q8_endpoint_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260634L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "biv_gaussian_q8_endpoint")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 45L)
  expect_equal(nrow(out$aggregate), 45L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_true(all(
    c(
      "optimizer_code",
      "optimizer_message",
      "objective",
      "max_gradient",
      "qgt2_blocks",
      "max_q",
      "max_pairs",
      "min_group_n",
      "min_sd_mu",
      "min_sd_sigma",
      "max_abs_cor",
      "min_cor_eigen",
      "max_cor_condition"
    ) %in%
      names(out$run$summary)
  ))
  expect_setequal(
    out$run$summary$parameter_class,
    c(
      "fixed_mu1",
      "fixed_mu2",
      "fixed_sigma1",
      "fixed_sigma2",
      "random_sd",
      "derived_random_correlation",
      "residual_rho12"
    )
  )
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu1:(Intercept)",
      "mu1:x",
      "mu2:(Intercept)",
      "mu2:x",
      "sigma1:(Intercept)",
      "sigma1:x",
      "sigma2:(Intercept)",
      "sigma2:x",
      paste0("sd:mu:", phase18_biv_gaussian_q8_endpoint_sd_mu_names()),
      paste0("sd:sigma:", phase18_biv_gaussian_q8_endpoint_sd_sigma_names()),
      paste0("cor:re_cov:", phase18_biv_gaussian_q8_endpoint_cor_names()),
      "rho12"
    )
  )
  class_by_parameter <- stats::setNames(
    out$run$summary$parameter_class,
    out$run$summary$parameter
  )
  expect_identical(
    class_by_parameter[[
      "cor:re_cov:cor(sigma1:x,sigma2:x | p | id)"
    ]],
    "derived_random_correlation"
  )
  expect_identical(class_by_parameter[["rho12"]], "residual_rho12")
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
  expect_true(all(out$run$summary$qgt2_blocks == 1L))
  expect_true(all(out$run$summary$max_q == 8L))
  expect_true(all(out$run$summary$max_pairs == 28L))
  expect_true(all(is.finite(out$run$summary$objective)))
  expect_true(all(is.finite(out$run$summary$max_gradient)))
  expect_true(all(is.finite(out$run$summary$min_sd_mu)))
  expect_true(all(is.finite(out$run$summary$min_sd_sigma)))
  expect_true(all(is.finite(out$run$summary$max_abs_cor)))
  expect_true(all(is.finite(out$run$summary$min_cor_eigen)))
  expect_true(all(is.finite(out$run$summary$max_cor_condition)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "biv_gaussian_q8_endpoint_001",
    1L
  )))
})

test_that("Phase 18 bivariate Gaussian q8 endpoint grid writer saves artifacts", {
  source_phase18_biv_gaussian_q8_endpoint()

  output_dir <- tempfile("phase18-biv-gaussian-q8-endpoint-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 24L,
    n_each = 6L
  )

  out <- phase18_write_biv_gaussian_q8_endpoint_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260634L
  )

  expect_identical(out$surface, "biv_gaussian_q8_endpoint_grid")
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_equal(nrow(out$summary$manifest), 1L)
  aggregate <- utils::read.csv(out$paths$aggregate_csv, check.names = FALSE)
  replicates <- utils::read.csv(out$paths$replicate_csv, check.names = FALSE)
  expect_equal(nrow(aggregate), 45L)
  expect_equal(nrow(replicates), 45L)
  expect_true(all(
    replicates$parameter_class[grepl("^cor:re_cov:", replicates$parameter)] ==
      "derived_random_correlation"
  ))
  expect_equal(nrow(utils::read.csv(out$paths$manifest_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$failures_csv)), 0L)
  expect_error(
    phase18_write_biv_gaussian_q8_endpoint_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 20260634L
    ),
    "already exists"
  )
  expect_silent(phase18_write_biv_gaussian_q8_endpoint_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260634L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 bivariate Gaussian q8 endpoint helpers reject malformed inputs", {
  source_phase18_biv_gaussian_q8_endpoint()

  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint(0L, 6L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint(12L, 6L, residual_rho = 1),
    "absolute value below 1"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint(
      12L,
      6L,
      sd_mu = c(1, 1, 1)
    ),
    "length 4"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint(
      12L,
      6L,
      cor_re_cov = rep(1, 28L)
    ),
    "absolute value below 1"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint_cell(
      data.frame(cell_id = "bad"),
      seed = 241L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})
