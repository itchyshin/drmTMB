phase18_summarise_spatial_q2_smoke <- function(
  conditions = phase18_spatial_q2_conditions(
    n_site = 10L,
    n_each = 6L,
    geometry = "ring"
  ),
  n_rep = 1L,
  master_seed = 20260525L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  cores = 1L,
  backend = "none"
) {
  run <- phase18_run_spatial_q2_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    cores = cores,
    backend = backend
  )
  if (nrow(run$summary) == 0L) {
    stop(
      "The spatial q2 smoke run produced no summaries.",
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
  wald_ready <- run$summary[
    is.finite(run$summary$std.error),
    ,
    drop = FALSE
  ]
  wald_intervals <- if (nrow(wald_ready) == 0L) {
    data.frame()
  } else {
    phase18_add_wald_intervals(
      wald_ready,
      interval_scale = "formula_coefficient"
    )
  }
  wald_coverage <- phase18_optional_interval_coverage(
    wald_intervals,
    by = by
  )
  profile_status_rows <- run$summary[
    !is.finite(run$summary$std.error),
    ,
    drop = FALSE
  ]
  profile_intervals <- phase18_optional_intervals_from_columns(
    profile_status_rows,
    prefix = "profile"
  )
  profile_requested <- profile_intervals[
    profile_intervals$interval_status != "not_requested",
    ,
    drop = FALSE
  ]
  profile_coverage <- phase18_optional_interval_coverage(
    profile_requested,
    by = by
  )
  interval_evidence <- phase18_interval_evidence_table(
    wald_intervals,
    profile_intervals
  )
  interval_failures <- phase18_interval_failures(interval_evidence)
  interval_diagnostics <- phase18_optional_interval_diagnostics(
    interval_evidence,
    by = unique(c(by, "interval_method"))
  )

  list(
    surface = "spatial_q2",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures,
    wald_intervals = wald_intervals,
    wald_coverage = wald_coverage,
    profile_intervals = profile_intervals,
    profile_coverage = profile_coverage,
    interval_evidence = interval_evidence,
    interval_diagnostics = interval_diagnostics,
    interval_failures = interval_failures
  )
}
