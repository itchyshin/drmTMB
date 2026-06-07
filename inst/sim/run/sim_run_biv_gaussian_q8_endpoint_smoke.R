phase18_dgp_biv_gaussian_q8_endpoint_cell <- function(
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
    "sd_mu1_intercept",
    "sd_mu1_x",
    "sd_mu2_intercept",
    "sd_mu2_x",
    "sd_sigma1_intercept",
    "sd_sigma1_x",
    "sd_sigma2_intercept",
    "sd_sigma2_x",
    "cor_base",
    "cor_mu_intercept",
    "cor_mu_x",
    "cor_sigma_intercept",
    "cor_sigma_x",
    "cor_mu1_sigma1_intercept",
    "cor_mu1_sigma1_x",
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
  phase18_dgp_biv_gaussian_q8_endpoint(
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
    sd_mu = c(
      "mu1:(1 + x | p | id):(Intercept)" = cell$sd_mu1_intercept[[1L]],
      "mu1:(1 + x | p | id):x" = cell$sd_mu1_x[[1L]],
      "mu2:(1 + x | p | id):(Intercept)" = cell$sd_mu2_intercept[[1L]],
      "mu2:(1 + x | p | id):x" = cell$sd_mu2_x[[1L]]
    ),
    sd_sigma = c(
      "sigma1:(1 + x | p | id):(Intercept)" = cell$sd_sigma1_intercept[[1L]],
      "sigma1:(1 + x | p | id):x" = cell$sd_sigma1_x[[1L]],
      "sigma2:(1 + x | p | id):(Intercept)" = cell$sd_sigma2_intercept[[1L]],
      "sigma2:(1 + x | p | id):x" = cell$sd_sigma2_x[[1L]]
    ),
    cor_re_cov = phase18_biv_gaussian_q8_endpoint_correlations(
      cor_base = cell$cor_base[[1L]],
      cor_mu_intercept = cell$cor_mu_intercept[[1L]],
      cor_mu_x = cell$cor_mu_x[[1L]],
      cor_sigma_intercept = cell$cor_sigma_intercept[[1L]],
      cor_sigma_x = cell$cor_sigma_x[[1L]],
      cor_mu1_sigma1_intercept = cell$cor_mu1_sigma1_intercept[[1L]],
      cor_mu1_sigma1_x = cell$cor_mu1_sigma1_x[[1L]]
    ),
    residual_rho = cell$residual_rho[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_biv_gaussian_q8_endpoint <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(
      mu1 = y1 ~ x + (1 + x | p | id),
      mu2 = y2 ~ x + (1 + x | p | id),
      sigma1 = ~ x + (1 + x | p | id),
      sigma2 = ~ x + (1 + x | p | id),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = data,
    control = drm_control(
      optimizer = list(eval.max = 800, iter.max = 800),
      se = FALSE
    )
  )
}

phase18_run_biv_gaussian_q8_endpoint_smoke <- function(
  conditions = phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 48L,
    n_each = 10L
  ),
  n_rep = 1L,
  master_seed = 20260634L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "biv_gaussian_q8_endpoint",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_biv_gaussian_q8_endpoint_cell,
    fit_fun = phase18_fit_biv_gaussian_q8_endpoint,
    summarise_fun = phase18_summarise_biv_gaussian_q8_endpoint_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "biv_gaussian_q8_endpoint",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
