validate_phylo_tree <- function(tree, species = NULL,
                                tolerance = sqrt(.Machine$double.eps)) {
  if (!inherits(tree, "phylo")) {
    cli::cli_abort(c(
      "{.arg tree} must be a phylogeny object.",
      "x" = "Use an object with class {.cls phylo}, branch lengths, and tip labels."
    ))
  }
  if (!is.list(tree)) {
    cli::cli_abort("{.arg tree} must be a list-like {.cls phylo} object.")
  }

  edge <- tree$edge
  edge_length <- tree$edge.length
  tip_label <- tree$tip.label
  n_node <- tree$Nnode

  if (!is.character(tip_label) || length(tip_label) < 2L ||
      anyNA(tip_label) || any(!nzchar(tip_label))) {
    cli::cli_abort("{.arg tree} must contain at least two non-missing tip labels.")
  }
  if (anyDuplicated(tip_label)) {
    duplicate <- tip_label[duplicated(tip_label)][[1L]]
    cli::cli_abort(c(
      "{.arg tree} tip labels must be unique.",
      "x" = "Duplicated tip label: {.val {duplicate}}."
    ))
  }
  n_tip <- length(tip_label)

  if (!is.numeric(n_node) || length(n_node) != 1L ||
      is.na(n_node) || n_node < 1L || n_node != as.integer(n_node)) {
    cli::cli_abort("{.arg tree} must contain a scalar positive integer {.field Nnode}.")
  }
  n_node <- as.integer(n_node)
  n_total <- n_tip + n_node

  if (!is.matrix(edge) || ncol(edge) != 2L || nrow(edge) < 2L ||
      !is.numeric(edge) || anyNA(edge)) {
    cli::cli_abort("{.arg tree$edge} must be a two-column numeric matrix.")
  }
  if (any(edge != as.integer(edge)) || any(edge < 1L) || any(edge > n_total)) {
    cli::cli_abort("{.arg tree$edge} contains invalid node indices.")
  }
  edge <- matrix(as.integer(edge), ncol = 2L)

  if (!is.numeric(edge_length) || length(edge_length) != nrow(edge) ||
      anyNA(edge_length) || any(!is.finite(edge_length))) {
    cli::cli_abort("{.arg tree} must contain finite branch lengths for every edge.")
  }
  if (any(edge_length < 0)) {
    cli::cli_abort("{.arg tree} branch lengths must be non-negative.")
  }

  parent <- edge[, 1L]
  child <- edge[, 2L]
  if (any(parent <= n_tip)) {
    cli::cli_abort("{.arg tree} is invalid: tip nodes cannot be parent nodes.")
  }
  if (anyDuplicated(child)) {
    cli::cli_abort("{.arg tree} is invalid: at least one node has more than one parent.")
  }

  root <- setdiff(unique(parent), child)
  if (length(root) != 1L) {
    cli::cli_abort("{.arg tree} must have exactly one root node.")
  }
  root <- root[[1L]]

  depths <- phylo_node_depths(edge, edge_length, n_total, root)
  if (anyNA(depths)) {
    cli::cli_abort("{.arg tree} must be connected from a single root.")
  }

  tip_depths <- depths[seq_len(n_tip)]
  height <- tip_depths[[1L]]
  scale <- max(1, abs(height), abs(tip_depths))
  if (max(abs(tip_depths - height)) > tolerance * scale) {
    cli::cli_abort(c(
      "{.arg tree} must be ultrametric.",
      "x" = "Root-to-tip distances differ by more than {.val {tolerance}}."
    ))
  }
  if (height <= 0) {
    cli::cli_abort("{.arg tree} must have positive root-to-tip height.")
  }

  species_levels <- validate_phylo_species(species, tip_label)
  species_index <- if (is.null(species_levels)) {
    NULL
  } else {
    match(species_levels, tip_label)
  }

  list(
    n_tip = n_tip,
    n_node = n_node,
    root = root,
    tip_label = tip_label,
    height = height,
    node_depth = depths,
    species_levels = species_levels,
    species_index = species_index
  )
}

validate_phylo_species <- function(species, tip_label) {
  if (is.null(species)) {
    return(NULL)
  }
  species <- as.character(species)
  if (length(species) == 0L) {
    cli::cli_abort("{.arg species} must contain at least one observed species.")
  }
  if (anyNA(species) || any(!nzchar(species))) {
    cli::cli_abort("{.arg species} must not contain missing or empty labels.")
  }

  species_levels <- unique(species)
  missing <- setdiff(species_levels, tip_label)
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "All observed species must be represented in {.arg tree}.",
      "x" = "Missing tip label{?s}: {.val {missing}}."
    ))
  }
  species_levels
}

phylo_node_depths <- function(edge, edge_length, n_total, root) {
  children <- split(seq_len(nrow(edge)), edge[, 1L])
  depths <- rep(NA_real_, n_total)
  depths[[root]] <- 0
  stack <- root

  while (length(stack) > 0L) {
    node <- stack[[length(stack)]]
    stack <- stack[-length(stack)]
    child_edges <- children[[as.character(node)]]
    if (is.null(child_edges)) {
      next
    }
    for (edge_id in child_edges) {
      child <- edge[edge_id, 2L]
      depths[[child]] <- depths[[node]] + edge_length[[edge_id]]
      stack <- c(stack, child)
    }
  }

  depths
}

drm_phylo_tip_covariance <- function(tree, species = NULL,
                                     correlation = TRUE,
                                     tolerance = sqrt(.Machine$double.eps)) {
  info <- validate_phylo_tree(tree, species = species, tolerance = tolerance)
  edge <- matrix(as.integer(tree$edge), ncol = 2L)
  parent <- integer(info$n_tip + info$n_node)
  parent[edge[, 2L]] <- edge[, 1L]
  nodes <- if (is.null(info$species_index)) {
    seq_len(info$n_tip)
  } else {
    info$species_index
  }
  labels <- if (is.null(info$species_levels)) {
    info$tip_label
  } else {
    info$species_levels
  }

  ancestors <- lapply(nodes, phylo_node_ancestors, parent = parent)
  covariance <- matrix(0, nrow = length(nodes), ncol = length(nodes))
  for (i in seq_along(nodes)) {
    for (j in seq_len(i)) {
      shared <- intersect(ancestors[[i]], ancestors[[j]])
      covariance[i, j] <- covariance[j, i] <- max(info$node_depth[shared])
    }
  }

  if (correlation) {
    covariance <- covariance / info$height
  }
  dimnames(covariance) <- list(labels, labels)
  covariance
}

phylo_node_ancestors <- function(node, parent) {
  out <- node
  while (parent[[node]] != 0L) {
    node <- parent[[node]]
    out <- c(out, node)
  }
  out
}
