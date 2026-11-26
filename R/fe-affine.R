# Internal fixed-effect affine reparameterisation for numerical conditioning.
# Centers and scales non-intercept numeric columns before optimisation and
# sdreport, then maps coefficients and Wald covariance back to the user's units.

drm_fe_affine_dpar_tmb_x <- c(
  mu = "X_mu",
  sigma = "X_sigma",
  nu = "X_nu",
  zi = "X_zi"
)

drm_fe_affine_dpar_beta <- c(
  mu = "beta_mu",
  sigma = "beta_sigma",
  nu = "beta_nu",
  zi = "beta_zi"
)

drm_fe_affine_is_intercept_col <- function(nm) {
  identical(nm, "(Intercept)") || grepl("^\\(Intercept\\)", nm)
}

# Return NULL when no numeric slope columns exist (nothing to condition).
drm_fe_affine_meta <- function(X, dpar) {
  if (!is.matrix(X) || ncol(X) < 2L) {
    return(NULL)
  }
  nms <- colnames(X)
  if (is.null(nms) || any(!nzchar(nms))) {
    return(NULL)
  }
  slope <- vapply(
    seq_len(ncol(X)),
    function(j) {
      if (drm_fe_affine_is_intercept_col(nms[[j]])) {
        return(FALSE)
      }
      storage.mode(X[, j]) <- "double"
      isTRUE(all(is.finite(X[, j]))) && is.numeric(X[, j, drop = TRUE])
    },
    logical(1L)
  )
  if (!any(slope)) {
    return(NULL)
  }
  center <- rep(0, ncol(X))
  scale <- rep(1, ncol(X))
  for (j in which(slope)) {
    center[[j]] <- mean(X[, j])
    sj <- stats::sd(X[, j])
    if (!is.finite(sj) || sj < 1e-12) {
      return(NULL)
    }
    scale[[j]] <- sj
  }
  intercept <- which(vapply(nms, drm_fe_affine_is_intercept_col, logical(1L)))
  intercept <- if (length(intercept) == 1L) intercept[[1L]] else NA_integer_
  list(
    dpar = dpar,
    center = center,
    scale = scale,
    slope = slope,
    intercept = intercept
  )
}

drm_fe_affine_scale_matrix <- function(X, meta) {
  out <- X
  storage.mode(out) <- "double"
  for (j in which(meta$slope)) {
    out[, j] <- (out[, j] - meta$center[[j]]) / meta$scale[[j]]
  }
  out
}

drm_fe_affine_scale_beta <- function(beta, meta) {
  out <- as.numeric(beta)
  if (length(out) != length(meta$scale)) {
    return(out)
  }
  if (any(meta$slope)) {
    out[meta$slope] <- out[meta$slope] * meta$scale[meta$slope]
    if (!is.na(meta$intercept)) {
      out[[meta$intercept]] <- out[[meta$intercept]] + sum(
        out[meta$slope] * meta$center[meta$slope] / meta$scale[meta$slope]
      )
    }
  }
  stats::setNames(out, names(beta))
}

drm_fe_affine_unscale_beta <- function(beta, meta) {
  out <- as.numeric(beta)
  if (length(out) != length(meta$scale)) {
    return(out)
  }
  if (any(meta$slope)) {
    if (!is.na(meta$intercept)) {
      out[[meta$intercept]] <- out[[meta$intercept]] - sum(
        out[meta$slope] * meta$center[meta$slope] / meta$scale[meta$slope]
      )
    }
    out[meta$slope] <- out[meta$slope] / meta$scale[meta$slope]
  }
  stats::setNames(out, names(beta))
}

drm_fe_affine_jacobian <- function(meta) {
  p <- length(meta$scale)
  J <- diag(p)
  if (any(meta$slope)) {
    for (j in which(meta$slope)) {
      if (!is.na(meta$intercept)) {
        J[meta$intercept, j] <- -meta$center[[j]] / meta$scale[[j]]
      }
      J[j, j] <- 1 / meta$scale[[j]]
    }
  }
  J
}

drm_fe_affine_transform_vcov <- function(cov, meta, par_names, beta_name) {
  if (!is.matrix(cov) || is.null(meta)) {
    return(cov)
  }
  hits <- which(par_names == beta_name)
  if (length(hits) != length(meta$scale)) {
    return(cov)
  }
  J <- drm_fe_affine_jacobian(meta)
  cov[hits, hits] <- J %*% cov[hits, hits, drop = FALSE] %*% t(J)
  cov
}

drm_apply_fe_affine_spec <- function(spec) {
  if (!is.list(spec$X)) {
    return(spec)
  }
  fe_affine <- list()
  # Only mu fixed-effect columns for now (refs #1737). Other dpars need profile
  # engine agreement before conditioning their designs.
  for (dpar in "mu") {
    if (!dpar %in% names(spec$X)) {
      next
    }
    meta <- drm_fe_affine_meta(spec$X[[dpar]], dpar)
    if (is.null(meta)) {
      next
    }
    spec$X[[dpar]] <- drm_fe_affine_scale_matrix(spec$X[[dpar]], meta)
    tmb_x <- drm_fe_affine_dpar_tmb_x[[dpar]]
    if (!is.null(spec$tmb_data[[tmb_x]])) {
      spec$tmb_data[[tmb_x]] <- spec$X[[dpar]]
    }
    beta_name <- drm_fe_affine_dpar_beta[[dpar]]
    if (!is.null(spec$start[[beta_name]])) {
      spec$start[[beta_name]] <- drm_fe_affine_scale_beta(
        spec$start[[beta_name]],
        meta
      )
    }
    fe_affine[[dpar]] <- meta
  }
  if (length(fe_affine) == 0L) {
    return(spec)
  }
  spec$fe_affine <- fe_affine
  spec
}

drm_fe_affine_restore_fit <- function(opt, sdr, spec) {
  if (!is.list(spec$fe_affine) || length(spec$fe_affine) == 0L) {
    return(list(opt = opt, sdr = sdr))
  }
  if (is.null(sdr) || is.null(sdr$cov.fixed)) {
    return(list(opt = opt, sdr = sdr))
  }
  par_names <- names(opt$par)
  cov <- sdr$cov.fixed
  for (dpar in names(spec$fe_affine)) {
    meta <- spec$fe_affine[[dpar]]
    beta_name <- drm_fe_affine_dpar_beta[[dpar]]
    hits <- which(par_names == beta_name)
    if (length(hits) != length(meta$scale)) {
      next
    }
    cov <- drm_fe_affine_transform_vcov(cov, meta, par_names, beta_name)
    if (!is.null(sdr$value) && beta_name %in% names(sdr$value)) {
      idx <- which(names(sdr$value) == beta_name)
      if (length(idx) == length(meta$scale)) {
        sdr$value[idx] <- drm_fe_affine_unscale_beta(sdr$value[idx], meta)
      }
    }
  }
  sdr$cov.fixed <- cov
  list(opt = opt, sdr = sdr)
}

drm_fe_affine_unscale_parlist <- function(par, spec) {
  if (!is.list(spec$fe_affine) || length(spec$fe_affine) == 0L) {
    return(par)
  }
  for (dpar in names(spec$fe_affine)) {
    beta_name <- drm_fe_affine_dpar_beta[[dpar]]
    if (!is.null(par[[beta_name]])) {
      par[[beta_name]] <- drm_fe_affine_unscale_beta(
        par[[beta_name]],
        spec$fe_affine[[dpar]]
      )
    }
  }
  par
}