phase18_structured_re_ademp_conditions <- function(
  dimensions = c("q1", "q2", "q4"),
  structured_type = c("phylo", "spatial", "animal", "relmat"),
  matrix_condition = c("well_conditioned", "stress"),
  signal_strength = c("weak", "moderate"),
  boundary_proximity = c("interior", "near_boundary")
) {
  dimensions <- phase18_structured_re_ademp_match_choices(
    dimensions,
    c("q1", "q2", "q4"),
    "dimensions"
  )
  structured_type <- phase18_structured_re_ademp_match_choices(
    structured_type,
    c("phylo", "spatial", "animal", "relmat"),
    "structured_type"
  )
  matrix_condition <- phase18_structured_re_ademp_match_choices(
    matrix_condition,
    c("well_conditioned", "stress"),
    "matrix_condition"
  )
  signal_strength <- phase18_structured_re_ademp_match_choices(
    signal_strength,
    c("weak", "moderate"),
    "signal_strength"
  )
  boundary_proximity <- phase18_structured_re_ademp_match_choices(
    boundary_proximity,
    c("interior", "near_boundary"),
    "boundary_proximity"
  )

  out <- expand.grid(
    dimension = dimensions,
    structured_type = structured_type,
    matrix_condition = matrix_condition,
    signal_strength = signal_strength,
    boundary_proximity = boundary_proximity,
    stringsAsFactors = FALSE
  )
  out$endpoint_axes <- unname(c(
    q1 = "mu;sigma",
    q2 = "mu1;mu2",
    q4 = "mu1;mu2;sigma1;sigma2"
  )[out$dimension])
  out$estimator <- "ML"
  out$native_route <- "native_tmb"
  out$bridge_route <- "not_dispatched"
  out$dgp_label <- paste(
    "gaussian",
    out$dimension,
    out$structured_type,
    out$matrix_condition,
    sep = "_"
  )
  out$estimand_set <- unname(c(
    q1 = "fixed_effects;structured_sd",
    q2 = "fixed_effects;structured_sd;mean_mean_covariance",
    q4 = "fixed_effects;direct_structured_sd;derived_correlations"
  )[out$dimension])
  out$failed_fit_policy <- "all_replicates_in_denominator"
  out$interval_policy <- ifelse(
    out$dimension == "q4",
    "direct_and_derived_intervals_unavailable_until_calibrated",
    "intervals_unavailable_until_calibrated"
  )
  out$coverage_claim <- "none"

  ord <- order(
    match(out$dimension, c("q1", "q2", "q4")),
    match(out$structured_type, c("phylo", "spatial", "animal", "relmat")),
    match(out$matrix_condition, c("well_conditioned", "stress")),
    match(out$signal_strength, c("weak", "moderate")),
    match(out$boundary_proximity, c("interior", "near_boundary"))
  )
  out <- out[ord, , drop = FALSE]
  row.names(out) <- NULL
  out
}

phase18_structured_re_ademp_registry <- function(
  conditions = NULL,
  n_rep = 500L,
  master_seed = 20260622L,
  ...
) {
  assert_positive_whole_number(n_rep, "n_rep")
  assert_positive_whole_number(master_seed, "master_seed")
  if (is.null(conditions)) {
    conditions <- phase18_structured_re_ademp_conditions(...)
  }
  phase18_cell_registry(
    surface = "structured_re_ademp",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )
}

phase18_structured_re_ademp_mcse_n <- function(
  level = 0.95,
  target_mcse = 0.01
) {
  phase18_structured_re_ademp_assert_probability(level, "level")
  phase18_structured_re_ademp_assert_positive_number(
    target_mcse,
    "target_mcse"
  )
  n_rep <- level * (1 - level) / target_mcse^2
  as.integer(ceiling(n_rep - sqrt(.Machine$double.eps)))
}

