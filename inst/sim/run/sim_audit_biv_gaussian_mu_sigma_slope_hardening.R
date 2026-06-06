phase18_audit_biv_gaussian_mu_sigma_slope_hardening <- function(
  artifact_dir = file.path(
    "inst",
    "sim",
    "results",
    "actions",
    "biv_gaussian_mu_sigma_slope_recovery"
  ),
  output_dir = file.path(artifact_dir, "refit-audit"),
  conditions = phase18_biv_gaussian_mu_sigma_slope_conditions(
    n_id = c(72L, 96L),
    n_each = 10L
  ),
  n_rep = NULL,
  master_seed = 20260630L,
  run_refits = TRUE,
  robust_control = list(eval.max = 5000L, iter.max = 5000L),
  profile_replicates_per_cell = 1L,
  profile_level = 0.95,
  overwrite = FALSE
) {
  artifact <- phase18_read_biv_gaussian_mu_sigma_slope_recovery_artifact(
    artifact_dir
  )
  if (is.null(n_rep)) {
    n_rep <- max(artifact$manifest$replicate)
  }
  assert_positive_whole_number(n_rep, "n_rep")
  assert_positive_whole_number(master_seed, "master_seed")
  if (
    !is.logical(run_refits) || length(run_refits) != 1L || is.na(run_refits)
  ) {
    stop("`run_refits` must be TRUE or FALSE.", call. = FALSE)
  }
  phase18_assert_nonnegative_whole_number(
    profile_replicates_per_cell,
    "profile_replicates_per_cell"
  )
  phase18_assert_probability(profile_level, "profile_level")
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  registry <- phase18_cell_registry(
    surface = "biv_gaussian_mu_sigma_slope",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )
  phase18_assert_biv_gaussian_mu_sigma_slope_registry_matches_artifact(
    registry,
    artifact$manifest
  )

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  paths <- phase18_biv_gaussian_mu_sigma_slope_hardening_paths(output_dir)
  phase18_assert_biv_gaussian_mu_sigma_slope_hardening_overwrite(
    paths,
    overwrite
  )

  weak <- phase18_biv_gaussian_mu_sigma_slope_weak_replicates(
    replicates = artifact$replicates,
    manifest = artifact$manifest
  )
  original_recovery <- phase18_biv_gaussian_mu_sigma_slope_point_recovery_by_fit_status(
    artifact$replicates,
    weak
  )

  refits <- if (run_refits) {
    phase18_refit_biv_gaussian_mu_sigma_slope_weak(
      weak = weak,
      registry = registry,
      control = robust_control
    )
  } else {
    list(
      status = phase18_empty_biv_gaussian_mu_sigma_slope_refit_status(),
      summaries = phase18_empty_biv_gaussian_mu_sigma_slope_summary()
    )
  }
  coverage <- phase18_biv_gaussian_mu_sigma_slope_combined_wald_coverage(
    original = artifact$replicates,
    weak = weak,
    robust = refits$summaries
  )
  deltas <- phase18_biv_gaussian_mu_sigma_slope_refit_deltas(
    original = artifact$replicates,
    robust = refits$summaries
  )
  profile <- phase18_profile_biv_gaussian_mu_sigma_slope_clean_fits(
    replicates = artifact$replicates,
    registry = registry,
    per_cell = profile_replicates_per_cell,
    level = profile_level
  )

  utils::write.csv(weak, paths$weak_replicates_csv, row.names = FALSE)
  utils::write.csv(
    refits$status,
    paths$robust_refit_status_csv,
    row.names = FALSE
  )
  utils::write.csv(
    refits$summaries,
    paths$robust_refit_summaries_csv,
    row.names = FALSE
  )
  utils::write.csv(
    coverage,
    paths$robust_combined_fixed_wald_coverage_csv,
    row.names = FALSE
  )
  utils::write.csv(
    original_recovery,
    paths$original_point_recovery_by_fit_status_csv,
    row.names = FALSE
  )
  utils::write.csv(
    deltas,
    paths$robust_vs_original_weak_estimate_deltas_csv,
    row.names = FALSE
  )
  utils::write.csv(
    profile$status,
    paths$profile_feasibility_status_csv,
    row.names = FALSE
  )
  utils::write.csv(
    profile$intervals,
    paths$profile_feasibility_intervals_csv,
    row.names = FALSE
  )
  utils::write.csv(
    profile$targets,
    paths$profile_feasibility_targets_csv,
    row.names = FALSE
  )

  list(
    artifact_dir = artifact_dir,
    output_dir = output_dir,
    paths = paths,
    weak_replicates = weak,
    robust_refit = refits,
    robust_combined_fixed_wald_coverage = coverage,
    original_point_recovery_by_fit_status = original_recovery,
    robust_vs_original_weak_estimate_deltas = deltas,
    profile_feasibility = profile
  )
}

