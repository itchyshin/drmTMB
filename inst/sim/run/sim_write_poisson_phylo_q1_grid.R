phase18_write_poisson_phylo_q1_grid_outputs <- function(
  output_dir,
  conditions = phase18_poisson_phylo_q1_conditions(
    n_species = c(20L, 40L),
    n_per_species = 4L,
    sd_phylo = c(0, 0.25, 0.60),
    mean_count = 2.5,
    tree_shape = "balanced"
  ),
  n_rep = 5L,
  master_seed = 20260524L,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- phase18_poisson_phylo_q1_grid_paths(dirs$table_dir)
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Poisson phylogenetic q1 grid"
  )

  summary <- phase18_summarise_poisson_phylo_q1_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = dirs$result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  phase18_write_poisson_phylo_q1_grid_tables(summary, paths)

  list(
    surface = "poisson_phylo_q1_grid",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "poisson_phylo_q1_grid",
      paths
    ),
    summary = summary
  )
}

phase18_poisson_phylo_q1_grid_paths <- function(table_dir) {
  c(
    phase18_simple_grid_paths(table_dir, prefix = "poisson-phylo-q1"),
    list(
      wald_intervals_csv = file.path(
        table_dir,
        "poisson-phylo-q1-wald-intervals.csv"
      ),
      wald_coverage_csv = file.path(
        table_dir,
        "poisson-phylo-q1-wald-coverage.csv"
      ),
      profile_targets_csv = file.path(
        table_dir,
        "poisson-phylo-q1-profile-targets.csv"
      )
    )
  )
}

phase18_write_poisson_phylo_q1_grid_tables <- function(summary, paths) {
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
  invisible(paths)
}
