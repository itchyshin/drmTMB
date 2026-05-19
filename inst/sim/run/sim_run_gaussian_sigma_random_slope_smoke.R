phase18_dgp_gaussian_sigma_rs_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_group",
    "n_per_group",
    "sd_sigma_w",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
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
  phase18_dgp_gaussian_sigma_rs(
    n_group = cell$n_group[[1L]],
    n_per_group = cell$n_per_group[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = cell$beta_sigma_intercept[[1L]],
      z = cell$beta_sigma_z[[1L]]
    ),
    sd_sigma_w = cell$sd_sigma_w[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_gaussian_sigma_rs <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(y ~ x, sigma ~ z + (0 + w | id)),
    family = gaussian(),
    data = data,
    control = list(eval.max = 500, iter.max = 500)
  )
}

phase18_run_gaussian_sigma_rs_smoke <- function(
  conditions = phase18_gaussian_sigma_rs_conditions(
    n_group = 32L,
    n_per_group = 8L
  ),
  n_rep = 1L,
  master_seed = 20260518L,
  result_dir = NULL,
  overwrite = FALSE
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "gaussian_sigma_random_slope",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- vector("list", nrow(registry$seeds))
  for (i in seq_len(nrow(registry$seeds))) {
    seed_row <- registry$seeds[i, , drop = FALSE]
    cell <- registry$cells[seed_row$cell_index[[1L]], , drop = FALSE]
    results[[i]] <- phase18_run_replicate(
      cell = cell,
      seed_row = seed_row,
      dgp_fun = phase18_dgp_gaussian_sigma_rs_cell,
      fit_fun = phase18_fit_gaussian_sigma_rs,
      summarise_fun = phase18_summarise_gaussian_sigma_rs_fit,
      result_dir = result_dir,
      overwrite = overwrite
    )
  }
  names(results) <- paste(
    registry$seeds$cell_id,
    sprintf("rep%04d", registry$seeds$replicate),
    sep = ":"
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "gaussian_sigma_random_slope",
    registry = registry,
    results = results,
    summary = summary
  )
}
