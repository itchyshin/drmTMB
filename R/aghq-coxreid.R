# Nested O3 estimator (doc 224 S2): adaptive Gauss-Hermite quadrature (AGHQ) inner
# marginalization over a SCALAR random effect per cluster + Cox-Reid outer adjustment
# over the fixed effects, for non-Gaussian families where TMB's joint Laplace `random=`
# fold is insufficient for nominal small-cluster RE-SD coverage (cumulative_logit) or as
# the AGHQ counterpart of the binomial O2 REML path. Scalar RE per cluster: random
# intercept (z == 1) or random slope (z == covariate). This is the callable estimator the
# coverage harness uses to re-score the small-cluster non-Gaussian RE-SD cells.
#
# Two levers (both validated deterministically before any Monte-Carlo, doc 224 S7a):
#   * AGHQ marginal over u (adaptive: recentre at the per-cluster Laplace mode, rescale by
#     curvature; nq=1 collapses EXACTLY to Laplace; nq large -> exact marginal).
#   * Cox-Reid: profile the fixed effects (beta, and for cumulative_logit the cutpoints
#     theta on the pinned theta0+log-gap scale) and add 0.5*log|I| of the AGHQ-marginal
#     information w.r.t. those fixed effects.
# Internal; not exported. Validated in tests/testthat/test-aghq-coxreid.R.

# Gauss-Hermite nodes/weights (physicists': int e^{-x^2} f dx ~ sum w f(x)), via
# Golub-Welsch: nodes are the eigenvalues of the symmetric tridiagonal Jacobi matrix
# (off-diagonal sqrt(k/2) for the Hermite weight e^{-x^2}); weights are sqrt(pi) times
# the squared first components of the normalized eigenvectors. Self-contained (no
# statmod dependency); matches statmod::gauss.quad(.,"hermite") to ~1e-14.
drm_o3_gh <- function(nq) {
  if (nq == 1L) return(list(x = 0, w = sqrt(pi)))
  i <- seq_len(nq - 1L)
  b <- sqrt(i / 2)
  J <- matrix(0, nq, nq)
  J[cbind(i, i + 1L)] <- b
  J[cbind(i + 1L, i)] <- b
  e <- eigen(J, symmetric = TRUE)
  ord <- order(e$values)
  list(x = e$values[ord], w = (sqrt(pi) * e$vectors[1L, ]^2)[ord])
}

# Conditional log-likelihood of one cluster given scalar u. Family-specific leaf; drops
# terms constant in the parameters (log-choose) -- irrelevant to argmax and to the
# Cox-Reid information. `theta` is used only for cumulative_logit.
drm_o3_cluster_ll <- function(u, beta, theta, family, Xm, zm, ym, trials) {
  lin <- as.numeric(Xm %*% beta) + zm * u
  if (family == "binomial") {
    sum(ym * lin - trials * log1p(exp(lin)))
  } else {
    cut <- c(theta[1L], theta[1L] + cumsum(exp(theta[-1L])))
    cutx <- c(-Inf, cut, Inf)
    p <- plogis(cutx[ym + 1L] - lin) - plogis(cutx[ym] - lin)
    sum(log(pmax(p, 1e-300)))
  }
}

# Per-cluster Laplace mode uhat and curvature^{-1/2} tau of g(u) = -[cll + logN(u;0,sd)].
# Newton from a warm start u0 (cached mode from the previous marginal evaluation); Newton
# converges to the SAME mode regardless of start, so the cache only speeds convergence and
# cannot change the answer. Robust golden-section fallback if a Newton step misbehaves.
drm_o3_mode <- function(beta, theta, sd, family, Xm, zm, ym, trials, u0 = 0) {
  inv_s2 <- 1 / sd^2; h <- 1e-4
  cll <- function(uu) drm_o3_cluster_ll(uu, beta, theta, family, Xm, zm, ym, trials)
  u <- u0; ok <- TRUE
  for (it in seq_len(50L)) {
    f0 <- cll(u); fp <- cll(u + h); fm <- cll(u - h)
    g1 <- -(fp - fm) / (2 * h) + u * inv_s2          # g'(u),  g = -[cll + logN(0,sd)]
    g2 <- -(fp - 2 * f0 + fm) / (h * h) + inv_s2      # g''(u)
    if (!is.finite(g2) || g2 <= 1e-8) { ok <- FALSE; break }
    step <- g1 / g2; u <- u - step
    if (!is.finite(u)) { ok <- FALSE; break }
    if (abs(step) < 1e-9) break
  }
  if (!ok) {
    f <- function(uu) -(cll(uu) + dnorm(uu, 0, sd, log = TRUE))
    u <- stats::optimize(f, c(-8 * sd, 8 * sd), tol = 1e-9)$minimum
  }
  f0 <- cll(u); fp <- cll(u + h); fm <- cll(u - h)
  g2 <- -(fp - 2 * f0 + fm) / (h * h) + inv_s2
  list(uhat = u, tau = 1 / sqrt(g2))
}

