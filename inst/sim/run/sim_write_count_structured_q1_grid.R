phase18_write_count_structured_q1_grid_outputs <- function(
  output_dir,
  conditions = phase18_count_structured_q1_conditions(
    family = c("poisson", "nbinom2"),
    structured_type = c("spatial", "animal", "relmat"),
    n_level = c(10L, 16L),
    n_per_level = 8L,
    sd_structured = c(0.25, 0.60),
    mean_count = 3.0,
    sigma_baseline = 0.45,
    geometry = "ring"
  ),
  n_rep = 5L,
  master_seed = 20260529L,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  cores = 1L,
  backend = "none"
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- phase18_count_structured_q1_grid_paths(dirs$table_dir)
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Count structured q1 grid"
  )

  summary <- phase18_summarise_count_structured_q1_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = dirs$result_dir,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    cores = cores,
    backend = backend
  )
  phase18_write_count_structured_q1_grid_tables(summary, paths)

  list(
    surface = "count_structured_q1_grid",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "count_structured_q1_grid",
      paths
    ),
    summary = summary
  )
}

phase18_count_structured_q1_grid_paths <- function(table_dir) {
  c(
    phase18_simple_grid_paths(table_dir, prefix = "count-structured-q1"),
    list(
      wald_intervals_csv = file.path(
        table_dir,
        "count-structured-q1-wald-intervals.csv"
      ),
      wald_coverage_csv = file.path(
        table_dir,
        "count-structured-q1-wald-coverage.csv"
      ),
      profile_targets_csv = file.path(
        table_dir,
        "count-structured-q1-profile-targets.csv"
      ),
      profile_intervals_csv = file.path(
        table_dir,
        "count-structured-q1-profile-intervals.csv"
      ),
      profile_coverage_csv = file.path(
        table_dir,
        "count-structured-q1-profile-coverage.csv"
      ),
      interval_evidence_csv = file.path(
        table_dir,
        "count-structured-q1-interval-evidence.csv"
      ),
      interval_diagnostics_csv = file.path(
        table_dir,
        "count-structured-q1-interval-diagnostics.csv"
      ),
      interval_failures_csv = file.path(
        table_dir,
        "count-structured-q1-interval-failures.csv"
      )
    )
  )
}

phase18_write_count_structured_q1_grid_tables <- function(summary, paths) {
  phase18_write_simple_grid_tables(summary, paths)
  utils::write.csv(
    summary$wald_intervals,
    paths$wald_intervals_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$wald_coverage,
    paths$wald_coverage_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$profile_targets,
    paths$profile_targets_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$profile_intervals,
    paths$profile_intervals_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$profile_coverage,
    paths$profile_coverage_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$interval_evidence,
    paths$interval_evidence_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$interval_diagnostics,
    paths$interval_diagnostics_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$interval_failures,
    paths$interval_failures_csv,
    row.names = FALSE
  )
  invisible(paths)
}

