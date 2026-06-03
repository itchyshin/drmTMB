phase18_dgp_biv_gaussian_q4_location_cell <- function(
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
    "sd_mu1_intercept",
    "sd_mu1_x",
    "sd_mu2_intercept",
    "sd_mu2_x",
    "cor_mu1_intercept_mu1_x",
    "cor_mu1_intercept_mu2_intercept",
    "cor_mu1_intercept_mu2_x",
    "cor_mu1_x_mu2_intercept",
    "cor_mu1_x_mu2_x",
    "cor_mu2_intercept_mu2_x",
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
  phase18_dgp_biv_gaussian_q4_location(
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
    sigma = c(
      sigma1 = cell$sigma1[[1L]],
      sigma2 = cell$sigma2[[1L]]
    ),
    sd_mu = c(
      "mu1:(1 + x | p | id):(Intercept)" = cell$sd_mu1_intercept[[1L]],
      "mu1:(1 + x | p | id):x" = cell$sd_mu1_x[[1L]],
      "mu2:(1 + x | p | id):(Intercept)" = cell$sd_mu2_intercept[[1L]],
      "mu2:(1 + x | p | id):x" = cell$sd_mu2_x[[1L]]
    ),
    cor_mu = c(
      "cor(mu1:(Intercept),mu1:x | p | id)" = cell$cor_mu1_intercept_mu1_x[[
        1L
      ]],
      "cor(mu1:(Intercept),mu2:(Intercept) | p | id)" = cell$cor_mu1_intercept_mu2_intercept[[
        1L
      ]],
      "cor(mu1:(Intercept),mu2:x | p | id)" = cell$cor_mu1_intercept_mu2_x[[
        1L
      ]],
      "cor(mu1:x,mu2:(Intercept) | p | id)" = cell$cor_mu1_x_mu2_intercept[[
        1L
      ]],
      "cor(mu1:x,mu2:x | p | id)" = cell$cor_mu1_x_mu2_x[[1L]],
      "cor(mu2:(Intercept),mu2:x | p | id)" = cell$cor_mu2_intercept_mu2_x[[1L]]
    ),
    residual_rho = cell$residual_rho[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_biv_gaussian_q4_location <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  drmTMB(
    bf(
      mu1 = y1 ~ x + (1 + x | p | id),
      mu2 = y2 ~ x + (1 + x | p | id),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = data
  )
}

phase18_run_biv_gaussian_q4_location_smoke <- function(
  conditions = phase18_biv_gaussian_q4_location_conditions(
    n_id = 24L,
    n_each = 5L
  ),
  n_rep = 1L,
  master_seed = 20260609L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "biv_gaussian_q4_location",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_biv_gaussian_q4_location_cell,
    fit_fun = phase18_fit_biv_gaussian_q4_location,
    summarise_fun = phase18_summarise_biv_gaussian_q4_location_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "biv_gaussian_q4_location",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
