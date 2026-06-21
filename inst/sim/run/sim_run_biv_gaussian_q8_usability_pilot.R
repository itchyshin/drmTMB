phase18_biv_gaussian_q8_usability_conditions <- function(
    include_stress = TRUE,
    include_sample_size = TRUE) {
  rows <- list()
  if (isTRUE(include_stress)) {
    stress <- phase18_biv_gaussian_q8_endpoint_diagnostic_audit_conditions(
      "stress"
    )
    stress$usability_axis <- "stress"
    rows[[length(rows) + 1L]] <- stress
  }
  if (isTRUE(include_sample_size)) {
    rows[[length(rows) + 1L]] <-
      phase18_biv_gaussian_q8_usability_sample_size_conditions()
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_biv_gaussian_q8_usability_sample_size_conditions <- function() {
  rows <- list(
    phase18_biv_gaussian_q8_endpoint_condition_row(
      "sample_size",
      "low",
      "Sample-size ladder: low q8 replication.",
      n_id = 24L,
      n_each = 6L
    ),
    phase18_biv_gaussian_q8_endpoint_condition_row(
      "sample_size",
      "baseline",
      "Sample-size ladder: lane-sized q8 replication.",
      n_id = 48L,
      n_each = 10L
    ),
    phase18_biv_gaussian_q8_endpoint_condition_row(
      "sample_size",
      "high",
      "Sample-size ladder: larger q8 replication.",
      n_id = 96L,
      n_each = 12L
    )
  )
  out <- do.call(rbind, rows)
  out$diagnostic_id <- sprintf("q8_size_%03d", seq_len(nrow(out)))
  out$usability_axis <- "sample_size"
  out <- out[c(
    "diagnostic_id",
    "diagnostic_preset",
    "diagnostic_level",
    "diagnostic_note",
    "usability_axis",
    setdiff(
      names(out),
      c(
        "diagnostic_id",
        "diagnostic_preset",
        "diagnostic_level",
        "diagnostic_note",
        "usability_axis"
      )
    )
  )]
  row.names(out) <- NULL
  out
}

phase18_biv_gaussian_q8_optimizer_budgets <- function() {
  list(
    baseline_800 = list(eval.max = 800L, iter.max = 800L),
    budget_1600 = list(eval.max = 1600L, iter.max = 1600L)
  )
}

phase18_q8_optimizer_budget_rows <- function(
    optimizer_budgets = phase18_biv_gaussian_q8_optimizer_budgets()) {
  labels <- names(optimizer_budgets)
  if (is.null(labels) || any(!nzchar(labels))) {
    stop("`optimizer_budgets` must be a named list.", call. = FALSE)
  }
  rows <- lapply(labels, function(label) {
    phase18_q8_optimizer_metadata(label, optimizer_budgets[[label]])
  })
  do.call(rbind, rows)
}

phase18_biv_gaussian_q8_endpoint_formula <- function() {
  bf(
    mu1 = y1 ~ x + (1 + x | p | id),
    mu2 = y2 ~ x + (1 + x | p | id),
    sigma1 = ~ x + (1 + x | p | id),
    sigma2 = ~ x + (1 + x | p | id),
    rho12 = ~1
  )
}

phase18_biv_gaussian_q4_endpoint_formula <- function() {
  bf(
    mu1 = y1 ~ x + (1 | p | id),
    mu2 = y2 ~ x + (1 | p | id),
    sigma1 = ~ x + (1 | p | id),
    sigma2 = ~ x + (1 | p | id),
    rho12 = ~1
  )
}

phase18_fit_biv_gaussian_q8_endpoint_strategy <- function(
    data,
    strategy = c("cold", "q4_sd_staged", "q4_theta_staged"),
    se = FALSE,
    keep_data = TRUE,
    keep_tmb_object = TRUE,
    optimizer = list(eval.max = 800, iter.max = 800),
    theta_re_cov_shrink = 0.85) {
  strategy <- match.arg(strategy)
  formula <- phase18_biv_gaussian_q8_endpoint_formula()
  control <- drm_control(
    optimizer = optimizer,
    se = se,
    keep_data = keep_data,
    keep_tmb_object = keep_tmb_object
  )
  if (identical(strategy, "cold")) {
    return(drmTMB(
      formula,
      family = biv_gaussian(),
      data = data,
      control = control
    ))
  }

  source_fit <- drmTMB(
    phase18_biv_gaussian_q4_endpoint_formula(),
    family = biv_gaussian(),
    data = data,
    control = drm_control(
      optimizer = optimizer,
      se = FALSE,
      keep_data = TRUE,
      keep_tmb_object = TRUE
    )
  )
  target_spec <- drmTMB:::drm_build_biv_gaussian_spec(formula, data)
  mapped <- drmTMB:::drm_qgt2_staged_start_override(
    source_fit = source_fit,
    target_spec = target_spec,
    copy_theta_re_cov = identical(strategy, "q4_theta_staged"),
    theta_re_cov_shrink = theta_re_cov_shrink,
    strategy = strategy
  )
  fit <- drmTMB:::drm_fit_spec(
    spec = target_spec,
    formula = formula,
    family = biv_gaussian(),
    control = control,
    call = quote(drmTMB()),
    start_override = mapped$override,
    start_provenance = mapped$provenance
  )
  attr(fit, "q8_staged_mapping") <- mapped
  fit
}

phase18_run_biv_gaussian_q8_usability_pilot <- function(
    conditions = phase18_biv_gaussian_q8_usability_conditions(),
    strategies = c("cold", "q4_sd_staged", "q4_theta_staged"),
    master_seed = 20260680L,
    se_hessian_levels = c("sample_size:high", "correlation:high"),
    optimizer = list(eval.max = 800L, iter.max = 800L),
    optimizer_label = "baseline_800",
    result_dir = NULL,
    overwrite = FALSE,
    theta_re_cov_shrink = 0.85) {
  if (is.null(result_dir)) {
    result_dir <- file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "q8-usability-pilot"
    )
  }
  if (dir.exists(result_dir) && !isTRUE(overwrite)) {
    stop(
      "`result_dir` already exists; use `overwrite = TRUE` to replace it.",
      call. = FALSE
    )
  }
  dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)

  rows <- list()
  targets <- list()
  mappings <- list()
  failures <- list()
  for (i in seq_len(nrow(conditions))) {
    condition <- conditions[i, , drop = FALSE]
    seed <- master_seed + i - 1L
    dat <- phase18_dgp_biv_gaussian_q8_endpoint_cell(
      cell = condition,
      seed = seed,
      cell_id = condition$diagnostic_id[[1L]],
      replicate = 1L
    )
    truth <- attr(dat, "truth", exact = TRUE)
    se_flags <- FALSE
    key <- paste(
      condition$diagnostic_preset[[1L]],
      condition$diagnostic_level[[1L]],
      sep = ":"
    )
    if (key %in% se_hessian_levels) {
      se_flags <- c(FALSE, TRUE)
    }
    for (strategy in strategies) {
      for (se in se_flags) {
        fit <- phase18_capture_q8_usability_fit(
          phase18_fit_biv_gaussian_q8_endpoint_strategy(
            data = dat,
            strategy = strategy,
            se = se,
            optimizer = optimizer,
            theta_re_cov_shrink = theta_re_cov_shrink
          )
        )
        rows[[length(rows) + 1L]] <- phase18_q8_usability_fit_row(
          fit = fit$value,
          truth = truth,
          condition = condition,
          strategy = strategy,
          se = se,
          optimizer_label = optimizer_label,
          optimizer = optimizer,
          elapsed = fit$elapsed,
          warnings = fit$warnings
        )
        if (inherits(fit$value, "error")) {
          failures[[length(failures) + 1L]] <- data.frame(
            diagnostic_id = condition$diagnostic_id,
            strategy = strategy,
            se = se,
            optimizer_label =
              phase18_q8_optimizer_metadata(optimizer_label, optimizer)$optimizer_label,
            eval_max =
              phase18_q8_optimizer_metadata(optimizer_label, optimizer)$eval_max,
            iter_max =
              phase18_q8_optimizer_metadata(optimizer_label, optimizer)$iter_max,
            status = "error",
            message = conditionMessage(fit$value),
            stringsAsFactors = FALSE
          )
          next
        }
        fit_targets <- profile_targets(fit$value)
        fit_targets$diagnostic_id <- condition$diagnostic_id
        fit_targets$diagnostic_preset <- condition$diagnostic_preset
        fit_targets$diagnostic_level <- condition$diagnostic_level
        fit_targets$usability_axis <- condition$usability_axis
        fit_targets$strategy <- strategy
        fit_targets$se <- se
        fit_targets <- phase18_q8_add_optimizer_columns(
          fit_targets,
          optimizer_label,
          optimizer
        )
        targets[[length(targets) + 1L]] <- fit_targets
        mapping <- attr(fit$value, "q8_staged_mapping", exact = TRUE)
        if (!is.null(mapping)) {
          map_rows <- phase18_q8_mapping_rows(
            mapping = mapping,
            condition = condition,
            strategy = strategy,
            se = se,
            optimizer_label = optimizer_label,
            optimizer = optimizer
          )
          mappings <- c(mappings, map_rows)
        }
      }
    }
  }

  summary <- do.call(rbind, rows)
  write.csv(summary, file.path(result_dir, "fit-summary.csv"), row.names = FALSE)
  if (length(targets) > 0L) {
    write.csv(
      do.call(rbind, targets),
      file.path(result_dir, "profile-targets.csv"),
      row.names = FALSE
    )
  }
  if (length(mappings) > 0L) {
    write.csv(
      phase18_q8_rbind_fill(mappings),
      file.path(result_dir, "start-mapping.csv"),
      row.names = FALSE
    )
  }
  if (length(failures) > 0L) {
    write.csv(
      do.call(rbind, failures),
      file.path(result_dir, "failures.csv"),
      row.names = FALSE
    )
  }
  manifest <- data.frame(
    artifact = c(
      "fit-summary",
      "profile-targets",
      "start-mapping",
      "failures"
    ),
    path = file.path(
      result_dir,
      c(
        "fit-summary.csv",
        "profile-targets.csv",
        "start-mapping.csv",
        "failures.csv"
      )
    ),
    stringsAsFactors = FALSE
  )
  manifest$exists <- file.exists(manifest$path)
  write.csv(manifest, file.path(result_dir, "manifest.csv"), row.names = FALSE)

  list(
    conditions = conditions,
    summary = summary,
    manifest = manifest,
    result_dir = result_dir
  )
}

