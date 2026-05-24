phase18_summarise_poisson_phylo_q1_smoke <- function(
  conditions = phase18_poisson_phylo_q1_conditions(
    n_species = 20L,
    n_per_species = 4L,
    sd_phylo = 0.25,
    mean_count = 2.5,
    tree_shape = "balanced"
  ),
  n_rep = 1L,
  master_seed = 20260523L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  cores = 1L,
  backend = "none"
) {
  run <- phase18_run_poisson_phylo_q1_smoke(
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
      "The Poisson phylogenetic q1 smoke run produced no summaries.",
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
    run$summary$parameter_class == "fixed_mu",
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
  profile_targets <- phase18_poisson_phylo_q1_profile_targets(run$summary)

  list(
    surface = "poisson_phylo_q1",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures,
    wald_intervals = wald_intervals,
    wald_coverage = wald_coverage,
    profile_targets = profile_targets
  )
}

phase18_poisson_phylo_q1_profile_targets <- function(summary) {
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
