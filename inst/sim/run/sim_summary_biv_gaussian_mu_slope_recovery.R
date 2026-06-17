phase18_summarise_biv_gaussian_mu_slope_recovery <- function(
  conditions = phase18_biv_gaussian_mu_slope_conditions(
    n_id = 36L,
    n_each = 6L
  ),
  n_rep = 50L,
  master_seed = 20260631L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  wald_level = 0.95,
  cores = 1L,
  backend = "none"
) {
  run <- phase18_run_biv_gaussian_mu_slope_smoke(
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
      "The bivariate Gaussian mu slope recovery run produced no summaries.",
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

  # Wald coverage is meaningful only for endpoints that carry a standard error
  # (the fixed mu1/mu2 coefficients and fixed residual-scale intercepts). The
  # two slope random-effect SDs and the slope-slope correlation have no Wald
  # standard error, so they fall out of the coverage table as unusable rather
  # than being reported as interval-ready. This keeps the slope-slope
  # correlation at derived_interval_unavailable.
  wald_intervals <- phase18_add_wald_intervals(
    run$summary,
    conf.level = wald_level,
    interval_scale = "formula_coefficient"
  )
  wald_coverage <- phase18_summarise_interval_coverage(
    wald_intervals,
    by = by
  )
  profile_intervals <- phase18_optional_intervals_from_columns(
    run$summary,
    prefix = "profile",
    parameters = character()
  )
  bootstrap_intervals <- data.frame()
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
    surface = "biv_gaussian_mu_slope_recovery",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures,
    wald_intervals = wald_intervals,
    wald_coverage = wald_coverage,
    interval_evidence = interval_evidence,
    interval_diagnostics = interval_diagnostics,
    interval_failures = interval_failures
  )
}