phase18_run_biv_gaussian_q8_optimizer_budget_pilot <- function(
    condition =
      phase18_biv_gaussian_q8_usability_sample_size_conditions()[3L, ,
        drop = FALSE
      ],
    optimizer_budgets = phase18_biv_gaussian_q8_optimizer_budgets(),
    strategies = c("cold", "q4_sd_staged", "q4_theta_staged"),
    seed = 20260687L,
    se = TRUE,
    result_dir = NULL,
    overwrite = FALSE,
    theta_re_cov_shrink = 0.85) {
  if (nrow(condition) != 1L) {
    stop("`condition` must contain exactly one q8 condition row.", call. = FALSE)
  }
  budget_rows <- phase18_q8_optimizer_budget_rows(optimizer_budgets)
  if (is.null(result_dir)) {
    result_dir <- file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "q8-optimizer-budget-pilot"
    )
  }
  if (dir.exists(result_dir) && !isTRUE(overwrite)) {
    stop(
      "`result_dir` already exists; use `overwrite = TRUE` to replace it.",
      call. = FALSE
    )
  }
  dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)

  dat <- phase18_dgp_biv_gaussian_q8_endpoint_cell(
    cell = condition,
    seed = seed,
    cell_id = condition$diagnostic_id[[1L]],
    replicate = 1L
  )
  truth <- attr(dat, "truth", exact = TRUE)
  rows <- list()
  targets <- list()
  mappings <- list()
  failures <- list()
  labels <- budget_rows$optimizer_label
  for (optimizer_label in labels) {
    optimizer <- optimizer_budgets[[optimizer_label]]
    for (strategy in strategies) {
      fit <- phase18_capture_q8_usability_fit(
        phase18_fit_biv_gaussian_q8_endpoint_strategy(
          data = dat,
          strategy = strategy,
          se = se,
          optimizer = optimizer,
          theta_re_cov_shrink = theta_re_cov_shrink
        )
      )
      rows[[length(rows) + 1L]] <- phase18_q8_usability_fit_row(
        fit = fit$value,
        truth = truth,
        condition = condition,
        strategy = strategy,
        se = se,
        optimizer_label = optimizer_label,
        optimizer = optimizer,
        elapsed = fit$elapsed,
        warnings = fit$warnings
      )
      if (inherits(fit$value, "error")) {
        failures[[length(failures) + 1L]] <- data.frame(
          diagnostic_id = condition$diagnostic_id,
          strategy = strategy,
          se = se,
          optimizer_label = optimizer_label,
          eval_max = phase18_q8_optimizer_setting(optimizer, "eval.max"),
          iter_max = phase18_q8_optimizer_setting(optimizer, "iter.max"),
          status = "error",
          message = conditionMessage(fit$value),
          stringsAsFactors = FALSE
        )
        next
      }
      fit_targets <- profile_targets(fit$value)
      fit_targets$diagnostic_id <- condition$diagnostic_id
      fit_targets$diagnostic_preset <- condition$diagnostic_preset
      fit_targets$diagnostic_level <- condition$diagnostic_level
      fit_targets$usability_axis <- condition$usability_axis
      fit_targets$strategy <- strategy
      fit_targets$se <- se
      fit_targets <- phase18_q8_add_optimizer_columns(
        fit_targets,
        optimizer_label,
        optimizer
      )
      targets[[length(targets) + 1L]] <- fit_targets
      mapping <- attr(fit$value, "q8_staged_mapping", exact = TRUE)
      if (!is.null(mapping)) {
        map_rows <- phase18_q8_mapping_rows(
          mapping = mapping,
          condition = condition,
          strategy = strategy,
          se = se,
          optimizer_label = optimizer_label,
          optimizer = optimizer
        )
        mappings <- c(mappings, map_rows)
      }
    }
  }

  summary <- do.call(rbind, rows)
  write.csv(summary, file.path(result_dir, "fit-summary.csv"), row.names = FALSE)
  if (length(targets) > 0L) {
    write.csv(
      do.call(rbind, targets),
      file.path(result_dir, "profile-targets.csv"),
      row.names = FALSE
    )
  }
  if (length(mappings) > 0L) {
    write.csv(
      phase18_q8_rbind_fill(mappings),
      file.path(result_dir, "start-mapping.csv"),
      row.names = FALSE
    )
  }
  if (length(failures) > 0L) {
    write.csv(
      do.call(rbind, failures),
      file.path(result_dir, "failures.csv"),
      row.names = FALSE
    )
  }
  manifest <- data.frame(
    artifact = c(
      "fit-summary",
      "profile-targets",
      "start-mapping",
      "failures"
    ),
    path = file.path(
      result_dir,
      c(
        "fit-summary.csv",
        "profile-targets.csv",
        "start-mapping.csv",
        "failures.csv"
      )
    ),
    stringsAsFactors = FALSE
  )
  manifest$exists <- file.exists(manifest$path)
  write.csv(manifest, file.path(result_dir, "manifest.csv"), row.names = FALSE)

  list(
    condition = condition,
    optimizer_budgets = budget_rows,
    summary = summary,
    manifest = manifest,
    result_dir = result_dir
  )
}

