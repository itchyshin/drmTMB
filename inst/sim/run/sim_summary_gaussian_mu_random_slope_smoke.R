phase18_summarise_gaussian_mu_rs_smoke <- function(
  conditions = phase18_gaussian_mu_rs_conditions(
    n_group = 24L,
    n_per_group = 7L
  ),
  n_rep = 1L,
  master_seed = 20260518L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL
) {
  run <- phase18_run_gaussian_mu_rs_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite
  )
  if (nrow(run$summary) == 0L) {
    stop(
      "The Gaussian mu random-slope smoke run produced no summaries.",
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

  list(
    surface = "gaussian_mu_random_slope",
    run = run,
    aggregate = aggregate,
    manifest = manifest,
    failures = failures
  )
}
