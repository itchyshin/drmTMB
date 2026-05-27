phase18_write_bounded_response_mu_ri_grid_outputs <- function(
  output_dir,
  conditions = phase18_bounded_response_mu_ri_conditions(
    family = c("beta", "beta_binomial"),
    n_group = c(32L, 48L),
    n_per_group = 8L,
    trial_min = c(14L, 24L),
    trial_max = c(24L, 36L),
    beta_sigma_intercept = c(-0.95, -0.70),
    beta_sigma_z = c(0, 0.18),
    sd_intercept = c(0.35, 0.55),
    rho_xz = c(0, 0.40)
  ),
  n_rep = 5L,
  master_seed = 20260538L,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  result_dir <- file.path(output_dir, "results")
  table_dir <- file.path(output_dir, "tables")
  dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

  paths <- list(
    aggregate_csv = file.path(
      table_dir,
      "bounded-response-mu-ri-aggregate.csv"
    ),
    replicate_csv = file.path(
      table_dir,
      "bounded-response-mu-ri-replicates.csv"
    ),
    manifest_csv = file.path(table_dir, "bounded-response-mu-ri-manifest.csv"),
    failures_csv = file.path(table_dir, "bounded-response-mu-ri-failures.csv"),
    wald_intervals_csv = file.path(
      table_dir,
      "bounded-response-mu-ri-wald-intervals.csv"
    ),
    wald_coverage_csv = file.path(
      table_dir,
      "bounded-response-mu-ri-wald-coverage.csv"
    ),
    profile_intervals_csv = file.path(
      table_dir,
      "bounded-response-mu-ri-profile-intervals.csv"
    ),
    profile_coverage_csv = file.path(
      table_dir,
      "bounded-response-mu-ri-profile-coverage.csv"
    )
  )
  phase18_assert_bounded_response_mu_ri_grid_overwrite(paths, overwrite)

  summary <- phase18_summarise_bounded_response_mu_ri_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  utils::write.csv(summary$aggregate, paths$aggregate_csv, row.names = FALSE)
  utils::write.csv(summary$replicates, paths$replicate_csv, row.names = FALSE)
  utils::write.csv(summary$manifest, paths$manifest_csv, row.names = FALSE)
  utils::write.csv(summary$failures, paths$failures_csv, row.names = FALSE)
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
    summary$profile_intervals,
    paths$profile_intervals_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$profile_coverage,
    paths$profile_coverage_csv,
    row.names = FALSE
  )

  list(
    surface = "bounded_response_mu_random_intercept_grid",
    output_dir = output_dir,
    result_dir = result_dir,
    table_dir = table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "bounded_response_mu_random_intercept_grid",
      paths
    ),
    summary = summary
  )
}

phase18_assert_bounded_response_mu_ri_grid_overwrite <- function(
  paths,
  overwrite
) {
  path_values <- unlist(paths, use.names = FALSE)
  existing <- path_values[file.exists(path_values)]
  if (!overwrite && length(existing) > 0L) {
    stop(
      "Bounded-response mu random-intercept grid output already exists: ",
      paste(existing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
