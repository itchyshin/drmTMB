# Separation screen for fixed-effect binomial / Bernoulli fits (drmTMB #1268;
# twin contract DRModels.jl #731 / #728).
#
# Policy (owner decision 2026-09-30, "detect and warn"): the fit is still
# returned, a warning names the affected coefficients, and their standard
# errors are reported as Inf. No refusal and no penalised estimator by default
# (MSPL stays an explicit opt-in, `estimator = "MSPL"`). The two packages agree
# on WHICH coefficients are flagged and on the warning, not on the
# (non-existent) maximum-likelihood coefficients.
#
# Method (Konis 2007, the idea behind `detectseparation`, written here from the
# published method and without that package). With signed design rows
# x~_i = x_i for a success and -x_i for a failure, the likelihood has no finite
# maximiser iff some direction d satisfies x~_i . d >= 0 for every row and > 0
# for at least one. That is linear-programming feasibility over the cone
# C = {d : X~ d >= 0}. We solve
#
#   max sum_i x~_i . d   s.t.   X~ d >= 0,  -1 <= d <= 1
#
# (optimum > 0 <=> separation), then for each coefficient j the max and min of
# d_j over the same polytope. Coefficient j is flagged when the cone holds a
# direction with d_j != 0 (a generic recession direction lies in the relative
# interior of C, so it has d_j != 0 exactly then). The same reasoning covers
# logit, probit and cloglog links: the recession cone depends on the sign
# pattern only, not on offsets or positive weights.
#
# Base R only: the problem has p (small) variables and one constraint per row,
# so a small bounded simplex in inequality form (a basis of p active
# constraints; Bland's rule against the heavy degeneracy at d = 0) is used.
#
# Scope: fixed-effect binomial fits (no random effects, no phylo term, no
# missing-predictor model). Random-effect routes are not screened: a random
# intercept can absorb part of the separation, so the fixed-design LP does not
# decide it.

# Constants shared with the DRModels.jl twin; keep identical in both packages.
drm_sep_obj_tol <- function() 1e-9   # LP optimum above this => separation
drm_sep_coef_tol <- function() 1e-6  # box-scaled |d_j| above this => coefficient flagged
drm_sep_rank_tol <- function() 1e-10 # relative |R_jj| below this => aliased, not screened
drm_sep_near_p <- function() 1e-8    # near separation: fitted probability within this of 0/1 ...
drm_sep_near_se <- function() 1e4    # ... AND a Wald SE above this (or non-finite)

# Signed, column-scaled, row-normalised constraint matrix. Returns
# list(A, keep) where `keep` indexes the columns of `X` that are screened.
drm_sep_constraints <- function(X, successes, failures) {
  p <- ncol(X)
  pos <- which(successes > 0 & rowSums(abs(X)) > 0)
  neg <- which(failures > 0 & rowSums(abs(X)) > 0)
  M <- rbind(X[pos, , drop = FALSE], -X[neg, , drop = FALSE])
  if (nrow(M) == 0L) {
    return(list(A = matrix(0, 0L, 0L), keep = integer()))
  }
  sc <- pmax(apply(abs(M), 2L, max), .Machine$double.eps)
  M <- sweep(M, 2L, sc, "/")
  qrM <- qr(M, LAPACK = TRUE)
  dR <- abs(diag(qr.R(qrM)))
  r <- if (dR[[1L]] == 0) 0L else sum(dR > drm_sep_rank_tol() * dR[[1L]])
  keep <- sort(qrM$pivot[seq_len(r)])
  A <- M[, keep, drop = FALSE]
  nrm <- sqrt(rowSums(A^2))
  ok <- nrm > 0
  list(A = A[ok, , drop = FALSE] / nrm[ok], keep = keep)
}

