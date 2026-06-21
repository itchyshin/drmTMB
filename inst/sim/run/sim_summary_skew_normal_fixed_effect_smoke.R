phase18_summarise_skew_normal_fe_smoke <- function(
  conditions = phase18_skew_normal_fe_conditions(
    skew_regime = c("left", "right"),
    n = 320L,
    rho_xz = 0.20
  ),
  n_rep = 1L,
  master_seed = 20260636L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  cores = 1L,
  backend = "none"
) {
  run <- phase18_run_skew_normal_fe_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  if (nrow(run$summary) == 0L) {
    stop(
      "The skew-normal fixed-effect smoke run produced no summaries.",
      call. = FALSE
    )
  }
  if (is.null(by)) {
    by <- phase18_default_summary_groups(run$summary)
  }
  aggregate <- phase18_aggregate_parameters(run$summary, by = by)
  mcse <- phase18_aggregate_error_mcse(run$summary, by = by)
  aggregate <- merge(
    aggregate,
    mcse,
    by = c(by, "n_replicate"),
    all.x = TRUE,
    sort = FALSE
  )
  manifest <- phase18_result_manifest(run$results)
  failures <- phase18_result_failures(run$results)
  diagnostics <- phase18_summarise_skew_normal_fe_fit_diagnostics(
    run$summary
  )

  list(
    surface = "skew_normal_fixed_effect",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures,
    diagnostics = diagnostics
  )
}

phase18_summarise_skew_normal_fe_false_positive_smoke <- function(
  conditions = phase18_skew_normal_fe_false_positive_conditions(),
  n_rep = 1L,
  master_seed = 20260640L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  nu_abs_threshold = 0.5,
  cores = 1L,
  backend = "none"
) {
  summary <- phase18_summarise_skew_normal_fe_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    by = by,
    cores = cores,
    backend = backend
  )
  summary$surface <- "skew_normal_fixed_effect_false_positive"
  summary$run$surface <- "skew_normal_fixed_effect_false_positive"
  summary$run$summary$surface <- "skew_normal_fixed_effect_false_positive"
  summary$aggregate$surface <- "skew_normal_fixed_effect_false_positive"
  summary$replicates$surface <- "skew_normal_fixed_effect_false_positive"
  summary$diagnostics$surface <- "skew_normal_fixed_effect_false_positive"
  summary$false_positive_summary <-
    phase18_summarise_skew_normal_fe_false_positive(
      summary$replicates,
      nu_abs_threshold = nu_abs_threshold
    )
  summary
}

phase18_summarise_skew_normal_fe_false_positive <- function(
  summary,
  by = intersect(
    c("surface", "skew_regime", "beta_sigma_z", "rho_xz"),
    names(summary)
  ),
  nu_abs_threshold = 0.5
) {
  if (
    !is.numeric(nu_abs_threshold) ||
      length(nu_abs_threshold) != 1L ||
      !is.finite(nu_abs_threshold) ||
      nu_abs_threshold <= 0
  ) {
    stop(
      "`nu_abs_threshold` must be one positive finite number.",
      call. = FALSE
    )
  }
  required <- c(
    "cell_id",
    "replicate",
    "converged",
    "pdHess",
    "warning_count",
    "fitted_nu_max_abs",
    "skew_normal_nu_status"
  )
  phase18_assert_summary_columns(summary, c(required, by))
  if (!is.character(by) || length(by) == 0L || any(!nzchar(by))) {
    stop("`by` must be a non-empty character vector.", call. = FALSE)
  }

  fit_columns <- unique(c(by, required))
  fit_rows <- unique(summary[fit_columns])
  split_key <- interaction(fit_rows[by], drop = TRUE, lex.order = TRUE)
  rows <- lapply(split(fit_rows, split_key), function(x) {
    phase18_skew_normal_fe_false_positive_row(
      x,
      by,
      nu_abs_threshold = nu_abs_threshold
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_skew_normal_fe_false_positive_row <- function(
  x,
  by,
  nu_abs_threshold
) {
  data.frame(
    x[1L, by, drop = FALSE],
    n_fit = nrow(x),
    nu_abs_threshold = nu_abs_threshold,
    convergence_rate = phase18_skew_normal_fe_rate(x$converged),
    pdHess_rate = phase18_skew_normal_fe_rate(x$pdHess),
    warning_rate = phase18_skew_normal_fe_rate(x$warning_count > 0),
    skew_normal_nu_note_rate = phase18_skew_normal_fe_rate(
      x$skew_normal_nu_status == "note"
    ),
    nu_false_positive_rate = phase18_skew_normal_fe_rate(
      x$fitted_nu_max_abs > nu_abs_threshold
    ),
    mean_fitted_nu_abs = phase18_skew_normal_fe_mean_finite(
      x$fitted_nu_max_abs
    ),
    max_fitted_nu_abs = phase18_skew_normal_fe_max_finite(
      x$fitted_nu_max_abs
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

phase18_summarise_skew_normal_fe_fit_diagnostics <- function(
  summary,
  by = intersect(
    c("surface", "skew_regime"),
    names(summary)
  )
) {
  required <- c(
    "cell_id",
    "replicate",
    "converged",
    "pdHess",
    "warning_count",
    "fitted_nu_max_abs",
    "skew_normal_nu_status"
  )
  phase18_assert_summary_columns(summary, c(required, by))
  if (!is.character(by) || length(by) == 0L || any(!nzchar(by))) {
    stop("`by` must be a non-empty character vector.", call. = FALSE)
  }

  fit_columns <- unique(c(by, required))
  fit_rows <- unique(summary[fit_columns])
  split_key <- interaction(fit_rows[by], drop = TRUE, lex.order = TRUE)
  rows <- lapply(split(fit_rows, split_key), function(x) {
    phase18_skew_normal_fe_fit_diagnostic_row(x, by)
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_skew_normal_fe_fit_diagnostic_row <- function(x, by) {
  data.frame(
    x[1L, by, drop = FALSE],
    n_fit = nrow(x),
    convergence_rate = phase18_skew_normal_fe_rate(x$converged),
    pdHess_rate = phase18_skew_normal_fe_rate(x$pdHess),
    warning_rate = phase18_skew_normal_fe_rate(x$warning_count > 0),
    skew_normal_nu_ok_rate = phase18_skew_normal_fe_rate(
      x$skew_normal_nu_status == "ok"
    ),
    skew_normal_nu_note_rate = phase18_skew_normal_fe_rate(
      x$skew_normal_nu_status == "note"
    ),
    max_fitted_nu_abs = phase18_skew_normal_fe_max_finite(
      x$fitted_nu_max_abs
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

phase18_skew_normal_fe_rate <- function(x) {
  x <- as.logical(x)
  if (length(x) == 0L || all(is.na(x))) {
    return(NA_real_)
  }
  mean(x, na.rm = TRUE)
}

phase18_skew_normal_fe_mean_finite <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  mean(x)
}