# AGHQ marginal log-likelihood, summed over clusters (adaptive, doc 224 S4.4). `cache` (an
# env with numeric $m indexed by cluster position) warm-starts each cluster's mode search
# and is updated in place -- a pure speedup, mathematically inert.
drm_o3_marginal_ll <- function(beta, theta, sd, family, X, z, y, group_idx, trials, nodes, cache = NULL) {
  tot <- 0
  for (k in seq_along(group_idx)) {
    idx <- group_idx[[k]]
    u0 <- if (is.null(cache)) 0 else cache$m[k]
    m <- drm_o3_mode(beta, theta, sd, family, X[idx, , drop = FALSE], z[idx], y[idx], trials[idx], u0 = u0)
    if (!is.null(cache)) cache$m[k] <- m$uhat
    zz <- m$uhat + sqrt(2) * m$tau * nodes$x
    logh <- vapply(zz, function(uu)
      drm_o3_cluster_ll(uu, beta, theta, family, X[idx, , drop = FALSE], z[idx], y[idx], trials[idx]) +
        dnorm(uu, 0, sd, log = TRUE), numeric(1))
    a <- log(nodes$w) + nodes$x^2 + logh
    Mx <- max(a)
    tot <- tot + log(sqrt(2) * m$tau) + Mx + log(sum(exp(a - Mx)))
  }
  tot
}

# Pack/unpack the fixed-effect vector psi = (beta, theta) for a family.
drm_o3_npar <- function(family, p, K) if (family == "binomial") p else p + (K - 1L)
drm_o3_split <- function(psi, family, p) {
  if (family == "binomial") list(beta = psi, theta = NULL)
  else list(beta = psi[seq_len(p)], theta = psi[-seq_len(p)])
}

# The Cox-Reid restricted negative log-likelihood at a given sd: profile (beta,theta) out
# of the AGHQ marginal, then add 0.5*log|I_{psi psi}| (Hessian of the profiled negative
# AGHQ marginal). Returns -ell_R(sd) and the profiled psi.
drm_o3_cr_negll <- function(sd, family, X, z, y, group_idx, trials, K, nodes, psi_start, cache = NULL) {
  p <- ncol(X)
  fpsi <- function(psi) {
    s <- drm_o3_split(psi, family, p)
    -drm_o3_marginal_ll(s$beta, s$theta, sd, family, X, z, y, group_idx, trials, nodes, cache)
  }
  o <- stats::optim(psi_start, fpsi, method = "BFGS", control = list(reltol = 1e-8))
  H <- stats::optimHess(o$par, fpsi)
  list(value = o$value + 0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus),
       psi = o$par)
}

