# Internal center/scale of fixed-effect design columns for stable TMB Hessians.
# Coefficients and Wald covariance are mapped back to the user's predictor scale.

drm_fe_design_dpar_names <- c(
  "mu", "sigma", "nu", "zi", "zoi", "coi",
  "mu1", "mu2", "sigma1", "sigma2", "rho12"
)

drm_fe_design_beta_names <- c(
  "beta_mu", "beta_sigma", "beta_nu", "beta_zi", "beta_zoi", "beta_coi",
  "beta_mu1", "beta_mu2", "beta_sigma1", "beta_sigma2", "beta_rho12"
)

drm_fe_is_intercept_col <- function(x, name) {
  if (length(name) == 1L && identical(name, "(Intercept)")) {
    return(TRUE)
  }
  if (length(x) == 0L) {
    return(FALSE)
  }
  stats::sd(x) < 1e-10 * max(1, max(abs(x)))
}

drm_fe_column_scale <- function(x, center, fallback = 1) {
  centered <- x - center
  spread <- max(
    stats::sd(centered),
    max(abs(centered)),
    fallback,
    .Machine$double.eps
  )
  spread
}

drm_fe_prepare_design_matrix <- function(X) {
  if (is.null(X) || (!is.matrix(X) && !inherits(X, "Matrix"))) {
    return(list(X = X, meta = NULL))
  }
  dense <- as.matrix(X)
  if (ncol(dense) == 0L) {
    return(list(X = X, meta = NULL))
  }
  colnames_x <- colnames(dense)
  if (is.null(colnames_x)) {
    colnames_x <- paste0("fe", seq_len(ncol(dense)))
  }
  intercept_idx <- which(vapply(
    seq_len(ncol(dense)),
    function(j) drm_fe_is_intercept_col(dense[, j], colnames_x[[j]]),
    logical(1L)
  ))
  if (length(intercept_idx) > 1L) {
    intercept_idx <- intercept_idx[[1L]]
  } else if (length(intercept_idx) == 0L) {
    intercept_idx <- NA_integer_
  }
  center <- numeric(ncol(dense))
  scale <- rep(1, ncol(dense))
  X_std <- dense
  for (j in seq_len(ncol(dense))) {
    if (!is.na(intercept_idx) && j == intercept_idx) {
      next
    }
    center[[j]] <- mean(dense[, j])
    scale[[j]] <- drm_fe_column_scale(dense[, j], center[[j]])
    X_std[, j] <- (dense[, j] - center[[j]]) / scale[[j]]
  }
  out_X <- if (inherits(X, "Matrix")) {
    Matrix::Matrix(X_std, sparse = Matrix::nnzero(X) < length(X_std) * 0.2)
  } else {
    X_std
  }
  colnames(out_X) <- colnames_x
  list(
    X = out_X,
    meta = list(
      colnames = colnames_x,
      intercept = intercept_idx,
      center = center,
      scale = scale
    )
  )
}

drm_fe_internal_coef <- function(coef, meta) {
  if (is.null(meta) || is.null(coef)) {
    return(coef)
  }
  out <- coef
  names(out) <- names(coef)
  p <- length(coef)
  if (p != length(meta$scale)) {
    return(coef)
  }
  intercept <- meta$intercept
  if (!is.na(intercept) && intercept >= 1L && intercept <= p) {
    shift <- 0
    for (j in seq_len(p)) {
      if (j == intercept) {
        next
      }
      shift <- shift + coef[[j]] * meta$center[[j]]
    }
    out[[intercept]] <- coef[[intercept]] + shift
  }
  for (j in seq_len(p)) {
    if (!is.na(intercept) && j == intercept) {
      next
    }
    out[[j]] <- coef[[j]] * meta$scale[[j]]
  }
  out
}

drm_fe_user_coef <- function(coef, meta) {
  if (is.null(meta) || is.null(coef)) {
    return(coef)
  }
  out <- coef
  p <- length(coef)
  if (p != length(meta$scale)) {
    return(coef)
  }
  intercept <- meta$intercept
  for (j in seq_len(p)) {
    if (!is.na(intercept) && j == intercept) {
      next
    }
    out[[j]] <- coef[[j]] / meta$scale[[j]]
  }
  if (!is.na(intercept) && intercept >= 1L && intercept <= p) {
    shift <- 0
    for (j in seq_len(p)) {
      if (j == intercept) {
        next
      }
      shift <- shift + out[[j]] * meta$center[[j]]
    }
    out[[intercept]] <- coef[[intercept]] - shift
  }
  out
}

