phase18_dgp_binomial_fe_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "encoding",
    "n",
    "trial_min",
    "trial_max",
    "beta_mu_intercept",
    "beta_mu_x"
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

  phase18_dgp_binomial_fe(
    n = cell$n[[1L]],
    encoding = cell$encoding[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    trial_min = cell$trial_min[[1L]],
    trial_max = cell$trial_max[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_binomial_fe <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  encoding <- phase18_binomial_fe_encoding(cell$encoding[[1L]])
  if (identical(encoding, "binary")) {
    target <- drmTMB(
      bf(y01 ~ x),
      family = stats::binomial(),
      data = data
    )
    glm_fit <- stats::glm(
      y01 ~ x,
      family = stats::binomial(),
      data = data
    )
  } else {
    target <- drmTMB(
      bf(cbind(success, failure) ~ x),
      family = stats::binomial(),
      data = data
    )
    glm_fit <- stats::glm(
      cbind(success, failure) ~ x,
      family = stats::binomial(),
      data = data
    )
  }
  list(target = target, glm = glm_fit)
}

phase18_run_binomial_fe_smoke <- function(
  conditions = phase18_binomial_fe_conditions(
    encoding = c("binary", "cbind"),
    n = 320L,
    trial_min = 10L,
    trial_max = 18L
  ),
  n_rep = 1L,
  master_seed = 20260616L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "binomial_fixed_effect",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_binomial_fe_cell,
    fit_fun = phase18_fit_binomial_fe,
    summarise_fun = phase18_summarise_binomial_fe_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "binomial_fixed_effect",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
