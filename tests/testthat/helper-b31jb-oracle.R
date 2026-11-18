# Shared base-R oracle for the b31jb Julia Binomial companion tests.
# No drmTMB code is used: hand link functions, dense joint Newton mode and
# Laplace logLik for y | u ~ Bernoulli(linkinv(X beta + M u)), u ~ N(0, K).
# Each block is list(idx, mult, sd, K): idx maps observations to levels, mult
# multiplies the level effect per observation (1 or a numeric covariate), sd is
# the per-level SD vector and K the level covariance (NULL means identity).

b31jb_link <- function(link) {
  switch(
    link,
    logit = list(
      p = function(e) stats::plogis(e),
      p1 = function(e) { p <- stats::plogis(e); p * (1 - p) },
      p2 = function(e) { p <- stats::plogis(e); p * (1 - p) * (1 - 2 * p) }
    ),
    probit = list(
      p = function(e) stats::pnorm(e),
      p1 = function(e) stats::dnorm(e),
      p2 = function(e) -e * stats::dnorm(e)
    ),
    cloglog = list(
      p = function(e) -expm1(-exp(e)),
      p1 = function(e) exp(e - exp(e)),
      p2 = function(e) exp(e - exp(e)) * (1 - exp(e))
    ),
    stop("unknown link")
  )
}

b31jb_clamp <- function(p) pmin(pmax(p, 1e-12), 1 - 1e-12)

b31jb_oracle <- function(y, link, X, beta, blocks) {
  lk <- b31jb_link(link)
  n <- length(y)
  sizes <- vapply(blocks, function(b) length(b$sd), integer(1))
  offsets <- c(0L, cumsum(sizes))
  total <- sum(sizes)
  M <- matrix(0, n, total)
  Q <- matrix(0, total, total)
  logdet_q <- 0
  for (k in seq_along(blocks)) {
    b <- blocks[[k]]
    mult <- if (is.null(b$mult)) rep(1, n) else b$mult
    M[cbind(seq_len(n), offsets[[k]] + b$idx)] <- mult * b$sd[b$idx]
    cols <- offsets[[k]] + seq_len(sizes[[k]])
    if (is.null(b$K)) {
      Q[cbind(cols, cols)] <- 1
    } else {
      ch <- chol(b$K)
      Q[cols, cols] <- chol2inv(ch)
      logdet_q <- logdet_q - 2 * sum(log(diag(ch)))
    }
  }
  eta_fixed <- drop(X %*% beta)
  joint_nll <- function(u) {
    p <- b31jb_clamp(lk$p(eta_fixed + drop(M %*% u)))
    0.5 * sum(u * drop(Q %*% u)) - sum(y * log(p) + (1 - y) * log1p(-p))
  }
  derivs <- function(u) {
    e <- eta_fixed + drop(M %*% u)
    p <- b31jb_clamp(lk$p(e)); p1 <- lk$p1(e); p2 <- lk$p2(e)
    v <- p * (1 - p)
    l1 <- p1 * (y - p) / v
    l2 <- (p2 * (y - p) - p1^2) / v - p1^2 * (y - p) * (1 - 2 * p) / v^2
    list(l1 = l1, w_obs = -l2, w_fisher = p1^2 / v)
  }
  u <- numeric(total)
  converged <- FALSE
  for (iteration in seq_len(200L)) {
    d <- derivs(u)
    gradient <- drop(Q %*% u) - drop(crossprod(M, d$l1))
    hessian <- Q + crossprod(M, M * d$w_obs)
    ch <- tryCatch(chol(hessian), error = function(e) NULL)
    if (is.null(ch)) hessian <- Q + crossprod(M, M * d$w_fisher)
    step <- drop(solve(hessian, gradient))
    if (max(abs(step)) < 1e-8) { converged <- TRUE; break }
    old <- joint_nll(u)
    rate <- 1
    while (rate > 1e-8) {
      candidate <- u - rate * step
      if (joint_nll(candidate) <= old) { u <- candidate; break }
      rate <- rate / 2
    }
    if (rate <= 1e-8) {
      if (max(abs(step)) < 1e-5) { converged <- TRUE; break }
      stop("b31jb Laplace mode did not converge", call. = FALSE)
    }
  }
  if (!converged) stop("b31jb Laplace mode exceeded 200 iterations", call. = FALSE)
  d <- derivs(u)
  hessian <- Q + crossprod(M, M * d$w_obs)
  -joint_nll(u) + 0.5 * logdet_q - sum(log(diag(chol(hessian))))
}

