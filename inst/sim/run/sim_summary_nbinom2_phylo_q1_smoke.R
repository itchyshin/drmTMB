phase18_summarise_nbinom2_phylo_q1_smoke <- function(
  conditions = phase18_nbinom2_phylo_q1_conditions(
    n_species = 20L,
    n_per_species = 6L,
    sd_phylo = 0.35,
    mean_count = 3.0,
    sigma_baseline = 0.55,
    tree_shape = "balanced"
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
  run <- phase18_run_nbinom2_phylo_q1_smoke(
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
      "The NB2 phylogenetic q1 smoke run produced no summaries.",
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
  interval_scale <- ifelse(
    run$summary$parameter_class %in% c("fixed_mu", "fixed_sigma"),
    "formula_coefficient",
    "public_sd"
  )
  wald_intervals <- phase18_add_wald_intervals(
    run$summary,
    interval_scale = interval_scale
  )
  interval_ready <- wald_intervals[
    wald_intervals$interval_status == "ok",
    ,
    drop = FALSE
  ]
  wald_coverage <- phase18_summarise_interval_coverage(
    interval_ready,
    by = by
  )
  profile_targets <- phase18_nbinom2_phylo_q1_profile_targets(run$summary)
  profile_status_rows <- run$summary[
    run$summary$parameter_class == "phylo_sd",
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
    surface = "nbinom2_phylo_q1",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures,
    wald_intervals = wald_intervals,
    wald_coverage = wald_coverage,
    profile_targets = profile_targets,
    profile_intervals = profile_intervals,
    profile_coverage = profile_coverage,
    interval_evidence = interval_evidence,
    interval_diagnostics = interval_diagnostics,
    interval_failures = interval_failures
  )
}

phase18_nbinom2_phylo_q1_profile_targets <- function(summary) {
  phase18_assert_summary_columns(
    summary,
    c(
      "surface",
      "cell_id",
      "replicate",
      "parameter",
      "parameter_class",
      "profile_target_status",
      "profile_target_parameter"
    )
  )
  out <- summary[
    summary$parameter_class == "phylo_sd",
    c(
      "surface",
      "cell_id",
      "replicate",
      "parameter",
      "profile_target_status",
      "profile_target_parameter"
    ),
    drop = FALSE
  ]
  out$artifact_grain <- "profile_target"
  row.names(out) <- NULL
  out
}
