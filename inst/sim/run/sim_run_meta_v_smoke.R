phase18_dgp_meta_v_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_study",
    "known_v_type",
    "beta_mu_intercept",
    "beta_mu_x",
    "sigma",
    "sampling_sd",
    "sampling_rho"
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
  phase18_dgp_meta_v(
    n_study = cell$n_study[[1L]],
    known_v_type = cell$known_v_type[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    sigma = cell$sigma[[1L]],
    sampling_sd = cell$sampling_sd[[1L]],
    sampling_rho = cell$sampling_rho[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_meta_v <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  V <- attr(data, "V", exact = TRUE)
  if (is.null(V)) {
    stop("`data` must carry a known sampling covariance `V`.", call. = FALSE)
  }
  drmTMB(
    bf(yi ~ x + meta_V(V = V), sigma ~ 1),
    family = gaussian(),
    data = data
  )
}

phase18_run_meta_v_smoke <- function(
  conditions = phase18_meta_v_conditions(
    n_study = 36L,
    known_v_type = c("vector", "dense"),
    sigma = 0.25,
    sampling_sd = 0.14,
    sampling_rho = c(0, 0.20)
  ),
  n_rep = 1L,
  master_seed = 20260518L,
  result_dir = NULL,
  overwrite = FALSE
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "meta_v",
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
      dgp_fun = phase18_dgp_meta_v_cell,
      fit_fun = phase18_fit_meta_v,
      summarise_fun = phase18_summarise_meta_v_fit,
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
    surface = "meta_v",
    registry = registry,
    results = results,
    summary = summary
  )
}