# Hand inverse links for simulation.
b31jb_linkinv <- function(link, eta) b31jb_link(link)$p(eta)

# Hand level-wise SD vector exp(Z alpha), Z = cbind(1, predictor).
b31jb_sd <- function(alpha, predictor) exp(alpha[[1L]] + alpha[[2L]] * predictor)

# Hand spatial kernel for one row of coordinates per level: exponential in
# Euclidean distance with range = median positive distance, plus 1e-6 jitter.
b31jb_spatial_K <- function(coords, range_fun = stats::median) {
  D <- sqrt(outer(coords[, 1L], coords[, 1L], `-`)^2 +
              outer(coords[, 2L], coords[, 2L], `-`)^2)
  K <- exp(-D / range_fun(D[D > 0]))
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(rownames(coords), rownames(coords))
  K
}

# Assert agreement and emulated-bug gaps; returns a one-line message.
b31jb_check <- function(ll, base, gaps, info, agreement_tol = 1e-3) {
  testthat::expect_lt(abs(ll - base), agreement_tol,
                      label = paste(info, "agreement"))
  for (nm in names(gaps)) {
    testthat::expect_gt(abs(gaps[[nm]]), 20 * agreement_tol,
                        label = paste(info, nm, "oracle gap"))
  }
  testthat::expect_gt(min(abs(gaps)) / agreement_tol, 20)
  sprintf("b31jb %s: ll=%.6f oracle=%.6f agreement=%.2e min_gap=%.4f (x%.0f); gaps: %s",
          info, ll, base, abs(ll - base), min(abs(gaps)),
          min(abs(gaps)) / agreement_tol,
          paste(sprintf("%s=%.3f", names(gaps), gaps), collapse = ", "))
}

# The Julia estimates should be a maximum of the independent likelihood.
b31jb_check_optimum <- function(oracle_fn, beta, alphas, base, tol = 1e-3,
                                step = 0.1) {
  for (k in seq_along(beta)) for (s in c(-step, step)) {
    b2 <- beta; b2[[k]] <- b2[[k]] + s
    testthat::expect_lt(oracle_fn(beta = b2), base + tol)
  }
  for (j in seq_along(alphas)) for (k in seq_along(alphas[[j]])) for (s in c(-step, step)) {
    a2 <- alphas; a2[[j]][[k]] <- a2[[j]][[k]] + s
    testthat::expect_lt(oracle_fn(alphas = a2), base + tol)
  }
}

# Exact marginal logLik for independent scalar group effects (iid blocks):
# sum_g log integral prod_i Bernoulli(y_i | eta_i + mult_i * sd_g * u) phi(u) du,
# integrated on a fine trapezoid grid (exponentially accurate for this
# smooth integrand). Uses no drmTMB code and no Laplace approximation.
b31jb_iid_exact <- function(y, link, X, beta, idx, mult, sd, half_width = 10,
                            grid_n = 2001L) {
  lk <- b31jb_link(link)
  u <- seq(-half_width, half_width, length.out = grid_n)
  du <- u[[2L]] - u[[1L]]
  eta_fixed <- drop(X %*% beta)
  if (is.null(mult)) mult <- rep(1, length(y))
  scale_i <- mult * sd[idx]
  eta <- outer(eta_fixed, rep(1, grid_n)) + outer(scale_i, u)
  p <- b31jb_clamp(lk$p(eta))
  ll_obs <- y * log(p) + (1 - y) * log1p(-p)
  ll_group <- rowsum(ll_obs, idx, reorder = TRUE)
  a <- sweep(ll_group, 2L, stats::dnorm(u, log = TRUE) + log(du), `+`)
  m <- apply(a, 1L, max)
  sum(m + log(rowSums(exp(a - m))))
}

# Hand Gauss-Hermite nodes and weights for weight exp(-z^2) (Golub-Welsch).
b31jb_gh <- function(k) {
  J <- matrix(0, k, k)
  if (k > 1L) {
    off <- sqrt(seq_len(k - 1L) / 2)
    J[cbind(seq_len(k - 1L), 2:k)] <- off
    J[cbind(2:k, seq_len(k - 1L))] <- off
  }
  e <- eigen(J, symmetric = TRUE)
  ord <- order(e$values)
  list(z = e$values[ord], w = sqrt(pi) * e$vectors[1L, ord]^2)
}