phase18_read_biv_gaussian_mu_sigma_slope_recovery_artifact <- function(
  artifact_dir
) {
  if (
    !is.character(artifact_dir) ||
      length(artifact_dir) != 1L ||
      !nzchar(artifact_dir)
  ) {
    stop("`artifact_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (!dir.exists(artifact_dir)) {
    stop("`artifact_dir` must be an existing directory.", call. = FALSE)
  }
  table_dir <- file.path(artifact_dir, "tables")
  prefix <- "biv-gaussian-mu-sigma-slope-recovery"
  replicate_path <- file.path(table_dir, paste0(prefix, "-replicates.csv"))
  manifest_path <- file.path(table_dir, paste0(prefix, "-manifest.csv"))
  if (file.exists(replicate_path) && file.exists(manifest_path)) {
    replicates <- utils::read.csv(replicate_path, check.names = FALSE)
    manifest <- utils::read.csv(manifest_path, check.names = FALSE)
  } else {
    results <- phase18_read_result_dir(file.path(artifact_dir, "results"))
    replicates <- phase18_result_summaries(results)
    manifest <- phase18_result_manifest(results)
  }
  phase18_assert_summary_columns(
    replicates,
    c(
      "cell_id",
      "replicate",
      "parameter",
      "parameter_class",
      "truth",
      "estimate",
      "std.error",
      "converged",
      "pdHess"
    )
  )
  phase18_assert_summary_columns(
    manifest,
    c("cell_id", "replicate", "seed", "status", "warning_count")
  )
  list(replicates = replicates, manifest = manifest)
}

phase18_biv_gaussian_mu_sigma_slope_hardening_paths <- function(output_dir) {
  list(
    weak_replicates_csv = file.path(output_dir, "weak-replicates.csv"),
    robust_refit_status_csv = file.path(output_dir, "robust-refit-status.csv"),
    robust_refit_summaries_csv = file.path(
      output_dir,
      "robust-refit-summaries.csv"
    ),
    robust_combined_fixed_wald_coverage_csv = file.path(
      output_dir,
      "robust-combined-fixed-wald-coverage.csv"
    ),
    original_point_recovery_by_fit_status_csv = file.path(
      output_dir,
      "original-point-recovery-by-fit-status.csv"
    ),
    robust_vs_original_weak_estimate_deltas_csv = file.path(
      output_dir,
      "robust-vs-original-weak-estimate-deltas.csv"
    ),
    profile_feasibility_status_csv = file.path(
      output_dir,
      "profile-feasibility-status.csv"
    ),
    profile_feasibility_intervals_csv = file.path(
      output_dir,
      "profile-feasibility-intervals.csv"
    ),
    profile_feasibility_targets_csv = file.path(
      output_dir,
      "profile-feasibility-targets.csv"
    )
  )
}

phase18_assert_nonnegative_whole_number <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x == as.integer(x) &&
    x >= 0
  if (!ok) {
    stop("`", name, "` must be one non-negative whole number.", call. = FALSE)
  }
  invisible(x)
}

phase18_assert_probability <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x > 0 &&
    x < 1
  if (!ok) {
    stop("`", name, "` must be one number between 0 and 1.", call. = FALSE)
  }
  invisible(x)
}

