phase18_write_correlation_block_status_outputs <- function(
  output_dir,
  registry = phase18_read_structured_workflow_registry(),
  overwrite = FALSE
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- list(
    correlation_block_plan_csv = file.path(
      dirs$table_dir,
      "correlation-block-plan.csv"
    ),
    correlation_block_dispatch_csv = file.path(
      dirs$table_dir,
      "correlation-block-dispatch.csv"
    ),
    correlation_block_wrapper_targets_csv = file.path(
      dirs$table_dir,
      "correlation-block-wrapper-targets.csv"
    ),
    correlation_block_registry_summary_csv = file.path(
      dirs$table_dir,
      "correlation-block-registry-summary.csv"
    )
  )
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Correlation-block status"
  )

  plan <- phase18_correlation_block_workflow_plan(registry)
  dispatch <- plan[!is.na(plan$actions_task), , drop = FALSE]
  targets <- phase18_correlation_block_wrapper_target_plan(registry)
  summary <- phase18_structured_workflow_registry_summary(
    registry,
    by = c("workflow_lane", "admission_status")
  )
  summary <- summary[
    summary$workflow_lane == "correlation_blocks",
    ,
    drop = FALSE
  ]
  row.names(summary) <- NULL

  utils::write.csv(
    plan,
    paths$correlation_block_plan_csv,
    row.names = FALSE
  )
  utils::write.csv(
    dispatch,
    paths$correlation_block_dispatch_csv,
    row.names = FALSE
  )
  utils::write.csv(
    targets,
    paths$correlation_block_wrapper_targets_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary,
    paths$correlation_block_registry_summary_csv,
    row.names = FALSE
  )

  list(
    surface = "phase18_correlation_block_status",
    output_dir = dirs$output_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "phase18_correlation_block_status",
      paths
    ),
    plan = plan,
    dispatch = dispatch,
    wrapper_targets = targets,
    registry_summary = summary
  )
}
