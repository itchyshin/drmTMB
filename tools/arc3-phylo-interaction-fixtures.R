# Arc 3 -- mu-side bipartite phylogenetic-interaction fixtures for mc-0321
# (gaussian) and mc-0409 (nbinom2).
#
# WHY THIS FILE EXISTS
# ---------------------
# Both cells target the SAME direct random-effect SD parameter,
# `sd:mu:phylo_interaction(1 | plant:pollinator)`, that mc-0438 (Poisson,
# same target string) already probed for profile feasibility and STOPPED on
# (docs/dev-log/interval-feasibility/results/c8e04258.../arc1-mc0438-profile-
# feasibility/mc-0438/*-receipt.tsv): nonfinite profile endpoints at BOTH
# `pair_groups_64_each_8` and `pair_groups_64_each_20`, despite a converged
# fit with a well-recovered point estimate (0.497 and 0.510 against a true
# 0.45). mc-0438's DGP used STAR trees (`ape::stree(type = "star")`, equal
# branch lengths) for both partites, which makes the phylogenetic covariance
# on each side exactly the identity -- i.e. the "phylogenetic" interaction
# collapses to a plain crossed iid pair random effect with 64 independent
# levels. This file tests whether that STOP is a property of the TARGET
# (pair-level interaction SD, any tree) or specifically of mc-0438's
# star/iid geometry, by trying both a star-tree rung (directly comparable to
# mc-0438) and a genuinely correlated balanced-binary-tree rung (the shape
# already validated for point-fit recovery in
# tests/testthat/test-phylo-interaction.R:339-402, `new_phylo_interaction_
# count_data()`).
#
# DESIGN RATIONALE -- ladder beyond mc-0438
# ------------------------------------------
# mc-0438 tried n_each in {8, 20} at n_plant = n_pollinator = 8 (64 pairs)
# and failed both. This file's builders are parameterised so the runner can
# push n_each well past 20 (40, 80, ...) at the SAME 64-pair star geometry,
# and separately try a smaller, correlated-tree geometry (4 plant x 4
# pollinator = 16 pairs, balanced binary trees) at higher n_each -- fewer,
# but genuinely non-independent, pair levels. Both families draw a genuine
# interaction-level SD of 0.6 (never 0, which would hit the [0, Inf)
# variance-component boundary by construction): comfortably inside 0.4-0.8
# and distinct from mc-0438's 0.45 so recovery is not an artefact of a
# specific numeric coincidence.
#
# `tree1`/`tree2` are returned as bare objects, never pre-evaluated into a
# covariance matrix: `phylo_interaction()` requires its `tree1`/`tree2`
# arguments to be bare local symbols in the formula's own environment
# (R/parse-formula.R:823-830, `is.symbol()` check), the same requirement
# `phylo()`'s `tree` argument imposes (tools/arc2-phylo-sigma-fixtures.R,
# tools/run-arc2-profile-feasibility.R's mc-0274 comment block).
#
# EACH PUBLIC FIXTURE FUNCTION IS FULLY SELF-CONTAINED (no sibling top-level
# helpers): tools/run-arc2-profile-feasibility.R's `source_fixture_builder()`
# sources only the ONE top-level `<-` assignment matching `fixture_name` out
# of this file (never the whole file), the same convention every other Arc 2/
# Arc 3 fixture file in tools/ already follows (e.g.
# tools/arc3-nbinom2-sigma-provider-fixtures.R has four independent builders,
# none calling a shared top-level helper). The tree-building and pair-level
# DGP logic is therefore nested INSIDE each of the two public functions below
# rather than factored out.

