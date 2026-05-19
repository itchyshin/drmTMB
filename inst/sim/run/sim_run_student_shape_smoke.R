phase18_dgp_student_shape_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n",
    "nu_intercept",
    "nu_slope",
    "sigma_slope",
    "rho_xw",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept"
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

  phase18_dgp_student_shape(
    n = cell$n[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = cell$beta_sigma_intercept[[1L]],
      z = cell$sigma_slope[[1L]]
    ),
    beta_nu = c(
      "(Intercept)" = cell$nu_intercept[[1L]],
      w = cell$nu_slope[[1L]]
    ),
    rho_xw = cell$rho_xw[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_student_shape <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ w),
    family = student(),
    data = data
  )
}

phase18_run_student_shape_smoke <- function(
  conditions = phase18_student_shape_conditions(
    n = 240L,
    nu_intercept = log(6),
    nu_slope = 0.25,
    sigma_slope = 0.20,
    rho_xw = 0.2
  ),
  n_rep = 1L,
  master_seed = 20260525L,
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
    surface = "student_shape",
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
      phase18_summarise_student_shape_fit(
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
      dgp_fun = phase18_dgp_student_shape_cell,
      fit_fun = phase18_fit_student_shape,
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
    surface = "student_shape",
    registry = registry,
    results = results,
    summary = summary
  )
}
