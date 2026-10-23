# Source-faithful production adapter for the exact Lane-B q2-plus phylogenetic
# location-SD bindings. Loading this module is inert: data are generated only
# by the explicit fixture entry point, which does not fit a model.

lane_b_q2plus_phylo_adapter_stop <- function(...) {
  stop(..., call. = FALSE)
}

lane_b_q2plus_phylo_production_contracts <- function() {
  data.frame(
    cell_id = c("mc-0089", "mc-0090"),
    target_id = c(
      "mc-0089::sd:mu:mu1:phylo(1 | pl | species)",
      "mc-0090::sd:mu:mu2:phylo(1 | pl | species)"
    ),
    profile_parameter = c(
      "sd:mu:mu1:phylo(1 | pl | species)",
      "sd:mu:mu2:phylo(1 | pl | species)"
    ),
    target_axis = c("mu1", "mu2"),
    target_truth = c(0.55, 0.45),
    seed = rep(823001L, 2L),
    n_tip = rep(8L, 2L),
    n_each = rep(50L, 2L),
    rung = rep("low", 2L),
    dgp_id = rep("qseries_phylo_q2_plus_q2_intercept", 2L),
    source_module = rep(
      "tools/run-structured-re-q2-plus-q2-intercept-smoke.R",
      2L
    ),
    formula = rep(
      paste0(
        "bf(mu1 = y1 ~ phylo(1 | pl | species, tree = tree), ",
        "mu2 = y2 ~ phylo(1 | pl | species, tree = tree), ",
        "sigma1 = ~ phylo(1 | ps | species, tree = tree), ",
        "sigma2 = ~ phylo(1 | ps | species, tree = tree), rho12 = ~1); ",
        "biv_gaussian(ML)"
      ),
      2L
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

lane_b_q2plus_phylo_production_row <- function(cell, seed, rung) {
  contracts <- lane_b_q2plus_phylo_production_contracts()
  if (
    !is.character(cell) ||
      length(cell) != 1L ||
      is.na(cell) ||
      !cell %in% contracts$cell_id
  ) {
    lane_b_q2plus_phylo_adapter_stop(
      "No q2-plus phylo production adapter is registered for ",
      cell,
      "."
    )
  }
  row <- contracts[match(cell, contracts$cell_id), , drop = FALSE]
  if (!identical(as.character(rung), row$rung[[1L]])) {
    lane_b_q2plus_phylo_adapter_stop(
      "The q2-plus phylo production adapter is frozen at the low execution rung."
    )
  }
  if (
    !is.numeric(seed) ||
      length(seed) != 1L ||
      is.na(seed) ||
      seed != row$seed[[1L]]
  ) {
    lane_b_q2plus_phylo_adapter_stop(
      "The q2-plus phylo production adapter requires its exact recorded seed."
    )
  }
  row
}

lane_b_q2plus_phylo_balanced_tree <- function(n_tip = 8L) {
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }

  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

lane_b_q2plus_phylo_correlated_intercept_effects <- function(
  K,
  sd1,
  sd2,
  cor12
) {
  endpoint_cov <- matrix(
    c(sd1^2, cor12 * sd1 * sd2, cor12 * sd1 * sd2, sd2^2),
    nrow = 2L
  )
  base <- t(chol(K)) %*% matrix(stats::rnorm(nrow(K) * 2L), nrow(K), 2L)
  out <- base %*% chol(endpoint_cov)
  colnames(out) <- c("axis1", "axis2")
  out
}

lane_b_q2plus_phylo_fit_closure <- function() {
  function(data) {
    tree <- attr(data, "tree", exact = TRUE)
    if (!inherits(tree, "phylo")) {
      lane_b_q2plus_phylo_adapter_stop(
        "The q2-plus phylo adapter data must retain its production tree."
      )
    }
    drmTMB::drmTMB(
      drmTMB::bf(
        mu1 = y1 ~ phylo(1 | pl | species, tree = tree),
        mu2 = y2 ~ phylo(1 | pl | species, tree = tree),
        sigma1 = ~phylo(1 | ps | species, tree = tree),
        sigma2 = ~phylo(1 | ps | species, tree = tree),
        rho12 = ~1
      ),
      family = drmTMB::biv_gaussian(),
      data = data,
      control = drmTMB::drm_control(
        optimizer = list(eval.max = 2500, iter.max = 2500)
      )
    )
  }
}

lane_b_q2plus_phylo_production_adapter_fixture <- function(cell, seed, rung) {
  row <- lane_b_q2plus_phylo_production_row(cell, seed, rung)
  set.seed(as.integer(row$seed[[1L]]))
  tree <- lane_b_q2plus_phylo_balanced_tree(as.integer(row$n_tip[[1L]]))
  labels <- tree$tip.label
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  location_effects <- lane_b_q2plus_phylo_correlated_intercept_effects(
    K, sd1 = 0.55, sd2 = 0.45, cor12 = 0.20
  )
  scale_effects <- lane_b_q2plus_phylo_correlated_intercept_effects(
    K, sd1 = 0.45, sd2 = 0.40, cor12 = 0.15
  )
  row.names(location_effects) <- labels
  row.names(scale_effects) <- labels

  species <- rep(labels, each = as.integer(row$n_each[[1L]]))
  eta1 <- 0.25 + location_effects[species, "axis1"]
  eta2 <- -0.10 + location_effects[species, "axis2"]
  log_sigma1 <- -1.00 + scale_effects[species, "axis1"]
  log_sigma2 <- -0.90 + scale_effects[species, "axis2"]
  data <- data.frame(
    y1 = stats::rnorm(length(species), eta1, exp(log_sigma1)),
    y2 = stats::rnorm(length(species), eta2, exp(log_sigma2)),
    species = species,
    stringsAsFactors = FALSE
  )
  attr(data, "tree") <- tree

  truth <- list(
    mu1_intercept = 0.25,
    mu2_intercept = -0.10,
    sigma1_intercept = -1.00,
    sigma2_intercept = -0.90,
    rho12 = 0.00,
    sd_mu1_intercept = 0.55,
    sd_mu2_intercept = 0.45,
    cor_mu1_mu2_intercept = 0.20,
    sd_sigma1_intercept = 0.45,
    sd_sigma2_intercept = 0.40,
    cor_sigma1_sigma2_intercept = 0.15,
    target_id = row$target_id[[1L]],
    profile_parameter = row$profile_parameter[[1L]],
    target_axis = row$target_axis[[1L]],
    target_truth = row$target_truth[[1L]],
    dgp_id = row$dgp_id[[1L]],
    cell_id = row$cell_id[[1L]],
    execution_rung = row$rung[[1L]]
  )
  list(data = data, truth = truth, fit = lane_b_q2plus_phylo_fit_closure())
}
