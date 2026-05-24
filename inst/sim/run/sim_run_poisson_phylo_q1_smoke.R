phase18_dgp_poisson_phylo_q1_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_species",
    "n_per_species",
    "sd_phylo",
    "mean_count",
    "beta_mu_x",
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
  phase18_dgp_poisson_phylo_q1(
    n_species = cell$n_species[[1L]],
    n_per_species = cell$n_per_species[[1L]],
    beta_mu = c(
      "(Intercept)" = log(cell$mean_count[[1L]]),
      x = cell$beta_mu_x[[1L]]
    ),
    sd_phylo = cell$sd_phylo[[1L]],
    tree_shape = cell$tree_shape[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_fit_poisson_phylo_q1 <- function(data, cell) {
  phase18_assert_one_row_data_frame(cell, "cell")
  truth <- attr(data, "truth", exact = TRUE)
  if (!is.list(truth) || !inherits(truth$tree, "phylo")) {
    stop(
      "`data` must carry a Poisson phylogenetic q1 truth tree.",
      call. = FALSE
    )
  }
  tree <- truth$tree
  drmTMB(
    bf(count ~ x + phylo(1 | species, tree = tree)),
    family = stats::poisson(link = "log"),
    data = data
  )
}

phase18_run_poisson_phylo_q1_smoke <- function(
  conditions = phase18_poisson_phylo_q1_conditions(
    n_species = 20L,
    n_per_species = 4L,
    sd_phylo = 0.25,
    mean_count = 2.5,
    tree_shape = "balanced"
  ),
  n_rep = 1L,
  master_seed = 20260523L,
  result_dir = NULL,
  overwrite = FALSE,
  cores = 1L,
  backend = "none"
) {
  assert_positive_whole_number(n_rep, "n_rep")
  registry <- phase18_cell_registry(
    surface = "poisson_phylo_q1",
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed
  )

  results <- phase18_run_replicates(
    cells = registry$cells,
    seeds = registry$seeds,
    dgp_fun = phase18_dgp_poisson_phylo_q1_cell,
    fit_fun = phase18_fit_poisson_phylo_q1,
    summarise_fun = phase18_summarise_poisson_phylo_q1_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )

  summary <- phase18_result_summaries(results)

  list(
    surface = "poisson_phylo_q1",
    registry = registry,
    parallel = attr(results, "phase18_parallel", exact = TRUE),
    results = results,
    summary = summary
  )
}
