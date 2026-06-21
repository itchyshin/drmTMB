phase18_summarise_biv_gaussian_q8_endpoint_smoke <- function(
  conditions = phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 48L,
    n_each = 10L
  ),
  n_rep = 1L,
  master_seed = 20260634L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  cores = 1L,
  backend = "none"
) {
  run <- phase18_run_biv_gaussian_q8_endpoint_smoke(
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
      "The bivariate Gaussian q8 endpoint smoke run produced no summaries.",
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

  list(
    surface = "biv_gaussian_q8_endpoint",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures
  )
}

phase18_summarise_biv_gaussian_q8_endpoint_diagnostic_presets <- function(
  conditions = phase18_biv_gaussian_q8_endpoint_diagnostic_conditions("all"),
  n_rep = 1L,
  master_seed = 20260635L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  cores = 1L,
  backend = "none"
) {
  if (is.null(by)) {
    by <- phase18_biv_gaussian_q8_endpoint_diagnostic_groups(conditions)
  }
  summary <- phase18_summarise_biv_gaussian_q8_endpoint_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    by = by,
    cores = cores,
    backend = backend
  )
  summary$surface <- "biv_gaussian_q8_endpoint_diagnostic"
  summary$run$surface <- "biv_gaussian_q8_endpoint_diagnostic"
  summary$run$summary$surface <- "biv_gaussian_q8_endpoint_diagnostic"
  summary$aggregate$surface <- "biv_gaussian_q8_endpoint_diagnostic"
  summary$replicates$surface <- "biv_gaussian_q8_endpoint_diagnostic"
  summary$diagnostic_summary <-
    phase18_summarise_biv_gaussian_q8_endpoint_fit_diagnostics(
      summary$replicates
    )
  summary
}

phase18_biv_gaussian_q8_endpoint_diagnostic_groups <- function(
  conditions_or_summary
) {
  if (
    !is.data.frame(conditions_or_summary) ||
      nrow(conditions_or_summary) == 0L
  ) {
    stop(
      "`conditions_or_summary` must be a non-empty data frame.",
      call. = FALSE
    )
  }
  required <- c("diagnostic_preset", "diagnostic_level")
  missing <- setdiff(required, names(conditions_or_summary))
  if (length(missing) > 0L) {
    stop(
      "`conditions_or_summary` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  unique(c("surface", required, "parameter"))
}

phase18_summarise_biv_gaussian_q8_endpoint_fit_diagnostics <- function(
  summary,
  by = intersect(
    c("surface", "diagnostic_preset", "diagnostic_level"),
    names(summary)
  )
) {
  required <- c(
    "cell_id",
    "replicate",
    "converged",
    "pdHess",
    "warning_count",
    "optimizer_code",
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
  )
  phase18_assert_summary_columns(summary, c(required, by))
  if (!is.character(by) || length(by) == 0L || any(!nzchar(by))) {
    stop("`by` must be a non-empty character vector.", call. = FALSE)
  }

  fit_columns <- unique(c(by, required))
  fit_rows <- unique(summary[fit_columns])
  split_key <- interaction(fit_rows[by], drop = TRUE, lex.order = TRUE)
  rows <- lapply(split(fit_rows, split_key), function(x) {
    phase18_biv_gaussian_q8_endpoint_fit_diagnostic_row(x, by)
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phase18_biv_gaussian_q8_endpoint_fit_diagnostic_row <- function(x, by) {
  data.frame(
    x[1L, by, drop = FALSE],
    n_fit = nrow(x),
    convergence_rate = phase18_biv_gaussian_q8_endpoint_rate(x$converged),
    pdHess_rate = phase18_biv_gaussian_q8_endpoint_rate(x$pdHess),
    warning_rate = phase18_biv_gaussian_q8_endpoint_rate(x$warning_count > 0),
    optimizer_ok_rate = phase18_biv_gaussian_q8_endpoint_rate(
      x$optimizer_code == 0
    ),
    qgt2_rate = phase18_biv_gaussian_q8_endpoint_rate(x$qgt2_blocks > 0),
    mean_max_gradient = phase18_biv_gaussian_q8_endpoint_mean_finite(
      x$max_gradient
    ),
    min_sd_mu = phase18_biv_gaussian_q8_endpoint_min_finite(x$min_sd_mu),
    min_sd_sigma = phase18_biv_gaussian_q8_endpoint_min_finite(x$min_sd_sigma),
    max_abs_cor = phase18_biv_gaussian_q8_endpoint_max_finite(x$max_abs_cor),
    min_cor_eigen = phase18_biv_gaussian_q8_endpoint_min_finite(
      x$min_cor_eigen
    ),
    max_cor_condition = phase18_biv_gaussian_q8_endpoint_max_finite(
      x$max_cor_condition
    ),
    sd_boundary_rate = phase18_biv_gaussian_q8_endpoint_rate(
      x$min_sd_mu < 0.02 | x$min_sd_sigma < 0.02
    ),
    high_correlation_rate = phase18_biv_gaussian_q8_endpoint_rate(
      x$max_abs_cor > 0.95
    ),
    ill_conditioned_rate = phase18_biv_gaussian_q8_endpoint_rate(
      x$min_cor_eigen < 1e-6 | x$max_cor_condition > 1e6
    ),
    max_q = phase18_biv_gaussian_q8_endpoint_max_finite(x$max_q),
    max_pairs = phase18_biv_gaussian_q8_endpoint_max_finite(x$max_pairs),
    min_group_n = phase18_biv_gaussian_q8_endpoint_min_finite(x$min_group_n),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

phase18_biv_gaussian_q8_endpoint_rate <- function(x) {
  x <- as.logical(x)
  if (length(x) == 0L || all(is.na(x))) {
    return(NA_real_)
  }
  mean(x, na.rm = TRUE)
}

phase18_biv_gaussian_q8_endpoint_mean_finite <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  mean(x)
}
