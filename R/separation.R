# Separation screen for fixed-effect binomial / Bernoulli fits (drmTMB #1268;
# twin contract DRModels.jl #731 / #728).
#
# Provenance: ported from the DRModels.jl twin (`src/separation.jl`, MIT, same
# owner) into this GPL package; the two implementations are kept in lockstep
# (same algorithm, same constants, same flagged coefficients on the same data).
#
# Policy (owner decision 2026-09-30, "detect and warn"): the fit is still
# returned, a warning names the affected coefficients, and their standard
# errors are reported as Inf (vcov, summary, Wald confint and tidy agree). No
# refusal and no penalised estimator by default (MSPL stays an explicit opt-in,
# `estimator = "mspl"`). The two packages agree on WHICH coefficients are
# flagged and on the warning, not on the (non-existent) maximum-likelihood
# coefficients.
#
# Method (the separation criterion of Albert & Anderson 1984 / Konis 2007,
# written here from the published mathematics and without `detectseparation`).
# With signed design rows a_i = x_i for a success and -x_i for a failure, the
# likelihood has no finite maximiser iff the cone C = {d : A d >= 0} holds a
# direction with a_i . d > 0 for some row: moving along d never lowers the
# likelihood. The same holds for logit, probit and cloglog links (the cone
# depends on the sign pattern only, not on offsets or positive weights).
#
# Algorithm (#1442 review: replaces a Bland-rule simplex that stalled on
# degenerate designs). By Farkas' lemma, for a row set U either
# -sum_{i in U} a_i lies in cone(rows), or some d in C has sum_U a_i . d > 0.
# A Lawson-Hanson non-negative least-squares solve of
# min_{y >= 0} || A' y + sum_U a_i || decides which: its residual r is zero in
# the first case, and otherwise r itself is in C with sum_U a_i . r = ||r||^2.
# Starting from U = all rows, every non-zero residual moves the rows it
# separates out of U; when the residual vanishes the remaining rows J are tied
# (a_i . d = 0 for every d in C), and C spans the null space of A_J.
# Coefficient j is flagged iff that null space has a non-zero j-th coordinate,
# i.e. iff SOME direction in C moves beta_j. (detectseparation reports the
# components of one particular LP direction instead, so the two can differ in
# which coefficients they list; we do not claim parity with it.) Typically one
# or two NNLS solves; each is bounded by an iteration budget, and an exhausted
# budget is reported (`conclusive = FALSE`) and warned about, never read as
# "no separation".
#
# Scope: fixed-effect binomial fits (no random effects, no phylo term, no
# missing-predictor model). Random-effect routes are not screened: a random
# intercept can absorb part of the separation, so the fixed-design check does
# not decide it.

# Constants shared with the DRModels.jl twin; keep identical in both packages.
drm_sep_obj_tol <- function() 1e-9   # row margin (box-scaled direction) above this => row separated
drm_sep_coef_tol <- function() 1e-6  # |null-space coordinate| above this => coefficient flagged
drm_sep_rank_tol <- function() 1e-10 # relative singular value below this => rank-deficient
drm_sep_resid_tol <- function() 1e-8 # relative NNLS residual below this => no separating direction
drm_sep_max_iter <- function(q) 20L * q + 200L  # NNLS budget (inner steps) per screen
drm_sep_near_p <- function() 1e-8    # near separation: a fitted probability within this of 0/1 ...
drm_sep_near_z <- function() 0.05    # ... and |beta_j / SE_j| below this ...
# ... while beta_j alone moves the linear predictor across the whole
# [near_p, 1 - near_p] probability range (|beta_j| * range(x_j) above
# g(1 - near_p) - g(near_p); 36.84 on the logit scale).

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