phase18_capture_q8_usability_fit <- function(expr) {
  phase18_capture_q8_usability_expr(substitute(expr), parent.frame())
}

phase18_capture_q8_usability_expr <- function(
    expr,
    envir = parent.frame(),
    elapsed_limit = NULL) {
  if (!is.null(elapsed_limit)) {
    if (
      !is.numeric(elapsed_limit) ||
        length(elapsed_limit) != 1L ||
        !is.finite(elapsed_limit) ||
        elapsed_limit <= 0
    ) {
      stop("`elapsed_limit` must be one positive finite number.", call. = FALSE)
    }
  }
  warnings <- character()
  elapsed <- system.time({
    if (!is.null(elapsed_limit)) {
      setTimeLimit(elapsed = elapsed_limit, transient = TRUE)
      on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE),
        add = TRUE
      )
    }
    value <- withCallingHandlers(
      tryCatch(eval(expr, envir = envir), error = function(e) e),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })[["elapsed"]]
  list(
    value = value,
    warnings = unique(warnings),
    elapsed = elapsed
  )
}

phase18_q8_usability_fit_row <- function(
    fit,
    truth,
    condition,
    strategy,
    se,
    optimizer_label = NA_character_,
    optimizer = NULL,
    elapsed,
    warnings) {
  optimizer_info <- phase18_q8_optimizer_metadata(optimizer_label, optimizer)
  if (inherits(fit, "error")) {
    return(data.frame(
      diagnostic_id = condition$diagnostic_id,
      diagnostic_preset = condition$diagnostic_preset,
      diagnostic_level = condition$diagnostic_level,
      usability_axis = condition$usability_axis,
      strategy = strategy,
      se = se,
      optimizer_label = optimizer_info$optimizer_label,
      eval_max = optimizer_info$eval_max,
      iter_max = optimizer_info$iter_max,
      status = "error",
      convergence = NA_integer_,
      pdHess = NA,
      objective = NA_real_,
      max_gradient = NA_real_,
      min_sd_mu = NA_real_,
      min_sd_sigma = NA_real_,
      max_abs_cor = NA_real_,
      min_cor_eigen = NA_real_,
      max_cor_condition = NA_real_,
      nobs = NA_integer_,
      elapsed = elapsed,
      warning_count = length(warnings),
      warnings = paste(warnings, collapse = " | "),
      error = conditionMessage(fit),
      stringsAsFactors = FALSE
    ))
  }
  diagnostics <- phase18_biv_gaussian_q8_endpoint_fit_diagnostics(fit)
  data.frame(
    diagnostic_id = condition$diagnostic_id,
    diagnostic_preset = condition$diagnostic_preset,
    diagnostic_level = condition$diagnostic_level,
    usability_axis = condition$usability_axis,
    strategy = strategy,
    se = se,
    optimizer_label = optimizer_info$optimizer_label,
    eval_max = optimizer_info$eval_max,
    iter_max = optimizer_info$iter_max,
    status = "ok",
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    objective = diagnostics$objective,
    max_gradient = diagnostics$max_gradient,
    min_sd_mu = diagnostics$min_sd_mu,
    min_sd_sigma = diagnostics$min_sd_sigma,
    max_abs_cor = diagnostics$max_abs_cor,
    min_cor_eigen = diagnostics$min_cor_eigen,
    max_cor_condition = diagnostics$max_cor_condition,
    nobs = stats::nobs(fit),
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    error = NA_character_,
    stringsAsFactors = FALSE
  )
}