phase18_audit_count_structured_q1_boundary_gate <- function(
  output_dir,
  require_complete = FALSE,
  hessian_rate_limit = 0.05,
  sd_boundary_rate_limit = 0.15,
  sd_boundary_condition_rate_limit = 0.40,
  min_condition_replicates = 5L
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(require_complete) && !identical(require_complete, FALSE)) {
    stop("`require_complete` must be TRUE or FALSE.", call. = FALSE)
  }

  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  table_dir <- file.path(output_dir, "tables")
  paths <- phase18_count_structured_q1_grid_paths(table_dir)
  missing <- names(paths)[!file.exists(unlist(paths, use.names = FALSE))]
  if (require_complete && length(missing) > 0L) {
    stop(
      "Missing count structured q1 artifacts: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  replicates <- phase18_read_count_structured_q1_csv(paths$replicate_csv)
  failures <- phase18_read_count_structured_q1_csv(paths$failures_csv)
  gate <- phase18_count_structured_q1_boundary_gate_summary(
    replicates = replicates,
    failures = failures,
    hessian_rate_limit = hessian_rate_limit,
    sd_boundary_rate_limit = sd_boundary_rate_limit,
    sd_boundary_condition_rate_limit = sd_boundary_condition_rate_limit,
    min_condition_replicates = min_condition_replicates
  )

  list(
    surface = "count_structured_q1_boundary_gate_audit",
    output_dir = output_dir,
    table_dir = table_dir,
    paths = paths,
    missing_artifacts = missing,
    boundary_gate = gate
  )
}

phase18_audit_count_structured_q1_profile_gate <- function(
  output_dir,
  require_complete = FALSE,
  profile_failure_rate_limit = 0.05,
  profile_condition_failure_rate_limit = 0.10,
  watch_cells = character(),
  watch_failure_rate_limit = 0.10
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(require_complete) && !identical(require_complete, FALSE)) {
    stop("`require_complete` must be TRUE or FALSE.", call. = FALSE)
  }

  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  table_dir <- file.path(output_dir, "tables")
  paths <- phase18_count_structured_q1_grid_paths(table_dir)
  missing <- names(paths)[!file.exists(unlist(paths, use.names = FALSE))]
  if (require_complete && length(missing) > 0L) {
    stop(
      "Missing count structured q1 artifacts: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  intervals <- phase18_read_count_structured_q1_csv(
    paths$profile_intervals_csv
  )
  gate <- phase18_count_structured_q1_profile_gate_summary(
    intervals = intervals,
    profile_failure_rate_limit = profile_failure_rate_limit,
    profile_condition_failure_rate_limit = profile_condition_failure_rate_limit,
    watch_cells = watch_cells,
    watch_failure_rate_limit = watch_failure_rate_limit
  )
  gate$failure_summary <- phase18_count_structured_q1_attach_example_result_paths(
    gate$failure_summary,
    output_dir
  )

  list(
    surface = "count_structured_q1_profile_gate_audit",
    output_dir = output_dir,
    table_dir = table_dir,
    paths = paths,
    missing_artifacts = missing,
    profile_gate = gate
  )
}

phase18_read_count_structured_q1_csv <- function(path) {
  if (!file.exists(path)) {
    return(data.frame())
  }
  if (is.na(file.info(path)$size) || file.info(path)$size == 0L) {
    return(data.frame())
  }
  tryCatch(
    utils::read.csv(path, stringsAsFactors = FALSE),
    error = function(e) data.frame()
  )
}

phase18_count_structured_q1_boundary_gate_summary <- function(
  replicates,
  failures = data.frame(),
  hessian_rate_limit = 0.05,
  sd_boundary_rate_limit = 0.15,
  sd_boundary_condition_rate_limit = 0.40,
  min_condition_replicates = 5L
) {
  phase18_count_structured_q1_assert_rate(
    hessian_rate_limit,
    "hessian_rate_limit"
  )
  phase18_count_structured_q1_assert_rate(
    sd_boundary_rate_limit,
    "sd_boundary_rate_limit"
  )
  phase18_count_structured_q1_assert_rate(
    sd_boundary_condition_rate_limit,
    "sd_boundary_condition_rate_limit"
  )
  assert_positive_whole_number(
    min_condition_replicates,
    "min_condition_replicates"
  )

  fits <- phase18_count_structured_q1_fit_diagnostic_table(replicates)
  overall <- phase18_count_structured_q1_boundary_overall(fits)
  conditions <- phase18_count_structured_q1_boundary_conditions(fits)
  checks <- phase18_count_structured_q1_boundary_checks(
    fits = fits,
    overall = overall,
    conditions = conditions,
    failures = failures,
    hessian_rate_limit = hessian_rate_limit,
    sd_boundary_rate_limit = sd_boundary_rate_limit,
    sd_boundary_condition_rate_limit = sd_boundary_condition_rate_limit,
    min_condition_replicates = min_condition_replicates
  )
  decision <- phase18_count_structured_q1_boundary_decision(checks)

  list(
    surface = "count_structured_q1_boundary_gate",
    fits = fits,
    overall = overall,
    conditions = conditions,
    checks = checks,
    decision = decision
  )
}

phase18_count_structured_q1_fit_diagnostic_table <- function(replicates) {
  phase18_assert_summary_columns(
    replicates,
    c(
      "cell_id",
      "replicate",
      "fit_diagnostic_status",
      "hessian_status",
      "sd_boundary_status"
    )
  )

  keys <- paste(replicates$cell_id, replicates$replicate, sep = "\r")
  rows <- lapply(split(replicates, keys, drop = TRUE), function(x) {
    data.frame(
      surface = phase18_count_structured_q1_first(x, "surface"),
      family = phase18_count_structured_q1_first(x, "family"),
      structured_type = phase18_count_structured_q1_first(
        x,
        "structured_type"
      ),
      group = phase18_count_structured_q1_first(x, "group"),
      cell_id = phase18_count_structured_q1_first(x, "cell_id"),
      replicate = phase18_count_structured_q1_first(x, "replicate"),
      n_level = phase18_count_structured_q1_first(x, "n_level"),
      n_per_level = phase18_count_structured_q1_first(x, "n_per_level"),
      sd_structured = phase18_count_structured_q1_sd_value(x),
      mean_count = phase18_count_structured_q1_first(x, "mean_count"),
      sigma_baseline = phase18_count_structured_q1_first(x, "sigma_baseline"),
      geometry = phase18_count_structured_q1_first(x, "geometry"),
      matrix_decay = phase18_count_structured_q1_first(x, "matrix_decay"),
      converged = phase18_count_structured_q1_all_true(x, "converged"),
      pdHess = phase18_count_structured_q1_all_true(x, "pdHess"),
      warning_count = phase18_count_structured_q1_max_value(
        x,
        "warning_count"
      ),
      warnings = phase18_count_structured_q1_collapse_message(
        x$warnings
      ),
      fit_diagnostic_status = phase18_count_structured_q1_diagnostic_rollup(
        x$fit_diagnostic_status
      ),
      fit_diagnostic_message = phase18_count_structured_q1_collapse_message(
        x$fit_diagnostic_message
      ),
      hessian_status = phase18_count_structured_q1_diagnostic_rollup(
        x$hessian_status
      ),
      hessian_message = phase18_count_structured_q1_collapse_message(
        x$hessian_message
      ),
      sd_boundary_status = phase18_count_structured_q1_diagnostic_rollup(
        x$sd_boundary_status
      ),
      sd_boundary_message = phase18_count_structured_q1_collapse_message(
        x$sd_boundary_message
      ),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_count_structured_q1_boundary_overall <- function(fits) {
  n_fit <- nrow(fits)
  fit_warning <- phase18_count_structured_q1_status_not_ok(
    fits$fit_diagnostic_status
  )
  sd_warning <- phase18_count_structured_q1_status_not_ok(
    fits$sd_boundary_status
  )
  hessian_warning <- phase18_count_structured_q1_status_not_ok(
    fits$hessian_status
  )
  warning_replicate <- fits$warning_count > 0L
  data.frame(
    n_fit = n_fit,
    fit_diagnostic_warning = sum(fit_warning),
    fit_diagnostic_rate = sum(fit_warning) / n_fit,
    sd_boundary_warning = sum(sd_warning),
    sd_boundary_rate = sum(sd_warning) / n_fit,
    hessian_warning = sum(hessian_warning),
    hessian_rate = sum(hessian_warning) / n_fit,
    warning_replicates = sum(warning_replicate, na.rm = TRUE),
    warning_replicate_rate = sum(warning_replicate, na.rm = TRUE) / n_fit,
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_boundary_conditions <- function(fits) {
  condition_vars <- intersect(
    c(
      "cell_id",
      "family",
      "structured_type",
      "n_level",
      "sd_structured",
      "mean_count",
      "sigma_baseline"
    ),
    names(fits)
  )
  keys <- do.call(
    paste,
    c(fits[condition_vars], list(sep = "\r"))
  )
  rows <- lapply(split(fits, keys, drop = TRUE), function(x) {
    fit_warning <- phase18_count_structured_q1_status_not_ok(
      x$fit_diagnostic_status
    )
    sd_warning <- phase18_count_structured_q1_status_not_ok(
      x$sd_boundary_status
    )
    hessian_warning <- phase18_count_structured_q1_status_not_ok(
      x$hessian_status
    )
    out <- x[1L, condition_vars, drop = FALSE]
    out$n_fit <- nrow(x)
    out$fit_diagnostic_warning <- sum(fit_warning)
    out$fit_diagnostic_rate <- sum(fit_warning) / nrow(x)
    out$sd_boundary_warning <- sum(sd_warning)
    out$sd_boundary_rate <- sum(sd_warning) / nrow(x)
    out$hessian_warning <- sum(hessian_warning)
    out$hessian_rate <- sum(hessian_warning) / nrow(x)
    out
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_count_structured_q1_boundary_checks <- function(
  fits,
  overall,
  conditions,
  failures,
  hessian_rate_limit,
  sd_boundary_rate_limit,
  sd_boundary_condition_rate_limit,
  min_condition_replicates
) {
  hessian_cells <- conditions$hessian_warning >= 2L
  sd_cells <- (conditions$n_fit >= min_condition_replicates &
    conditions$sd_boundary_rate >= sd_boundary_condition_rate_limit) |
    (conditions$n_fit < min_condition_replicates &
      conditions$sd_boundary_warning >= 2L)
  unexplained <- phase18_count_structured_q1_unexplained_failures(
    failures,
    fits
  )

  data.frame(
    check = c(
      "hessian_rate",
      "hessian_condition_count",
      "sd_boundary_rate",
      "sd_boundary_condition_rate",
      "unexplained_warning_ledger"
    ),
    status = c(
      ifelse(overall$hessian_rate > hessian_rate_limit, "failed", "ok"),
      ifelse(any(hessian_cells), "failed", "ok"),
      ifelse(
        overall$sd_boundary_rate >= sd_boundary_rate_limit,
        "failed",
        "ok"
      ),
      ifelse(any(sd_cells), "failed", "ok"),
      ifelse(nrow(unexplained) > 0L, "failed", "ok")
    ),
    n = c(
      overall$hessian_warning,
      sum(hessian_cells),
      overall$sd_boundary_warning,
      sum(sd_cells),
      nrow(unexplained)
    ),
    rate = c(
      overall$hessian_rate,
      NA_real_,
      overall$sd_boundary_rate,
      NA_real_,
      NA_real_
    ),
    threshold = c(
      hessian_rate_limit,
      2,
      sd_boundary_rate_limit,
      sd_boundary_condition_rate_limit,
      NA_real_
    ),
    message = c(
      paste0(
        overall$hessian_warning,
        " of ",
        overall$n_fit,
        " fitted replicates had non-ok Hessian diagnostics"
      ),
      phase18_count_structured_q1_condition_message(
        conditions,
        hessian_cells
      ),
      paste0(
        overall$sd_boundary_warning,
        " of ",
        overall$n_fit,
        " fitted replicates had non-ok SD-boundary diagnostics"
      ),
      phase18_count_structured_q1_condition_message(conditions, sd_cells),
      phase18_count_structured_q1_failure_message(unexplained)
    ),
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_boundary_decision <- function(checks) {
  if (!is.data.frame(checks) || !all(c("check", "status") %in% names(checks))) {
    stop(
      "`checks` must be a data frame with `check` and `status`.",
      call. = FALSE
    )
  }
  failed <- checks$status == "failed"
  decision <- if (any(failed)) {
    "hold_diagnostic"
  } else {
    "propose_next_pilot"
  }
  reason <- if (any(failed)) {
    paste(checks$check[failed], collapse = ", ")
  } else {
    "boundary gate checks passed; a separate design note is still required"
  }
  data.frame(
    surface = "count_structured_q1",
    decision = decision,
    reason = reason,
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_profile_gate_summary <- function(
  intervals,
  profile_failure_rate_limit = 0.05,
  profile_condition_failure_rate_limit = 0.10,
  watch_cells = character(),
  watch_failure_rate_limit = 0.10
) {
  phase18_count_structured_q1_assert_rate(
    profile_failure_rate_limit,
    "profile_failure_rate_limit"
  )
  phase18_count_structured_q1_assert_rate(
    profile_condition_failure_rate_limit,
    "profile_condition_failure_rate_limit"
  )
  phase18_count_structured_q1_assert_rate(
    watch_failure_rate_limit,
    "watch_failure_rate_limit"
  )
  phase18_assert_summary_columns(
    intervals,
    c("cell_id", "replicate", "interval_status")
  )
  watch_cells <- as.character(watch_cells)
  watch_cells <- watch_cells[!is.na(watch_cells) & nzchar(watch_cells)]

  requested <- intervals[
    is.na(intervals$interval_status) |
      intervals$interval_status != "not_requested",
    ,
    drop = FALSE
  ]
  if (nrow(requested) == 0L) {
    stop("`intervals` must contain requested interval rows.", call. = FALSE)
  }

  conditions <- phase18_count_structured_q1_profile_conditions(requested)
  overall <- phase18_count_structured_q1_profile_overall(requested)
  failure_summary <- phase18_count_structured_q1_profile_failure_summary(
    requested
  )
  checks <- phase18_count_structured_q1_profile_checks(
    overall = overall,
    conditions = conditions,
    profile_failure_rate_limit = profile_failure_rate_limit,
    profile_condition_failure_rate_limit = profile_condition_failure_rate_limit,
    watch_cells = watch_cells,
    watch_failure_rate_limit = watch_failure_rate_limit
  )
  decision <- phase18_count_structured_q1_profile_decision(checks)

  list(
    surface = "count_structured_q1_profile_gate",
    overall = overall,
    conditions = conditions,
    failure_summary = failure_summary,
    checks = checks,
    decision = decision
  )
}

phase18_count_structured_q1_profile_overall <- function(intervals) {
  failed <- phase18_count_structured_q1_status_not_ok(intervals$interval_status)
  n_interval <- nrow(intervals)
  data.frame(
    n_interval = n_interval,
    failed_interval = sum(failed),
    failure_rate = sum(failed) / n_interval,
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_profile_conditions <- function(intervals) {
  condition_vars <- intersect(
    c(
      "cell_id",
      "family",
      "structured_type",
      "n_level",
      "sd_structured",
      "mean_count",
      "sigma_baseline"
    ),
    names(intervals)
  )
  keys <- do.call(
    paste,
    c(intervals[condition_vars], list(sep = "\r"))
  )
  rows <- lapply(split(intervals, keys, drop = TRUE), function(x) {
    failed <- phase18_count_structured_q1_status_not_ok(x$interval_status)
    out <- x[1L, condition_vars, drop = FALSE]
    out$n_interval <- nrow(x)
    out$failed_interval <- sum(failed)
    out$failure_rate <- sum(failed) / nrow(x)
    out
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_count_structured_q1_profile_failure_summary <- function(intervals) {
  phase18_assert_summary_columns(
    intervals,
    c("cell_id", "replicate", "interval_status")
  )
  requested <- intervals[
    is.na(intervals$interval_status) |
      intervals$interval_status != "not_requested",
    ,
    drop = FALSE
  ]
  if (nrow(requested) == 0L) {
    return(data.frame())
  }

  failed <- phase18_count_structured_q1_status_not_ok(
    requested$interval_status
  )
  if (!any(failed)) {
    return(data.frame())
  }

  failures <- requested[failed, , drop = FALSE]
  if (!"interval_message" %in% names(failures)) {
    failures$interval_message <- NA_character_
  }
  failures$failure_class <- phase18_count_structured_q1_profile_failure_class(
    failures$interval_message
  )
  condition_vars <- intersect(
    c(
      "cell_id",
      "family",
      "structured_type",
      "n_level",
      "sd_structured",
      "mean_count",
      "sigma_baseline"
    ),
    names(requested)
  )
  group_vars <- c(condition_vars, "interval_status", "failure_class")
  keys <- do.call(
    paste,
    c(failures[group_vars], list(sep = "\r"))
  )
  rows <- lapply(split(failures, keys, drop = TRUE), function(x) {
    out <- x[1L, group_vars, drop = FALSE]
    out$example_interval_message <- phase18_count_structured_q1_first(
      x,
      "interval_message"
    )
    out$example_replicate <- phase18_count_structured_q1_first(x, "replicate")
    out$failed_interval <- nrow(x)
    out
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL

  denominators <- phase18_count_structured_q1_profile_conditions(requested)
  denominator_vars <- c(condition_vars, "n_interval", "failure_rate")
  out <- merge(
    out,
    denominators[denominator_vars],
    by = condition_vars,
    all.x = TRUE,
    sort = FALSE
  )
  out <- out[,
    c(
      condition_vars,
      "interval_status",
      "failure_class",
      "example_interval_message",
      "example_replicate",
      "failed_interval",
      "n_interval",
      "failure_rate"
    ),
    drop = FALSE
  ]
  out <- out[
    order(
      -out$failed_interval,
      out$cell_id,
      out$interval_status,
      out$failure_class
    ),
    ,
    drop = FALSE
  ]
  row.names(out) <- NULL
  out
}

phase18_count_structured_q1_attach_example_result_paths <- function(
  failure_summary,
  output_dir
) {
  if (!is.data.frame(failure_summary) || nrow(failure_summary) == 0L) {
    return(failure_summary)
  }
  if (!all(c("cell_id", "example_replicate") %in% names(failure_summary))) {
    return(failure_summary)
  }

  out <- failure_summary
  replicate <- suppressWarnings(as.integer(out$example_replicate))
  path <- rep(NA_character_, nrow(out))
  has_replicate <- !is.na(replicate)
  path[has_replicate] <- file.path(
    output_dir,
    "results",
    out$cell_id[has_replicate],
    sprintf("replicate_%04d.rds", replicate[has_replicate])
  )
  exists <- !is.na(path) & file.exists(path)
  path[exists] <- normalizePath(path[exists], mustWork = TRUE)
  out$example_result_path <- path
  out$example_result_exists <- exists
  out
}

phase18_count_structured_q1_profile_failure_class <- function(message) {
  message <- as.character(message)
  out <- rep("other_profile_failure", length(message))
  missing <- is.na(message) | !nzchar(message)
  out[missing] <- "missing_interval_message"

  nonfinite <- !missing &
    grepl(
      "nonfinite_interval|non-finite|nonfinite",
      message,
      ignore.case = TRUE
    )
  out[nonfinite] <- "nonfinite_interval"

  crossing <- !missing &
    !nonfinite &
    grepl(
      paste(
        c(
          "two finite crossing",
          "threshold on both sides",
          "need at least two non-NA values",
          "interpolate"
        ),
        collapse = "|"
      ),
      message,
      ignore.case = TRUE
    )
  out[crossing] <- "profile_crossing_failure"
  out
}

phase18_count_structured_q1_profile_checks <- function(
  overall,
  conditions,
  profile_failure_rate_limit,
  profile_condition_failure_rate_limit,
  watch_cells,
  watch_failure_rate_limit
) {
  condition_failed <- conditions$failure_rate >=
    profile_condition_failure_rate_limit
  watch_index <- conditions$cell_id %in%
    watch_cells &
    conditions$failure_rate >= watch_failure_rate_limit

  data.frame(
    check = c(
      "profile_interval_rate",
      "profile_condition_failure_rate",
      "watch_profile_failure_rate"
    ),
    status = c(
      ifelse(
        overall$failure_rate > profile_failure_rate_limit,
        "failed",
        "ok"
      ),
      ifelse(any(condition_failed), "failed", "ok"),
      ifelse(any(watch_index), "failed", "ok")
    ),
    n = c(
      overall$failed_interval,
      sum(condition_failed),
      sum(watch_index)
    ),
    rate = c(
      overall$failure_rate,
      NA_real_,
      NA_real_
    ),
    threshold = c(
      profile_failure_rate_limit,
      profile_condition_failure_rate_limit,
      watch_failure_rate_limit
    ),
    message = c(
      paste0(
        overall$failed_interval,
        " of ",
        overall$n_interval,
        " requested profile intervals were non-ok"
      ),
      phase18_count_structured_q1_condition_message(
        conditions,
        condition_failed
      ),
      phase18_count_structured_q1_condition_message(
        conditions,
        watch_index
      )
    ),
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_profile_decision <- function(checks) {
  if (!is.data.frame(checks) || !all(c("check", "status") %in% names(checks))) {
    stop(
      "`checks` must be a data frame with `check` and `status`.",
      call. = FALSE
    )
  }
  failed <- checks$status == "failed"
  decision <- if (any(failed)) {
    "hold_interval_diagnostic"
  } else {
    "propose_next_pilot"
  }
  reason <- if (any(failed)) {
    paste(checks$check[failed], collapse = ", ")
  } else {
    "profile interval gate checks passed; a separate design note is still required"
  }
  data.frame(
    surface = "count_structured_q1",
    decision = decision,
    reason = reason,
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_unexplained_failures <- function(failures, fits) {
  if (!is.data.frame(failures) || nrow(failures) == 0L) {
    return(data.frame())
  }
  missing <- setdiff(
    c("cell_id", "replicate", "severity", "message"),
    names(failures)
  )
  if (length(missing) > 0L) {
    stop(
      "`failures` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  fit_status <- fits[, c("cell_id", "replicate", "sd_boundary_status")]
  merged <- merge(
    failures,
    fit_status,
    by = c("cell_id", "replicate"),
    all.x = TRUE,
    sort = FALSE
  )
  message <- as.character(merged$message)
  severe <- merged$severity == "error" |
    grepl("optimizer|NaNs produced|non-finite", message, ignore.case = TRUE)
  has_fit <- !is.na(merged$sd_boundary_status)
  explained_by_sd <- has_fit &
    phase18_count_structured_q1_status_not_ok(merged$sd_boundary_status)
  merged[severe & !explained_by_sd, , drop = FALSE]
}

phase18_count_structured_q1_condition_message <- function(conditions, index) {
  if (!any(index)) {
    return("No condition-level trigger.")
  }
  paste(conditions$cell_id[index], collapse = ", ")
}

phase18_count_structured_q1_failure_message <- function(failures) {
  if (nrow(failures) == 0L) {
    return("No unexplained optimizer or non-finite warning-ledger rows.")
  }
  paste(
    paste(failures$cell_id, failures$replicate, failures$message, sep = ":"),
    collapse = " | "
  )
}

phase18_count_structured_q1_status_not_ok <- function(status) {
  status <- as.character(status)
  is.na(status) | status != "ok"
}

phase18_count_structured_q1_assert_rate <- function(x, name) {
  if (
    !is.numeric(x) ||
      length(x) != 1L ||
      !is.finite(x) ||
      x < 0 ||
      x > 1
  ) {
    stop("`", name, "` must be one number in [0, 1].", call. = FALSE)
  }
  invisible(x)
}

phase18_count_structured_q1_first <- function(x, name, default = NA) {
  if (!name %in% names(x)) {
    return(default)
  }
  value <- x[[name]]
  value <- value[!is.na(value)]
  if (length(value) == 0L) {
    return(default)
  }
  value[[1L]]
}

phase18_count_structured_q1_sd_value <- function(x) {
  if ("sd_structured" %in% names(x)) {
    return(phase18_count_structured_q1_first(x, "sd_structured"))
  }
  if (all(c("parameter_class", "truth") %in% names(x))) {
    structured <- x[x$parameter_class == "structured_sd", , drop = FALSE]
    if (nrow(structured) > 0L) {
      return(structured$truth[[1L]])
    }
  }
  NA_real_
}

phase18_count_structured_q1_all_true <- function(x, name) {
  if (!name %in% names(x)) {
    return(NA)
  }
  value <- x[[name]]
  if (length(value) == 0L || anyNA(value)) {
    return(NA)
  }
  all(value)
}

phase18_count_structured_q1_max_value <- function(x, name) {
  if (!name %in% names(x)) {
    return(NA_integer_)
  }
  value <- x[[name]]
  value <- value[!is.na(value)]
  if (length(value) == 0L) {
    return(NA_integer_)
  }
  max(value)
}

phase18_count_structured_q1_collapse_message <- function(message) {
  if (is.null(message)) {
    return(NA_character_)
  }
  message <- unique(as.character(message))
  message <- message[!is.na(message) & nzchar(message)]
  if (length(message) == 0L) {
    return(NA_character_)
  }
  paste(message, collapse = " | ")
}