drm_fe_jacobian_beta <- function(meta) {
  p <- length(meta$scale)
  J <- diag(1, p, p)
  intercept <- meta$intercept
  if (!is.na(intercept) && intercept >= 1L && intercept <= p) {
    for (j in seq_len(p)) {
      if (j == intercept) {
        next
      }
      J[intercept, j] <- -meta$center[[j]] / meta$scale[[j]]
      J[j, j] <- 1 / meta$scale[[j]]
    }
  } else {
    for (j in seq_len(p)) {
      J[j, j] <- 1 / meta$scale[[j]]
    }
  }
  J
}

drm_fe_userize_cov_block <- function(cov, meta) {
  if (is.null(meta) || is.null(cov) || !is.matrix(cov)) {
    return(cov)
  }
  if (nrow(cov) != length(meta$scale)) {
    return(cov)
  }
  J <- drm_fe_jacobian_beta(meta)
  J %*% cov %*% t(J)
}

drm_fe_standardize_spec <- function(spec) {
  if (!is.list(spec$X) || length(spec$X) == 0L) {
    return(spec)
  }
  meta <- list()
  for (dpar in intersect(names(spec$X), drm_fe_design_dpar_names)) {
    prep <- drm_fe_prepare_design_matrix(spec$X[[dpar]])
    if (is.null(prep$meta)) {
      next
    }
    spec$X[[dpar]] <- prep$X
    meta[[dpar]] <- prep$meta
  }
  if (length(meta) == 0L) {
    return(spec)
  }
  spec$fe_design_meta <- meta
  spec$start <- drm_fe_transform_spec_start(spec$start, meta)
  spec$tmb_data <- add_covariance_block_tmb_data(make_tmb_data(spec), spec)
  if (
    is.list(spec$sparse_fixed) &&
      isTRUE(spec$sparse_fixed$mu) &&
      "mu" %in% names(meta)
  ) {
    spec$tmb_data$X_mu_sparse <- spec$X$mu
  }
  spec
}

drm_fe_transform_spec_start <- function(start, meta) {
  if (!is.list(start)) {
    return(start)
  }
  beta_map <- stats::setNames(
    drm_fe_design_dpar_names,
    drm_fe_design_beta_names
  )
  for (beta_name in names(beta_map)) {
    dpar <- beta_map[[beta_name]]
    if (
      !beta_name %in% names(start) ||
        is.null(meta[[dpar]]) ||
        is.null(start[[beta_name]])
    ) {
      next
    }
    coef <- start[[beta_name]]
    if (is.null(names(coef))) {
      names(coef) <- meta[[dpar]]$colnames
    }
    start[[beta_name]] <- drm_fe_internal_coef(unname(coef), meta[[dpar]])
    names(start[[beta_name]]) <- meta[[dpar]]$colnames
  }
  start
}

drm_fe_userize_parameters <- function(par, meta) {
  if (length(meta) == 0L || !is.list(par)) {
    return(par)
  }
  beta_map <- stats::setNames(
    drm_fe_design_dpar_names,
    drm_fe_design_beta_names
  )
  for (dpar in names(par)) {
    if (!dpar %in% names(meta)) {
      next
    }
    par[[dpar]] <- drm_fe_user_coef(unname(par[[dpar]]), meta[[dpar]])
    names(par[[dpar]]) <- meta[[dpar]]$colnames
  }
  # split_tmb_parameters uses top-level dpars, not beta_* names
  par
}

drm_fe_userize_coefficients_list <- function(coefs, meta) {
  if (length(meta) == 0L || !is.list(coefs)) {
    return(coefs)
  }
  for (dpar in intersect(names(coefs), names(meta))) {
    coefs[[dpar]] <- drm_fe_user_coef(unname(coefs[[dpar]]), meta[[dpar]])
    names(coefs[[dpar]]) <- meta[[dpar]]$colnames
  }
  coefs
}

drm_fe_userize_sdreport <- function(sdr, par_names, meta) {
  if (is.null(sdr) || length(meta) == 0L || !is.matrix(sdr$cov.fixed)) {
    return(sdr)
  }
  cov <- sdr$cov.fixed
  beta_map <- stats::setNames(
    drm_fe_design_dpar_names,
    drm_fe_design_beta_names
  )
  for (beta_name in names(beta_map)) {
    dpar <- beta_map[[beta_name]]
    if (is.null(meta[[dpar]])) {
      next
    }
    idx <- which(par_names == beta_name)
  if (length(idx) != length(meta[[dpar]]$scale)) {
      next
    }
    block <- cov[idx, idx, drop = FALSE]
    cov[idx, idx] <- drm_fe_userize_cov_block(block, meta[[dpar]])
  }
  sdr$cov.fixed <- cov
  sdr
}