phase18_q8_mapping_rows <- function(
    mapping,
    condition,
    strategy,
    se,
    optimizer_label = NA_character_,
    optimizer = NULL) {
  out <- list()
  sd_matches <- mapping$provenance$qgt2_sd_matches
  if (is.data.frame(sd_matches) && nrow(sd_matches) > 0L) {
    sd_matches$mapping_type <- "sd"
    out[[length(out) + 1L]] <- phase18_q8_annotate_mapping_rows(
      sd_matches,
      condition,
      strategy,
      se,
      optimizer_label,
      optimizer
    )
  }
  theta_matches <- mapping$provenance$qgt2_theta_matches
  if (is.data.frame(theta_matches) && nrow(theta_matches) > 0L) {
    theta_matches$mapping_type <- "theta"
    out[[length(out) + 1L]] <- phase18_q8_annotate_mapping_rows(
      theta_matches,
      condition,
      strategy,
      se,
      optimizer_label,
      optimizer
    )
  }
  out
}

phase18_q8_annotate_mapping_rows <- function(
    rows,
    condition,
    strategy,
    se,
    optimizer_label = NA_character_,
    optimizer = NULL) {
  rows$diagnostic_id <- condition$diagnostic_id
  rows$diagnostic_preset <- condition$diagnostic_preset
  rows$diagnostic_level <- condition$diagnostic_level
  rows$usability_axis <- condition$usability_axis
  rows$strategy <- strategy
  rows$se <- se
  phase18_q8_add_optimizer_columns(rows, optimizer_label, optimizer)
}

