phase18_dgp_spatial_q2_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_site",
    "n_each",
    "geometry",
    "sd_spatial1",
    "sd_spatial2",
    "rho_spatial",
    "sigma1",
    "sigma2",
    "rho12",
    "beta_mu1_intercept",
    "beta_mu1_x",
    "beta_mu2_intercept",
    "beta_mu2_x"
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

  phase18_dgp_spatial_q2(
    n_site = cell$n_site[[1L]],
    n_each = cell$n_each[[1L]],
    geometry = cell$geometry[[1L]],
    beta_mu1 = c(
      "(Intercept)" = cell$beta_mu1_intercept[[1L]],
      x = cell$beta_mu1_x[[1L]]
    ),
    beta_mu2 = c(
      "(Intercept)" = cell$beta_mu2_intercept[[1L]],
      x = cell$beta_mu2_x[[1L]]
    ),
    sd_spatial = c(
      mu1 = cell$sd_spatial1[[1L]],
      mu2 = cell$sd_spatial2[[1L]]
    ),
    rho_spatial = cell$rho_spatial[[1L]],
    sigma = c(
      sigma1 = cell$sigma1[[1L]],
      sigma2 = cell$sigma2[[1L]]
    ),
    rho12 = cell$rho12[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_spatial_q2 <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  truth <- attr(data, "truth", exact = TRUE)
  if (!is.list(truth) || !identical(truth$surface, "spatial_q2")) {
    stop("`data` must carry a spatial q2 truth object.", call. = FALSE)
  }
  coords <- truth$coords
  drmTMB(
    bf(
      mu1 = y1 ~ x + spatial(1 | p | site, coords = coords),
      mu2 = y2 ~ x + spatial(1 | p | site, coords = coords),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = data,
    control = list(eval.max = 500, iter.max = 500)
  )
}

phase18_run_spatial_q2_smoke <- function(
  conditions = phase18_spatial_q2_conditions(
    n_site = 10L,
    n_each = 6L,
    geometry = "ring",
    sd_spatial1 = 0.50,
    sd_spatial2 = 0.42,
    rho_spatial = 0.35,
    sigma1 = 0.18,
    sigma2 = 0.20,
    rho12 = -0.10
  ),
  n_rep = 1L,
  master_seed = 20260525L,
  result_dir = NULL,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "spatial_q2",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )
  summarise_fun_factory <- function(cell, seed_row) {
    force(cell)
    force(seed_row)
    function(
      fit,
      truth,
      cell_id,
      replicate,
      elapsed,
      warnings
    ) {
      phase18_summarise_spatial_q2_fit(
        fit = fit,
        truth = truth,
        cell_id = cell_id,
        replicate = replicate,
        elapsed = elapsed,
        warnings = warnings,
        profile_parameters = profile_parameters,
        profile_level = profile_level,
        profile_args = profile_args
      )
    }
  }

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_spatial_q2_cell,
    fit_fun = phase18_fit_spatial_q2,
    summarise_fun_factory = summarise_fun_factory,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "spatial_q2",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
