phase18_summarise_nbinom2_mu_re_smoke <- function(
  conditions = phase18_nbinom2_mu_re_conditions(
    n_group = 36L,
    n_per_group = 9L
  ),
  n_rep = 1L,
  master_seed = 20260519L,
  result_dir = NULL,
  overwrite = FALSE,
  by = NULL,
  cores = 1L,
  backend = "none"
) {
  run <- phase18_run_nbinom2_mu_re_smoke(
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
      "The NB2 mu random-effect smoke run produced no summaries.",
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
  profile_intervals <- phase18_nbinom2_mu_re_profile_intervals(run$summary)
  profile_ready <- profile_intervals[
    profile_intervals$interval_status == "ok",
    ,
    drop = FALSE
  ]
  profile_coverage <- if (nrow(profile_ready) == 0L) {
    data.frame()
  } else {
    phase18_summarise_interval_coverage(profile_ready, by = by)
  }

  list(
    surface = "nbinom2_mu_random_effect",
    run = run,
    aggregate = aggregate,
    replicates = run$summary,
    manifest = manifest,
    failures = failures,
    wald_intervals = wald_intervals,
    wald_coverage = wald_coverage,
    profile_intervals = profile_intervals,
    profile_coverage = profile_coverage
  )
}

phase18_nbinom2_mu_re_profile_intervals <- function(summary) {
  phase18_assert_summary_columns(
    summary,
    c(
      "parameter",
      "parameter_class",
      "profile.conf.low",
      "profile.conf.high",
      "profile.status",
      "profile.message"
    )
  )
  out <- summary[summary$parameter_class == "random_sd", , drop = FALSE]
  out$conf.low <- out$profile.conf.low
  out$conf.high <- out$profile.conf.high
  out$conf.level <- out$profile.conf.level
  out$interval_method <- "profile"
  out$interval_scale <- "public_sd"
  out$interval_status <- ifelse(
    is.finite(out$conf.low) & is.finite(out$conf.high),
    "ok",
    "failed"
  )
  out$interval_message <- out$profile.message
  row.names(out) <- NULL
  out
}
