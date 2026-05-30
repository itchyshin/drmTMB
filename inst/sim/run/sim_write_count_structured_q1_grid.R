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
  gate$failure_summary <- phase18_count_structured_q1_attach_example_profile_details(
    gate$failure_summary
  )
  gate$example_geometry_summary <-
    phase18_count_structured_q1_profile_example_geometry_summary(
      gate$failure_summary
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

phase18_count_structured_q1_attach_example_profile_details <- function(
  failure_summary
) {
  if (!is.data.frame(failure_summary) || nrow(failure_summary) == 0L) {
    return(failure_summary)
  }
  if (
    !all(
      c("example_result_path", "example_result_exists") %in%
        names(failure_summary)
    )
  ) {
    return(failure_summary)
  }

  details <- lapply(seq_len(nrow(failure_summary)), function(i) {
    phase18_count_structured_q1_example_profile_detail(
      failure_summary$example_result_path[[i]],
      failure_summary$example_result_exists[[i]]
    )
  })
  cbind(failure_summary, do.call(rbind, details))
}

phase18_count_structured_q1_example_profile_detail <- function(path, exists) {
  out <- phase18_count_structured_q1_empty_example_profile_detail()
  if (!isTRUE(exists) || is.na(path) || !nzchar(path)) {
    out$example_profile_detail_status <- "missing_result"
    return(out)
  }

  result <- tryCatch(readRDS(path), error = function(e) e)
  if (inherits(result, "error")) {
    out$example_profile_detail_status <- "read_error"
    out$example_profile_message <- conditionMessage(result)
    return(out)
  }
  if (!is.list(result) || !is.data.frame(result$summary)) {
    out$example_profile_detail_status <- "missing_summary"
    return(out)
  }

  summary <- result$summary
  if (!"profile.status" %in% names(summary)) {
    out$example_profile_detail_status <- "missing_requested_profile_row"
    return(out)
  }
  requested <- summary[
    is.na(summary$profile.status) | summary$profile.status != "not_requested",
    ,
    drop = FALSE
  ]
  if (nrow(requested) == 0L) {
    out$example_profile_detail_status <- "missing_requested_profile_row"
    return(out)
  }

  failed <- phase18_count_structured_q1_status_not_ok(requested$profile.status)
  row <- if (any(failed)) {
    requested[which(failed)[[1L]], , drop = FALSE]
  } else {
    requested[1L, , drop = FALSE]
  }

  out$example_profile_detail_status <- "ok"
  out$example_parameter <- phase18_count_structured_q1_first(row, "parameter")
  out$example_parameter_class <- phase18_count_structured_q1_first(
    row,
    "parameter_class"
  )
  out$example_truth <- as.numeric(
    phase18_count_structured_q1_first(row, "truth", NA_real_)
  )
  out$example_estimate <- as.numeric(
    phase18_count_structured_q1_first(row, "estimate", NA_real_)
  )
  out$example_profile_conf_low <- as.numeric(
    phase18_count_structured_q1_first(row, "profile.conf.low", NA_real_)
  )
  out$example_profile_conf_high <- as.numeric(
    phase18_count_structured_q1_first(row, "profile.conf.high", NA_real_)
  )
  out$example_profile_status <- phase18_count_structured_q1_first(
    row,
    "profile.status"
  )
  out$example_profile_message <- phase18_count_structured_q1_first(
    row,
    "profile.message"
  )
  out$example_profile_target_status <- phase18_count_structured_q1_first(
    row,
    "profile_target_status"
  )
  out$example_profile_target_parameter <- phase18_count_structured_q1_first(
    row,
    "profile_target_parameter"
  )
  out
}

phase18_count_structured_q1_empty_example_profile_detail <- function() {
  data.frame(
    example_profile_detail_status = NA_character_,
    example_parameter = NA_character_,
    example_parameter_class = NA_character_,
    example_truth = NA_real_,
    example_estimate = NA_real_,
    example_profile_conf_low = NA_real_,
    example_profile_conf_high = NA_real_,
    example_profile_status = NA_character_,
    example_profile_message = NA_character_,
    example_profile_target_status = NA_character_,
    example_profile_target_parameter = NA_character_,
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_profile_example_geometry_summary <- function(
  failure_summary
) {
  if (!is.data.frame(failure_summary) || nrow(failure_summary) == 0L) {
    return(data.frame())
  }
  required <- c(
    "failure_class",
    "failed_interval",
    "example_profile_detail_status",
    "example_truth",
    "example_estimate",
    "example_profile_conf_low",
    "example_profile_conf_high"
  )
  if (!all(required %in% names(failure_summary))) {
    return(data.frame())
  }

  rows <- lapply(
    split(failure_summary, failure_summary$failure_class, drop = TRUE),
    phase18_count_structured_q1_profile_example_geometry_row
  )
  out <- do.call(rbind, rows)
  out <- out[order(out$failure_class), , drop = FALSE]
  row.names(out) <- NULL
  out
}

phase18_count_structured_q1_profile_example_geometry_row <- function(x) {
  detail_ok <- x$example_profile_detail_status == "ok"
  estimate <- as.numeric(x$example_estimate)
  truth <- as.numeric(x$example_truth)
  estimate_ratio <- estimate / truth
  finite_estimate <- which(is.finite(estimate))
  min_row <- if (length(finite_estimate) > 0L) {
    finite_estimate[which.min(estimate[finite_estimate])]
  } else {
    NA_integer_
  }

  data.frame(
    failure_class = x$failure_class[[1L]],
    n_failure_summary_row = nrow(x),
    failed_interval = sum(x$failed_interval, na.rm = TRUE),
    n_example_detail_ok = sum(detail_ok, na.rm = TRUE),
    n_missing_lower_endpoint = sum(
      detail_ok & is.na(x$example_profile_conf_low),
      na.rm = TRUE
    ),
    n_missing_upper_endpoint = sum(
      detail_ok & is.na(x$example_profile_conf_high),
      na.rm = TRUE
    ),
    min_example_estimate = phase18_count_structured_q1_range_value(
      estimate,
      min
    ),
    max_example_estimate = phase18_count_structured_q1_range_value(
      estimate,
      max
    ),
    min_example_estimate_over_truth = phase18_count_structured_q1_range_value(
      estimate_ratio,
      min
    ),
    max_example_estimate_over_truth = phase18_count_structured_q1_range_value(
      estimate_ratio,
      max
    ),
    min_example_cell_id = phase18_count_structured_q1_index_value(
      x,
      "cell_id",
      min_row
    ),
    min_example_replicate = phase18_count_structured_q1_index_value(
      x,
      "example_replicate",
      min_row
    ),
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_range_value <- function(x, fun) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  fun(x)
}

phase18_count_structured_q1_index_value <- function(x, name, index) {
  if (is.na(index) || !name %in% names(x)) {
    return(NA)
  }
  x[[name]][[index]]
}

phase18_count_structured_q1_profile_trace_examples <- function() {
  data.frame(
    cell_id = c(
      "count_structured_q1_006",
      "count_structured_q1_003",
      "count_structured_q1_001"
    ),
    replicate = c(45L, 33L, 25L),
    seed = c(932584520L, 461195966L, 32713190L),
    failure_class = c(
      "nonfinite_interval",
      "profile_crossing_failure",
      "profile_crossing_failure"
    ),
    example_role = c(
      "minimum_nonfinite_estimate",
      "minimum_crossing_estimate",
      "larger_crossing_estimate"
    ),
    profile_parameters = c(
      "sd:mu:spatial(1 | site)",
      "sd:mu:animal(1 | id)",
      "sd:mu:spatial(1 | site)"
    ),
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_profile_trace_plan <- function(
  examples = phase18_count_structured_q1_profile_trace_examples(),
  condition_set = "stable",
  master_seed = 20260530L,
  profile_parameters = NULL,
  profile_level = 0.70,
  ystep = c(current = 0.50, smaller_ystep = 0.25)
) {
  phase18_assert_summary_columns(examples, c("cell_id", "replicate"))
  assert_positive_whole_number(master_seed, "master_seed")
  if (is.null(profile_parameters)) {
    phase18_assert_summary_columns(examples, "profile_parameters")
    if (
      !is.character(examples$profile_parameters) ||
        any(!nzchar(examples$profile_parameters))
    ) {
      stop(
        "`examples$profile_parameters` must contain non-empty strings.",
        call. = FALSE
      )
    }
  } else {
    if (
      !is.character(profile_parameters) ||
        length(profile_parameters) != 1L ||
        !nzchar(profile_parameters)
    ) {
      stop("`profile_parameters` must be one non-empty string.", call. = FALSE)
    }
    examples$profile_parameters <- profile_parameters
  }
  if (
    !is.numeric(profile_level) ||
      length(profile_level) != 1L ||
      !is.finite(profile_level) ||
      profile_level <= 0 ||
      profile_level >= 1
  ) {
    stop("`profile_level` must be one number between 0 and 1.", call. = FALSE)
  }
  if (
    !is.numeric(ystep) ||
      length(ystep) == 0L ||
      any(!is.finite(ystep)) ||
      any(ystep <= 0)
  ) {
    stop("`ystep` must be a positive numeric vector.", call. = FALSE)
  }

  profile_pass <- names(ystep)
  if (is.null(profile_pass) || any(!nzchar(profile_pass))) {
    profile_pass <- paste0("ystep_", format(ystep, trim = TRUE))
  }
  examples <- examples[seq_len(nrow(examples)), , drop = FALSE]
  examples$replicate <- as.integer(examples$replicate)
  if (any(is.na(examples$replicate)) || any(examples$replicate <= 0L)) {
    stop(
      "`examples$replicate` must contain positive whole numbers.",
      call. = FALSE
    )
  }
  example_has_seed <- "seed" %in% names(examples)
  if (example_has_seed) {
    examples$seed <- as.integer(examples$seed)
    if (any(is.na(examples$seed)) || any(examples$seed <= 0L)) {
      stop(
        "`examples$seed` must contain positive whole numbers.",
        call. = FALSE
      )
    }
  }

  registry <- phase18_cell_registry(
    surface = "count_structured_q1",
    conditions = phase18_count_structured_q1_followup_conditions(condition_set),
    n_rep = max(examples$replicate),
    master_seed = master_seed
  )
  seed_rows <- registry$seeds[,
    c("cell_id", "cell_index", "replicate", "seed"),
    drop = FALSE
  ]
  names(seed_rows)[names(seed_rows) == "seed"] <- "registry_seed"
  plan <- merge(
    examples,
    seed_rows,
    by = c("cell_id", "replicate"),
    all.x = TRUE,
    sort = FALSE
  )
  if (any(is.na(plan$cell_index))) {
    stop(
      "Every selected example must match a seeded registry row.",
      call. = FALSE
    )
  }
  if (example_has_seed) {
    plan$seed <- as.integer(plan$seed)
  } else {
    plan$seed <- as.integer(plan$registry_seed)
  }
  plan$registry_seed <- NULL

  expanded <- lapply(seq_along(ystep), function(i) {
    out <- plan
    out$profile_pass <- profile_pass[[i]]
    out$profile_level <- profile_level
    out$ystep <- unname(ystep[[i]])
    out
  })
  out <- do.call(rbind, expanded)
  row.names(out) <- NULL
  out
}

phase18_write_count_structured_q1_profile_trace_plan <- function(
  output_dir,
  plan = phase18_count_structured_q1_profile_trace_plan(),
  overwrite = FALSE
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }
  phase18_assert_summary_columns(
    plan,
    c(
      "cell_id",
      "replicate",
      "seed",
      "profile_pass",
      "profile_parameters",
      "profile_level",
      "ystep"
    )
  )

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  path <- phase18_count_structured_q1_profile_trace_run_paths(
    dirs$table_dir
  )$plan_csv
  if (file.exists(path) && !overwrite) {
    stop(
      "Count structured q1 profile trace plan already exists: ",
      path,
      call. = FALSE
    )
  }

  utils::write.csv(plan, path, row.names = FALSE)
  list(
    surface = "count_structured_q1_profile_trace_plan",
    output_dir = dirs$output_dir,
    table_dir = dirs$table_dir,
    path = path,
    plan = plan
  )
}

phase18_write_count_structured_q1_profile_trace_run <- function(
  output_dir,
  plan = phase18_count_structured_q1_profile_trace_plan(),
  conditions = phase18_count_structured_q1_followup_conditions("stable"),
  overwrite = FALSE,
  dgp_fun = phase18_dgp_count_structured_q1_cell,
  fit_fun = phase18_fit_count_structured_q1,
  profile_fun = stats::profile
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- phase18_count_structured_q1_profile_trace_run_paths(
    dirs$table_dir
  )
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Count structured q1 profile trace run"
  )

  trace <- phase18_count_structured_q1_profile_trace_run_plan(
    plan = plan,
    conditions = conditions,
    dgp_fun = dgp_fun,
    fit_fun = fit_fun,
    profile_fun = profile_fun
  )
  summary <- phase18_count_structured_q1_profile_trace_summary(trace)
  side_summary <- phase18_count_structured_q1_profile_trace_side_summary(trace)
  utils::write.csv(plan, paths$plan_csv, row.names = FALSE)
  utils::write.csv(trace, paths$trace_csv, row.names = FALSE)
  utils::write.csv(summary, paths$summary_csv, row.names = FALSE)
  utils::write.csv(side_summary, paths$side_summary_csv, row.names = FALSE)

  list(
    surface = "count_structured_q1_profile_trace_run",
    output_dir = dirs$output_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    plan = plan,
    trace = trace,
    summary = summary,
    side_summary = side_summary
  )
}

phase18_count_structured_q1_profile_trace_run_paths <- function(table_dir) {
  list(
    plan_csv = file.path(
      table_dir,
      "count-structured-q1-profile-trace-plan.csv"
    ),
    trace_csv = file.path(
      table_dir,
      "count-structured-q1-profile-trace.csv"
    ),
    summary_csv = file.path(
      table_dir,
      "count-structured-q1-profile-trace-summary.csv"
    ),
    side_summary_csv = file.path(
      table_dir,
      "count-structured-q1-profile-trace-side-summary.csv"
    )
  )
}

phase18_write_count_structured_q1_profile_trace_plot <- function(
  output_dir,
  trace,
  overwrite = FALSE,
  width = 9,
  height = 5.5,
  dpi = 160
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  figure_dir <- file.path(dirs$output_dir, "figures")
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(
    figure_dir,
    "count-structured-q1-profile-trace.png"
  )
  phase18_assert_simple_grid_overwrite(
    list(plot_png = path),
    overwrite,
    "Count structured q1 profile trace plot"
  )

  plot <- phase18_plot_count_structured_q1_profile_trace(trace)
  ggplot2::ggsave(
    filename = path,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = dpi
  )

  list(
    surface = "count_structured_q1_profile_trace_plot",
    output_dir = dirs$output_dir,
    table_dir = dirs$table_dir,
    figure_dir = figure_dir,
    path = path,
    plot = plot,
    summary = phase18_count_structured_q1_profile_trace_summary(trace)
  )
}

phase18_count_structured_q1_profile_trace_result <- function(
  fit,
  plan_row,
  profile_fun = stats::profile
) {
  if (!inherits(fit, "drmTMB")) {
    stop("`fit` must be a drmTMB object.", call. = FALSE)
  }
  phase18_assert_one_row_data_frame(plan_row, "plan_row")
  phase18_assert_summary_columns(
    plan_row,
    c(
      "cell_id",
      "replicate",
      "seed",
      "profile_pass",
      "profile_parameters",
      "profile_level",
      "ystep"
    )
  )
  phase18_assert_function(profile_fun, "profile_fun")

  started <- proc.time()[["elapsed"]]
  prof <- tryCatch(
    profile_fun(
      fit,
      parm = plan_row$profile_parameters[[1L]],
      level = plan_row$profile_level[[1L]],
      ystep = plan_row$ystep[[1L]]
    ),
    error = function(e) e
  )
  elapsed <- proc.time()[["elapsed"]] - started
  metadata <- phase18_count_structured_q1_profile_trace_metadata(
    plan_row,
    elapsed = elapsed
  )

  if (inherits(prof, "error")) {
    return(phase18_count_structured_q1_profile_trace_failure(
      plan_row,
      conditionMessage(prof),
      elapsed
    ))
  }
  trace <- as.data.frame(prof)
  if (nrow(trace) == 0L) {
    return(phase18_count_structured_q1_profile_trace_failure(
      plan_row,
      "profile trace returned no rows",
      elapsed
    ))
  }

  metadata$trace_status <- "ok"
  metadata$trace_message <- ""
  out <- cbind(
    metadata[rep(1L, nrow(trace)), , drop = FALSE],
    trace,
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

phase18_count_structured_q1_profile_trace_run_plan <- function(
  plan = phase18_count_structured_q1_profile_trace_plan(),
  conditions = phase18_count_structured_q1_followup_conditions("stable"),
  dgp_fun = phase18_dgp_count_structured_q1_cell,
  fit_fun = phase18_fit_count_structured_q1,
  profile_fun = stats::profile
) {
  if (!is.data.frame(plan) || nrow(plan) == 0L) {
    stop("`plan` must be a non-empty data frame.", call. = FALSE)
  }
  if (!is.data.frame(conditions) || nrow(conditions) == 0L) {
    stop("`conditions` must be a non-empty data frame.", call. = FALSE)
  }
  phase18_assert_summary_columns(
    plan,
    c(
      "cell_id",
      "replicate",
      "seed",
      "cell_index",
      "profile_pass",
      "profile_parameters",
      "profile_level",
      "ystep"
    )
  )
  phase18_assert_function(dgp_fun, "dgp_fun")
  phase18_assert_function(fit_fun, "fit_fun")
  phase18_assert_function(profile_fun, "profile_fun")

  rows <- lapply(seq_len(nrow(plan)), function(i) {
    plan_row <- plan[i, , drop = FALSE]
    started <- proc.time()[["elapsed"]]
    cell_index <- plan_row$cell_index[[1L]]
    assert_positive_whole_number(cell_index, "plan_row$cell_index")
    if (cell_index > nrow(conditions)) {
      stop(
        "`plan$cell_index` must refer to a row in `conditions`.",
        call. = FALSE
      )
    }
    cell <- conditions[cell_index, , drop = FALSE]
    data <- tryCatch(
      dgp_fun(
        cell = cell,
        seed = plan_row$seed[[1L]],
        cell_id = plan_row$cell_id[[1L]],
        replicate = plan_row$replicate[[1L]]
      ),
      error = function(e) e
    )
    if (inherits(data, "error")) {
      return(phase18_count_structured_q1_profile_trace_failure(
        plan_row,
        paste("dgp_fun failed:", conditionMessage(data)),
        proc.time()[["elapsed"]] - started
      ))
    }

    fit <- tryCatch(
      fit_fun(data = data, cell = cell),
      error = function(e) e
    )
    if (inherits(fit, "error")) {
      return(phase18_count_structured_q1_profile_trace_failure(
        plan_row,
        paste("fit_fun failed:", conditionMessage(fit)),
        proc.time()[["elapsed"]] - started
      ))
    }

    phase18_count_structured_q1_profile_trace_result(
      fit,
      plan_row,
      profile_fun = profile_fun
    )
  })
  phase18_count_structured_q1_profile_trace_bind_rows(rows)
}

phase18_count_structured_q1_profile_trace_metadata <- function(
  plan_row,
  elapsed
) {
  optional <- c("failure_class", "example_role", "cell_index")
  for (name in optional) {
    if (!name %in% names(plan_row)) {
      plan_row[[name]] <- NA
    }
  }
  data.frame(
    cell_id = plan_row$cell_id[[1L]],
    replicate = as.integer(plan_row$replicate[[1L]]),
    seed = as.integer(plan_row$seed[[1L]]),
    failure_class = plan_row$failure_class[[1L]],
    example_role = plan_row$example_role[[1L]],
    cell_index = as.integer(plan_row$cell_index[[1L]]),
    profile_pass = plan_row$profile_pass[[1L]],
    profile_parameters = plan_row$profile_parameters[[1L]],
    profile_level = as.numeric(plan_row$profile_level[[1L]]),
    ystep = as.numeric(plan_row$ystep[[1L]]),
    trace_status = NA_character_,
    trace_message = NA_character_,
    trace_elapsed = as.numeric(elapsed),
    stringsAsFactors = FALSE
  )
}

phase18_count_structured_q1_profile_trace_failure <- function(
  plan_row,
  message,
  elapsed
) {
  metadata <- phase18_count_structured_q1_profile_trace_metadata(
    plan_row,
    elapsed = elapsed
  )
  metadata$trace_status <- "failed"
  metadata$trace_message <- message
  metadata
}

phase18_count_structured_q1_profile_trace_bind_rows <- function(pieces) {
  pieces <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, pieces)
  if (length(pieces) == 0L) {
    return(data.frame())
  }
  all_names <- unique(unlist(lapply(pieces, names), use.names = FALSE))
  aligned <- lapply(pieces, function(x) {
    missing <- setdiff(all_names, names(x))
    for (name in missing) {
      x[[name]] <- NA
    }
    x[all_names]
  })
  out <- do.call(rbind, aligned)
  row.names(out) <- NULL
  out
}

phase18_count_structured_q1_profile_trace_summary <- function(trace) {
  if (!is.data.frame(trace) || nrow(trace) == 0L) {
    stop("`trace` must be a non-empty data frame.", call. = FALSE)
  }
  phase18_assert_summary_columns(
    trace,
    c("cell_id", "replicate", "profile_pass", "trace_status")
  )

  keys <- paste(trace$cell_id, trace$replicate, trace$profile_pass, sep = "\r")
  rows <- lapply(split(trace, keys, drop = TRUE), function(x) {
    trace_status <- phase18_count_structured_q1_trace_status_rollup(
      x$trace_status
    )
    data.frame(
      cell_id = phase18_count_structured_q1_first(x, "cell_id"),
      replicate = phase18_count_structured_q1_first(x, "replicate"),
      failure_class = phase18_count_structured_q1_first(
        x,
        "failure_class"
      ),
      example_role = phase18_count_structured_q1_first(x, "example_role"),
      profile_pass = phase18_count_structured_q1_first(x, "profile_pass"),
      profile_parameters = phase18_count_structured_q1_first(
        x,
        "profile_parameters"
      ),
      trace_status = trace_status,
      n_trace_row = nrow(x),
      n_trace_ok = sum(x$trace_status == "ok", na.rm = TRUE),
      n_trace_failed = sum(x$trace_status == "failed", na.rm = TRUE),
      trace_elapsed = phase18_count_structured_q1_range_value(
        x$trace_elapsed,
        max
      ),
      estimate = phase18_count_structured_q1_first(x, "estimate"),
      link_estimate = phase18_count_structured_q1_first(x, "link_estimate"),
      conf_low = phase18_count_structured_q1_first(x, "conf.low"),
      conf_high = phase18_count_structured_q1_first(x, "conf.high"),
      conf_status = phase18_count_structured_q1_first(
        x,
        "conf.status"
      ),
      n_missing_lower_endpoint = phase18_count_structured_q1_missing_count(
        x,
        "conf.low"
      ),
      n_missing_upper_endpoint = phase18_count_structured_q1_missing_count(
        x,
        "conf.high"
      ),
      min_profile_value = phase18_count_structured_q1_range_value(
        x$profile_value,
        min
      ),
      max_profile_value = phase18_count_structured_q1_range_value(
        x$profile_value,
        max
      ),
      max_delta_deviance = phase18_count_structured_q1_range_value(
        x$delta_deviance,
        max
      ),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_count_structured_q1_trace_status_rollup <- function(status) {
  status <- unique(status[!is.na(status) & nzchar(status)])
  if (length(status) == 0L) {
    return("missing")
  }
  if (length(status) == 1L) {
    return(status[[1L]])
  }
  if (all(status == "ok")) {
    return("ok")
  }
  "mixed"
}

phase18_count_structured_q1_missing_count <- function(x, name) {
  if (!name %in% names(x)) {
    return(NA_integer_)
  }
  sum(is.na(x[[name]]))
}

phase18_count_structured_q1_profile_trace_side_summary <- function(trace) {
  if (!is.data.frame(trace) || nrow(trace) == 0L) {
    stop("`trace` must be a non-empty data frame.", call. = FALSE)
  }
  phase18_assert_summary_columns(
    trace,
    c(
      "cell_id",
      "replicate",
      "profile_pass",
      "trace_status",
      "profile_level",
      "profile_value",
      "profile_value_link",
      "link_estimate",
      "delta_deviance",
      "conf.low",
      "conf.high"
    )
  )

  keys <- paste(trace$cell_id, trace$replicate, trace$profile_pass, sep = "\r")
  rows <- lapply(split(trace, keys, drop = TRUE), function(x) {
    level <- phase18_count_structured_q1_first(x, "profile_level", 0.70)
    if (!is.numeric(level) || length(level) != 1L || !is.finite(level)) {
      level <- 0.70
    }
    cutoff <- stats::qchisq(level, df = 1)
    link_estimate <- as.numeric(
      phase18_count_structured_q1_first(x, "link_estimate", NA_real_)
    )
    profile_value_link <- as.numeric(x$profile_value_link)
    side_specs <- list(
      lower = list(
        rows = if (is.finite(link_estimate)) {
          x[
            is.finite(profile_value_link) & profile_value_link <= link_estimate,
            ,
            drop = FALSE
          ]
        } else {
          x[FALSE, , drop = FALSE]
        },
        endpoint_name = "conf.low"
      ),
      upper = list(
        rows = if (is.finite(link_estimate)) {
          x[
            is.finite(profile_value_link) & profile_value_link >= link_estimate,
            ,
            drop = FALSE
          ]
        } else {
          x[FALSE, , drop = FALSE]
        },
        endpoint_name = "conf.high"
      )
    )
    do.call(
      rbind,
      lapply(names(side_specs), function(side) {
        spec <- side_specs[[side]]
        side_rows <- spec$rows
        max_delta <- phase18_count_structured_q1_range_value(
          side_rows$delta_deviance,
          max
        )
        endpoint_value <- phase18_count_structured_q1_first(
          x,
          spec$endpoint_name,
          NA_real_
        )
        data.frame(
          cell_id = phase18_count_structured_q1_first(x, "cell_id"),
          replicate = phase18_count_structured_q1_first(x, "replicate"),
          failure_class = phase18_count_structured_q1_first(
            x,
            "failure_class"
          ),
          example_role = phase18_count_structured_q1_first(x, "example_role"),
          profile_pass = phase18_count_structured_q1_first(x, "profile_pass"),
          profile_parameters = phase18_count_structured_q1_first(
            x,
            "profile_parameters"
          ),
          profile_side = side,
          profile_level = level,
          cutoff_delta_deviance = cutoff,
          endpoint_value = as.numeric(endpoint_value),
          endpoint_present = is.finite(as.numeric(endpoint_value)),
          n_side_trace_row = nrow(side_rows),
          min_side_profile_value = phase18_count_structured_q1_range_value(
            side_rows$profile_value,
            min
          ),
          max_side_profile_value = phase18_count_structured_q1_range_value(
            side_rows$profile_value,
            max
          ),
          min_side_profile_value_link = phase18_count_structured_q1_range_value(
            side_rows$profile_value_link,
            min
          ),
          max_side_profile_value_link = phase18_count_structured_q1_range_value(
            side_rows$profile_value_link,
            max
          ),
          max_side_delta_deviance = max_delta,
          side_reaches_cutoff = isTRUE(
            is.finite(max_delta) && max_delta >= cutoff
          ),
          stringsAsFactors = FALSE
        )
      })
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_plot_count_structured_q1_profile_trace <- function(trace) {
  phase18_count_structured_q1_require_ggplot2()
  phase18_assert_summary_columns(
    trace,
    c(
      "cell_id",
      "replicate",
      "profile_pass",
      "profile_value",
      "profile_value_link",
      "delta_deviance"
    )
  )
  summary <- phase18_count_structured_q1_profile_trace_summary(trace)
  trace$.trace_facet <- phase18_count_structured_q1_trace_facet(trace)
  summary$.trace_facet <- phase18_count_structured_q1_trace_facet(summary)
  level <- phase18_count_structured_q1_first(trace, "profile_level", 0.70)
  if (!is.numeric(level) || length(level) != 1L || !is.finite(level)) {
    level <- 0.70
  }
  cutoff <- stats::qchisq(level, df = 1)

  ggplot2::ggplot(
    trace,
    ggplot2::aes(
      x = .data[["profile_value_link"]],
      y = .data[["delta_deviance"]],
      colour = .data[["profile_pass"]],
      linetype = .data[["profile_pass"]]
    )
  ) +
    ggplot2::geom_hline(
      yintercept = cutoff,
      linewidth = 0.35,
      linetype = "dashed",
      colour = "grey45"
    ) +
    ggplot2::geom_vline(
      data = summary,
      ggplot2::aes(xintercept = .data[["link_estimate"]]),
      inherit.aes = FALSE,
      linewidth = 0.35,
      colour = "grey35"
    ) +
    ggplot2::geom_line(linewidth = 0.45, na.rm = TRUE) +
    ggplot2::geom_point(size = 0.8, alpha = 0.75, na.rm = TRUE) +
    ggplot2::scale_colour_manual(
      values = c(current = "#C85A5A", smaller_ystep = "#008C95")
    ) +
    ggplot2::scale_linetype_manual(
      values = c(current = "solid", smaller_ystep = "longdash")
    ) +
    ggplot2::scale_y_sqrt() +
    ggplot2::facet_wrap(~.trace_facet, scales = "free_x") +
    ggplot2::labs(
      x = "Log structured SD profile value",
      y = "Likelihood-ratio distance (sqrt scale)",
      colour = "Profile pass",
      linetype = "Profile pass"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom"
    )
}

phase18_count_structured_q1_trace_facet <- function(x) {
  role <- if ("example_role" %in% names(x)) {
    x$example_role
  } else {
    rep(NA_character_, nrow(x))
  }
  role[is.na(role) | !nzchar(role)] <- x$cell_id[is.na(role) | !nzchar(role)]
  paste0(role, "\n", x$cell_id, " rep ", x$replicate)
}

phase18_count_structured_q1_require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop(
      "`phase18_plot_count_structured_q1_profile_trace()` requires ggplot2.",
      call. = FALSE
    )
  }
  invisible(TRUE)
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
