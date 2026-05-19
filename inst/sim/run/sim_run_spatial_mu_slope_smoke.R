phase18_dgp_spatial_mu_slope_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_site",
    "n_each",
    "sd_intercept",
    "sd_slope",
    "beta_mu_intercept",
    "beta_mu_x",
    "sigma"
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
  phase18_dgp_spatial_mu_slope(
    n_site = cell$n_site[[1L]],
    n_each = cell$n_each[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    sigma = cell$sigma[[1L]],
    sd = c(
      "(Intercept)" = cell$sd_intercept[[1L]],
      x = cell$sd_slope[[1L]]
    ),
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_spatial_mu_slope <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  truth <- attr(data, "truth", exact = TRUE)
  coords <- truth$coords
  drmTMB(
    bf(y ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1),
    family = gaussian(),
    data = data
  )
}

phase18_run_spatial_mu_slope_smoke <- function(
  conditions = phase18_spatial_mu_slope_conditions(
    n_site = 12L,
    n_each = 8L
  ),
  n_rep = 1L,
  master_seed = 20260518L,
  result_dir = NULL,
  overwrite = FALSE
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "spatial_mu_slope",
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
      dgp_fun = phase18_dgp_spatial_mu_slope_cell,
      fit_fun = phase18_fit_spatial_mu_slope,
      summarise_fun = phase18_summarise_spatial_mu_slope_fit,
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
    surface = "spatial_mu_slope",
    registry = registry,
    results = results,
    summary = summary
  )
}