#' Gaussian mu-side bipartite phylogenetic-interaction fixture (mc-0321)
#'
#' @param n_plant,n_pollinator Tip counts on each side.
#' @param n_each Observations per plant:pollinator pair (the denominator
#'   mc-0438's STOP was tested against at 8 and 20).
#' @param sd_pair True SD of the phylogenetic-interaction random effect on
#'   mu (identity link).
#' @param tree_type "star" (mc-0438-comparable: equal branch lengths, tip
#'   covariance = identity, so the pair effect collapses to plain iid) or
#'   "balanced" (genuinely correlated tips via a balanced binary tree, the
#'   shape tests/testthat/test-phylo-interaction.R validates for point-fit).
#' @param seed RNG seed.
#' @param resid_sd Residual SD (default 0.4).
#' @return list(data, plant_tree, pollinator_tree, sd_pair, n_pair)
arc3_phylo_interaction_gaussian_fixture <- function(n_plant = 8L,
                                                    n_pollinator = 8L,
                                                    n_each = 8L,
                                                    sd_pair = 0.6,
                                                    tree_type = "star",
                                                    seed = 101L,
                                                    resid_sd = 0.4) {
  tree_type <- match.arg(tree_type, c("star", "balanced"))
  balanced_tree <- function(n_tip, prefix) {
    stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
    edges <- matrix(integer(), ncol = 2L)
    edge_lengths <- numeric()
    next_node <- n_tip + 1L
    build <- function(tips) {
      if (length(tips) == 1L) return(tips)
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
        edge = edges, edge.length = edge_lengths,
        tip.label = paste0(prefix, seq_len(n_tip)), Nnode = n_tip - 1L
      ),
      class = "phylo"
    )
  }
  star_tree <- function(n_tip, prefix) {
    if (!requireNamespace("ape", quietly = TRUE)) {
      stop("ape is required for a phylo_interaction star-tree fixture.", call. = FALSE)
    }
    tree <- ape::stree(n_tip, type = "star")
    tree$tip.label <- paste0(prefix, seq_len(n_tip))
    tree$edge.length <- rep(1, nrow(tree$edge))
    tree
  }
  set.seed(seed)
  build_tree <- if (identical(tree_type, "star")) star_tree else balanced_tree
  plant_tree <- build_tree(n_plant, "plant")
  pollinator_tree <- build_tree(n_pollinator, "poll")
  plant_cov <- drmTMB:::drm_phylo_tip_covariance(plant_tree)
  pollinator_cov <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
  pair_cov <- kronecker(pollinator_cov, plant_cov)
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  pair_effect <- as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair))
  names(pair_effect) <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
  row_id <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[row_id, , drop = FALSE]
  dat$x <- stats::rnorm(nrow(dat))
  eta <- 0.5 - 0.25 * dat$x + pair_effect[paste0(dat$plant, ":", dat$pollinator)]
  dat$y <- eta + stats::rnorm(nrow(dat), sd = resid_sd)
  list(
    data = dat, plant_tree = plant_tree, pollinator_tree = pollinator_tree,
    sd_pair = sd_pair, n_pair = nrow(pair_grid)
  )
}

#' NB2 mu-side bipartite phylogenetic-interaction fixture (mc-0409)
#'
#' @param n_plant,n_pollinator,n_each,sd_pair,tree_type,seed See
#'   `arc3_phylo_interaction_gaussian_fixture()`.
#' @param sigma_nb2 True NB2 dispersion (default 0.35, matching the
#'   test-suite `new_phylo_interaction_count_data()` default).
#' @return list(data, plant_tree, pollinator_tree, sd_pair, n_pair)
arc3_phylo_interaction_nbinom2_fixture <- function(n_plant = 8L,
                                                   n_pollinator = 8L,
                                                   n_each = 8L,
                                                   sd_pair = 0.6,
                                                   tree_type = "star",
                                                   seed = 101L,
                                                   sigma_nb2 = 0.35) {
  tree_type <- match.arg(tree_type, c("star", "balanced"))
  balanced_tree <- function(n_tip, prefix) {
    stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
    edges <- matrix(integer(), ncol = 2L)
    edge_lengths <- numeric()
    next_node <- n_tip + 1L
    build <- function(tips) {
      if (length(tips) == 1L) return(tips)
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
        edge = edges, edge.length = edge_lengths,
        tip.label = paste0(prefix, seq_len(n_tip)), Nnode = n_tip - 1L
      ),
      class = "phylo"
    )
  }
  star_tree <- function(n_tip, prefix) {
    if (!requireNamespace("ape", quietly = TRUE)) {
      stop("ape is required for a phylo_interaction star-tree fixture.", call. = FALSE)
    }
    tree <- ape::stree(n_tip, type = "star")
    tree$tip.label <- paste0(prefix, seq_len(n_tip))
    tree$edge.length <- rep(1, nrow(tree$edge))
    tree
  }
  set.seed(seed)
  build_tree <- if (identical(tree_type, "star")) star_tree else balanced_tree
  plant_tree <- build_tree(n_plant, "plant")
  pollinator_tree <- build_tree(n_pollinator, "poll")
  plant_cov <- drmTMB:::drm_phylo_tip_covariance(plant_tree)
  pollinator_cov <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
  pair_cov <- kronecker(pollinator_cov, plant_cov)
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  pair_effect <- as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair))
  names(pair_effect) <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
  row_id <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[row_id, , drop = FALSE]
  dat$x <- stats::rnorm(nrow(dat))
  eta <- 0.9 - 0.25 * dat$x + pair_effect[paste0(dat$plant, ":", dat$pollinator)]
  dat$nb2 <- stats::rnbinom(nrow(dat), size = 1 / sigma_nb2^2, mu = exp(eta))
  list(
    data = dat, plant_tree = plant_tree, pollinator_tree = pollinator_tree,
    sd_pair = sd_pair, n_pair = nrow(pair_grid)
  )
}