# Lawson-Hanson NNLS: minimise || t(A) y + cvec || over y >= 0. Returns
# list(r, converged, iter) with r = t(A) y + cvec the residual. At a converged
# solution A r >= 0 (KKT), so r is in the separation cone.
drm_sep_nnls <- function(A, cvec, maxiter) {
  m <- nrow(A)
  y <- numeric(m)
  P <- logical(m)
  banned <- logical(m)
  r <- cvec
  tol <- 1e-12 * max(1, sqrt(sum(cvec^2)))
  iter <- 0L
  repeat {
    w <- -as.numeric(A %*% r)
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
        # the entering variable cannot move (numerical tie): set it aside
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

# Separation screen. Returns list(separated, flagged, conclusive) where
# `flagged` are the column indices of `X` whose coefficients can diverge and
# `conclusive = FALSE` means the iteration budget ran out (the verdict is then
# incomplete and must be reported as such). `max_iter` overrides the NNLS
# budget (`drm_sep_max_iter(q)`); tests only.
drm_detect_separation <- function(X, successes, failures, max_iter = NULL) {
  none <- list(separated = FALSE, flagged = integer(), conclusive = TRUE)
  cons <- drm_sep_constraints(X, successes, failures)
  A <- cons$A
  keep <- cons$keep
  q <- length(keep)
  if (q == 0L || nrow(A) == 0L) return(none)
  budget <- if (is.null(max_iter)) drm_sep_max_iter(q) else max_iter
  pos <- logical(nrow(A))   # rows some cone direction separates strictly
  conclusive <- TRUE
  repeat {
    U <- !pos
    if (!any(U)) break
    cU <- colSums(A[U, , drop = FALSE])
    nn <- drm_sep_nnls(A, cU, budget)
    budget <- budget - nn$iter
    if (!nn$converged) {
      conclusive <- FALSE
      break
    }
    r <- nn$r
    if (sqrt(sum(r^2)) <= drm_sep_resid_tol() * max(1, sqrt(sum(cU^2)))) break
    marg <- as.numeric(A %*% (r / max(abs(r))))
    new <- U & marg > drm_sep_obj_tol()
    if (min(marg) < -drm_sep_resid_tol() || !any(new)) {
      conclusive <- FALSE   # numerically unreliable direction: do not guess
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
      apply(abs(N), 1L, max) > drm_sep_coef_tol()
    }
  }
  list(separated = TRUE, flagged = keep[flag], conclusive = conclusive)
}

# Near separation (no exact separating direction, but a coefficient sits far
# out on a flat likelihood ridge). Scale-free: coefficient j is flagged when
# some fitted probability is within `drm_sep_near_p()` of 0 or 1, beta_j alone
# moves the linear predictor across the whole [p, 1 - p] range
# (|beta_j| * range(x_j) > g(1 - p) - g(p)), and its Wald |z| is below
# `drm_sep_near_z()`. A missing or non-finite SE (se = FALSE, a failed vcov)
# is never evidence of near separation. Returns the flagged column indices.
drm_near_separation <- function(mu_hat, beta, se, xrange, link = "logit") {
  p <- drm_sep_near_p()
  if (!any(pmin(mu_hat, 1 - mu_hat) < p, na.rm = TRUE)) return(integer())
  lf <- stats::binomial(link = link)$linkfun
  eta_span <- abs(lf(1 - p) - lf(p))
  ok <- is.finite(se) & se > 0 & is.finite(beta)
  z <- ifelse(ok, abs(beta) / ifelse(ok, se, 1), NA_real_)
  which(ok & abs(beta) * xrange > eta_span & z < drm_sep_near_z())
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
# `status` ("none", "complete_or_quasi", "near" or "inconclusive"), `flagged`
# (coefficient names as in `names(coef(fit)$mu)`) and `conclusive` (FALSE when
# the separation check ran out of its iteration budget).
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
    mu_labels <- paste0("mu:", colnames(X))
    se <- rep(NA_real_, length(mu_labels))
    vc <- tryCatch(
      suppressWarnings(stats::vcov(fit)),
      error = function(e) NULL
    )
    if (is.matrix(vc)) {
      v <- diag(vc)[match(mu_labels, rownames(vc))]
      se <- ifelse(is.finite(v) & v > 0, sqrt(v), NA_real_)
    }
    xrange <- apply(X[use, , drop = FALSE], 2L, function(col) diff(range(col)))
    near <- drm_near_separation(mu_hat, beta, se, xrange, link = spec$link)
    if (length(near)) {
      status <- "near"
      flagged <- near
    } else if (!det$conclusive) {
      status <- "inconclusive"
    }
  }
  list(
    status = status,
    flagged = colnames(X)[flagged],
    conclusive = det$conclusive
  )
}

# Warn (cli) for a flagged or inconclusive fit. Called once at fit time.
drm_warn_separation <- function(sep) {
  if (is.null(sep) || identical(sep$status, "none")) return(invisible(sep))
  if (identical(sep$status, "inconclusive")) {
    cli::cli_warn(
      c(
        "The separation check for this binomial fixed-effect fit was inconclusive (its iteration budget ran out).",
        "i" = "Separation is neither confirmed nor ruled out; inspect large coefficients and standard errors, or compare with the penalised {.code estimator = \"mspl\"} fit."
      ),
      class = "drmTMB_separation_warning"
    )
    return(invisible(sep))
  }
  what <- if (identical(sep$status, "near")) {
    "near-separation (a coefficient that moves the linear predictor across the whole 1e-8 to 1 - 1e-8 probability range has Wald |z| below {drm_sep_near_z()}, with fitted probabilities within {drm_sep_near_p()} of 0 or 1)"
  } else {
    "(quasi-)complete separation"
  }
  affected <- if (length(sep$flagged)) sep$flagged else "(none identified)"
  msg <- c(
    paste0("Binomial fixed-effect fit shows ", what, "."),
    "x" = "The maximum-likelihood estimate does not exist or is not finite; the affected coefficients can grow without bound at little or no cost in likelihood, and the reported values are an arbitrary stopping point of the optimiser.",
    "i" = "Affected coefficient{?s}: {.val {affected}}; the standard error{?s} of {?this/these} coefficient{?s} {?is/are} reported as {.code Inf} and {?its/their} Wald interval{?s} as {.code (-Inf, Inf)}.",
    "i" = "Consider removing or collapsing the offending predictor, or the penalised {.code estimator = \"mspl\"} fit."
  )
  if (isFALSE(sep$conclusive)) {
    msg <- c(msg, "!" = "The separation check ran out of its iteration budget, so this list may be incomplete.")
  }
  cli::cli_warn(msg, class = "drmTMB_separation_warning")
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