# Maximise c . d over {A d >= 0, -1 <= d <= 1}. `basis0` holds p linearly
# independent row indices of A (d = 0 is then a degenerate vertex). Returns
# list(value, d), or NULL if the iteration cap is hit.
drm_sep_lp <- function(A, cvec, basis0, maxiter = 50000L) {
  m <- nrow(A)
  p <- ncol(A)
  basis <- basis0
  gvec <- function(i) {
    if (i <= m) {
      A[i, ]
    } else if (i <= m + p) {
      e <- numeric(p); e[[i - m]] <- 1; e
    } else {
      e <- numeric(p); e[[i - m - p]] <- -1; e
    }
  }
  hval <- function(i) if (i <= m) 0 else -1
  for (iter in seq_len(maxiter)) {
    Gb <- do.call(rbind, lapply(basis, gvec))
    d <- solve(Gb, vapply(basis, hval, numeric(1L)))
    lambda <- solve(t(Gb), cvec)   # cvec = sum lambda_k g_k; optimal for max iff all <= 0
    eligible <- which(lambda > 1e-10)
    if (length(eligible) == 0L) {
      return(list(value = sum(cvec * d), d = d))
    }
    kpos <- eligible[[which.min(basis[eligible])]]
    ek <- numeric(p); ek[[kpos]] <- 1
    delta <- solve(Gb, ek)
    rate <- as.numeric(A %*% delta)
    slack <- as.numeric(A %*% d)
    cand_i <- integer(); cand_t <- numeric()
    rows <- which(rate < -1e-10)
    rows <- setdiff(rows, basis)
    if (length(rows)) {
      cand_i <- c(cand_i, rows)
      cand_t <- c(cand_t, pmax(slack[rows], 0) / -rate[rows])
    }
    lo <- which(delta < -1e-10)
    lo <- lo[!(m + lo) %in% basis]
    if (length(lo)) {
      cand_i <- c(cand_i, m + lo)
      cand_t <- c(cand_t, pmax(d[lo] + 1, 0) / -delta[lo])
    }
    up <- which(delta > 1e-10)
    up <- up[!(m + p + up) %in% basis]
    if (length(up)) {
      cand_i <- c(cand_i, m + p + up)
      cand_t <- c(cand_t, pmax(1 - d[up], 0) / delta[up])
    }
    if (length(cand_i) == 0L) return(NULL)
    tmin <- min(cand_t)
    ties <- cand_i[cand_t <= tmin + 1e-12]
    basis[[kpos]] <- min(ties)
  }
  NULL
}

# Konis-style LP screen. Returns list(separated, flagged, conclusive) where
# `flagged` are the column indices of `X` whose coefficients can diverge.
drm_detect_separation <- function(X, successes, failures) {
  none <- list(separated = FALSE, flagged = integer(), conclusive = TRUE)
  cons <- drm_sep_constraints(X, successes, failures)
  A <- cons$A
  keep <- cons$keep
  q <- length(keep)
  if (q == 0L || nrow(A) == 0L) return(none)
  basis0 <- sort(qr(t(A), LAPACK = TRUE)$pivot[seq_len(q)])
  res <- drm_sep_lp(A, colSums(A), basis0)
  if (is.null(res)) {
    none$conclusive <- FALSE
    return(none)
  }
  if (!(res$value > drm_sep_obj_tol())) return(none)
  flagged <- integer()
  conclusive <- TRUE
  for (jj in seq_len(q)) {
    hit <- FALSE
    for (sg in c(1, -1)) {
      cvec <- numeric(q); cvec[[jj]] <- sg
      r <- drm_sep_lp(A, cvec, basis0)
      if (is.null(r)) {
        conclusive <- FALSE
      } else if (r$value > drm_sep_coef_tol()) {
        hit <- TRUE
      }
    }
    if (hit) flagged <- c(flagged, keep[[jj]])
  }
  list(separated = TRUE, flagged = sort(flagged), conclusive = conclusive)
}