phase18_assert_biv_gaussian_mu_sigma_slope_hardening_overwrite <- function(
  paths,
  overwrite
) {
  existing <- unlist(paths, use.names = FALSE)
  existing <- existing[file.exists(existing)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Bivariate Gaussian mu/sigma slope hardening audit output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}

phase18_assert_biv_gaussian_mu_sigma_slope_registry_matches_artifact <- function(
  registry,
  manifest
) {
  expected <- registry$seeds[c("cell_id", "replicate", "seed")]
  observed <- manifest[c("cell_id", "replicate", "seed")]
  expected$key <- paste(expected$cell_id, expected$replicate, sep = "\r")
  observed$key <- paste(observed$cell_id, observed$replicate, sep = "\r")
  matched <- expected[match(observed$key, expected$key), ]
  missing <- is.na(matched$seed)
  if (any(missing) || any(matched$seed != observed$seed)) {
    stop(
      "`conditions`, `n_rep`, and `master_seed` do not reproduce the artifact manifest seeds.",
      call. = FALSE
    )
  }
  invisible(registry)
}

phase18_biv_gaussian_mu_sigma_slope_weak_replicates <- function(
  replicates,
  manifest
) {
  phase18_assert_summary_columns(
    replicates,
    c("cell_id", "replicate", "converged", "pdHess")
  )
  phase18_assert_summary_columns(
    manifest,
    c("cell_id", "replicate", "seed", "warning_count")
  )
  key <- paste(replicates$cell_id, replicates$replicate, sep = "\r")
  pieces <- split(replicates, key)
  rows <- lapply(pieces, function(x) {
    data.frame(
      cell_id = x$cell_id[[1L]],
      replicate = x$replicate[[1L]],
      original_converged = all(!is.na(x$converged) & as.logical(x$converged)),
      original_pdHess = all(!is.na(x$pdHess) & as.logical(x$pdHess)),
      stringsAsFactors = FALSE
    )
  })
  status <- do.call(rbind, rows)
  row.names(status) <- NULL
  status <- status[
    !status$original_converged | !status$original_pdHess,
    ,
    drop = FALSE
  ]
  if (nrow(status) == 0L) {
    return(data.frame(
      cell_id = character(),
      replicate = integer(),
      seed = integer(),
      original_converged = logical(),
      original_pdHess = logical(),
      original_warning_count = integer(),
      stringsAsFactors = FALSE
    ))
  }
  manifest$key <- paste(manifest$cell_id, manifest$replicate, sep = "\r")
  status$key <- paste(status$cell_id, status$replicate, sep = "\r")
  manifest_match <- manifest[match(status$key, manifest$key), , drop = FALSE]
  out <- data.frame(
    cell_id = status$cell_id,
    replicate = status$replicate,
    seed = manifest_match$seed,
    original_converged = status$original_converged,
    original_pdHess = status$original_pdHess,
    original_warning_count = manifest_match$warning_count,
    stringsAsFactors = FALSE
  )
  out[order(out$cell_id, out$replicate), , drop = FALSE]
}

phase18_refit_biv_gaussian_mu_sigma_slope_weak <- function(
  weak,
  registry,
  control
) {
  if (nrow(weak) == 0L) {
    return(list(
      status = phase18_empty_biv_gaussian_mu_sigma_slope_refit_status(),
      summaries = phase18_empty_biv_gaussian_mu_sigma_slope_summary()
    ))
  }
  rows <- vector("list", nrow(weak))
  summaries <- vector("list", nrow(weak))
  for (i in seq_len(nrow(weak))) {
    one <- weak[i, , drop = FALSE]
    cell <- phase18_biv_gaussian_mu_sigma_slope_cell_for_replicate(
      one,
      registry
    )
    refit <- phase18_refit_one_biv_gaussian_mu_sigma_slope_weak(
      weak = one,
      cell = cell,
      control = control
    )
    rows[[i]] <- refit$status
    summaries[[i]] <- refit$summary
  }
  status <- do.call(rbind, rows)
  row.names(status) <- NULL
  summaries <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, summaries)
  summary <- if (length(summaries) == 0L) {
    phase18_empty_biv_gaussian_mu_sigma_slope_summary()
  } else {
    out <- do.call(rbind, summaries)
    row.names(out) <- NULL
    if (!"artifact_grain" %in% names(out)) {
      out$artifact_grain <- "replicate"
    }
    out
  }
  list(status = status, summaries = summary)
}

