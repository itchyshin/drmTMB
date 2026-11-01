# Maximum-likelihood existence screens (sweep-oct16 t4 FX3).
#
# A fit whose MLE does not exist must not report is_converged() = TRUE with no
# signal. ?convergence_status already says that "no proper maximum" is
# "degenerate". This file decides three geometries that the existing
# Hessian / inflated-SE screens miss:
#
# 1. Binomial / Bernoulli (quasi-)complete separation (Albert and Anderson
#    1984; Konis 2007). Owner decision on #1270 / #1268: detect and warn;
#    do not refuse; do not apply Firth/MSPL by default. The cone solver is
#    the #1442 Lawson-Hanson / Farkas screen, kept lockstep with
#    DRModels.jl `src/separation.jl`.
# 2. Poisson / NB2 fixed-effect nonexistence (Haberman 1974; Santos Silva
#    and Tenreyro 2010, Econ. Lett. 107:310-312). The same cone decides it
#    when successes = 1{y > 0} and trials = 1 + successes (#1553; Julia
#    twin #1109).
# 3. Unbounded continuous location-scale: a scale predictor drives an
#    exactly fitted observation to the lower log(sigma) clamp (#1469;
#    #1509 verdict, computed here so convergence_status() does not need
#    a fit-time store).
#
# Random-effect, phylogenetic, mi() predictor, and MSPL routes are not
# screened: a random intercept can absorb part of the ray, and MSPL is
# already a finite estimator.
#
# This file does not change coefficient values, vcov(), or Inf masking.
# It only classifies the fit. The 238/750 twin-flag contract (#1554) is
# not decided here.

# Constants shared with DRModels.jl src/separation.jl / #1442.
drm_sep_obj_tol <- function() 1e-9
drm_sep_coef_tol <- function() 1e-6
drm_sep_rank_tol <- function() 1e-10
drm_sep_resid_tol <- function() 1e-8
drm_sep_max_iter <- function(q) 20L * q + 200L

drm_fe_mle_screen_applicable <- function(spec) {
  if (is.null(spec) || drm_is_mspl(spec$estimator)) {
    return(FALSE)
  }
  n_re <- spec$random$mu$n_re
  if (!is.null(n_re) && !identical(as.integer(n_re), 0L)) {
    return(FALSE)
  }
  if (isTRUE(spec$structured$phylo_mu$has)) {
    return(FALSE)
  }
  if (isTRUE(spec$missing_predictor$enabled)) {
    return(FALSE)
  }
  TRUE
}

drm_sep_constraints <- function(X, successes, failures) {
  p <- ncol(X)
  pos <- which(successes > 0 & rowSums(abs(X)) > 0)
  neg <- which(failures > 0 & rowSums(abs(X)) > 0)
  M <- rbind(X[pos, , drop = FALSE], -X[neg, , drop = FALSE])
  if (nrow(M) == 0L) {
    return(list(A = matrix(0, 0L, 0L), keep = integer()))
  }
  sc <- apply(abs(M), 2L, function(col) {
    nz <- col[col != 0]
    if (length(nz)) stats::median(nz) else 1
  })
  M <- sweep(M, 2L, sc, "/")
  M <- M / sqrt(rowSums(M^2))
  qrM <- qr(M, LAPACK = TRUE)
  dR <- abs(diag(qr.R(qrM)))
  r <- if (dR[[1L]] == 0) 0L else sum(dR > drm_sep_rank_tol() * dR[[1L]])
  keep <- sort(qrM$pivot[seq_len(r)])
  A <- M[, keep, drop = FALSE]
  alias <- setdiff(seq_len(p), keep)
  alias_coef <- matrix(0, length(keep), length(alias))
  if (length(alias) && length(keep)) {
    alias_coef <- qr.coef(qr(A), M[, alias, drop = FALSE])
    alias_coef[is.na(alias_coef)] <- 0
    alias_coef <- matrix(alias_coef, length(keep), length(alias))
  }
  nrm <- sqrt(rowSums(A^2))
  ok <- nrm > 0
  list(
    A = A[ok, , drop = FALSE] / nrm[ok],
    keep = keep,
    alias = alias,
    alias_coef = alias_coef
  )
}

