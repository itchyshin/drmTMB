phase18_summarise_skew_normal_fe_smoke <- function(
  conditions = phase18_skew_normal_fe_conditions(
    n = 720L,
    nu_intercept = 1.20,
    nu_slope = 0.35,
    sigma_slope = 0.20,
    rho_xw = 0.20
  ),
  n_rep = 2L,
  master_seed = 20260617L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  bootstrap_nsim = 0L,
  bootstrap_level = 0.70,
  bootstrap_cores = 1L,
  bootstrap_backend = "none",
  cores = 1L,
  backend = "none"
) {
  run <- phase18_run_skew_normal_fe_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    bootstrap_nsim = bootstrap_nsim,
    bootstrap_level = bootstrap_level,
    bootstrap_cores = bootstrap_cores,
    bootstrap_backend = bootstrap_backend,
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
  wald_intervals <- phase18_add_wald_intervals(
    run$summary,
    interval_scale = "formula_coefficient"
  )
  wald_coverage <- phase18_summarise_interval_coverage(
    wald_intervals,
    by = by
  )
  profile_intervals <- phase18_optional_intervals_from_columns(
    run$summary,
    prefix = "profile",
    parameters = profile_parameters
  )
  profile_coverage <- phase18_optional_interval_coverage(
    profile_intervals,
    by = by
  )
  bootstrap_intervals <- if (bootstrap_nsim > 0L) {
    phase18_optional_intervals_from_columns(
      run$summary,
      prefix = "bootstrap",
      parameters = unique(run$summary$parameter)
    )
  } else {
    data.frame()
  }
  bootstrap_coverage <- phase18_optional_interval_coverage(
    bootstrap_intervals,
    by = by
  )
  interval_evidence <- phase18_interval_evidence_table(
    wald_intervals,
    profile_intervals,
    bootstrap_intervals
  )
  interval_failures <- phase18_interval_failures(interval_evidence)
  interval_diagnostics <- phase18_optional_interval_diagnostics(
    interval_evidence,
    by = unique(c(by, "interval_method"))
  )

  list(
    surface = "skew_normal_fixed_effect",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures,
    wald_intervals = wald_intervals,
    wald_coverage = wald_coverage,
    profile_intervals = profile_intervals,
    profile_coverage = profile_coverage,
    bootstrap_intervals = bootstrap_intervals,
    bootstrap_coverage = bootstrap_coverage,
    interval_evidence = interval_evidence,
    interval_diagnostics = interval_diagnostics,
    interval_failures = interval_failures
  )
}