phase18_refit_one_biv_gaussian_mu_sigma_slope_weak <- function(
  weak,
  cell,
  control
) {
  phase18_assert_one_row_data_frame(weak, "weak")
  phase18_assert_one_row_data_frame(cell, "cell")
  warnings <- character()
  error <- NULL
  fit <- NULL
  data <- NULL
  summary <- NULL
  started <- proc.time()[["elapsed"]]
  withCallingHandlers(
    tryCatch(
      {
        data <- phase18_dgp_biv_gaussian_mu_sigma_slope_cell(
          cell = cell,
          seed = weak$seed[[1L]],
          cell_id = weak$cell_id[[1L]],
          replicate = weak$replicate[[1L]]
        )
        fit <- phase18_fit_biv_gaussian_mu_sigma_slope_with_control(
          data = data,
          control = control
        )
        summary <- phase18_summarise_biv_gaussian_mu_sigma_slope_fit(
          fit = fit,
          truth = data,
          cell_id = weak$cell_id[[1L]],
          replicate = weak$replicate[[1L]],
          elapsed = proc.time()[["elapsed"]] - started,
          warnings = warnings
        )
      },
      error = function(e) {
        error <<- conditionMessage(e)
      }
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  status <- data.frame(
    cell_id = weak$cell_id,
    replicate = weak$replicate,
    seed = weak$seed,
    variant = "robust",
    original_converged = weak$original_converged,
    original_pdHess = weak$original_pdHess,
    original_warning_count = weak$original_warning_count,
    refit_error = !is.null(error),
    refit_message = if (is.null(error)) NA_character_ else error,
    refit_converged = isTRUE(!is.null(fit) && fit$opt$convergence == 0),
    refit_pdHess = isTRUE(!is.null(fit) && fit$sdr$pdHess),
    opt_convergence = if (is.null(fit)) NA_integer_ else fit$opt$convergence,
    opt_message = if (is.null(fit)) NA_character_ else fit$opt$message,
    max_abs_gradient = phase18_biv_gaussian_mu_sigma_slope_max_gradient(fit),
    elapsed = proc.time()[["elapsed"]] - started,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
  if (is.null(summary)) {
    summary <- phase18_empty_biv_gaussian_mu_sigma_slope_summary()
  }
  list(status = status, summary = summary)
}

phase18_fit_biv_gaussian_mu_sigma_slope_with_control <- function(
  data,
  control
) {
  drmTMB(
    bf(
      mu1 = y1 ~ x + (0 + x | p | id),
      mu2 = y2 ~ x,
      sigma1 = ~ x + (0 + x | p | id),
      sigma2 = ~x,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = data,
    control = control
  )
}

phase18_biv_gaussian_mu_sigma_slope_max_gradient <- function(fit) {
  if (is.null(fit) || is.null(fit$obj) || is.null(fit$opt)) {
    return(NA_real_)
  }
  gradient <- tryCatch(
    fit$obj$gr(fit$opt$par),
    error = function(e) NA_real_
  )
  if (!is.numeric(gradient) || all(is.na(gradient))) {
    return(NA_real_)
  }
  max(abs(gradient), na.rm = TRUE)
}

phase18_biv_gaussian_mu_sigma_slope_cell_for_replicate <- function(
  row,
  registry
) {
  phase18_assert_one_row_data_frame(row, "row")
  seed_row <- registry$seeds[
    registry$seeds$cell_id == row$cell_id[[1L]] &
      registry$seeds$replicate == row$replicate[[1L]],
    ,
    drop = FALSE
  ]
  if (nrow(seed_row) != 1L || seed_row$seed[[1L]] != row$seed[[1L]]) {
    stop(
      "The registry does not contain the requested replicate seed.",
      call. = FALSE
    )
  }
  registry$cells[seed_row$cell_index[[1L]], , drop = FALSE]
}

phase18_biv_gaussian_mu_sigma_slope_combined_wald_coverage <- function(
  original,
  weak,
  robust,
  wald_level = 0.95
) {
  if (nrow(weak) > 0L) {
    weak_key <- paste(weak$cell_id, weak$replicate, sep = "\r")
    original_key <- paste(original$cell_id, original$replicate, sep = "\r")
    original <- original[!original_key %in% weak_key, , drop = FALSE]
  }
  combined <- phase18_bind_biv_gaussian_mu_sigma_slope_rows(original, robust)
  if (nrow(combined) == 0L) {
    return(data.frame(
      cell_id = character(),
      parameter = character(),
      n_replicate = integer(),
      n_interval = integer(),
      n_covered = integer(),
      coverage_all = numeric(),
      coverage_interval_available = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  intervals <- phase18_add_wald_intervals(
    combined,
    conf.level = wald_level,
    interval_scale = "formula_coefficient"
  )
  fixed <- grepl("^fixed_", intervals$parameter_class)
  intervals <- intervals[fixed, , drop = FALSE]
  phase18_biv_gaussian_mu_sigma_slope_fixed_coverage(intervals)
}

phase18_biv_gaussian_mu_sigma_slope_fixed_coverage <- function(intervals) {
  key <- paste(intervals$cell_id, intervals$parameter, sep = "\r")
  pieces <- split(intervals, key)
  rows <- lapply(pieces, function(x) {
    interval_ok <- is.finite(x$conf.low) & is.finite(x$conf.high)
    covered <- interval_ok & x$truth >= x$conf.low & x$truth <= x$conf.high
    data.frame(
      cell_id = x$cell_id[[1L]],
      parameter = x$parameter[[1L]],
      n_replicate = nrow(x),
      n_interval = sum(interval_ok),
      n_covered = sum(covered),
      coverage_all = sum(covered) / nrow(x),
      coverage_interval_available = if (sum(interval_ok) == 0L) {
        NA_real_
      } else {
        sum(covered) / sum(interval_ok)
      },
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out[order(out$cell_id, out$parameter), , drop = FALSE]
}

phase18_biv_gaussian_mu_sigma_slope_point_recovery_by_fit_status <- function(
  replicates,
  weak
) {
  weak_key <- paste(weak$cell_id, weak$replicate, sep = "\r")
  key <- paste(replicates$cell_id, replicates$replicate, sep = "\r")
  replicates$fit_status <- ifelse(
    key %in% weak_key,
    "original_weak",
    "original_ok"
  )
  split_key <- paste(
    replicates$cell_id,
    replicates$parameter,
    replicates$fit_status,
    sep = "\r"
  )
  pieces <- split(replicates, split_key)
  rows <- lapply(pieces, function(x) {
    error <- x$estimate - x$truth
    data.frame(
      cell_id = x$cell_id[[1L]],
      parameter = x$parameter[[1L]],
      parameter_class = x$parameter_class[[1L]],
      fit_status = x$fit_status[[1L]],
      n_replicate = nrow(x),
      bias = mean(error),
      rmse = sqrt(mean(error^2)),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out[order(out$cell_id, out$parameter, out$fit_status), , drop = FALSE]
}

phase18_biv_gaussian_mu_sigma_slope_refit_deltas <- function(original, robust) {
  if (nrow(robust) == 0L) {
    return(data.frame(
      cell_id = character(),
      replicate = integer(),
      parameter = character(),
      original_estimate = numeric(),
      robust_estimate = numeric(),
      estimate_delta = numeric(),
      abs_estimate_delta = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  original$key <- paste(
    original$cell_id,
    original$replicate,
    original$parameter,
    sep = "\r"
  )
  robust$key <- paste(
    robust$cell_id,
    robust$replicate,
    robust$parameter,
    sep = "\r"
  )
  original <- original[match(robust$key, original$key), , drop = FALSE]
  out <- data.frame(
    cell_id = robust$cell_id,
    replicate = robust$replicate,
    parameter = robust$parameter,
    original_estimate = original$estimate,
    robust_estimate = robust$estimate,
    estimate_delta = robust$estimate - original$estimate,
    abs_estimate_delta = abs(robust$estimate - original$estimate),
    stringsAsFactors = FALSE
  )
  out[order(out$cell_id, out$replicate, out$parameter), , drop = FALSE]
}

phase18_bind_biv_gaussian_mu_sigma_slope_rows <- function(x, y) {
  columns <- union(names(x), names(y))
  for (column in setdiff(columns, names(x))) {
    x[[column]] <- rep(NA, nrow(x))
  }
  for (column in setdiff(columns, names(y))) {
    y[[column]] <- rep(NA, nrow(y))
  }
  rbind(x[columns], y[columns])
}

phase18_profile_biv_gaussian_mu_sigma_slope_clean_fits <- function(
  replicates,
  registry,
  per_cell,
  level
) {
  if (per_cell <= 0L) {
    return(list(
      status = phase18_empty_biv_gaussian_mu_sigma_slope_profile_status(),
      intervals = phase18_empty_biv_gaussian_mu_sigma_slope_profile_intervals(),
      targets = data.frame()
    ))
  }
  candidates <- phase18_biv_gaussian_mu_sigma_slope_profile_candidates(
    replicates,
    registry,
    per_cell = per_cell
  )
  if (nrow(candidates) == 0L) {
    return(list(
      status = phase18_empty_biv_gaussian_mu_sigma_slope_profile_status(),
      intervals = phase18_empty_biv_gaussian_mu_sigma_slope_profile_intervals(),
      targets = data.frame()
    ))
  }
  statuses <- vector("list", nrow(candidates))
  intervals <- vector("list", nrow(candidates))
  targets <- vector("list", nrow(candidates))
  for (i in seq_len(nrow(candidates))) {
    one <- candidates[i, , drop = FALSE]
    cell <- phase18_biv_gaussian_mu_sigma_slope_cell_for_replicate(
      one,
      registry
    )
    profiled <- phase18_profile_one_biv_gaussian_mu_sigma_slope_clean_fit(
      row = one,
      cell = cell,
      level = level
    )
    statuses[[i]] <- profiled$status
    intervals[[i]] <- profiled$intervals
    targets[[i]] <- profiled$targets
  }
  list(
    status = phase18_bind_or_empty(
      statuses,
      phase18_empty_biv_gaussian_mu_sigma_slope_profile_status()
    ),
    intervals = phase18_bind_or_empty(
      intervals,
      phase18_empty_biv_gaussian_mu_sigma_slope_profile_intervals()
    ),
    targets = phase18_bind_or_empty(targets, data.frame())
  )
}

phase18_biv_gaussian_mu_sigma_slope_profile_candidates <- function(
  replicates,
  registry,
  per_cell
) {
  key <- paste(replicates$cell_id, replicates$replicate, sep = "\r")
  pieces <- split(replicates, key)
  rows <- lapply(pieces, function(x) {
    warning_count <- if (all(is.na(x$warning_count))) {
      NA_integer_
    } else {
      max(x$warning_count, na.rm = TRUE)
    }
    data.frame(
      cell_id = x$cell_id[[1L]],
      replicate = x$replicate[[1L]],
      converged = all(!is.na(x$converged) & as.logical(x$converged)),
      pdHess = all(!is.na(x$pdHess) & as.logical(x$pdHess)),
      warning_count = warning_count,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out <- out[out$converged & out$pdHess, , drop = FALSE]
  if (nrow(out) == 0L) {
    return(out)
  }
  out <- out[order(out$cell_id, out$replicate), , drop = FALSE]
  selected <- do.call(
    rbind,
    lapply(split(out, out$cell_id), utils::head, per_cell)
  )
  row.names(selected) <- NULL
  selected$key <- paste(selected$cell_id, selected$replicate, sep = "\r")
  seeds <- registry$seeds
  seeds$key <- paste(seeds$cell_id, seeds$replicate, sep = "\r")
  selected$seed <- seeds$seed[match(selected$key, seeds$key)]
  selected$key <- NULL
  selected
}

phase18_profile_one_biv_gaussian_mu_sigma_slope_clean_fit <- function(
  row,
  cell,
  level
) {
  warnings <- character()
  error <- NULL
  intervals <- phase18_empty_biv_gaussian_mu_sigma_slope_profile_intervals()
  targets <- data.frame()
  fit <- NULL
  started <- proc.time()[["elapsed"]]
  withCallingHandlers(
    tryCatch(
      {
        data <- phase18_dgp_biv_gaussian_mu_sigma_slope_cell(
          cell = cell,
          seed = row$seed[[1L]],
          cell_id = row$cell_id[[1L]],
          replicate = row$replicate[[1L]]
        )
        fit <- phase18_fit_biv_gaussian_mu_sigma_slope(data, cell)
        targets <- profile_targets(fit, ready_only = TRUE)
        requested <- phase18_biv_gaussian_mu_sigma_slope_profile_parms()
        intervals <- phase18_confint_biv_gaussian_mu_sigma_slope_targets(
          fit,
          requested,
          level = level
        )
        if (nrow(intervals) > 0L) {
          intervals <- data.frame(
            cell_id = row$cell_id,
            replicate = row$replicate,
            seed = row$seed,
            intervals,
            stringsAsFactors = FALSE,
            check.names = FALSE
          )
        }
      },
      error = function(e) {
        error <<- conditionMessage(e)
      }
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (nrow(targets) > 0L) {
    targets <- data.frame(
      cell_id = row$cell_id,
      replicate = row$replicate,
      seed = row$seed,
      targets,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
  status <- data.frame(
    cell_id = row$cell_id,
    replicate = row$replicate,
    seed = row$seed,
    fit_converged = isTRUE(!is.null(fit) && fit$opt$convergence == 0),
    fit_pdHess = isTRUE(!is.null(fit) && fit$sdr$pdHess),
    fit_warning_count = length(warnings),
    profile_error = !is.null(error),
    profile_message = if (is.null(error)) NA_character_ else error,
    elapsed = proc.time()[["elapsed"]] - started,
    stringsAsFactors = FALSE
  )
  list(status = status, intervals = intervals, targets = targets)
}

phase18_biv_gaussian_mu_sigma_slope_profile_parms <- function() {
  c(
    "rho12",
    paste0("sd:mu:", phase18_biv_gaussian_mu_sigma_slope_sd_mu_name()),
    paste0("sd:sigma:", phase18_biv_gaussian_mu_sigma_slope_sd_sigma_name()),
    paste0("cor:mu_sigma:", phase18_biv_gaussian_mu_sigma_slope_cor_name())
  )
}

phase18_confint_biv_gaussian_mu_sigma_slope_targets <- function(
  fit,
  requested,
  level
) {
  rows <- lapply(requested, function(parm) {
    ci <- stats::confint(
      fit,
      parm = parm,
      level = level,
      method = "profile",
      profile_engine = "endpoint"
    )
    out <- as.data.frame(ci, stringsAsFactors = FALSE)
    data.frame(
      requested_parm = parm,
      out,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_bind_or_empty <- function(rows, empty) {
  rows <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, rows)
  if (length(rows) == 0L) {
    return(empty)
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_empty_biv_gaussian_mu_sigma_slope_refit_status <- function() {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    variant = character(),
    original_converged = logical(),
    original_pdHess = logical(),
    original_warning_count = integer(),
    refit_error = logical(),
    refit_message = character(),
    refit_converged = logical(),
    refit_pdHess = logical(),
    opt_convergence = integer(),
    opt_message = character(),
    max_abs_gradient = numeric(),
    elapsed = numeric(),
    warning_count = integer(),
    warnings = character(),
    artifact_grain = character(),
    stringsAsFactors = FALSE
  )
}

phase18_empty_biv_gaussian_mu_sigma_slope_summary <- function() {
  data.frame(
    surface = character(),
    cell_id = character(),
    replicate = integer(),
    parameter = character(),
    parameter_class = character(),
    truth = numeric(),
    estimate = numeric(),
    std.error = numeric(),
    error = numeric(),
    converged = logical(),
    pdHess = logical(),
    nobs = integer(),
    elapsed = numeric(),
    warning_count = integer(),
    warnings = character(),
    stringsAsFactors = FALSE
  )
}

phase18_empty_biv_gaussian_mu_sigma_slope_profile_status <- function() {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    fit_converged = logical(),
    fit_pdHess = logical(),
    fit_warning_count = integer(),
    profile_error = logical(),
    profile_message = character(),
    elapsed = numeric(),
    stringsAsFactors = FALSE
  )
}

phase18_empty_biv_gaussian_mu_sigma_slope_profile_intervals <- function() {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    requested_parm = character(),
    parm = character(),
    level = numeric(),
    lower = numeric(),
    upper = numeric(),
    scale = character(),
    transformation = character(),
    tmb_parameter = character(),
    index = integer(),
    method = character(),
    profile.engine = character(),
    conf.status = character(),
    profile.boundary = logical(),
    profile.message = character(),
    stringsAsFactors = FALSE
  )
}