phase18_q8_add_optimizer_columns <- function(
    rows,
    optimizer_label = NA_character_,
    optimizer = NULL) {
  optimizer_info <- phase18_q8_optimizer_metadata(optimizer_label, optimizer)
  rows$optimizer_label <- optimizer_info$optimizer_label
  rows$eval_max <- optimizer_info$eval_max
  rows$iter_max <- optimizer_info$iter_max
  rows
}

phase18_q8_optimizer_metadata <- function(
    optimizer_label = NA_character_,
    optimizer = NULL) {
  if (length(optimizer_label) != 1L) {
    stop("`optimizer_label` must be one value.", call. = FALSE)
  }
  if (is.null(optimizer)) {
    optimizer <- list()
  }
  data.frame(
    optimizer_label = as.character(optimizer_label),
    eval_max = phase18_q8_optimizer_setting(optimizer, "eval.max"),
    iter_max = phase18_q8_optimizer_setting(optimizer, "iter.max"),
    stringsAsFactors = FALSE
  )
}

phase18_q8_optimizer_setting <- function(optimizer, name) {
  if (!is.list(optimizer) || !name %in% names(optimizer)) {
    return(NA_integer_)
  }
  value <- optimizer[[name]]
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) {
    return(NA_integer_)
  }
  as.integer(value)
}

