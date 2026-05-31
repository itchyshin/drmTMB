phase18_phylo_mu_slope_conditions <- function(
  n_tip = c(8L, 16L),
  n_each = c(7L, 9L),
  sd_intercept = 0.55,
  sd_slope = 0.32,
  beta_mu_intercept = 0.40,
  beta_mu_x = -0.25,
  sigma = 0.22
) {
  conditions <- expand.grid(
    n_tip = as.integer(n_tip),
    n_each = as.integer(n_each),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$sd_intercept <- sd_intercept
  conditions$sd_slope <- sd_slope
  conditions$beta_mu_intercept <- beta_mu_intercept
  conditions$beta_mu_x <- beta_mu_x
  conditions$sigma <- sigma
  conditions
}

phase18_dgp_phylo_mu_slope_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_tip",
    "n_each",
    "sd_intercept",
    "sd_slope",
    "beta_mu_intercept",
    "beta_mu_x",
    "sigma"
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

  phase18_dgp_phylo_mu_slope(
    n_tip = cell$n_tip[[1L]],
    n_each = cell$n_each[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    sigma = cell$sigma[[1L]],
    sd = c(
      "(Intercept)" = cell$sd_intercept[[1L]],
      x = cell$sd_slope[[1L]]
    ),
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_dgp_phylo_mu_slope <- function(
  n_tip,
  n_each,
  beta_mu = c("(Intercept)" = 0.40, x = -0.25),
  sigma = 0.22,
  sd = c("(Intercept)" = 0.55, x = 0.32),
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_tip, "n_tip")
  assert_positive_whole_number(n_each, "n_each")
  if (n_tip < 2L) {
    stop("`n_tip` must be at least 2.", call. = FALSE)
  }
  if (log2(n_tip) != floor(log2(n_tip))) {
    stop("`n_tip` must be a power of two.", call. = FALSE)
  }
  if (n_each < 2L) {
    stop("`n_each` must be at least 2.", call. = FALSE)
  }
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  sd <- phase18_named_pair(sd, c("(Intercept)", "x"), "sd")
  if (any(sd <= 0)) {
    stop("`sd` values must be positive.", call. = FALSE)
  }
  assert_phase18_positive_number(sigma, "sigma")

  draw <- function() {
    tree <- phase18_phylo_mu_slope_tree(n_tip)
    A <- drmTMB:::drm_phylo_tip_covariance(tree)

    phylo_intercept <- as.vector(
      t(chol(A)) %*% stats::rnorm(n_tip, sd = sd[["(Intercept)"]])
    )
    phylo_slope <- as.vector(
      t(chol(A)) %*% stats::rnorm(n_tip, sd = sd[["x"]])
    )
    names(phylo_intercept) <- tree$tip.label
    names(phylo_slope) <- tree$tip.label

    species <- rep(tree$tip.label, each = n_each)
    x <- rep(seq(-1, 1, length.out = n_each), times = n_tip)
    mu <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x"]] * x +
        phylo_intercept[species] +
        phylo_slope[species] * x
    )
    y <- stats::rnorm(length(species), mean = mu, sd = sigma)

    dat <- data.frame(
      y = y,
      x = x,
      species = species,
      mu = mu,
      sigma = sigma,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "phylo_mu_slope",
      beta_mu = beta_mu,
      sigma = sigma,
      sd = stats::setNames(
        sd,
        c("phylo(1 | species)", "phylo(0 + x | species)")
      ),
      phylo_intercept = phylo_intercept,
      phylo_slope = phylo_slope,
      tree = tree,
      A = A,
      n_tip = n_tip,
      n_each = n_each
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_phylo_mu_slope_tree <- function(n_tip) {
  assert_positive_whole_number(n_tip, "n_tip")
  if (n_tip < 2L || log2(n_tip) != floor(log2(n_tip))) {
    stop("`n_tip` must be a power of two and at least 2.", call. = FALSE)
  }

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
