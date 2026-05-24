phase18_poisson_phylo_q1_conditions <- function(
  n_species = c(20L, 40L),
  n_per_species = c(4L, 8L),
  sd_phylo = c(0, 0.25, 0.60),
  mean_count = c(1.5, 4.0),
  beta_mu_x = -0.20,
  tree_shape = c("balanced", "mildly_uneven")
) {
  conditions <- expand.grid(
    n_species = as.integer(n_species),
    n_per_species = as.integer(n_per_species),
    sd_phylo = sd_phylo,
    mean_count = mean_count,
    beta_mu_x = beta_mu_x,
    tree_shape = tree_shape,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions
}

phase18_dgp_poisson_phylo_q1 <- function(
  n_species,
  n_per_species,
  beta_mu = c("(Intercept)" = log(2.5), x = -0.20),
  sd_phylo = 0.35,
  tree_shape = "balanced",
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_species, "n_species")
  assert_positive_whole_number(n_per_species, "n_per_species")
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  phase18_assert_nonnegative_number(sd_phylo, "sd_phylo")
  tree_shape <- phase18_poisson_phylo_q1_tree_shape(tree_shape)

  draw <- function() {
    tree <- phase18_poisson_phylo_q1_tree(n_species, tree_shape)
    covariance <- phase18_poisson_phylo_q1_tip_correlation(tree)
    phylo_effect <- as.vector(
      (t(chol(covariance)) %*% stats::rnorm(n_species)) * sd_phylo
    )
    names(phylo_effect) <- tree$tip.label

    species <- factor(
      rep(tree$tip.label, each = n_per_species),
      levels = tree$tip.label
    )
    x <- rep(seq(-1, 1, length.out = n_per_species), times = n_species)
    eta <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x"]] * x +
        phylo_effect[as.character(species)]
    )
    mu <- exp(eta)
    count <- stats::rpois(length(mu), lambda = mu)

    dat <- data.frame(
      count = count,
      x = x,
      species = species,
      eta_mu = eta,
      mu = mu,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "poisson_phylo_q1",
      beta_mu = beta_mu,
      sd = stats::setNames(sd_phylo, "phylo(1 | species)"),
      tree = tree,
      tree_shape = tree_shape,
      n_species = n_species,
      n_per_species = n_per_species
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_poisson_phylo_q1_tree <- function(n_species, tree_shape = "balanced") {
  assert_positive_whole_number(n_species, "n_species")
  if (n_species < 2L) {
    stop("`n_species` must be at least 2.", call. = FALSE)
  }
  tree_shape <- phase18_poisson_phylo_q1_tree_shape(tree_shape)

  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_species + 1L

  split_index <- function(n_tip) {
    if (identical(tree_shape, "balanced")) {
      return(floor(n_tip / 2L))
    }
    max(1L, min(n_tip - 1L, floor(n_tip / 3L)))
  }

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(list(node = tips, height = 0))
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- split_index(length(tips))
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    height <- max(left$height, right$height) + 1
    edges <<- rbind(edges, c(node, left$node), c(node, right$node))
    edge_lengths <<- c(
      edge_lengths,
      height - left$height,
      height - right$height
    )
    list(node = node, height = height)
  }

  build(seq_len(n_species))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_species)),
      Nnode = n_species - 1L
    ),
    class = "phylo"
  )
}

phase18_poisson_phylo_q1_tip_correlation <- function(tree) {
  covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  diag_sd <- sqrt(diag(covariance))
  covariance / outer(diag_sd, diag_sd)
}

phase18_poisson_phylo_q1_tree_shape <- function(tree_shape) {
  ok <- c("balanced", "mildly_uneven")
  if (
    !is.character(tree_shape) ||
      length(tree_shape) != 1L ||
      !tree_shape %in% ok
  ) {
    stop(
      "`tree_shape` must be \"balanced\" or \"mildly_uneven\".",
      call. = FALSE
    )
  }
  tree_shape
}

phase18_assert_nonnegative_number <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x >= 0
  if (!ok) {
    stop("`", name, "` must be one non-negative finite number.", call. = FALSE)
  }
  invisible(x)
}
