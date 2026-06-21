phase18_write_skew_normal_fe_grid_outputs <- function(
  output_dir,
  conditions = phase18_skew_normal_fe_conditions(
    skew_regime = c("left", "symmetric", "right"),
    n = c(320L, 520L),
    rho_xz = c(0, 0.35)
  ),
  n_rep = 5L,
  master_seed = 20260636L,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- phase18_simple_grid_paths(
    dirs$table_dir,
    prefix = "skew-normal-fe"
  )
  paths$diagnostics_csv <- file.path(
    dirs$table_dir,
    "skew-normal-fe-diagnostics.csv"
  )
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Skew-normal fixed-effect grid"
  )

  summary <- phase18_summarise_skew_normal_fe_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = dirs$result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  phase18_write_simple_grid_tables(summary, paths)
  utils::write.csv(
    summary$diagnostics,
    paths$diagnostics_csv,
    row.names = FALSE
  )

  list(
    surface = "skew_normal_fixed_effect_grid",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "skew_normal_fixed_effect_grid",
      paths
    ),
    summary = summary
  )
}

phase18_write_skew_normal_fe_false_positive_grid_outputs <- function(
  output_dir,
  conditions = phase18_skew_normal_fe_false_positive_conditions(),
  n_rep = 5L,
  master_seed = 20260640L,
  overwrite = FALSE,
  nu_abs_threshold = 0.5,
  cores = 1L,
  backend = "none"
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- phase18_simple_grid_paths(
    dirs$table_dir,
    prefix = "skew-normal-fe-false-positive"
  )
  paths$diagnostics_csv <- file.path(
    dirs$table_dir,
    "skew-normal-fe-false-positive-diagnostics.csv"
  )
  paths$false_positive_summary_csv <- file.path(
    dirs$table_dir,
    "skew-normal-fe-false-positive-summary.csv"
  )
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Skew-normal fixed-effect false-positive grid"
  )

  summary <- phase18_summarise_skew_normal_fe_false_positive_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = dirs$result_dir,
    overwrite = overwrite,
    nu_abs_threshold = nu_abs_threshold,
    cores = cores,
    backend = backend
  )
  phase18_write_simple_grid_tables(summary, paths)
  utils::write.csv(
    summary$diagnostics,
    paths$diagnostics_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$false_positive_summary,
    paths$false_positive_summary_csv,
    row.names = FALSE
  )

  list(
    surface = "skew_normal_fixed_effect_false_positive_grid",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "skew_normal_fixed_effect_false_positive_grid",
      paths
    ),
    summary = summary
  )
}
