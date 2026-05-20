validate_phylo_tree <- function(
  tree,
  species = NULL,
  tolerance = sqrt(.Machine$double.eps)
) {
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

  if (
    !is.character(tip_label) ||
      length(tip_label) < 2L ||
      anyNA(tip_label) ||
      any(!nzchar(tip_label))
  ) {
    cli::cli_abort(
      "{.arg tree} must contain at least two non-missing tip labels."
    )
  }
  if (anyDuplicated(tip_label)) {
    duplicate <- tip_label[duplicated(tip_label)][[1L]]
    cli::cli_abort(c(
      "{.arg tree} tip labels must be unique.",
      "x" = "Duplicated tip label: {.val {duplicate}}."
    ))
  }
  n_tip <- length(tip_label)

  if (
    !is.numeric(n_node) ||
      length(n_node) != 1L ||
      is.na(n_node) ||
      n_node < 1L ||
      n_node != as.integer(n_node)
  ) {
    cli::cli_abort(
      "{.arg tree} must contain a scalar positive integer {.field Nnode}."
    )
  }
  n_node <- as.integer(n_node)
  n_total <- n_tip + n_node

  if (
    !is.matrix(edge) ||
      ncol(edge) != 2L ||
      nrow(edge) < 2L ||
      !is.numeric(edge) ||
      anyNA(edge)
  ) {
    cli::cli_abort("{.arg tree$edge} must be a two-column numeric matrix.")
  }
  if (any(edge != as.integer(edge)) || any(edge < 1L) || any(edge > n_total)) {
    cli::cli_abort("{.arg tree$edge} contains invalid node indices.")
  }
  edge <- matrix(as.integer(edge), ncol = 2L)

  if (
    !is.numeric(edge_length) ||
      length(edge_length) != nrow(edge) ||
      anyNA(edge_length) ||
      any(!is.finite(edge_length))
  ) {
    cli::cli_abort(
      "{.arg tree} must contain finite branch lengths for every edge."
    )
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
    cli::cli_abort(
      "{.arg tree} is invalid: at least one node has more than one parent."
    )
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

  species_values <- if (is.null(species)) {
    NULL
  } else {
    as.character(species)
  }
  species_levels <- validate_phylo_species(species_values, tip_label)
  species_index <- if (is.null(species_levels)) {
    NULL
  } else {
    match(species_levels, tip_label)
  }
  observation_species_index <- if (is.null(species_levels)) {
    NULL
  } else {
    match(species_values, species_levels)
  }

  list(
    n_tip = n_tip,
    n_node = n_node,
    root = root,
    tip_label = tip_label,
    height = height,
    node_depth = depths,
    species_levels = species_levels,
    species_index = species_index,
    observation_species_index = observation_species_index
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

drm_phylo_tip_covariance <- function(
  tree,
  species = NULL,
  correlation = TRUE,
  tolerance = sqrt(.Machine$double.eps)
) {
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

drm_phylo_augmented_precision <- function(
  tree,
  species = NULL,
  correlation = TRUE,
  tolerance = sqrt(.Machine$double.eps)
) {
  if (
    !is.logical(correlation) || length(correlation) != 1L || is.na(correlation)
  ) {
    cli::cli_abort("{.arg correlation} must be {.code TRUE} or {.code FALSE}.")
  }
  info <- validate_phylo_tree(tree, species = species, tolerance = tolerance)
  edge <- matrix(as.integer(tree$edge), ncol = 2L)
  edge_length <- tree$edge.length
  if (any(edge_length <= 0)) {
    cli::cli_abort(
      "{.arg tree} branch lengths must be positive to build sparse precision."
    )
  }

  n_total <- info$n_tip + info$n_node
  included_nodes <- setdiff(seq_len(n_total), info$root)
  node_index <- integer(n_total)
  node_index[included_nodes] <- seq_along(included_nodes)
  n_aug <- length(included_nodes)

  rows <- integer(0)
  cols <- integer(0)
  values <- numeric(0)
  for (edge_id in seq_len(nrow(edge))) {
    parent <- edge[edge_id, 1L]
    child <- edge[edge_id, 2L]
    child_index <- node_index[[child]]
    weight <- 1 / edge_length[[edge_id]]

    rows <- c(rows, child_index)
    cols <- c(cols, child_index)
    values <- c(values, weight)

    if (parent != info$root) {
      parent_index <- node_index[[parent]]
      rows <- c(rows, parent_index, parent_index, child_index)
      cols <- c(cols, parent_index, child_index, parent_index)
      values <- c(values, weight, -weight, -weight)
    }
  }

  scale <- if (isTRUE(correlation)) {
    info$height
  } else {
    1
  }
  node_labels <- phylo_augmented_node_labels(included_nodes, info$tip_label)
  precision <- Matrix::drop0(Matrix::sparseMatrix(
    i = rows,
    j = cols,
    x = scale * values,
    dims = c(n_aug, n_aug),
    dimnames = list(node_labels, node_labels)
  ))

  tip_node_index <- node_index[seq_len(info$n_tip)]
  names(tip_node_index) <- info$tip_label
  species_node_index <- if (is.null(info$species_index)) {
    NULL
  } else {
    out <- tip_node_index[info$species_index]
    names(out) <- info$species_levels
    out
  }

  out <- list(
    precision = precision,
    log_det_precision = n_aug * log(scale) - sum(log(edge_length)),
    correlation = isTRUE(correlation),
    scale = scale,
    node_id = included_nodes,
    node_index = node_index,
    node_labels = node_labels,
    tip_label = info$tip_label,
    tip_node_index = tip_node_index,
    species_levels = info$species_levels,
    species_tip_index = info$species_index,
    species_node_index = species_node_index,
    observation_species_index = info$observation_species_index,
    root = info$root,
    height = info$height
  )
  class(out) <- "drm_phylo_precision"
  out
}

drm_known_relatedness_precision <- function(
  matrix,
  group,
  matrix_type = c("precision", "covariance"),
  marker = "relmat",
  object = "Q",
  group_name = "id",
  tolerance = sqrt(.Machine$double.eps)
) {
  matrix_type <- match.arg(matrix_type)
  group <- as.character(group)
  if (length(group) == 0L || anyNA(group) || any(!nzchar(group))) {
    cli::cli_abort(
      "{.fn {marker}} grouping variable {.field {group_name}} must contain non-missing labels."
    )
  }

  mat <- drm_standardize_relatedness_matrix(
    matrix,
    marker = marker,
    object = object
  )
  labels <- rownames(mat)
  observed <- unique(group)
  missing <- setdiff(observed, labels)
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "{.fn {marker}} matrix {.field {object}} does not cover every observed {.field {group_name}} level.",
      "x" = "Missing level{?s}: {.val {missing}}."
    ))
  }

  mat <- mat[labels, labels, drop = FALSE]
  mat_sparse <- Matrix::Matrix(mat, sparse = TRUE)
  if (!Matrix::isSymmetric(mat_sparse, tol = tolerance)) {
    cli::cli_abort(c(
      "{.fn {marker}} matrix {.field {object}} must be symmetric.",
      "x" = "Rows and columns should use the same relatedness scale and labels."
    ))
  }

  precision <- if (identical(matrix_type, "precision")) {
    drm_validate_known_precision_matrix(
      mat_sparse,
      marker = marker,
      object = object
    )
  } else {
    drm_covariance_to_known_precision(
      mat_sparse,
      marker = marker,
      object = object
    )
  }

  species_node_index <- match(observed, labels)
  names(species_node_index) <- observed
  out <- list(
    precision = precision$precision,
    log_det_precision = precision$log_det_precision,
    matrix_type = matrix_type,
    object = object,
    node_labels = labels,
    species_levels = observed,
    species_node_index = species_node_index,
    observation_species_index = match(group, observed)
  )
  class(out) <- "drm_known_relatedness_precision"
  out
}

drm_standardize_relatedness_matrix <- function(matrix, marker, object) {
  if (inherits(matrix, "Matrix")) {
    if (!methods::is(matrix, "dMatrix")) {
      cli::cli_abort(
        "{.fn {marker}} matrix {.field {object}} must be numeric."
      )
    }
    mat <- matrix
  } else {
    if (is.data.frame(matrix)) {
      matrix <- as.matrix(matrix)
    }
    if (!is.matrix(matrix) || !is.numeric(matrix)) {
      cli::cli_abort(c(
        "{.fn {marker}} matrix {.field {object}} must be a numeric square matrix.",
        "i" = "Use row and column names that match the grouping variable."
      ))
    }
    mat <- matrix
  }

  if (length(dim(mat)) != 2L || nrow(mat) != ncol(mat) || nrow(mat) < 2L) {
    cli::cli_abort(
      "{.fn {marker}} matrix {.field {object}} must be a square matrix with at least two rows."
    )
  }
  if (any(!is.finite(mat))) {
    cli::cli_abort(
      "{.fn {marker}} matrix {.field {object}} must contain finite numeric values."
    )
  }

  row_labels <- rownames(mat)
  col_labels <- colnames(mat)
  if (
    is.null(row_labels) ||
      is.null(col_labels) ||
      anyNA(row_labels) ||
      anyNA(col_labels) ||
      any(!nzchar(row_labels)) ||
      any(!nzchar(col_labels))
  ) {
    cli::cli_abort(
      "{.fn {marker}} matrix {.field {object}} must have non-empty row and column names."
    )
  }
  if (anyDuplicated(row_labels) || anyDuplicated(col_labels)) {
    cli::cli_abort(
      "{.fn {marker}} matrix {.field {object}} row and column names must be unique."
    )
  }
  if (!setequal(row_labels, col_labels)) {
    cli::cli_abort(c(
      "{.fn {marker}} matrix {.field {object}} row and column names must match.",
      "x" = "Rows without matching columns: {.val {setdiff(row_labels, col_labels)}}.",
      "x" = "Columns without matching rows: {.val {setdiff(col_labels, row_labels)}}."
    ))
  }
  mat[, row_labels, drop = FALSE]
}

drm_validate_known_precision_matrix <- function(matrix, marker, object) {
  precision <- Matrix::forceSymmetric(
    Matrix::Matrix(matrix, sparse = TRUE),
    uplo = "U"
  )
  chol_precision <- tryCatch(
    Matrix::Cholesky(precision, LDL = FALSE, perm = FALSE),
    error = function(e) NULL
  )
  if (is.null(chol_precision)) {
    cli::cli_abort(c(
      "{.fn {marker}} precision matrix {.field {object}} must be positive definite.",
      "x" = "Check the matrix scale, ordering, and any duplicated levels."
    ))
  }
  determinant <- tryCatch(
    Matrix::determinant(precision, logarithm = TRUE),
    error = function(e) NULL
  )
  if (
    is.null(determinant) ||
      !is.finite(as.numeric(determinant$modulus)) ||
      determinant$sign <= 0
  ) {
    cli::cli_abort(
      "{.fn {marker}} precision matrix {.field {object}} must have a positive finite determinant."
    )
  }
  list(
    precision = Matrix::drop0(precision),
    log_det_precision = as.numeric(determinant$modulus)
  )
}

drm_covariance_to_known_precision <- function(matrix, marker, object) {
  covariance <- as.matrix(Matrix::forceSymmetric(
    Matrix::Matrix(matrix, sparse = FALSE),
    uplo = "U"
  ))
  chol_covariance <- tryCatch(
    chol(covariance),
    error = function(e) NULL
  )
  if (is.null(chol_covariance)) {
    cli::cli_abort(c(
      "{.fn {marker}} covariance matrix {.field {object}} must be positive definite.",
      "x" = "For large or sparse relatedness models, supply a precision matrix instead."
    ))
  }
  precision <- chol2inv(chol_covariance)
  dimnames(precision) <- dimnames(covariance)
  list(
    precision = Matrix::drop0(Matrix::Matrix(precision, sparse = TRUE)),
    log_det_precision = -2 * sum(log(diag(chol_covariance)))
  )
}

drm_phylo_precision_nll <- function(effect, precision, log_sd = 0) {
  if (!inherits(precision, "drm_phylo_precision")) {
    cli::cli_abort(
      "{.arg precision} must come from {.fn drm_phylo_augmented_precision}."
    )
  }
  effect <- as.numeric(effect)
  n_effect <- length(effect)
  if (
    n_effect != nrow(precision$precision) ||
      anyNA(effect) ||
      any(!is.finite(effect))
  ) {
    cli::cli_abort(
      "{.arg effect} must be a finite numeric vector matching the precision size."
    )
  }
  if (
    !is.numeric(log_sd) ||
      length(log_sd) != 1L ||
      is.na(log_sd) ||
      !is.finite(log_sd)
  ) {
    cli::cli_abort("{.arg log_sd} must be a finite numeric scalar.")
  }

  quadratic <- sum(effect * as.numeric(precision$precision %*% effect))
  0.5 *
    (n_effect *
      log(2 * pi) +
      2 * n_effect * log_sd -
      precision$log_det_precision +
      exp(-2 * log_sd) * quadratic)
}

drm_phylo_correlated_precision_nll <- function(effect, precision, covariance) {
  if (!inherits(precision, "drm_phylo_precision")) {
    cli::cli_abort(
      "{.arg precision} must come from {.fn drm_phylo_augmented_precision}."
    )
  }
  if (
    !is.matrix(effect) ||
      !is.numeric(effect) ||
      nrow(effect) != nrow(precision$precision) ||
      anyNA(effect) ||
      any(!is.finite(effect))
  ) {
    cli::cli_abort(
      "{.arg effect} must be a finite numeric matrix with one row per phylogenetic precision node."
    )
  }
  if (
    !is.matrix(covariance) ||
      !is.numeric(covariance) ||
      nrow(covariance) != ncol(covariance) ||
      nrow(covariance) != ncol(effect) ||
      anyNA(covariance) ||
      any(!is.finite(covariance))
  ) {
    cli::cli_abort(
      "{.arg covariance} must be a finite square numeric matrix matching the effect columns."
    )
  }
  covariance_chol <- tryCatch(
    chol(covariance),
    error = function(e) NULL
  )
  if (is.null(covariance_chol)) {
    cli::cli_abort("{.arg covariance} must be positive definite.")
  }

  n_node <- nrow(effect)
  q <- ncol(effect)
  covariance_inverse <- chol2inv(covariance_chol)
  quadratic_matrix <- crossprod(
    effect,
    as.matrix(precision$precision %*% effect)
  )
  quadratic <- sum(covariance_inverse * quadratic_matrix)
  log_det_covariance <- 2 * sum(log(diag(covariance_chol)))

  0.5 *
    (n_node *
      q *
      log(2 * pi) +
      n_node * log_det_covariance -
      q * precision$log_det_precision +
      quadratic)
}

drm_phylo_q4_endpoint_pairs <- function(
  group,
  responses = c("y1", "y2"),
  block = "phylo"
) {
  if (
    !is.character(group) ||
      length(group) != 1L ||
      is.na(group) ||
      !nzchar(group)
  ) {
    cli::cli_abort("{.arg group} must be a single non-empty string.")
  }
  if (
    !is.character(responses) ||
      length(responses) != 2L ||
      anyNA(responses) ||
      any(!nzchar(responses))
  ) {
    cli::cli_abort(
      "{.arg responses} must contain two non-empty response names."
    )
  }
  if (
    !is.character(block) ||
      length(block) != 1L ||
      is.na(block) ||
      !nzchar(block)
  ) {
    cli::cli_abort("{.arg block} must be a single non-empty string.")
  }

  from_dpar <- c("mu1", "mu1", "mu1", "mu2", "mu2", "sigma1")
  to_dpar <- c("mu2", "sigma1", "sigma2", "sigma1", "sigma2", "sigma2")
  from_response <- phylo_endpoint_response(from_dpar, responses)
  to_response <- phylo_endpoint_response(to_dpar, responses)
  data.frame(
    level = "phylogenetic",
    group = group,
    block = block,
    from_dpar = from_dpar,
    to_dpar = to_dpar,
    from_coef = "(Intercept)",
    to_coef = "(Intercept)",
    from_response = from_response,
    to_response = to_response,
    class = c(
      "mean-mean",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "mean-scale",
      "scale-scale"
    ),
    parameter = paste0(
      "cor(",
      from_dpar,
      ":(Intercept),",
      to_dpar,
      ":(Intercept) | ",
      block,
      " | ",
      group,
      ")"
    ),
    estimate = NA_real_,
    min = NA_real_,
    max = NA_real_,
    n_values = 0L,
    link_estimate = NA_real_,
    link_min = NA_real_,
    link_max = NA_real_,
    modelled = FALSE,
    status = "planned",
    support_note = "planned_bivariate_phylogenetic_q4",
    stringsAsFactors = FALSE
  )
}

phylo_endpoint_response <- function(dpar, responses) {
  ifelse(grepl("1$", dpar), responses[[1L]], responses[[2L]])
}

phylo_augmented_node_labels <- function(node_id, tip_label) {
  labels <- paste0("node", node_id)
  tip <- node_id <= length(tip_label)
  labels[tip] <- tip_label[node_id[tip]]
  labels
}

phylo_node_ancestors <- function(node, parent) {
  out <- node
  while (parent[[node]] != 0L) {
    node <- parent[[node]]
    out <- c(out, node)
  }
  out
}