phase18_q8_profile_direct_sd <- function(
    fit,
    level = 0.70,
    max_targets = 2L,
    elapsed_limit = NULL) {
  targets <- profile_targets(fit)
  direct_sd <- targets[
    targets$target_class == "random-effect-sd" &
      targets$target_type == "direct" &
      targets$profile_ready, ,
    drop = FALSE
  ]
  if (nrow(direct_sd) == 0L) {
    return(data.frame())
  }
  direct_sd <- direct_sd[seq_len(min(max_targets, nrow(direct_sd))), , drop = FALSE]
  rows <- lapply(direct_sd$parm, function(parm) {
    attempt <- phase18_capture_q8_usability_expr(
      quote(confint(
        fit,
        parm = parm,
        method = "profile",
        profile_engine = "endpoint",
        level = level,
        trace = FALSE
      )),
      envir = environment(),
      elapsed_limit = elapsed_limit
    )
    if (inherits(attempt$value, "error")) {
      return(data.frame(
        parm = parm,
        level = level,
        lower = NA_real_,
        upper = NA_real_,
        method = "profile",
        conf.status = "error",
        profile.message = conditionMessage(attempt$value),
        elapsed = attempt$elapsed,
        warning_count = length(attempt$warnings),
        warnings = paste(attempt$warnings, collapse = " | "),
        stringsAsFactors = FALSE
      ))
    }
    out <- attempt$value
    out$elapsed <- attempt$elapsed
    out$warning_count <- length(attempt$warnings)
    out$warnings <- paste(attempt$warnings, collapse = " | ")
    out
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_q8_derived_correlation_bootstrap <- function(
    fit,
    nsim = 10L,
    seed = NULL,
    refit_strategy = c("q4_theta_staged", "q4_sd_staged", "cold"),
    theta_re_cov_shrink = 0.85,
    conf.level = 0.70,
    refit_elapsed_limit = NULL) {
  refit_strategy <- match.arg(refit_strategy)
  assert_positive_whole_number(nsim, "nsim")
  if (!is.null(seed)) {
    assert_positive_whole_number(seed, "seed")
  }
  simulations <- stats::simulate(fit, nsim = nsim, seed = seed)
  rows <- lapply(seq_len(nsim), function(i) {
    phase18_q8_derived_correlation_bootstrap_one(
      fit = fit,
      simulations = simulations,
      index = i,
      refit_strategy = refit_strategy,
      theta_re_cov_shrink = theta_re_cov_shrink,
      refit_elapsed_limit = refit_elapsed_limit
    )
  })
  draws <- do.call(rbind, rows)
  row.names(draws) <- NULL
  intervals <- phase18_bootstrap_percentile_intervals(
    draws,
    conf.level = conf.level,
    parameter = "parameter",
    estimate = "estimate",
    status = "status"
  )
  list(
    draws = draws,
    intervals = intervals
  )
}

phase18_run_biv_gaussian_q8_inference_pilot <- function(
    condition = phase18_biv_gaussian_q8_usability_conditions(
      include_sample_size = FALSE
    )[1L, , drop = FALSE],
    strategy = "q4_sd_staged",
    seed = 20260691L,
    result_dir = NULL,
    overwrite = FALSE,
    profile_level = 0.70,
    profile_max_targets = 1L,
    profile_elapsed_limit = 60,
    bootstrap_nsim = 2L,
    bootstrap_seed = 20260692L,
    bootstrap_refit_strategy = "q4_theta_staged",
    bootstrap_refit_elapsed_limit = 60,
    theta_re_cov_shrink = 0.70) {
  if (nrow(condition) != 1L) {
    stop("`condition` must contain exactly one q8 condition row.", call. = FALSE)
  }
  if (is.null(result_dir)) {
    result_dir <- file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "q8-usability-inference-pilot"
    )
  }
  if (dir.exists(result_dir) && !isTRUE(overwrite)) {
    stop(
      "`result_dir` already exists; use `overwrite = TRUE` to replace it.",
      call. = FALSE
    )
  }
  dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)

  dat <- phase18_dgp_biv_gaussian_q8_endpoint_cell(
    cell = condition,
    seed = seed,
    cell_id = condition$diagnostic_id[[1L]],
    replicate = 1L
  )
  truth <- attr(dat, "truth", exact = TRUE)
  fit <- phase18_capture_q8_usability_fit(
    phase18_fit_biv_gaussian_q8_endpoint_strategy(
      data = dat,
      strategy = strategy,
      se = FALSE,
      keep_data = TRUE,
      keep_tmb_object = TRUE,
      theta_re_cov_shrink = theta_re_cov_shrink
    )
  )
  source_fit <- phase18_q8_usability_fit_row(
    fit = fit$value,
    truth = truth,
    condition = condition,
    strategy = strategy,
    se = FALSE,
    elapsed = fit$elapsed,
    warnings = fit$warnings
  )
  manifest <- list(phase18_q8_write_csv(
    source_fit,
    result_dir,
    "inference-source-fit.csv"
  ))

  if (!inherits(fit$value, "error")) {
    profiles <- phase18_q8_profile_direct_sd(
      fit$value,
      level = profile_level,
      max_targets = profile_max_targets,
      elapsed_limit = profile_elapsed_limit
    )
    manifest[[length(manifest) + 1L]] <- phase18_q8_write_csv(
      profiles,
      result_dir,
      "direct-sd-profile.csv"
    )

    bootstrap <- tryCatch(
      phase18_q8_derived_correlation_bootstrap(
        fit = fit$value,
        nsim = bootstrap_nsim,
        seed = bootstrap_seed,
        refit_strategy = bootstrap_refit_strategy,
        theta_re_cov_shrink = theta_re_cov_shrink,
        conf.level = profile_level,
        refit_elapsed_limit = bootstrap_refit_elapsed_limit
      ),
      error = function(e) e
    )
    if (inherits(bootstrap, "error")) {
      bootstrap_failure <- data.frame(
        status = "error",
        message = conditionMessage(bootstrap),
        stringsAsFactors = FALSE
      )
      manifest[[length(manifest) + 1L]] <- phase18_q8_write_csv(
        bootstrap_failure,
        result_dir,
        "derived-correlation-bootstrap-failures.csv"
      )
    } else {
      manifest[[length(manifest) + 1L]] <- phase18_q8_write_csv(
        bootstrap$draws,
        result_dir,
        "derived-correlation-bootstrap-draws.csv"
      )
      manifest[[length(manifest) + 1L]] <- phase18_q8_write_csv(
        bootstrap$intervals,
        result_dir,
        "derived-correlation-bootstrap-intervals.csv"
      )
    }
  }

  manifest <- do.call(rbind, manifest)
  write.csv(manifest, file.path(result_dir, "manifest.csv"), row.names = FALSE)
  list(
    source_fit = source_fit,
    manifest = manifest,
    result_dir = result_dir
  )
}

phase18_q8_write_csv <- function(data, result_dir, file) {
  path <- file.path(result_dir, file)
  write.csv(data, path, row.names = FALSE)
  data.frame(
    artifact = tools::file_path_sans_ext(file),
    path = path,
    exists = file.exists(path),
    rows = nrow(data),
    stringsAsFactors = FALSE
  )
}

phase18_q8_derived_correlation_bootstrap_one <- function(
    fit,
    simulations,
    index,
    refit_strategy,
    theta_re_cov_shrink,
    refit_elapsed_limit = NULL) {
  data <- phase18_q8_bootstrap_response_data(fit, simulations, index)
  refit <- phase18_capture_q8_usability_expr(
    quote(phase18_fit_biv_gaussian_q8_endpoint_strategy(
      data = data,
      strategy = refit_strategy,
      se = FALSE,
      keep_data = FALSE,
      keep_tmb_object = FALSE,
      theta_re_cov_shrink = theta_re_cov_shrink
    )),
    envir = environment(),
    elapsed_limit = refit_elapsed_limit
  )
  if (inherits(refit$value, "error")) {
    return(data.frame(
      artifact_grain = "bootstrap",
      bootstrap = index,
      parameter = NA_character_,
      estimate = NA_real_,
      status = "error",
      refit_convergence = NA_integer_,
      refit_pdHess = NA,
      refit_message = conditionMessage(refit$value),
      refit_elapsed = refit$elapsed,
      stringsAsFactors = FALSE
    ))
  }
  cor <- refit$value$corpars$re_cov
  status <- if (isTRUE(refit$value$opt$convergence == 0L)) {
    "ok"
  } else {
    "nonconverged"
  }
  data.frame(
    artifact_grain = "bootstrap",
    bootstrap = index,
    parameter = names(cor),
    estimate = unname(cor),
    status = status,
    refit_convergence = refit$value$opt$convergence,
    refit_pdHess = isTRUE(refit$value$sdr$pdHess),
    refit_message = refit$value$opt$message,
    refit_elapsed = refit$elapsed,
    stringsAsFactors = FALSE
  )
}

phase18_q8_bootstrap_response_data <- function(fit, simulations, index) {
  data <- fit$data
  if (is.null(data)) {
    stop("q8 bootstrap requires a fit with stored data.", call. = FALSE)
  }
  response_names <- drmTMB:::bivariate_response_names(fit)
  sim_y1 <- paste0("sim_", index, "_y1")
  sim_y2 <- paste0("sim_", index, "_y2")
  if (!all(c(sim_y1, sim_y2) %in% names(simulations))) {
    stop("q8 bootstrap simulations are missing bivariate response columns.",
      call. = FALSE
    )
  }
  data[[response_names[[1L]]]] <- simulations[[sim_y1]]
  data[[response_names[[2L]]]] <- simulations[[sim_y2]]
  data
}

phase18_q8_rbind_fill <- function(rows) {
  if (length(rows) == 0L) {
    return(data.frame())
  }
  columns <- unique(unlist(lapply(rows, names), use.names = FALSE))
  rows <- lapply(rows, function(row) {
    missing <- setdiff(columns, names(row))
    for (column in missing) {
      row[[column]] <- NA
    }
    row[columns]
  })
  do.call(rbind, rows)
}
