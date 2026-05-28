phase18_summarise_tweedie_fe_smoke <- function(
  conditions = phase18_tweedie_fe_conditions(
    n = 320L,
    zero_regime = c("low", "high"),
    rho_xz = 0.20
  ),
  n_rep = 2L,
  master_seed = 20260538L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  cores = 1L,
  backend = "none"
) {
  run <- phase18_run_tweedie_fe_smoke(
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
      "The Tweedie fixed-effect smoke run produced no summaries.",
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
    surface = "tweedie_fixed_effect",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures,
    wald_intervals = wald_intervals,
    wald_coverage = wald_coverage
  )
}