# Per-group adaptive Gauss-Hermite marginal logLik with nq nodes, the scheme
# the Julia iid route documents (nodes at each group's posterior mode, observed
# curvature), hand-coded from the definition. Groups are independent scalars.
b31jb_iid_aghq <- function(y, link, X, beta, idx, mult, sd, nq = 5L) {
  lk <- b31jb_link(link)
  if (is.null(mult)) mult <- rep(1, length(y))
  eta_fixed <- drop(X %*% beta)
  G <- length(sd)
  scale_i <- mult * sd[idx]
  loglik_i <- function(e) {
    p <- b31jb_clamp(lk$p(e))
    y * log(p) + (1 - y) * log1p(-p)
  }
  d12 <- function(e) {
    p <- b31jb_clamp(lk$p(e)); p1 <- lk$p1(e); p2 <- lk$p2(e)
    v <- p * (1 - p)
    list(l1 = p1 * (y - p) / v,
         l2 = (p2 * (y - p) - p1^2) / v - p1^2 * (y - p) * (1 - 2 * p) / v^2)
  }
  h_group <- function(u) {
    drop(rowsum(loglik_i(eta_fixed + scale_i * u[idx]), idx, reorder = TRUE)) -
      0.5 * u^2
  }
  u <- numeric(G)
  for (iteration in seq_len(100L)) {
    d <- d12(eta_fixed + scale_i * u[idx])
    g1 <- drop(rowsum(scale_i * d$l1, idx, reorder = TRUE)) - u
    g2 <- drop(rowsum(scale_i^2 * d$l2, idx, reorder = TRUE)) - 1
    step <- g1 / g2
    h_old <- h_group(u)
    rate <- 1
    repeat {
      cand <- u - rate * step
      if (all(h_group(cand) >= h_old - 1e-12) || rate < 1e-6) break
      rate <- rate / 2
    }
    u <- cand
    if (max(abs(step)) < 1e-10) break
  }
  d <- d12(eta_fixed + scale_i * u[idx])
  curv <- -(drop(rowsum(scale_i^2 * d$l2, idx, reorder = TRUE)) - 1)
  cc <- 1 / sqrt(curv)
  gh <- b31jb_gh(nq)
  total <- 0
  terms <- matrix(0, G, nq)
  for (k in seq_len(nq)) {
    node <- u + sqrt(2) * cc * gh$z[[k]]
    terms[, k] <- log(gh$w[[k]]) + gh$z[[k]]^2 + log(sqrt(2) * cc) +
      h_group(node) - 0.5 * log(2 * pi)
  }
  m <- apply(terms, 1L, max)
  sum(m + log(rowSums(exp(terms - m))))
}

# Driver for a single structured block (intercept: mult NULL; slope: mult x).
# K is the level covariance aligned to `levels`; K_bugs is a named list of
# wrong kernels (same dimension) to emulate. Evaluates the dense Laplace
# oracle at the live Julia estimates and returns agreement and gaps.
b31jb_struct_run <- function(fit, dat, link, sd_dpar, levels, idx, K, z_level,
                             mult = NULL, K_bugs = list()) {
  beta0 <- unname(coef(fit, dpar = "mu"))
  alpha0 <- unname(coef(fit, dpar = sd_dpar))
  X <- cbind(1, dat$x)
  oracle <- function(beta = beta0, alphas = list(alpha0), Kuse = K,
                     sd_rev = FALSE, mu_sd_swap = FALSE) {
    sdv <- b31jb_sd(alphas[[1L]], z_level)
    if (sd_rev) sdv <- rev(sdv)
    b <- beta
    if (mu_sd_swap) { b <- alphas[[1L]]; sdv <- b31jb_sd(beta, z_level) }
    b31jb_oracle(dat$y, link, X, b,
                 list(list(idx = idx, mult = mult, sd = sdv, K = Kuse)))
  }
  base <- oracle()
  bug_fun <- c(
    list(
      selector_swap = function() oracle(mu_sd_swap = TRUE),
      sd_slope_sign = function() oracle(alphas = list(c(alpha0[[1L]], -alpha0[[2L]]))),
      reversed_sd_vector = function() oracle(sd_rev = TRUE),
      sd_intercept_plus_log2 = function() oracle(alphas = list(alpha0 + c(log(2), 0))),
      K_scale_2 = function() oracle(Kuse = 2 * K)
    ),
    lapply(K_bugs, function(Kb) function() oracle(Kuse = Kb))
  )
  gaps <- vapply(bug_fun, function(f) f(), numeric(1)) - base
  list(ll = as.numeric(stats::logLik(fit)), base = base, gaps = gaps,
       oracle = oracle, beta = beta0, alpha = alpha0)
}
