empty_gaussian_aggregation <- function() {
  list(
    enabled = FALSE,
    n_original = 0L,
    n_cells = 0L,
    row_to_cell = integer(),
    cell_first_row = integer(),
    n = numeric(),
    sum_y = numeric(),
    mean_y = numeric(),
    css = numeric(),
    X_mu = matrix(0, nrow = 0L, ncol = 0L),
    X_sigma = matrix(0, nrow = 0L, ncol = 0L),
    offset_mu = numeric(),
    offset_sigma = numeric()
  )
}

drm_gaussian_aggregation <- function(
  y,
  X_mu,
  X_sigma,
  weights = rep(1, length(y)),
  offset_mu = rep(0, length(y)),
  offset_sigma = rep(0, length(y))
) {
  X_mu <- as.matrix(X_mu)
  X_sigma <- as.matrix(X_sigma)
  y <- as.numeric(y)
  weights <- as.numeric(weights)
  offset_mu <- as.numeric(offset_mu)
  offset_sigma <- as.numeric(offset_sigma)

  drm_validate_gaussian_aggregation_input(
    y,
    X_mu,
    X_sigma,
    weights,
    offset_mu,
    offset_sigma
  )
  drm_validate_gaussian_aggregation_weights(weights)

  key_matrix <- cbind(X_mu, X_sigma, offset_mu, offset_sigma)
  key <- apply(
    key_matrix,
    1L,
    function(row) {
      paste(
        format(row, digits = 17L, scientific = TRUE, trim = TRUE),
        collapse = "\r"
      )
    }
  )
  cell_key <- unique(key)
  row_to_cell <- match(key, cell_key)
  cell_first_row <- match(cell_key, key)
  cell_rows <- seq_along(cell_key)
  agg_sum <- function(value) {
    as.numeric(rowsum(value, row_to_cell, reorder = FALSE)[cell_rows, 1L])
  }

  n <- agg_sum(rep(1, length(y)))
  sum_y <- agg_sum(y)
  mean_y <- sum_y / n
  # Corrected (centered) sum of squares computed directly from the raw y
  # values. Forming this as sum_y2 - sum_y^2 / n would reintroduce the
  # catastrophic cancellation this path exists to avoid, so accumulate the
  # centered residuals per cell instead.
  css <- agg_sum((y - mean_y[row_to_cell])^2)

  list(
    enabled = TRUE,
    n_original = length(y),
    n_cells = length(cell_key),
    row_to_cell = as.integer(row_to_cell),
    cell_first_row = as.integer(cell_first_row),
    n = n,
    sum_y = sum_y,
    mean_y = mean_y,
    css = css,
    X_mu = X_mu[cell_first_row, , drop = FALSE],
    X_sigma = X_sigma[cell_first_row, , drop = FALSE],
    offset_mu = offset_mu[cell_first_row],
    offset_sigma = offset_sigma[cell_first_row]
  )
}

drm_validate_gaussian_aggregation_input <- function(
  y,
  X_mu,
  X_sigma,
  weights,
  offset_mu,
  offset_sigma
) {
  n <- length(y)
  if (n == 0L) {
    cli::cli_abort("Gaussian aggregation requires at least one response row.")
  }
  if (nrow(X_mu) != n || nrow(X_sigma) != n) {
    cli::cli_abort(
      "Gaussian aggregation requires {.code y}, {.code X_mu}, and {.code X_sigma} to have matching row counts."
    )
  }
  if (
    length(weights) != n ||
      length(offset_mu) != n ||
      length(offset_sigma) != n
  ) {
    cli::cli_abort(
      "Gaussian aggregation weights and offsets must have one value per response row."
    )
  }
  if (
    any(!is.finite(y)) ||
      any(!is.finite(X_mu)) ||
      any(!is.finite(X_sigma)) ||
      any(!is.finite(weights)) ||
      any(!is.finite(offset_mu)) ||
      any(!is.finite(offset_sigma))
  ) {
    cli::cli_abort(
      "Gaussian aggregation requires finite response, design, weight, and offset values."
    )
  }
  invisible(TRUE)
}

