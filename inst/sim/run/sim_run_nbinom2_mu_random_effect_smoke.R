phase18_dgp_nbinom2_mu_re_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_group",
    "n_per_group",
    "sd_intercept",
    "sd_x",
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
  phase18_dgp_nbinom2_mu_re(
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
    sd = c(
      "(Intercept)" = cell$sd_intercept[[1L]],
      x = cell$sd_x[[1L]]
    ),
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_nbinom2_mu_re <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ z),
    family = nbinom2(),
    data = data
  )
}

phase18_run_nbinom2_mu_re_smoke <- function(
  conditions = phase18_nbinom2_mu_re_conditions(
    n_group = 36L,
    n_per_group = 9L
  ),
  n_rep = 1L,
  master_seed = 20260519L,
  result_dir = NULL,
  overwrite = FALSE
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "nbinom2_mu_random_effect",
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
      dgp_fun = phase18_dgp_nbinom2_mu_re_cell,
      fit_fun = phase18_fit_nbinom2_mu_re,
      summarise_fun = phase18_summarise_nbinom2_mu_re_fit,
      result_dir = result_dir,
      overwrite = overwrite
    )
  }
  names(results) <- paste(
    registry$seeds$cell_id,
    sprintf("rep%04d", registry$seeds$replicate),
    sep = ":"
  )

  summaries <- lapply(results, function(result) result$summary)
  summaries <- Filter(is.data.frame, summaries)
  summary <- if (length(summaries) == 0L) {
    data.frame()
  } else {
    do.call(rbind, summaries)
  }

  list(
    surface = "nbinom2_mu_random_effect",
    registry = registry,
    results = results,
    summary = summary
  )
}
