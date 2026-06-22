phase18_write_structured_re_ademp_scaffold <- function(
  output_dir,
  conditions = NULL,
  n_rep = 500L,
  master_seed = 20260622L,
  overwrite = FALSE,
  level = 0.95,
  target_mcse = 0.01,
  ...
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- phase18_structured_re_ademp_scaffold_paths(dirs$table_dir)
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Structured RE ADEMP scaffold"
  )
  registry <- phase18_structured_re_ademp_registry(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    ...
  )
  policy <- phase18_structured_re_ademp_mcse_policy(
    level = level,
    target_mcse = target_mcse,
    planned_n_rep = n_rep
  )
  accounting_template <- phase18_structured_re_ademp_accounting_template()
  pilot_summary <- phase18_structured_re_ademp_pilot_summary(registry)

  utils::write.csv(registry$cells, paths$cells_csv, row.names = FALSE)
  utils::write.csv(registry$seeds, paths$seeds_csv, row.names = FALSE)
  utils::write.csv(policy, paths$mcse_policy_csv, row.names = FALSE)
  utils::write.csv(
    accounting_template,
    paths$accounting_template_csv,
    row.names = FALSE
  )
  utils::write.csv(
    pilot_summary$replicates,
    paths$pilot_replicates_csv,
    row.names = FALSE
  )
  utils::write.csv(
    pilot_summary$denominators,
    paths$pilot_denominators_csv,
    row.names = FALSE
  )

  list(
    surface = "structured_re_ademp_scaffold",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    registry = registry,
    mcse_policy = policy,
    accounting_template = accounting_template,
    pilot_replicates = pilot_summary$replicates,
    pilot_denominators = pilot_summary$denominators,
    artifact_manifest = phase18_grid_artifact_manifest(
      "structured_re_ademp_scaffold",
      paths
    )
  )
}

phase18_structured_re_ademp_scaffold_paths <- function(table_dir) {
  list(
    cells_csv = file.path(table_dir, "structured-re-ademp-cells.csv"),
    seeds_csv = file.path(table_dir, "structured-re-ademp-seeds.csv"),
    mcse_policy_csv = file.path(
      table_dir,
      "structured-re-ademp-mcse-policy.csv"
    ),
    accounting_template_csv = file.path(
      table_dir,
      "structured-re-ademp-accounting-template.csv"
    ),
    pilot_replicates_csv = file.path(
      table_dir,
      "structured-re-ademp-pilot-replicates.csv"
    ),
    pilot_denominators_csv = file.path(
      table_dir,
      "structured-re-ademp-pilot-denominators.csv"
    )
  )
}