drm_validate_gaussian_aggregation_weights <- function(weights) {
  if (!all(weights == 1)) {
    cli::cli_abort(c(
      "Gaussian aggregation currently requires unit likelihood weights.",
      "i" = "Fit without {.code aggregate_gaussian = TRUE}, or remove {.arg weights} until weighted sufficient statistics are implemented."
    ))
  }
  invisible(TRUE)
}

validate_gaussian_aggregation_gaussian <- function(
  meta,
  mu_phylo,
  mu_phylo_interaction = list(term = NULL),
  mu_spatial,
  mu_animal,
  mu_relmat,
  mu_re,
  sigma_re,
  sd_mu_entries,
  sd_phylo_entries,
  sparse_mu
) {
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "Gaussian aggregation is not implemented with known sampling covariance yet.",
      "i" = "Refit without {.code meta_V()} or set {.code aggregate_gaussian = FALSE}."
    ))
  }
  structured_terms <- list(
    mu_phylo$term,
    mu_phylo_interaction$term,
    mu_spatial$term,
    mu_animal$term,
    mu_relmat$term
  )
  if (any(!vapply(structured_terms, is.null, logical(1)))) {
    cli::cli_abort(c(
      "Gaussian aggregation is not implemented with structured random effects yet.",
      "i" = "Fit the phylogenetic, spatial, animal, or relatedness model without row aggregation in this phase."
    ))
  }
  if (length(mu_re$terms) > 0L || length(sigma_re$terms) > 0L) {
    cli::cli_abort(c(
      "Gaussian aggregation is not implemented with ordinary random effects yet.",
      "i" = "Use a fixed-effect Gaussian model first, or set {.code aggregate_gaussian = FALSE}."
    ))
  }
  if (length(sd_mu_entries) > 0L || length(sd_phylo_entries) > 0L) {
    cli::cli_abort(c(
      "Gaussian aggregation is not implemented with direct random-effect SD models yet.",
      "i" = "Use the full-row path for {.code sd()} and {.code sd_phylo()} models in this phase."
    ))
  }
  if (isTRUE(sparse_mu)) {
    cli::cli_abort(c(
      "Gaussian aggregation cannot be combined with sparse fixed-effect matrices yet.",
      "i" = "Use either {.code aggregate_gaussian = TRUE} or {.code sparse_fixed = TRUE}, but not both in this phase."
    ))
  }
  invisible(TRUE)
}

drm_gaussian_aggregation_tmb_data <- function(spec) {
  aggregation <- if (is.list(spec$aggregation)) {
    spec$aggregation$gaussian
  } else {
    NULL
  }
  use_aggregation <- is.list(aggregation) && isTRUE(aggregation$enabled)
  dummy_matrix <- matrix(0, nrow = 1L, ncol = 1L)
  if (!use_aggregation) {
    return(list(
      use_gaussian_aggregation = 0L,
      n_agg = 0L,
      agg_n = numeric(1),
      agg_mean_y = numeric(1),
      agg_css = numeric(1),
      X_mu_agg = dummy_matrix,
      X_sigma_agg = dummy_matrix,
      offset_mu_agg = numeric(1),
      offset_sigma_agg = numeric(1)
    ))
  }
  list(
    use_gaussian_aggregation = 1L,
    n_agg = as.integer(aggregation$n_cells),
    agg_n = aggregation$n,
    agg_mean_y = aggregation$mean_y,
    agg_css = aggregation$css,
    X_mu_agg = aggregation$X_mu,
    X_sigma_agg = aggregation$X_sigma,
    offset_mu_agg = aggregation$offset_mu,
    offset_sigma_agg = aggregation$offset_sigma
  )
}

