phase18_dgp_count_structured_q1_cell <- function(
  cell,
  seed,
  cell_id,
  replicate
) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "family",
    "structured_type",
    "n_level",
    "n_per_level",
    "sd_structured",
    "mean_count",
    "sigma_baseline",
    "beta_mu_x",
    "beta_sigma_z",
    "geometry",
    "matrix_decay"
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
  phase18_dgp_count_structured_q1(
    family = cell$family[[1L]],
    structured_type = cell$structured_type[[1L]],
    n_level = cell$n_level[[1L]],
    n_per_level = cell$n_per_level[[1L]],
    beta_mu = c(
      "(Intercept)" = log(cell$mean_count[[1L]]),
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = log(cell$sigma_baseline[[1L]]),
      z = cell$beta_sigma_z[[1L]]
    ),
    sd_structured = cell$sd_structured[[1L]],
    geometry = cell$geometry[[1L]],
    matrix_decay = cell$matrix_decay[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_count_structured_q1 <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  truth <- attr(data, "truth", exact = TRUE)
  if (!is.list(truth) || !identical(truth$surface, "count_structured_q1")) {
    stop("`data` must carry a count structured q1 truth object.", call. = FALSE)
  }

  if (identical(truth$structured_type, "spatial")) {
    coords <- truth$coords
    if (identical(truth$family, "poisson")) {
      return(drmTMB(
        bf(count ~ x + spatial(1 | site, coords = coords)),
        family = stats::poisson(link = "log"),
        data = data
      ))
    }
    return(drmTMB(
      bf(count ~ x + spatial(1 | site, coords = coords), sigma ~ z),
      family = nbinom2(),
      data = data,
      control = list(eval.max = 600, iter.max = 600)
    ))
  }

  Q <- truth$Q
  if (identical(truth$structured_type, "animal")) {
    if (identical(truth$family, "poisson")) {
      return(drmTMB(
        bf(count ~ x + animal(1 | id, Ainv = Q)),
        family = stats::poisson(link = "log"),
        data = data
      ))
    }
    return(drmTMB(
      bf(count ~ x + animal(1 | id, Ainv = Q), sigma ~ z),
      family = nbinom2(),
      data = data,
      control = list(eval.max = 600, iter.max = 600)
    ))
  }

  if (identical(truth$family, "poisson")) {
    return(drmTMB(
      bf(count ~ x + relmat(1 | id, Q = Q)),
      family = stats::poisson(link = "log"),
      data = data
    ))
  }
  drmTMB(
    bf(count ~ x + relmat(1 | id, Q = Q), sigma ~ z),
    family = nbinom2(),
    data = data,
    control = list(eval.max = 600, iter.max = 600)
  )
}

phase18_run_count_structured_q1_smoke <- function(
  conditions = phase18_count_structured_q1_conditions(
    family = c("poisson", "nbinom2"),
    structured_type = c("spatial", "animal", "relmat"),
    n_level = 10L,
    n_per_level = 8L,
    sd_structured = 0.35,
    mean_count = 3.0,
    sigma_baseline = 0.45,
    geometry = "ring"
  ),
  n_rep = 1L,
  master_seed = 20260528L,
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
    surface = "count_structured_q1",
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
      phase18_summarise_count_structured_q1_fit(
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
    dgp_fun = phase18_dgp_count_structured_q1_cell,
    fit_fun = phase18_fit_count_structured_q1,
    summarise_fun_factory = summarise_fun_factory,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "count_structured_q1",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