drm_sep_nnls <- function(A, cvec, maxiter) {
  m <- nrow(A)
  y <- numeric(m)
  P <- logical(m)
  banned <- logical(m)
  r <- cvec
  iter <- 0L
  rtol <- drm_sep_resid_tol() * max(1, sqrt(sum(cvec^2)))
  repeat {
    if (sqrt(sum(r^2)) <= rtol) {
      return(list(r = r, converged = TRUE, iter = iter))
    }
    w <- -as.numeric(A %*% r)
    tol <- max(1e-9 * max(abs(r)), 1e-12 * max(1, sqrt(sum(cvec^2))))
    w[P] <- -Inf
    blocked <- banned & w > tol
    w[banned] <- -Inf
    jin <- which.max(w)
    if (w[[jin]] <= tol) {
      return(list(r = r, converged = !any(blocked), iter = iter))
    }
    P[[jin]] <- TRUE
    first <- TRUE
    repeat {
      iter <- iter + 1L
      if (iter > maxiter) {
        return(list(r = r, converged = FALSE, iter = iter))
      }
      idx <- which(P)
      zP <- qr.coef(qr(t(A[idx, , drop = FALSE])), -cvec)
      zP[is.na(zP)] <- 0
      if (all(zP > 0)) {
        y[] <- 0
        y[idx] <- zP
        banned[] <- FALSE
        break
      }
      if (first && zP[[match(jin, idx)]] <= 0) {
        P[[jin]] <- FALSE
        banned[[jin]] <- TRUE
        break
      }
      first <- FALSE
      neg <- which(zP <= 0)
      ratio <- y[idx[neg]] / (y[idx[neg]] - zP[neg])
      k <- which.min(ratio)
      y[idx] <- y[idx] + ratio[[k]] * (zP - y[idx])
      y[idx[neg[[k]]]] <- 0
      P[idx[y[idx] <= 0]] <- FALSE
      y[!P] <- 0
    }
    r <- cvec + as.numeric(crossprod(A, y))
  }
}

# Exact cone screen. `successes` / `failures` are per-row counts (Bernoulli
# uses 0/1; Poisson uses s = 1{y > 0}, ntr = 1 + s).
drm_detect_separation <- function(X, successes, failures, max_iter = NULL) {
  none <- list(separated = FALSE, flagged = integer(), conclusive = TRUE)
  cons <- drm_sep_constraints(X, successes, failures)
  A <- cons$A
  keep <- cons$keep
  q <- length(keep)
  if (q == 0L || nrow(A) == 0L) {
    return(none)
  }
  budget <- if (is.null(max_iter)) drm_sep_max_iter(q) else max_iter
  pos <- logical(nrow(A))
  conclusive <- TRUE
  repeat {
    U <- !pos
    if (!any(U)) {
      break
    }
    cU <- colSums(A[U, , drop = FALSE])
    nn <- drm_sep_nnls(A, cU, budget)
    budget <- budget - nn$iter
    if (!nn$converged) {
      conclusive <- FALSE
      break
    }
    r <- nn$r
    if (sqrt(sum(r^2)) <= drm_sep_resid_tol() * max(1, sqrt(sum(cU^2)))) {
      break
    }
    marg <- as.numeric(A %*% (r / max(abs(r))))
    new <- U & marg > drm_sep_obj_tol()
    if (min(marg) < -drm_sep_resid_tol() || !any(new)) {
      conclusive <- FALSE
      break
    }
    pos <- pos | new
  }
  if (!any(pos)) {
    none$conclusive <- conclusive
    return(none)
  }
  J <- !pos
  if (!any(J)) {
    flag <- rep(TRUE, q)
  } else {
    sv <- svd(A[J, , drop = FALSE], nu = 0L, nv = q)
    rk <- sum(sv$d > drm_sep_rank_tol() * max(sv$d[[1L]], 1))
    flag <- if (rk >= q) {
      rep(FALSE, q)
    } else {
      N <- sv$v[, (rk + 1L):q, drop = FALSE]
      sqrt(rowSums(N^2)) > drm_sep_coef_tol()
    }
  }
  flagged <- keep[flag]
  if (length(cons$alias) && any(flag)) {
    rides <- colSums(abs(cons$alias_coef[flag, , drop = FALSE])) > 1e-8
    flagged <- sort(c(flagged, cons$alias[rides]))
  }
  list(separated = TRUE, flagged = flagged, conclusive = conclusive)
}

drm_observed_design_rows <- function(spec, n) {
  obs <- spec$missing_data$observed_y
  if (is.null(obs)) {
    obs <- rep(TRUE, n)
  }
  w <- spec$weights
  if (!is.null(w)) {
    obs <- obs & (w > 0)
  }
  obs
}

drm_count_family_success_failure <- function(y) {
  s <- as.numeric(y > 0)
  # Santos Silva & Tenreyro / #1109: s = 1{y > 0}, ntr = 1 + s so failures = 1.
  list(successes = s, failures = rep(1, length(s)))
}