drm_gaussian_aggregation_summary <- function(aggregation) {
  if (!is.list(aggregation) || !isTRUE(aggregation$enabled)) {
    return(NULL)
  }
  largest <- if (length(aggregation$n) == 0L) 0 else max(aggregation$n)
  data.frame(
    original_rows = aggregation$n_original,
    aggregation_cells = aggregation$n_cells,
    compression_ratio = aggregation$n_original / aggregation$n_cells,
    largest_cell_n = largest,
    stringsAsFactors = FALSE
  )
}

drm_gaussian_full_loglik <- function(
  y,
  X_mu,
  X_sigma,
  beta_mu,
  beta_sigma,
  offset_mu = rep(0, length(y)),
  offset_sigma = rep(0, length(y))
) {
  mu <- as.vector(as.matrix(X_mu) %*% beta_mu) + offset_mu
  log_sigma <- as.vector(as.matrix(X_sigma) %*% beta_sigma) + offset_sigma
  sigma <- exp(log_sigma)
  sum(stats::dnorm(y, mean = mu, sd = sigma, log = TRUE))
}

drm_gaussian_aggregated_loglik <- function(
  aggregation,
  beta_mu,
  beta_sigma
) {
  mu <- as.vector(aggregation$X_mu %*% beta_mu) + aggregation$offset_mu
  log_sigma <- as.vector(aggregation$X_sigma %*% beta_sigma) +
    aggregation$offset_sigma
  sigma2 <- exp(2 * log_sigma)
  # Centered quadratic: css + n (mean_y - mu)^2. Both terms are small when the
  # cell is well fit, avoiding the cancellation of the expanded second-moment
  # form (see #701).
  quadratic <- aggregation$css +
    aggregation$n * (aggregation$mean_y - mu)^2
  sum(
    -0.5 *
      aggregation$n *
      log(2 * pi) -
      aggregation$n * log_sigma -
      0.5 * quadratic / sigma2
  )
}

drm_gaussian_aggregation_parity <- function(
  y,
  X_mu,
  X_sigma,
  beta_mu = NULL,
  beta_sigma = NULL,
  weights = rep(1, length(y))
) {
  X_mu <- as.matrix(X_mu)
  X_sigma <- as.matrix(X_sigma)
  if (is.null(beta_mu)) {
    beta_mu <- seq_len(ncol(X_mu)) / max(ncol(X_mu), 1L)
    # Exercise the large-mean regime (#701): when the first mu column is an
    # intercept, give it a large default coefficient. This pushes the fitted
    # cell means far from zero, where the old expanded second-moment quadratic
    # loses precision and the centered (css + n (mean_y - mu)^2) form must not.
    if (ncol(X_mu) >= 1L && isTRUE(all(X_mu[, 1L] == 1))) {
      beta_mu[1L] <- 1e6
    }
  }
  if (is.null(beta_sigma)) {
    beta_sigma <- -seq_len(ncol(X_sigma)) / (2 * max(ncol(X_sigma), 1L))
  }
  if (length(beta_mu) != ncol(X_mu)) {
    cli::cli_abort(
      "{.arg beta_mu} must have length equal to the {.code X_mu} column count."
    )
  }
  if (length(beta_sigma) != ncol(X_sigma)) {
    cli::cli_abort(
      "{.arg beta_sigma} must have length equal to the {.code X_sigma} column count."
    )
  }

  aggregation <- drm_gaussian_aggregation(
    y = y,
    X_mu = X_mu,
    X_sigma = X_sigma,
    weights = weights
  )
  full_loglik <- drm_gaussian_full_loglik(
    y,
    X_mu,
    X_sigma,
    beta_mu,
    beta_sigma
  )
  aggregated_loglik <- drm_gaussian_aggregated_loglik(
    aggregation,
    beta_mu,
    beta_sigma
  )

  list(
    aggregation = aggregation,
    full_loglik = full_loglik,
    aggregated_loglik = aggregated_loglik,
    difference = aggregated_loglik - full_loglik
  )
}