# Fit the nested O3 estimator. Returns sd_hat, the fixed effects, and the restricted
# log-likelihood function of log-sd (for the profile CI). `estimator`:
#   "aghq"      -> AGHQ marginal ML (no Cox-Reid; oracle = glmer nAGQ)
#   "aghq_cr"   -> AGHQ + Cox-Reid (the O3 nominal object)
drm_o3_fit <- function(y, X, z, group, family = c("binomial", "cumulative_logit"),
                       nodes = 25L, estimator = c("aghq_cr", "aghq"),
                       trials = NULL, sd_bounds = c(1e-3, 5), n_categories = NULL) {
  family <- match.arg(family)
  estimator <- match.arg(estimator)
  stopifnot(is.matrix(X))
  group <- as.integer(as.factor(group))
  group_idx <- split(seq_along(group), group)
  if (is.null(trials)) trials <- rep(1, length(y))
  # K = number of ordinal categories. NEVER infer from length(unique(y)): a small /
  # low-information sample can omit a category, which would mis-specify the cutpoint
  # count and index cutx[ym + 1] out of range. Caller passes n_categories (the coverage
  # harness knows it); default to max(y) but require the top category to be present.
  K <- if (family == "cumulative_logit") {
    if (is.null(n_categories)) max(y) else n_categories
  } else 2L
  if (family == "cumulative_logit" && (max(y) > K || min(y) < 1L)) {
    stop("cumulative_logit y must be coded 1..n_categories; observed max exceeds K")
  }
  nd <- drm_o3_gh(nodes)
  p <- ncol(X)
  npar <- drm_o3_npar(family, p, K)
  # sensible starts: 0 for beta; increasing cutpoints for theta
  psi0 <- if (family == "binomial") rep(0, p) else c(rep(0, p), c(-1, rep(0, K - 2L)))
  cache <- new.env(parent = emptyenv()); cache$m <- numeric(length(group_idx))   # per-cluster mode warm-start

  if (estimator == "aghq") {
    obj <- function(par) {
      s <- drm_o3_split(par[seq_len(npar)], family, p)
      -drm_o3_marginal_ll(s$beta, s$theta, exp(par[npar + 1L]), family, X, z, y, group_idx, trials, nd, cache)
    }
    o <- stats::optim(c(psi0, log(0.7)), obj, method = "BFGS", control = list(reltol = 1e-8, maxit = 400))
    s <- drm_o3_split(o$par[seq_len(npar)], family, p)
    return(list(sd = exp(o$par[npar + 1L]), beta = s$beta, theta = s$theta,
                estimator = estimator, nodes = nodes, family = family))
  }

  # aghq_cr: outer optimize over log-sd of the Cox-Reid restricted negative loglik,
  # warm-starting psi from the previous evaluation.
  psi_env <- new.env(); psi_env$psi <- psi0
  llR <- function(logsd) {
    r <- drm_o3_cr_negll(exp(logsd), family, X, z, y, group_idx, trials, K, nd, psi_env$psi, cache)
    psi_env$psi <- r$psi
    -r$value                                   # ell_R(sd)
  }
  o <- stats::optimize(function(ls) -llR(ls), log(sd_bounds), tol = 1e-5)
  sd_hat <- exp(o$minimum)
  list(sd = sd_hat, beta = drm_o3_split(psi_env$psi, family, p)$beta,
       theta = drm_o3_split(psi_env$psi, family, p)$theta,
       estimator = estimator, nodes = nodes, family = family, llR = llR,
       logsd_hat = o$minimum, sd_bounds = sd_bounds)
}

# Profile-likelihood CI for the RE-SD from the Cox-Reid restricted objective, on the
# NATURAL RE-SD scale (doc 224 S4.7). Root-find D(sd)=2[ellR(hat)-ellR(sd)] = qchisq(level,1).
# Flags a non-finite endpoint (boundary pile-up) rather than inventing one. NOTE: the chi^2_1
# pivot is the interior reference; near sd=0 the 50:50 chi^2_0:chi^2_1 mixture applies -- the
# S7 gate scores boundary/non-finite endpoints explicitly.
drm_o3_profile_ci <- function(fit, level = 0.95) {
  stopifnot(!is.null(fit$llR))
  q <- stats::qchisq(level, 1)
  ll_hat <- fit$llR(fit$logsd_hat)
  dev <- function(ls) 2 * (ll_hat - fit$llR(ls)) - q
  lo_b <- log(fit$sd_bounds[1L]); hi_b <- log(fit$sd_bounds[2L])
  find <- function(interval) {
    f0 <- dev(interval[1L]); f1 <- dev(interval[2L])
    if (is.na(f0) || is.na(f1) || f0 * f1 > 0) return(NA_real_)
    exp(stats::uniroot(dev, interval, tol = 1e-6)$root)
  }
  lower <- find(c(lo_b, fit$logsd_hat))
  upper <- find(c(fit$logsd_hat, hi_b))
  list(estimate = fit$sd, lower = lower, upper = upper,
       finite = is.finite(lower) && is.finite(upper), level = level)
}