phase18_structured_re_ademp_mcse_policy <- function(
  level = 0.95,
  target_mcse = 0.01,
  planned_n_rep = NULL
) {
  required_n <- phase18_structured_re_ademp_mcse_n(
    level = level,
    target_mcse = target_mcse
  )
  if (is.null(planned_n_rep)) {
    planned_n_rep <- max(500L, required_n)
  }
  assert_positive_whole_number(planned_n_rep, "planned_n_rep")

  data.frame(
    level = level,
    target_mcse = target_mcse,
    required_n_rep = required_n,
    planned_n_rep = as.integer(planned_n_rep),
    planned_mcse = sqrt(level * (1 - level) / planned_n_rep),
    failed_fit_policy = "all_replicates_in_denominator",
    interval_policy = "unavailable_intervals_remain_in_denominator",
    claim_boundary = "no_coverage_claim_until_calibrated_grid_passes",
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_ademp_accounting_template <- function() {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    dimension = character(),
    structured_type = character(),
    fit_status = character(),
    interval_status = character(),
    covered = logical(),
    estimate = double(),
    truth = double(),
    elapsed = double(),
    artifact_grain = character(),
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_ademp_mock_replicates <- function(
  registry,
  fit_status = "not_run",
  interval_status = "not_evaluated"
) {
  if (!is.list(registry) || !all(c("cells", "seeds") %in% names(registry))) {
    stop("`registry` must contain `cells` and `seeds`.", call. = FALSE)
  }
  cells <- registry$cells
  seeds <- registry$seeds
  if (!is.data.frame(cells) || nrow(cells) == 0L) {
    stop("`registry$cells` must be a non-empty data frame.", call. = FALSE)
  }
  if (!is.data.frame(seeds) || nrow(seeds) == 0L) {
    stop("`registry$seeds` must be a non-empty data frame.", call. = FALSE)
  }
  missing_cells <- setdiff(
    c("cell_id", "dimension", "structured_type"),
    names(cells)
  )
  if (length(missing_cells) > 0L) {
    stop(
      "`registry$cells` is missing ",
      paste(missing_cells, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  missing_seeds <- setdiff(c("cell_id", "replicate"), names(seeds))
  if (length(missing_seeds) > 0L) {
    stop(
      "`registry$seeds` is missing ",
      paste(missing_seeds, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  phase18_structured_re_ademp_validate_statuses(
    fit_status,
    c("ok", "error", "nonconverged", "boundary", "not_run"),
    "fit_status"
  )
  phase18_structured_re_ademp_validate_statuses(
    interval_status,
    c("finite", "unavailable", "nonfinite", "not_evaluated", "not_applicable"),
    "interval_status"
  )

  cell_index <- match(seeds$cell_id, cells$cell_id)
  if (anyNA(cell_index)) {
    stop("`registry$seeds$cell_id` must match `registry$cells$cell_id`.")
  }
  n <- nrow(seeds)
  data.frame(
    cell_id = seeds$cell_id,
    replicate = seeds$replicate,
    dimension = cells$dimension[cell_index],
    structured_type = cells$structured_type[cell_index],
    fit_status = rep(fit_status, length.out = n),
    interval_status = rep(interval_status, length.out = n),
    covered = rep(NA, n),
    estimate = rep(NA_real_, n),
    truth = rep(NA_real_, n),
    elapsed = rep(NA_real_, n),
    artifact_grain = "replicate",
    stringsAsFactors = FALSE
  )
}

phase18_structured_re_ademp_pilot_summary <- function(
  registry,
  replicates = NULL,
  by = c("cell_id", "dimension")
) {
  if (is.null(replicates)) {
    replicates <- phase18_structured_re_ademp_mock_replicates(registry)
  }
  denominators <- phase18_structured_re_ademp_denominators(
    replicates = replicates,
    by = by
  )

  list(
    replicates = replicates,
    denominators = denominators,
    claim_boundary = "pilot adapter only; no coverage claim"
  )
}

phase18_structured_re_ademp_calibration_gate <- function(
  replicates,
  policy = phase18_structured_re_ademp_mcse_policy(),
  by = c("cell_id", "dimension")
) {
  if (!is.data.frame(policy) || nrow(policy) != 1L) {
    stop("`policy` must be a one-row data frame.", call. = FALSE)
  }
  missing_policy <- setdiff(
    c("target_mcse", "planned_n_rep"),
    names(policy)
  )
  if (length(missing_policy) > 0L) {
    stop(
      "`policy` is missing ",
      paste(missing_policy, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  phase18_structured_re_ademp_assert_positive_number(
    policy$target_mcse,
    "policy$target_mcse"
  )
  assert_positive_whole_number(policy$planned_n_rep, "policy$planned_n_rep")

  denominators <- phase18_structured_re_ademp_denominators(
    replicates = replicates,
    by = by
  )
  groups <- split(
    seq_len(nrow(replicates)),
    interaction(replicates[by], drop = TRUE, lex.order = TRUE)
  )
  status_rows <- lapply(groups, function(i) {
    x <- replicates[i, , drop = FALSE]
    n_not_run <- sum(x$fit_status == "not_run")
    n_not_evaluated <- sum(x$interval_status == "not_evaluated")
    data.frame(
      x[1L, by, drop = FALSE],
      n_fit_not_run = n_not_run,
      n_interval_not_evaluated = n_not_evaluated,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  status_rows <- do.call(rbind, status_rows)
  row.names(status_rows) <- NULL
  gate <- merge(
    denominators,
    status_rows,
    by = by,
    all.x = TRUE,
    sort = FALSE
  )

  target_mcse <- policy$target_mcse[[1L]]
  planned_n_rep <- policy$planned_n_rep[[1L]]
  gate$planned_n_rep <- planned_n_rep
  gate$target_mcse <- target_mcse
  gate$replicate_count_met <- gate$n_total >= planned_n_rep
  gate$interval_evaluation_complete <- gate$n_interval_not_evaluated == 0L
  gate$mcse_met <- !is.na(gate$coverage_mcse) &
    gate$coverage_mcse <= target_mcse

  reasons <- Map(
    function(n_total, n_not_run, n_not_evaluated, coverage_mcse, n_finite) {
      out <- character()
      if (n_total < planned_n_rep) {
        out <- c(out, "planned_n_rep_not_met")
      }
      if (n_not_run > 0L) {
        out <- c(out, "fit_rows_not_run")
      }
      if (n_not_evaluated > 0L) {
        out <- c(out, "interval_rows_not_evaluated")
      }
      if (n_finite == 0L) {
        out <- c(out, "no_finite_intervals")
      }
      if (is.na(coverage_mcse) || coverage_mcse > target_mcse) {
        out <- c(out, "coverage_mcse_unavailable_or_above_target")
      }
      if (length(out) == 0L) {
        "none"
      } else {
        paste(out, collapse = ";")
      }
    },
    gate$n_total,
    gate$n_fit_not_run,
    gate$n_interval_not_evaluated,
    gate$coverage_mcse,
    gate$n_interval_finite
  )
  gate$blocked_reasons <- unlist(reasons, use.names = FALSE)
  gate$gate_status <- ifelse(
    gate$blocked_reasons == "none",
    "eligible_for_review",
    "blocked"
  )
  gate$claim_boundary <- "calibration gate only; no coverage claim"
  gate
}

phase18_structured_re_ademp_denominators <- function(
  replicates,
  by = c("cell_id", "dimension")
) {
  if (!is.data.frame(replicates) || nrow(replicates) == 0L) {
    stop("`replicates` must be a non-empty data frame.", call. = FALSE)
  }
  missing <- setdiff(
    c("cell_id", "replicate", "fit_status", "interval_status"),
    names(replicates)
  )
  if (length(missing) > 0L) {
    stop(
      "`replicates` is missing ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  missing_by <- setdiff(by, names(replicates))
  if (length(missing_by) > 0L) {
    stop("`by` contains unknown columns: ", paste(missing_by, collapse = ", "))
  }
  phase18_structured_re_ademp_validate_statuses(
    replicates$fit_status,
    c("ok", "error", "nonconverged", "boundary", "not_run"),
    "fit_status"
  )
  phase18_structured_re_ademp_validate_statuses(
    replicates$interval_status,
    c("finite", "unavailable", "nonfinite", "not_evaluated", "not_applicable"),
    "interval_status"
  )
  if (!"covered" %in% names(replicates)) {
    replicates$covered <- NA
  }
  if (!is.logical(replicates$covered)) {
    stop("`covered` must be logical when present.", call. = FALSE)
  }

  groups <- split(
    seq_len(nrow(replicates)),
    interaction(replicates[by], drop = TRUE, lex.order = TRUE)
  )
  rows <- lapply(groups, function(i) {
    x <- replicates[i, , drop = FALSE]
    n_total <- nrow(x)
    coverage_numerator <- if (all(is.na(x$covered))) {
      NA_integer_
    } else {
      sum(!is.na(x$covered) & x$covered)
    }
    coverage_rate <- if (is.na(coverage_numerator)) {
      NA_real_
    } else {
      coverage_numerator / n_total
    }
    coverage_mcse <- if (is.na(coverage_rate)) {
      NA_real_
    } else {
      sqrt(coverage_rate * (1 - coverage_rate) / n_total)
    }

    data.frame(
      x[1L, by, drop = FALSE],
      n_total = n_total,
      n_fit_ok = sum(x$fit_status == "ok"),
      n_failed_fit = sum(x$fit_status != "ok"),
      n_interval_finite = sum(x$interval_status == "finite"),
      n_interval_unavailable = sum(x$interval_status != "finite"),
      coverage_denominator = n_total,
      coverage_numerator = coverage_numerator,
      coverage_rate = coverage_rate,
      coverage_mcse = coverage_mcse,
      failed_fit_policy = "all_replicates_in_denominator",
      interval_policy = "unavailable_intervals_remain_in_denominator",
      artifact_grain = "aggregate",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_structured_re_q4_interval_diagnostic_plan <- function(
  level = 0.95,
  target_mcse = 0.01,
  planned_n_rep = NULL
) {
  policy <- phase18_structured_re_ademp_mcse_policy(
    level = level,
    target_mcse = target_mcse,
    planned_n_rep = planned_n_rep
  )
  planned_n_rep <- policy$planned_n_rep[[1L]]
  mcse_label <- paste0("coverage_mcse<=", format(policy$target_mcse[[1L]]))
  denominator_fields <- paste(
    c(
      "coverage_denominator",
      "n_total",
      "n_fit_ok",
      "n_failed_fit",
      "n_interval_finite",
      "n_interval_unavailable",
      "coverage_mcse"
    ),
    collapse = ";"
  )

  direct_axes <- c("mu1", "mu2", "sigma1", "sigma2")
  direct_rows <- data.frame(
    diagnostic_id = paste0("q4_interval_diagnostic_sd_", direct_axes),
    slice_id = "SR150",
    target = "gaussian_q4_phylo",
    target_kind = "direct_sd",
    axis_pair = direct_axes,
    direct_sd_target = paste0("sd_", direct_axes),
    derived_correlation_target = "not_applicable",
    interval_methods = "wald;profile;bootstrap",
    required_fit_evidence = paste0(
      "converged_pdhess_true_replicates>=",
      planned_n_rep
    ),
    required_interval_evidence = paste0(
      "finite_direct_sd_intervals_by_method;",
      mcse_label
    ),
    denominator_fields = denominator_fields,
    current_blocker = "pilot_has_zero_converged_q4_rows_and_zero_finite_intervals",
    status = "planned",
    evidence_url = "docs/dev-log/after-task/2026-06-23-q4-interval-diagnostic-plan.md",
    claim_boundary = paste(
      "Q4 interval diagnostic plan only;",
      "no q4 interval reliability, interval coverage, q4 REML,",
      "AI-REML, or broad bridge support is promoted."
    ),
    next_gate = "Run deterministic q4 interval diagnostics before calibrated coverage wording.",
    stringsAsFactors = FALSE
  )

  pairs <- c(
    "mu1_mu2",
    "mu1_sigma1",
    "mu1_sigma2",
    "mu2_sigma1",
    "mu2_sigma2",
    "sigma1_sigma2"
  )
  derived_rows <- data.frame(
    diagnostic_id = paste0("q4_interval_diagnostic_cor_", pairs),
    slice_id = "SR150",
    target = "gaussian_q4_phylo",
    target_kind = "derived_correlation",
    axis_pair = pairs,
    direct_sd_target = "not_direct",
    derived_correlation_target = paste0("cor_", pairs),
    interval_methods = "wald;profile;bootstrap",
    required_fit_evidence = paste0(
      "corpairs_point_reconstruction_and_converged_replicates>=",
      planned_n_rep
    ),
    required_interval_evidence = paste0(
      "finite_derived_correlation_intervals_by_method;",
      mcse_label
    ),
    denominator_fields = denominator_fields,
    current_blocker = "derived_correlation_interval_reconstruction_not_available",
    status = "planned",
    evidence_url = "docs/dev-log/after-task/2026-06-23-q4-interval-diagnostic-plan.md",
    claim_boundary = paste(
      "Q4 derived-correlation interval diagnostic plan only;",
      "no q4 interval reliability, interval coverage, q4 REML,",
      "AI-REML, or broad bridge support is promoted."
    ),
    next_gate = "Bank q4 corpairs reconstruction and finite interval diagnostics before calibrated coverage wording.",
    stringsAsFactors = FALSE
  )

  out <- rbind(direct_rows, derived_rows)
  row.names(out) <- NULL
  out
}

phase18_structured_re_q4_interval_diagnostic_status <- function(
  pilot_rows,
  source_artifact = "docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/tables/structured-coverage-pilot-rows.csv"
) {
  if (!is.data.frame(pilot_rows)) {
    stop("`pilot_rows` must be a data frame.", call. = FALSE)
  }
  missing <- setdiff(
    c(
      "cell",
      "target",
      "fit_ok",
      "converged",
      "pdHess",
      "lower",
      "upper",
      "conf_status"
    ),
    names(pilot_rows)
  )
  if (length(missing) > 0L) {
    stop(
      "`pilot_rows` is missing ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (
    !is.character(source_artifact) ||
      length(source_artifact) != 1L ||
      !nzchar(source_artifact)
  ) {
    stop("`source_artifact` must be one non-empty string.", call. = FALSE)
  }

  plan <- phase18_structured_re_q4_interval_diagnostic_plan()
  direct_rows <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
  derived_rows <- plan[
    plan$target_kind == "derived_correlation",
    ,
    drop = FALSE
  ]
  direct_status <- lapply(seq_len(nrow(direct_rows)), function(i) {
    row <- direct_rows[i, , drop = FALSE]
    target_label <- paste0(
      "sd:mu:",
      row$axis_pair[[1L]],
      ":phylo(1 | p | species)"
    )
    observed <- pilot_rows[
      pilot_rows$cell == "q4_phylo_all_four" &
        pilot_rows$target == target_label,
      ,
      drop = FALSE
    ]
    finite <- is.finite(observed$lower) & is.finite(observed$upper)
    conf_status <- unique(stats::na.omit(as.character(observed$conf_status)))
    interval_status <- if (any(finite)) {
      "finite_wald_observed"
    } else if (length(conf_status) > 0L) {
      paste(conf_status, collapse = ";")
    } else {
      "not_evaluated"
    }
    failure_class <- if (nrow(observed) == 0L) {
      "no_q4_pilot_target_rows"
    } else if (any(finite)) {
      "finite_interval_observed_diagnostic_only"
    } else {
      "nonconverged_or_pdhess_false;no_finite_wald_intervals"
    }
    data.frame(
      diagnostic_id = paste0("q4_interval_status_sd_", row$axis_pair),
      slice_id = "SR150",
      target = "gaussian_q4_phylo",
      target_kind = row$target_kind,
      axis_pair = row$axis_pair,
      direct_sd_target = row$direct_sd_target,
      derived_correlation_target = row$derived_correlation_target,
      source_artifact = source_artifact,
      observed_target_rows = nrow(observed),
      n_fit_ok = sum(as.logical(observed$fit_ok), na.rm = TRUE),
      n_converged = sum(as.logical(observed$converged), na.rm = TRUE),
      n_pdhess = sum(as.logical(observed$pdHess), na.rm = TRUE),
      n_finite_intervals = sum(finite),
      interval_status = interval_status,
      failure_class = failure_class,
      interval_claim_status = "blocked",
      status = "covered",
      evidence_url = "docs/dev-log/after-task/2026-06-23-q4-interval-diagnostic-status.md",
      claim_boundary = paste(
        "Q4 interval diagnostic status only;",
        "no q4 interval reliability, interval coverage, q4 REML,",
        "AI-REML, or broad bridge support is promoted."
      ),
      next_gate = "Diagnose q4 convergence and pdHess failures before rerunning finite interval diagnostics.",
      stringsAsFactors = FALSE
    )
  })
  derived_status <- lapply(seq_len(nrow(derived_rows)), function(i) {
    row <- derived_rows[i, , drop = FALSE]
    data.frame(
      diagnostic_id = paste0("q4_interval_status_cor_", row$axis_pair),
      slice_id = "SR150",
      target = "gaussian_q4_phylo",
      target_kind = row$target_kind,
      axis_pair = row$axis_pair,
      direct_sd_target = row$direct_sd_target,
      derived_correlation_target = row$derived_correlation_target,
      source_artifact = source_artifact,
      observed_target_rows = 0L,
      n_fit_ok = 0L,
      n_converged = 0L,
      n_pdhess = 0L,
      n_finite_intervals = 0L,
      interval_status = "derived_interval_not_reconstructed",
      failure_class = "derived_correlation_interval_reconstruction_not_available",
      interval_claim_status = "blocked",
      status = "covered",
      evidence_url = "docs/dev-log/after-task/2026-06-23-q4-interval-diagnostic-status.md",
      claim_boundary = paste(
        "Q4 derived-correlation interval diagnostic status only;",
        "no q4 interval reliability, interval coverage, q4 REML,",
        "AI-REML, or broad bridge support is promoted."
      ),
      next_gate = "Implement derived-correlation interval reconstruction before calibrated coverage wording.",
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, c(direct_status, derived_status))
  row.names(out) <- NULL
  out
}

phase18_structured_re_ademp_match_choices <- function(x, choices, name) {
  if (!is.character(x) || length(x) == 0L || any(!nzchar(x))) {
    stop("`", name, "` must be a non-empty character vector.", call. = FALSE)
  }
  bad <- setdiff(x, choices)
  if (length(bad) > 0L) {
    stop(
      "`",
      name,
      "` contains unsupported values: ",
      paste(bad, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  unique(x)
}

phase18_structured_re_ademp_validate_statuses <- function(
  values,
  choices,
  name
) {
  values <- as.character(values)
  bad <- setdiff(unique(values), choices)
  if (length(bad) > 0L) {
    stop(
      "`",
      name,
      "` contains unsupported values: ",
      paste(bad, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  invisible(values)
}

phase18_structured_re_ademp_assert_probability <- function(x, name) {
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

phase18_structured_re_ademp_assert_positive_number <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x > 0
  if (!ok) {
    stop("`", name, "` must be one positive finite number.", call. = FALSE)
  }
  invisible(x)
}
