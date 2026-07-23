phase18_dgp_meta_v_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_study",
    "known_v_type",
    "beta_mu_intercept",
    "beta_mu_x",
    "sigma",
    "sampling_sd",
    "sampling_rho"
  )
  missing <- setdiff(required, names(cell))
  if (length(missing) > 0L) {
    stop(
      "`cell` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  phase18_dgp_meta_v(
    n_study = cell$n_study[[1L]],
    known_v_type = cell$known_v_type[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    sigma = cell$sigma[[1L]],
    sampling_sd = cell$sampling_sd[[1L]],
    sampling_rho = cell$sampling_rho[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_meta_v <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  V <- attr(data, "V", exact = TRUE)
  if (is.null(V)) {
    stop("`data` must carry a known sampling covariance `V`.", call. = FALSE)
  }
  drmTMB(
    bf(yi ~ x + meta_V(V = V), sigma ~ 1),
    family = gaussian(),
    data = data
  )
}

phase18_run_meta_v_smoke <- function(
  conditions = phase18_meta_v_conditions(
    n_study = 36L,
    known_v_type = c("vector", "dense"),
    sigma = 0.25,
    sampling_sd = 0.14,
    sampling_rho = c(0, 0.20)
  ),
  n_rep = 1L,
  master_seed = 20260518L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "meta_v",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_meta_v_cell,
    fit_fun = phase18_fit_meta_v,
    summarise_fun = phase18_summarise_meta_v_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  successful_summary <- phase18_result_summaries(results)
  summary <- phase18_meta_v_all_attempt_summary(
    results = results,
    cells = registry$cells,
    successful_summary = successful_summary
  )

  list(
    surface = "meta_v",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    successful_summary = successful_summary,
    summary = summary
  )
}

phase18_meta_v_all_attempt_summary <- function(
  results,
  cells,
  successful_summary = phase18_result_summaries(results)
) {
  if (!is.list(results) || length(results) == 0L) {
    stop("`results` must be a non-empty list of replicate results.", call. = FALSE)
  }
  if (!is.data.frame(cells) || nrow(cells) == 0L) {
    stop("`cells` must be a non-empty data frame.", call. = FALSE)
  }
  required_cell <- c(
    "cell_id", "surface", "known_v_type", "beta_mu_intercept",
    "beta_mu_x", "sigma", "n_study", "sampling_sd", "sampling_rho"
  )
  missing_cell <- setdiff(required_cell, names(cells))
  if (length(missing_cell) > 0L) {
    stop(
      "`cells` must contain ",
      paste(missing_cell, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  rows <- lapply(results, function(result) {
    cell <- cells[cells$cell_id == result$cell_id, , drop = FALSE]
    if (nrow(cell) != 1L) {
      stop(
        "Every result must match exactly one meta_V cell.",
        call. = FALSE
      )
    }
    phase18_meta_v_empty_attempt_rows(result, cell)
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL

  if (!is.data.frame(successful_summary) || nrow(successful_summary) == 0L) {
    return(out)
  }
  required_summary <- c("cell_id", "replicate", "parameter")
  missing_summary <- setdiff(required_summary, names(successful_summary))
  if (length(missing_summary) > 0L) {
    stop(
      "`successful_summary` must contain ",
      paste(missing_summary, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  key <- paste(out$cell_id, out$replicate, out$parameter, sep = "\r")
  summary_key <- paste(
    successful_summary$cell_id,
    successful_summary$replicate,
    successful_summary$parameter,
    sep = "\r"
  )
  matched <- match(key, summary_key)
  replace <- which(!is.na(matched))
  columns <- intersect(names(successful_summary), names(out))
  columns <- setdiff(columns, c("cell_id", "replicate", "parameter", "seed"))
  for (column in columns) {
    out[[column]][replace] <- successful_summary[[column]][matched[replace]]
  }
  out
}

phase18_meta_v_empty_attempt_rows <- function(result, cell) {
  required_result <- c(
    "cell_id", "replicate", "seed", "status", "warnings", "elapsed"
  )
  missing_result <- setdiff(required_result, names(result))
  if (length(missing_result) > 0L) {
    stop(
      "Each result must contain ",
      paste(missing_result, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  parameter <- c("mu:(Intercept)", "mu:x", "sigma")
  truth <- c(
    cell$beta_mu_intercept[[1L]],
    cell$beta_mu_x[[1L]],
    cell$sigma[[1L]]
  )
  error <- if (is.null(result$error)) NA_character_ else result$error
  known_v_diagnostics <- if (exists("phase18_make_meta_v", mode = "function")) {
    V <- phase18_make_meta_v(
      cell$n_study[[1L]], cell$known_v_type[[1L]], cell$sampling_sd[[1L]],
      cell$sampling_rho[[1L]]
    )
    c(
      rank = if (is.matrix(V)) qr(V)$rank else length(V),
      condition = if (is.matrix(V)) kappa(V, exact = TRUE) else max(V) / min(V)
    )
  } else {
    c(rank = NA_real_, condition = NA_real_)
  }
  data.frame(
    surface = rep(cell$surface[[1L]], length(parameter)),
    known_v_type = rep(cell$known_v_type[[1L]], length(parameter)),
    n_study = rep(cell$n_study[[1L]], length(parameter)),
    sampling_sd = rep(cell$sampling_sd[[1L]], length(parameter)),
    sampling_rho = rep(cell$sampling_rho[[1L]], length(parameter)),
    known_v_rank = rep(known_v_diagnostics[["rank"]], length(parameter)),
    known_v_condition = rep(known_v_diagnostics[["condition"]], length(parameter)),
    cell_id = rep(result$cell_id, length(parameter)),
    replicate = rep(result$replicate, length(parameter)),
    seed = rep(result$seed, length(parameter)),
    parameter = parameter,
    truth = truth,
    estimate = NA_real_,
    std.error = NA_real_,
    error = NA_real_,
    converged = FALSE,
    pdHess = FALSE,
    nobs = NA_real_,
    elapsed = rep(result$elapsed, length(parameter)),
    warning_count = rep(length(result$warnings), length(parameter)),
    warnings = rep(paste(result$warnings, collapse = " | "), length(parameter)),
    conf.low = NA_real_,
    conf.high = NA_real_,
    interval_method = NA_character_,
    interval_status = "failed",
    conf.status = NA_character_,
    interval_message = "fit did not produce an interval",
    result_status = rep(result$status, length(parameter)),
    result_error = rep(error, length(parameter)),
    artifact_grain = "replicate",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}
