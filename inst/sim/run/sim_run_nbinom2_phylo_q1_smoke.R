phase18_dgp_nbinom2_phylo_q1_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_species",
    "n_per_species",
    "sd_phylo",
    "mean_count",
    "sigma_baseline",
    "beta_mu_x",
    "beta_sigma_z",
    "tree_shape"
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
  phase18_dgp_nbinom2_phylo_q1(
    n_species = cell$n_species[[1L]],
    n_per_species = cell$n_per_species[[1L]],
    beta_mu = c(
      "(Intercept)" = log(cell$mean_count[[1L]]),
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = log(cell$sigma_baseline[[1L]]),
      z = cell$beta_sigma_z[[1L]]
    ),
    sd_phylo = cell$sd_phylo[[1L]],
    tree_shape = cell$tree_shape[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_nbinom2_phylo_q1 <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  truth <- attr(data, "truth", exact = TRUE)
  if (!is.list(truth) || !inherits(truth$tree, "phylo")) {
    stop(
      "`data` must carry an NB2 phylogenetic q1 truth tree.",
      call. = FALSE
    )
  }
  tree <- truth$tree
  target <- drmTMB(
    bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
    family = nbinom2(),
    data = data
  )
  grouped_comparator <- drmTMB(
    bf(count ~ x + (1 | species), sigma ~ z),
    family = nbinom2(),
    data = data
  )
  list(target = target, grouped_comparator = grouped_comparator)
}

phase18_run_nbinom2_phylo_q1_smoke <- function(
  conditions = phase18_nbinom2_phylo_q1_conditions(
    n_species = 20L,
    n_per_species = 6L,
    sd_phylo = 0.35,
    mean_count = 3.0,
    sigma_baseline = 0.55,
    tree_shape = "balanced"
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
    surface = "nbinom2_phylo_q1",
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
      phase18_summarise_nbinom2_phylo_q1_fit(
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
    dgp_fun = phase18_dgp_nbinom2_phylo_q1_cell,
    fit_fun = phase18_fit_nbinom2_phylo_q1,
    summarise_fun_factory = summarise_fun_factory,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "nbinom2_phylo_q1",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
