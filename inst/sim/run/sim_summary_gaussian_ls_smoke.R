phase18_summarise_gaussian_ls_smoke <- function(
  conditions = phase18_gaussian_ls_conditions(
    n = 120L,
    sigma_slope = 0.25,
    collinearity = 0.1
  ),
  n_rep = 2L,
  master_seed = 20260518L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL
) {
  run <- phase18_run_gaussian_ls_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite
  )
  if (nrow(run$summary) == 0L) {
    stop(
      "The Gaussian location-scale smoke run produced no summaries.",
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

  list(
    surface = "gaussian_ls",
    run = run,
    aggregate = aggregate,
    manifest = manifest,
    failures = failures,
    wald_intervals = wald_intervals,
    wald_coverage = wald_coverage
  )
}
