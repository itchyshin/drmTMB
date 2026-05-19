phase18_dgp_biv_rho12_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n",
    "delta0",
    "delta1",
    "sigma_ratio",
    "rho_xw",
    "beta_mu1_intercept",
    "beta_mu1_x",
    "beta_mu2_intercept",
    "beta_mu2_x",
    "beta_sigma1_intercept",
    "beta_sigma1_z",
    "beta_sigma2_z"
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

  phase18_dgp_biv_rho12(
    n = cell$n[[1L]],
    beta_mu1 = c(
      "(Intercept)" = cell$beta_mu1_intercept[[1L]],
      x = cell$beta_mu1_x[[1L]]
    ),
    beta_mu2 = c(
      "(Intercept)" = cell$beta_mu2_intercept[[1L]],
      x = cell$beta_mu2_x[[1L]]
    ),
    beta_sigma1 = c(
      "(Intercept)" = cell$beta_sigma1_intercept[[1L]],
      z1 = cell$beta_sigma1_z[[1L]]
    ),
    beta_sigma2 = c(
      "(Intercept)" = cell$beta_sigma1_intercept[[1L]] +
        log(cell$sigma_ratio[[1L]]),
      z2 = cell$beta_sigma2_z[[1L]]
    ),
    beta_rho12 = c(
      "(Intercept)" = cell$delta0[[1L]],
      w = cell$delta1[[1L]]
    ),
    rho_xw = cell$rho_xw[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_biv_rho12 <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z1,
      sigma2 = ~z2,
      rho12 = ~w
    ),
    family = biv_gaussian(),
    data = data
  )
}

phase18_run_biv_rho12_smoke <- function(
  conditions = phase18_biv_rho12_conditions(
    n = 180L,
    delta0 = atanh(0.25),
    delta1 = 0.25,
    sigma_ratio = 1.2,
    rho_xw = 0.2
  ),
  n_rep = 1L,
  master_seed = 20260523L,
  result_dir = NULL,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  bootstrap_nsim = 0L,
  bootstrap_level = 0.70
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "biv_rho12",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- vector("list", nrow(registry$seeds))
  for (i in seq_len(nrow(registry$seeds))) {
    seed_row <- registry$seeds[i, , drop = FALSE]
    cell <- registry$cells[seed_row$cell_index[[1L]], , drop = FALSE]
    bootstrap_seed <- ((seed_row$seed[[1L]] + 100000L - 1L) %%
      .Machine$integer.max) +
      1L
    summarise_fun <- function(
      fit,
      truth,
      cell_id,
      replicate,
      elapsed,
      warnings
    ) {
      phase18_summarise_biv_rho12_fit(
        fit = fit,
        truth = truth,
        cell_id = cell_id,
        replicate = replicate,
        elapsed = elapsed,
        warnings = warnings,
        profile_parameters = profile_parameters,
        profile_level = profile_level,
        profile_args = profile_args,
        bootstrap_nsim = bootstrap_nsim,
        bootstrap_level = bootstrap_level,
        bootstrap_seed = bootstrap_seed
      )
    }
    results[[i]] <- phase18_run_replicate(
      cell = cell,
      seed_row = seed_row,
      dgp_fun = phase18_dgp_biv_rho12_cell,
      fit_fun = phase18_fit_biv_rho12,
      summarise_fun = summarise_fun,
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
    surface = "biv_rho12",
    registry = registry,
    results = results,
    summary = summary
  )
}
