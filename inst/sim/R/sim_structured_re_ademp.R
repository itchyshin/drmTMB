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
