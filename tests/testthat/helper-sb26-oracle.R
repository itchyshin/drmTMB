# Shared, drmTMB-independent oracle pieces for the b26 sensitivity companions.
# Everything here is plain base R (plus ape::vcv for trees). None of it calls
# drmTMB internals; tests compare the package helpers against these pieces,
# never the other way round.

# Henderson tabular additive-relationship matrix. `ped` has columns id, dam,
# sire (NA for unknown) and parents listed before offspring.
sb26_tabular_A <- function(ped) {
  ids <- as.character(ped$id)
  n <- length(ids)
  pos <- function(p) if (is.na(p)) NA_integer_ else match(as.character(p), ids)
  A <- matrix(0, n, n, dimnames = list(ids, ids))
  for (i in seq_len(n)) {
    s <- pos(ped$sire[i])
    d <- pos(ped$dam[i])
    stopifnot(is.na(s) || s < i, is.na(d) || d < i)
    for (j in seq_len(i - 1L)) {
      a <- (if (is.na(s)) 0 else A[j, s]) + (if (is.na(d)) 0 else A[j, d])
      A[i, j] <- A[j, i] <- 0.5 * a
    }
    A[i, i] <- 1 + if (is.na(s) || is.na(d)) 0 else 0.5 * A[s, d]
  }
  A
}

# Pedigree with full-sib matings (inbred offspring, diag(A) = 1.25), so a
# cov2cor(A) mistake changes the likelihood.
sb26_inbred_pedigree <- function(n_family, n_inbred = 4L) {
  rows <- function(f) {
    data.frame(
      id = c(paste0("sire", f), paste0("dam", f), paste0("fsm", f),
             paste0("fsf", f), sprintf("inb%s_%d", f, seq_len(n_inbred))),
      dam = c(NA, NA, rep(paste0("dam", f), 2L),
              rep(paste0("fsf", f), n_inbred)),
      sire = c(NA, NA, rep(paste0("sire", f), 2L),
               rep(paste0("fsm", f), n_inbred)),
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, lapply(sprintf("%02d", seq_len(n_family)), rows))
}

# Exponential kernel on the median positive distance with a 1e-6 diagonal
# jitter, built by hand from named coordinates (rows ordered by `levels`).
sb26_spatial_kernel <- function(coords, levels) {
  d <- as.matrix(stats::dist(as.matrix(coords[levels, 1:2])))
  pos <- d[upper.tri(d)]
  K <- exp(-d / stats::median(pos[pos > 0]))
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(levels, levels)
  K
}

# Phylogenetic covariance from ape::vcv, standardised to unit tree height
# (the native scale convention; the SD intercept absorbs the scale).
sb26_phylo_K <- function(tree, levels) {
  V <- ape::vcv(tree)
  (V / max(diag(V)))[levels, levels]
}

# n x L design: row i has weight w_i * s[idx_i] in column idx_i (unit-scale
# latent field; the SD vector enters multiplicatively).
sb26_Z <- function(idx, n_level, s, w = 1) {
  Z <- matrix(0, length(idx), n_level)
  Z[cbind(seq_along(idx), idx)] <- w * s[idx]
  Z
}

sb26_blockdiag <- function(...) {
  blocks <- list(...)
  m <- sum(vapply(blocks, nrow, integer(1L)))
  out <- matrix(0, m, m)
  at <- 0L
  for (b in blocks) {
    k <- nrow(b)
    out[at + seq_len(k), at + seq_len(k)] <- b
    at <- at + k
  }
  out
}

# Per-observation log-likelihood, d/d eta and d2/d eta2 for several families.
sb26_deriv_poisson <- function(y) {
  function(eta) {
    mu <- exp(eta)
    list(l = stats::dpois(y, mu, log = TRUE), d1 = y - mu, d2 = -mu)
  }
}
sb26_deriv_nb2 <- function(y, size) {
  function(eta) {
    mu <- exp(eta)
    list(l = stats::dnbinom(y, size = size, mu = mu, log = TRUE),
         d1 = y - (y + size) * mu / (mu + size),
         d2 = -(y + size) * mu * size / (mu + size)^2)
  }
}
sb26_deriv_gamma <- function(y, shape) {
  function(eta) {
    mu <- exp(eta)
    list(l = stats::dgamma(y, shape = shape, scale = mu / shape, log = TRUE),
         d1 = shape * (y / mu - 1), d2 = -shape * y / mu)
  }
}
sb26_deriv_binary <- function(y, link) {
  # Numerically stable forms (log-scale probabilities, Mills ratios), so the
  # line search stays finite for large |eta|.
  function(eta) {
    if (identical(link, "probit")) {
      l1 <- stats::pnorm(eta, log.p = TRUE)
      l0 <- stats::pnorm(-eta, log.p = TRUE)
      ld <- stats::dnorm(eta, log = TRUE)
      lam1 <- exp(ld - l1)
      lam0 <- exp(ld - l0)
      list(l = y * l1 + (1 - y) * l0,
           d1 = y * lam1 - (1 - y) * lam0,
           d2 = -y * lam1 * (eta + lam1) - (1 - y) * lam0 * (lam0 - eta))
    } else {
      e <- exp(eta)
      p <- -expm1(-e)
      list(l = y * log(p) - (1 - y) * e,
           d1 = y * e / p - e,
           d2 = y * (e / p - e^2 * exp(-e) / p^2) - e)
    }
  }
}

# Dense Laplace log marginal likelihood for eta = eta_fixed + Z u, u ~ N(0,
# Sigma), observed information:  l(u*) - u*' S^-1 u* / 2 - log|I + S Z'WZ| / 2.
sb26_laplace <- function(deriv, eta_fixed, Z, Sigma) {
  m <- ncol(Z)
  Pinv <- solve(Sigma)
  pen <- function(u) {
    v <- sum(deriv(eta_fixed + drop(Z %*% u))$l) - 0.5 * sum(u * (Pinv %*% u))
    if (is.finite(v)) v else -Inf
  }
  u <- numeric(m)
  for (iter in seq_len(300L)) {
    d <- deriv(eta_fixed + drop(Z %*% u))
    grad <- drop(crossprod(Z, d$d1)) - drop(Pinv %*% u)
    H <- crossprod(Z, Z * (-d$d2)) + Pinv
    step <- drop(solve(H, grad))
    f0 <- pen(u)
    s <- 1
    while (pen(u + s * step) < f0 - 1e-12 && s > 1e-10) s <- s / 2
    u <- u + s * step
    if (max(abs(s * step)) < 1e-11) break
  }
  d <- deriv(eta_fixed + drop(Z %*% u))
  pen(u) - 0.5 * as.numeric(determinant(
    diag(m) + Sigma %*% crossprod(Z, Z * (-d$d2)), logarithm = TRUE
  )$modulus)
}

# Exact Gaussian marginal log-likelihood, y ~ N(mu, sigma^2 I + Z S Z').
sb26_gauss_loglik <- function(y, mu, sigma, Z, Sigma) {
  V <- Z %*% Sigma %*% t(Z) + diag(sigma^2, length(y))
  R <- chol(V)
  r <- backsolve(R, y - mu, transpose = TRUE)
  -0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

# Reverse a named vector's values across its names (misaligned SD vector).
sb26_reverse <- function(v) stats::setNames(rev(unname(v)), names(v))
