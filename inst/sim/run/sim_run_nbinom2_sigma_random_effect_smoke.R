phase18_dgp_nbinom2_sigma_re_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_group",
    "n_per_group",
    "mean_count",
    "sigma_baseline",
    "sd_sigma_intercept",
    "beta_mu_x",
    "beta_sigma_z"
  )
  missing <- setdiff(required, names(cell))
  if (length(missing) > 0L) {
    stop(
      "`cell` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  phase18_dgp_nbinom2_sigma_re(
    n_group = cell$n_group[[1L]],
    n_per_group = cell$n_per_group[[1L]],
    beta_mu = c(
      "(Intercept)" = log(cell$mean_count[[1L]]),
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = log(cell$sigma_baseline[[1L]]),
      z = cell$beta_sigma_z[[1L]]
    ),
    sd_sigma = cell$sd_sigma_intercept[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_nbinom2_sigma_re <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(count ~ x, sigma ~ z + (1 | id)),
    family = nbinom2(),
    data = data,
    control = list(eval.max = 600, iter.max = 600)
  )
}

phase18_run_nbinom2_sigma_re_smoke <- function(
  conditions = phase18_nbinom2_sigma_re_conditions(
    n_group = 32L,
    n_per_group = 14L,
    mean_count = 2.5,
    sigma_baseline = 0.55,
    sd_sigma_intercept = 0.35
  ),
  n_rep = 1L,
  master_seed = 20260524L,
  result_dir = NULL,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "nbinom2_sigma_random_effect",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )
  summarise_fun_factory <- function(cell, seed_row) {
    force(cell)
    force(seed_row)
    function(
      fit,
      truth,
      cell_id,
      replicate,
      elapsed,
      warnings
    ) {
      phase18_summarise_nbinom2_sigma_re_fit(
        fit = fit,
        truth = truth,
        cell_id = cell_id,
        replicate = replicate,
        elapsed = elapsed,
        warnings = warnings,
        profile_parameters = profile_parameters,
        profile_level = profile_level,
        profile_args = profile_args
      )
    }
  }

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_nbinom2_sigma_re_cell,
    fit_fun = phase18_fit_nbinom2_sigma_re,
    summarise_fun_factory = summarise_fun_factory,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "nbinom2_sigma_random_effect",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
