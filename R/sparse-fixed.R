drm_fixed_effect_matrix <- function(terms, data, sparse = FALSE) {
  if (isTRUE(sparse)) {
    return(Matrix::sparse.model.matrix(terms, data))
  }
  stats::model.matrix(terms, data)
}

drm_sparse_fixed_parity <- function(terms, data, beta = NULL) {
  dense <- drm_fixed_effect_matrix(terms, data, sparse = FALSE)
  sparse <- drm_fixed_effect_matrix(terms, data, sparse = TRUE)

  same_shape <- identical(dim(dense), dim(sparse))
  same_names <- identical(dimnames(dense), dimnames(sparse))
  max_abs_matrix_diff <- max(abs(dense - as.matrix(sparse)), 0)

  if (is.null(beta)) {
    beta <- seq_len(ncol(dense)) / max(ncol(dense), 1L)
  }
  if (length(beta) != ncol(dense)) {
    cli::cli_abort(
      "{.arg beta} must have length equal to the design-matrix column count."
    )
  }
  eta_dense <- as.vector(dense %*% beta)
  eta_sparse <- as.vector(sparse %*% beta)

  list(
    dense = dense,
    sparse = sparse,
    same_shape = same_shape,
    same_names = same_names,
    max_abs_matrix_diff = max_abs_matrix_diff,
    max_abs_eta_diff = max(abs(eta_dense - eta_sparse), 0)
  )
}
