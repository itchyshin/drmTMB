phase18_dgp_animal_relmat_q4_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "structured_surface",
    "matrix_argument",
    "n_level",
    "n_per_level",
    "matrix_decay",
    "matrix_jitter",
    "sd_mu1",
    "sd_mu2",
    "sd_sigma1",
    "sd_sigma2",
    "cor_mu1_mu2",
    "cor_mu1_sigma1",
    "cor_mu1_sigma2",
    "cor_mu2_sigma1",
    "cor_mu2_sigma2",
    "cor_sigma1_sigma2",
    "rho12",
    "beta_mu1_intercept",
    "beta_mu1_x",
    "beta_mu2_intercept",
    "beta_mu2_x",
    "beta_sigma1_intercept",
    "beta_sigma1_z",
    "beta_sigma2_intercept",
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

  phase18_dgp_animal_relmat_q4(
    n_level = cell$n_level[[1L]],
    n_per_level = cell$n_per_level[[1L]],
    surface = cell$structured_surface[[1L]],
    matrix_argument = cell$matrix_argument[[1L]],
    matrix_decay = cell$matrix_decay[[1L]],
    matrix_jitter = cell$matrix_jitter[[1L]],
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
      z = cell$beta_sigma1_z[[1L]]
    ),
    beta_sigma2 = c(
      "(Intercept)" = cell$beta_sigma2_intercept[[1L]],
      z = cell$beta_sigma2_z[[1L]]
    ),
    sd_struct = c(
      mu1 = cell$sd_mu1[[1L]],
      mu2 = cell$sd_mu2[[1L]],
      sigma1 = cell$sd_sigma1[[1L]],
      sigma2 = cell$sd_sigma2[[1L]]
    ),
    cor_struct = phase18_animal_relmat_q4_cor_matrix(
      cor_mu1_mu2 = cell$cor_mu1_mu2[[1L]],
      cor_mu1_sigma1 = cell$cor_mu1_sigma1[[1L]],
      cor_mu1_sigma2 = cell$cor_mu1_sigma2[[1L]],
      cor_mu2_sigma1 = cell$cor_mu2_sigma1[[1L]],
      cor_mu2_sigma2 = cell$cor_mu2_sigma2[[1L]],
      cor_sigma1_sigma2 = cell$cor_sigma1_sigma2[[1L]]
    ),
    rho12 = cell$rho12[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_animal_relmat_q4 <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  truth <- attr(data, "truth", exact = TRUE)
  if (!is.list(truth) || !identical(truth$surface, "animal_relmat_q4")) {
    stop("`data` must carry an animal/relmat q4 truth object.", call. = FALSE)
  }
  K <- truth$K
  Q <- truth$Q
  control <- drm_control(
    se = FALSE,
    optimizer = list(eval.max = 800, iter.max = 800)
  )

  if (identical(truth$structured_surface, "animal")) {
    if (identical(truth$matrix_argument, "pedigree")) {
      pedigree <- truth$pedigree
      return(drmTMB(
        bf(
          mu1 = y1 ~ x + animal(1 | p | id, pedigree = pedigree),
          mu2 = y2 ~ x + animal(1 | p | id, pedigree = pedigree),
          sigma1 = ~ z + animal(1 | p | id, pedigree = pedigree),
          sigma2 = ~ z + animal(1 | p | id, pedigree = pedigree),
          rho12 = ~1
        ),
        family = biv_gaussian(),
        data = data,
        control = control
      ))
    }
    if (identical(truth$matrix_argument, "precision")) {
      return(drmTMB(
        bf(
          mu1 = y1 ~ x + animal(1 | p | id, Ainv = Q),
          mu2 = y2 ~ x + animal(1 | p | id, Ainv = Q),
          sigma1 = ~ z + animal(1 | p | id, Ainv = Q),
          sigma2 = ~ z + animal(1 | p | id, Ainv = Q),
          rho12 = ~1
        ),
        family = biv_gaussian(),
        data = data,
        control = control
      ))
    }
    return(drmTMB(
      bf(
        mu1 = y1 ~ x + animal(1 | p | id, A = K),
        mu2 = y2 ~ x + animal(1 | p | id, A = K),
        sigma1 = ~ z + animal(1 | p | id, A = K),
        sigma2 = ~ z + animal(1 | p | id, A = K),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = data,
      control = control
    ))
  }

  if (identical(truth$matrix_argument, "precision")) {
    return(drmTMB(
      bf(
        mu1 = y1 ~ x + relmat(1 | p | id, Q = Q),
        mu2 = y2 ~ x + relmat(1 | p | id, Q = Q),
        sigma1 = ~ z + relmat(1 | p | id, Q = Q),
        sigma2 = ~ z + relmat(1 | p | id, Q = Q),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = data,
      control = control
    ))
  }
  drmTMB(
    bf(
      mu1 = y1 ~ x + relmat(1 | p | id, K = K),
      mu2 = y2 ~ x + relmat(1 | p | id, K = K),
      sigma1 = ~ z + relmat(1 | p | id, K = K),
      sigma2 = ~ z + relmat(1 | p | id, K = K),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = data,
    control = control
  )
}

phase18_run_animal_relmat_q4_smoke <- function(
  conditions = phase18_animal_relmat_q4_conditions(
    structured_surface = c("animal", "relmat"),
    matrix_argument = "precision",
    n_level = 12L,
    n_per_level = 7L
  ),
  n_rep = 1L,
  master_seed = 20260531L,
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
    surface = "animal_relmat_q4",
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
      phase18_summarise_animal_relmat_q4_fit(
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
    dgp_fun = phase18_dgp_animal_relmat_q4_cell,
    fit_fun = phase18_fit_animal_relmat_q4,
    summarise_fun_factory = summarise_fun_factory,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "animal_relmat_q4",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
