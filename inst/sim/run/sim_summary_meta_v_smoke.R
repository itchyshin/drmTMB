phase18_summarise_meta_v_smoke <- function(
  conditions = phase18_meta_v_conditions(
    n_study = 36L,
    known_v_type = c("vector", "dense"),
    sigma = 0.25,
    sampling_sd = 0.14,
    sampling_rho = c(0, 0.20)
  ),
  n_rep = 2L,
  master_seed = 20260518L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL
) {
  run <- phase18_run_meta_v_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite
  )
  if (nrow(run$summary) == 0L) {
    stop("The meta_V smoke run produced no summaries.", call. = FALSE)
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
    surface = "meta_v",
    run = run,
    aggregate = aggregate,
    manifest = manifest,
    failures = failures
  )
}
