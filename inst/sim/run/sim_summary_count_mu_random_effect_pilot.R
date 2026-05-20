phase18_summarise_count_mu_re_pilot <- function(
  poisson_conditions = phase18_poisson_mu_re_conditions(
    n_group = c(36L, 48L),
    n_per_group = 9L
  ),
  nbinom2_conditions = phase18_nbinom2_mu_re_conditions(
    n_group = c(44L, 56L),
    n_per_group = 10L
  ),
  n_rep = 1L,
  master_seed = 20260520L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  assert_positive_whole_number(master_seed, "master_seed")
  phase18_assert_nonempty_data_frame(poisson_conditions, "poisson_conditions")
  phase18_assert_nonempty_data_frame(nbinom2_conditions, "nbinom2_conditions")

  poisson_result_dir <- NULL
  nbinom2_result_dir <- NULL
  if (!is.null(result_dir)) {
    if (!is.character(result_dir) || length(result_dir) != 1L) {
      stop("`result_dir` must be one path string or NULL.", call. = FALSE)
    }
    poisson_result_dir <- file.path(result_dir, "poisson_mu_random_effect")
    nbinom2_result_dir <- file.path(result_dir, "nbinom2_mu_random_effect")
    dir.create(poisson_result_dir, recursive = TRUE, showWarnings = FALSE)
    dir.create(nbinom2_result_dir, recursive = TRUE, showWarnings = FALSE)
  }

  poisson <- phase18_summarise_poisson_mu_re_smoke(
    conditions = poisson_conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = poisson_result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  nbinom2 <- phase18_summarise_nbinom2_mu_re_smoke(
    conditions = nbinom2_conditions,
    n_rep = n_rep,
    master_seed = master_seed + 1L,
    result_dir = nbinom2_result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  list(
    surface = "count_mu_random_effect_pilot",
    poisson = poisson,
    nbinom2 = nbinom2,
    aggregate = phase18_bind_count_mu_re_outputs(
      poisson$aggregate,
      nbinom2$aggregate
    ),
    replicates = phase18_bind_count_mu_re_outputs(
      poisson$replicates,
      nbinom2$replicates
    ),
    manifest = phase18_bind_count_mu_re_outputs(
      poisson$manifest,
      nbinom2$manifest
    ),
    failures = phase18_bind_count_mu_re_outputs(
      poisson$failures,
      nbinom2$failures
    ),
    wald_intervals = phase18_bind_count_mu_re_outputs(
      poisson$wald_intervals,
      nbinom2$wald_intervals
    ),
    wald_coverage = phase18_bind_count_mu_re_outputs(
      poisson$wald_coverage,
      nbinom2$wald_coverage
    ),
    profile_intervals = phase18_bind_count_mu_re_outputs(
      poisson$profile_intervals,
      nbinom2$profile_intervals
    ),
    profile_coverage = phase18_bind_count_mu_re_outputs(
      poisson$profile_coverage,
      nbinom2$profile_coverage
    )
  )
}

phase18_bind_count_mu_re_outputs <- function(...) {
  pieces <- list(...)
  pieces <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, pieces)
  if (length(pieces) == 0L) {
    return(data.frame())
  }
  out <- do.call(rbind, pieces)
  row.names(out) <- NULL
  out
}

phase18_assert_nonempty_data_frame <- function(x, name) {
  if (!is.data.frame(x) || nrow(x) == 0L) {
    stop("`", name, "` must be a non-empty data frame.", call. = FALSE)
  }
  invisible(x)
}