# Near separation (the LP found no exact separating direction but the fit is
# numerically degenerate): some fitted probability within 1e-8 of 0 or 1 AND a
# Wald SE above 1e4 or non-finite. Returns the indices of such coefficients.
drm_near_separation <- function(mu_hat, se) {
  if (!any(pmin(mu_hat, 1 - mu_hat) < drm_sep_near_p())) return(integer())
  which(!is.finite(se) | se > drm_sep_near_se())
}

# Is this binomial spec a fixed-effect route the screen covers?
drm_separation_applicable <- function(spec) {
  identical(spec$model_type, "binomial") &&
    !drm_is_mspl(spec$estimator) &&
    isTRUE(spec$random$mu$n_re == 0L) &&
    !isTRUE(spec$structured$phylo_mu$has) &&
    !isTRUE(spec$missing_predictor$enabled)
}

# Screen a finished fit. Returns NULL when not applicable, else a list with
# `status` ("none", "complete_or_quasi" or "near"), `flagged` (coefficient names
# as in `names(coef(fit)$mu)`) and the constants used.
drm_separation_screen <- function(fit) {
  spec <- fit$model
  if (!isTRUE(drm_separation_applicable(spec))) return(NULL)
  X <- spec$X$mu
  obs <- spec$missing_data$observed_y
  w <- spec$weights
  use <- if (is.null(obs)) rep(TRUE, nrow(X)) else obs
  if (!is.null(w)) use <- use & (w > 0)
  det <- drm_detect_separation(
    X[use, , drop = FALSE], spec$y[use], spec$failures[use]
  )
  status <- "none"
  flagged <- det$flagged
  if (det$separated) {
    status <- "complete_or_quasi"
  } else {
    beta <- fit$coefficients$mu
    eta <- as.numeric(X %*% beta)
    if (!is.null(spec$offset$mu)) eta <- eta + spec$offset$mu
    mu_hat <- stats::binomial(link = spec$link)$linkinv(eta)[use]
    vc <- tryCatch(stats::vcov(fit), error = function(e) NULL)
    mu_labels <- paste0("mu:", colnames(X))
    se <- rep(NA_real_, length(mu_labels))
    if (is.matrix(vc)) {
      v <- diag(vc)[match(mu_labels, rownames(vc))]
      se <- ifelse(is.finite(v) & v >= 0, sqrt(v), NA_real_)
    }
    near <- drm_near_separation(mu_hat, se)
    if (length(near)) {
      status <- "near"
      flagged <- near
    }
  }
  list(
    status = status,
    flagged = colnames(X)[flagged],
    conclusive = det$conclusive
  )
}

# Warn (cli) for a flagged fit. Called once at fit time.
drm_warn_separation <- function(sep) {
  if (is.null(sep) || identical(sep$status, "none")) return(invisible(sep))
  what <- if (identical(sep$status, "near")) {
    "near-separation (a fitted probability within {drm_sep_near_p()} of 0 or 1 together with a Wald SE above {drm_sep_near_se()})"
  } else {
    "(quasi-)complete separation"
  }
  affected <- if (length(sep$flagged)) sep$flagged else "(none identified)"
  cli::cli_warn(
    c(
      paste0("Binomial fixed-effect fit shows ", what, "."),
      "x" = "The maximum-likelihood estimate does not exist or is not finite; the affected coefficients can grow without bound at no cost in likelihood, and the reported values are an arbitrary stopping point of the optimiser.",
      "i" = "Affected coefficient{?s}: {.val {affected}}; the standard error{?s} of {?this/these} coefficient{?s} {?is/are} reported as {.code Inf}.",
      "i" = "Consider removing or collapsing the offending predictor, or the penalised {.code estimator = \"MSPL\"} fit."
    ),
    class = "drmTMB_separation_warning"
  )
  invisible(sep)
}

# Standard errors / variances of flagged mu coefficients are infinite.
drm_separation_flagged_labels <- function(object) {
  sep <- object$separation
  if (is.null(sep) || identical(sep$status, "none") || !length(sep$flagged)) {
    return(character())
  }
  paste0("mu:", sep$flagged)
}