drm_glm_ray_screen <- function(fit) {
  spec <- fit$model
  type <- spec$model_type
  glm_types <- c("binomial", "poisson", "nbinom2")
  if (!isTRUE(type %in% glm_types) || !drm_fe_mle_screen_applicable(spec)) {
    return(NULL)
  }
  X <- spec$X$mu
  if (is.null(X) || !is.matrix(X) || ncol(X) == 0L) {
    return(NULL)
  }
  use <- drm_observed_design_rows(spec, nrow(X))
  if (!any(use)) {
    return(NULL)
  }
  if (identical(type, "binomial")) {
    successes <- spec$y
    failures <- spec$failures
    if (is.null(failures)) {
      failures <- spec$trials - spec$y
    }
    reason <- "binomial_separation"
  } else {
    sf <- drm_count_family_success_failure(spec$y)
    successes <- sf$successes
    failures <- sf$failures # always 1: ntr = 1 + 1{y > 0}
    reason <- "count_mle_nonexistent"
  }
  det <- drm_detect_separation(
    X[use, , drop = FALSE],
    successes[use],
    failures[use]
  )
  if (!isTRUE(det$separated)) {
    return(NULL)
  }
  labels <- colnames(X)
  if (is.null(labels)) {
    labels <- paste0("x", seq_len(ncol(X)))
  }
  list(
    reason = reason,
    flagged = labels[det$flagged],
    conclusive = det$conclusive
  )
}

drm_unbounded_scale_families <- function() {
  c(
    "gaussian",
    "lognormal",
    "student",
    "skew_normal",
    "gamma"
  )
}

drm_unbounded_location_scale <- function(fit) {
  spec <- fit$model
  if (
    !isTRUE(spec$model_type %in% drm_unbounded_scale_families()) ||
      isTRUE(spec$has_known_v) ||
      is.null(fit$obj) ||
      is.null(fit$tmb_state$last.par.best)
  ) {
    return(NULL)
  }
  report <- tryCatch(
    fit$obj$report(fit$tmb_state$last.par.best),
    error = function(e) NULL
  )
  if (is.null(report)) {
    return(NULL)
  }
  info <- drm_logsigma_clamp_active(report, spec$tmb_data)
  if (is.null(info) || !identical(info$arm, "lower")) {
    return(NULL)
  }
  log_sigma <- report$log_sigma
  log_sigma <- log_sigma[is.finite(log_sigma)]
  if (length(log_sigma) == 0L || (max(log_sigma) - min(log_sigma)) <= log(1e4)) {
    return(NULL)
  }
  sigma <- tryCatch(
    as.numeric(stats::predict(fit, dpar = "sigma", type = "response")),
    error = function(e) NULL
  )
  z <- tryCatch(
    suppressWarnings(as.numeric(stats::residuals(fit, type = "pearson"))),
    error = function(e) NULL
  )
  if (
    is.null(sigma) ||
      is.null(z) ||
      length(sigma) != length(z) ||
      !any(is.finite(sigma))
  ) {
    return(NULL)
  }
  smallest <- which.min(replace(sigma, !is.finite(sigma), Inf))
  if (!(is.finite(z[[smallest]]) && abs(z[[smallest]]) < 1e-3)) {
    return(NULL)
  }
  list(
    reason = "unbounded_location_scale",
    flagged = character(),
    conclusive = TRUE
  )
}

# NULL when a finite MLE may exist; otherwise a list with `reason`.
drm_mle_nonexistent <- function(object) {
  glm_hit <- drm_glm_ray_screen(object)
  if (!is.null(glm_hit)) {
    return(glm_hit)
  }
  drm_unbounded_location_scale(object)
}

drm_mle_nonexistent_is_true <- function(object) {
  !is.null(drm_mle_nonexistent(object))
}

check_mle_existence <- function(object) {
  hit <- drm_mle_nonexistent(object)
  if (is.null(hit)) {
    return(check_row(
      "mle_existence",
      "ok",
      "finite",
      "The screened fixed-effect geometry is consistent with a finite maximum-likelihood estimate."
    ))
  }
  flagged <- if (length(hit$flagged)) {
    paste(hit$flagged, collapse = ", ")
  } else {
    "(scale)"
  }
  message <- switch(
    hit$reason,
    binomial_separation = paste(
      "Binomial / Bernoulli fixed-effect fit has (quasi-)complete separation;",
      "the maximum-likelihood estimate does not exist. Reported coefficients",
      "are an arbitrary optimiser stop. Affected terms:",
      flagged,
      ". Simplify the predictor, collapse the separating factor, or use the",
      "penalised estimator = \"mspl\" fit."
    ),
    count_mle_nonexistent = paste(
      "Poisson / NB2 fixed-effect maximum-likelihood estimate does not exist",
      "(all-zero counts, or positives only on a face of the covariate cone;",
      "Haberman 1974; Santos Silva and Tenreyro 2010). Affected terms:",
      flagged,
      "."
    ),
    unbounded_location_scale = paste(
      "A scale predictor drives an exactly fitted observation to the lower",
      "log(sigma) clamp; the continuous location-scale likelihood has no",
      "finite maximum. Simplify the scale formula (for example sigma ~ 1)",
      "or collect more observations per scale parameter."
    ),
    paste("The maximum-likelihood estimate does not exist (", hit$reason, ").")
  )
  check_row("mle_existence", "warning", hit$reason, message)
}
