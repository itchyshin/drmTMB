phase18_dgp_biv_gaussian_q2_scale_slope_cell <- function(
  cell,
  seed,
  cell_id,
  replicate
) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_id",
    "n_each",
    "beta_mu1_intercept",
    "beta_mu1_x",
    "beta_mu2_intercept",
    "beta_mu2_x",
    "sigma1",
    "sigma2",
    "beta_sigma1_x",
    "beta_sigma2_x",
    "sd_sigma1",
    "sd_sigma2",
    "cor_sigma1_sigma2",
    "residual_rho"
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
  phase18_dgp_biv_gaussian_q2_scale_slope(
    n_id = cell$n_id[[1L]],
    n_each = cell$n_each[[1L]],
    beta_mu1 = c(
      "(Intercept)" = cell$beta_mu1_intercept[[1L]],
      x = cell$beta_mu1_x[[1L]]
    ),
    beta_mu2 = c(
      "(Intercept)" = cell$beta_mu2_intercept[[1L]],
      x = cell$beta_mu2_x[[1L]]
    ),
    beta_sigma1 = c(
      "(Intercept)" = log(cell$sigma1[[1L]]),
      x = cell$beta_sigma1_x[[1L]]
    ),
    beta_sigma2 = c(
      "(Intercept)" = log(cell$sigma2[[1L]]),
      x = cell$beta_sigma2_x[[1L]]
    ),
    sd_sigma = c(
      "sigma1:(0 + x | p | id)" = cell$sd_sigma1[[1L]],
      "sigma2:(0 + x | p | id)" = cell$sd_sigma2[[1L]]
    ),
    cor_sigma = cell$cor_sigma1_sigma2[[1L]],
    residual_rho = cell$residual_rho[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_biv_gaussian_q2_scale_slope <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~ x + (0 + x | p | id),
      sigma2 = ~ x + (0 + x | p | id),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = data,
    control = list(eval.max = 600, iter.max = 600)
  )
}

phase18_run_biv_gaussian_q2_scale_slope_smoke <- function(
  conditions = phase18_biv_gaussian_q2_scale_slope_conditions(
    n_id = 48L,
    n_each = 12L
  ),
  n_rep = 1L,
  master_seed = 20260625L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "biv_gaussian_q2_scale_slope",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_biv_gaussian_q2_scale_slope_cell,
    fit_fun = phase18_fit_biv_gaussian_q2_scale_slope,
    summarise_fun = phase18_summarise_biv_gaussian_q2_scale_slope_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "biv_gaussian_q2_scale_slope",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
