# Shared base-R oracles for the batch 34 Julia companion tests. No drmTMB
# code is used. Three independent likelihoods, each evaluated at the live
# Julia estimates:
#   b34_gaussian_marginal(): exact Gaussian marginal logLik for
#     y = X beta + diag(sd[idx]) w[idx] + e, w ~ N(0, K), e ~ N(0, sigma^2).
#   b34_laplace(): dense Laplace logLik for Poisson, NB2 (size 1 / sigma^2)
#     and Gamma (shape 1 / sigma^2) log-link responses with the same latent
#     structure, hand-coded derivatives and a joint Newton mode.
#   b34_iid_exact(): exact per-group one-dimensional integral for independent
#     scalar group effects (ZeroOneBeta and zero-inflated Poisson), on a fine
#     trapezoid grid.
# The kernels are built by hand here (Henderson tabular A from an inbred
# pedigree, exponential coordinate kernel with median range and 1e-6 jitter).

b34_sd <- function(alpha, predictor) exp(alpha[[1L]] + alpha[[2L]] * predictor)

# Hand coordinate kernel: exp(-d / median positive distance) + 1e-6 I.
b34_coord_kernel <- function(coords) {
  D <- sqrt(outer(coords[, 1L], coords[, 1L], `-`)^2 +
              outer(coords[, 2L], coords[, 2L], `-`)^2)
  K <- exp(-D / stats::median(D[D > 0]))
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(rownames(coords), rownames(coords))
  K
}

# Henderson tabular additive relationship matrix; parents must precede
# offspring. sire / dam are 0 for founders.
b34_henderson_A <- function(sire, dam, names) {
  n <- length(sire)
  A <- matrix(0, n, n)
  for (i in seq_len(n)) {
    s <- sire[[i]]; d <- dam[[i]]
    if (i > 1L) for (j in seq_len(i - 1L)) {
      a <- 0.5 * ((if (s > 0L) A[s, j] else 0) + (if (d > 0L) A[d, j] else 0))
      A[i, j] <- a; A[j, i] <- a
    }
    A[i, i] <- 1 + if (s > 0L && d > 0L) 0.5 * A[s, d] else 0
  }
  dimnames(A) <- list(names, names)
  A
}

# 40 animals: 8 founders, 16 full-sib offspring in four families, then 16
# offspring of full-sib matings (inbreeding F = 0.25, diagonal 1.25).
b34_inbred_pedigree <- function() {
  sire <- integer(40L); dam <- integer(40L)
  for (f in 1:4) {
    kids <- 8L + (f - 1L) * 4L + 1:4
    sire[kids] <- 2L * f - 1L
    dam[kids] <- 2L * f
  }
  for (f in 1:4) {
    sibs <- 8L + (f - 1L) * 4L + 1:4
    kids <- 24L + (f - 1L) * 4L + 1:4
    sire[kids[1:2]] <- sibs[[1L]]; dam[kids[1:2]] <- sibs[[2L]]
    sire[kids[3:4]] <- sibs[[3L]]; dam[kids[3:4]] <- sibs[[4L]]
  }
  names <- sprintf("a%02d", 1:40)
  list(sire = sire, dam = dam, names = names,
       A = b34_henderson_A(sire, dam, names))
}

b34_gaussian_marginal <- function(y, X, beta, sigma, idx, sd, K) {
  S <- (sd %o% sd) * K
  V <- S[idx, idx, drop = FALSE]
  diag(V) <- diag(V) + sigma^2
  ch <- chol(V)
  r <- backsolve(ch, y - drop(X %*% beta), transpose = TRUE)
  -0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(ch))) + sum(r^2))
}

# Per-observation log density and first two eta-derivatives (log link).
b34_family <- function(family, disp) {
  switch(
    family,
    poisson = list(
      ll = function(y, e) y * e - exp(e) - lgamma(y + 1),
      d1 = function(y, e) y - exp(e),
      d2 = function(y, e) -exp(e)
    ),
    nbinom2 = {
      r <- 1 / disp^2
      list(
        ll = function(y, e) {
          m <- exp(e)
          lgamma(y + r) - lgamma(r) - lgamma(y + 1) + r * log(r / (r + m)) +
            y * log(m / (r + m))
        },
        d1 = function(y, e) { m <- exp(e); r * (y - m) / (r + m) },
        d2 = function(y, e) { m <- exp(e); -r * m * (r + y) / (r + m)^2 }
      )
    },
    gamma = {
      k <- 1 / disp^2
      list(
        ll = function(y, e) k * log(k) - k * e - lgamma(k) + (k - 1) * log(y) -
          k * y * exp(-e),
        d1 = function(y, e) -k + k * y * exp(-e),
        d2 = function(y, e) -k * y * exp(-e)
      )
    },
    stop("unknown family")
  )
}

b34_laplace <- function(y, family, X, beta, disp, idx, sd, K) {
  fam <- b34_family(family, disp)
  n <- length(y); G <- length(sd)
  M <- matrix(0, n, G)
  M[cbind(seq_len(n), idx)] <- sd[idx]
  ch <- chol(K)
  Q <- chol2inv(ch)
  logdet_q <- -2 * sum(log(diag(ch)))
  eta0 <- drop(X %*% beta)
  nll <- function(u) 0.5 * sum(u * drop(Q %*% u)) -
    sum(fam$ll(y, eta0 + drop(M %*% u)))
  u <- numeric(G)
  for (iteration in seq_len(200L)) {
    e <- eta0 + drop(M %*% u)
    gradient <- drop(Q %*% u) - drop(crossprod(M, fam$d1(y, e)))
    hessian <- Q + crossprod(M, M * (-fam$d2(y, e)))
    step <- drop(solve(hessian, gradient))
    if (max(abs(step)) < 1e-9) break
    old <- nll(u); rate <- 1
    while (rate > 1e-10) {
      cand <- u - rate * step
      if (is.finite(nll(cand)) && nll(cand) <= old) { u <- cand; break }
      rate <- rate / 2
    }
    if (rate <= 1e-10) stop("b34 Laplace mode did not converge", call. = FALSE)
  }
  e <- eta0 + drop(M %*% u)
  hessian <- Q + crossprod(M, M * (-fam$d2(y, e)))
  -nll(u) + 0.5 * logdet_q - sum(log(diag(chol(hessian))))
}

# Exact per-group integral. loglik_i(eta) returns per-observation log density
# for a vector of linear predictors (a matrix is allowed); mult is NULL for an
# intercept and the covariate for a slope.
b34_iid_exact <- function(loglik_i, eta0, idx, mult, sd, half_width = 10,
                          grid_n = 4001L) {
  u <- seq(-half_width, half_width, length.out = grid_n)
  du <- u[[2L]] - u[[1L]]
  if (is.null(mult)) mult <- rep(1, length(eta0))
  eta <- outer(eta0, rep(1, grid_n)) + outer(mult * sd[idx], u)
  ll <- matrix(loglik_i(eta), nrow = length(eta0))
  ll_group <- rowsum(ll, idx, reorder = TRUE)
  a <- sweep(ll_group, 2L, stats::dnorm(u, log = TRUE) + log(du), `+`)
  m <- apply(a, 1L, max)
  sum(m + log(rowSums(exp(a - m))))
}

# ZeroOneBeta: atoms 0 / 1 with probability zoi (1 - coi) / zoi coi, interior
# (1 - zoi) Beta(mu phi, (1 - mu) phi), phi = 1 / sigma^2, mu = plogis(eta).
b34_zob_ll <- function(y, sigma, zoi, coi) {
  phi <- 1 / sigma^2
  force(y)
  function(eta) {
    mu <- stats::plogis(eta)
    yy <- matrix(y, nrow = nrow(eta), ncol = ncol(eta))
    interior <- yy > 0 & yy < 1
    out <- matrix(0, nrow(eta), ncol(eta))
    out[yy <= 0] <- log(zoi) + log1p(-coi)
    out[yy >= 1] <- log(zoi) + log(coi)
    ys <- yy[interior]
    out[interior] <- log1p(-zoi) +
      stats::dbeta(ys, mu[interior] * phi, (1 - mu[interior]) * phi, log = TRUE)
    out
  }
}

# Zero-inflated Poisson: P(0) = zi + (1 - zi) exp(-lambda), else (1 - zi) Pois.
b34_zip_ll <- function(y, zi) {
  force(y)
  function(eta) {
    yy <- matrix(y, nrow = nrow(eta), ncol = ncol(eta))
    lam <- exp(eta)
    pois <- stats::dpois(yy, lam, log = TRUE)
    ifelse(yy == 0, log(zi + (1 - zi) * exp(-lam)), log1p(-zi) + pois)
  }
}

# Assert agreement and bug gaps (each > 20 times the stated agreement
# tolerance); returns a one-line summary for the console log.
b34_check <- function(ll, base, gaps, info, agreement_tol) {
  testthat::expect_lt(abs(ll - base), agreement_tol,
                      label = paste(info, "agreement"))
  for (nm in names(gaps)) {
    testthat::expect_gt(abs(gaps[[nm]]), 20 * agreement_tol,
                        label = paste(info, nm, "oracle gap"))
  }
  sprintf("b34 %s: ll=%.8f oracle=%.8f agreement=%.2e min_gap=%.4f (x%.0f of tol %.0e); gaps: %s",
          info, ll, base, abs(ll - base), min(abs(gaps)),
          min(abs(gaps)) / agreement_tol, agreement_tol,
          paste(sprintf("%s=%.3f", names(gaps), gaps), collapse = ", "))
}

b34_live_setup <- function(.local_envir = parent.frame()) {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  testthat::skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
                    "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path, .local_envir = .local_envir)
  drm_test_local_julia_home(.local_envir = .local_envir)
}

# Evaluate the oracle for a structured intercept route at the Julia fit and
# the emulated-bug gaps. `family` is "gaussian", "poisson", "nbinom2" or
# "gamma"; K is the kernel aligned to `levels`; K_given is the same kernel as
# the user supplied it (a different row order), used only by the by-position
# bug. Bugs: swapped mu / SD selectors, reversed SD vector, cov2cor(K),
# kernel read by position, plus the route's own kernel bugs in K_bugs
# (cov2cor(K) for relmat and animal; a mean-distance range for spatial, whose
# kernel has unit diagonal so cov2cor would be a no-op).
b34_struct_run <- function(fit, dat, family, sd_dpar, levels, K, K_given,
                           z_level, K_bugs = list(cov2cor_K = stats::cov2cor(K))) {
  idx <- match(as.character(dat$id), levels)
  X <- cbind(1, dat$x)
  beta0 <- unname(coef(fit, dpar = "mu"))
  alpha0 <- unname(coef(fit, dpar = sd_dpar))
  disp0 <- if (family == "poisson") NULL else exp(unname(coef(fit, dpar = "sigma")))
  oracle <- function(beta = beta0, alpha = alpha0, Kuse = K, sd_rev = FALSE) {
    sdv <- b34_sd(alpha, z_level)
    if (sd_rev) sdv <- rev(sdv)
    if (family == "gaussian") {
      b34_gaussian_marginal(dat$y, X, beta, disp0, idx, sdv, Kuse)
    } else {
      b34_laplace(dat$y, family, X, beta, disp0, idx, sdv, Kuse)
    }
  }
  base <- oracle()
  gaps <- c(
    selector_swap = oracle(beta = alpha0, alpha = beta0),
    reversed_sd_vector = oracle(sd_rev = TRUE),
    vapply(K_bugs, function(Kb) oracle(Kuse = Kb), numeric(1)),
    kernel_by_position = oracle(Kuse = unname(K_given)),
    sd_intercept_plus_log2 = oracle(alpha = alpha0 + c(log(2), 0))
  ) - base
  list(ll = as.numeric(stats::logLik(fit)), base = base, gaps = gaps,
       beta = beta0, alpha = alpha0, disp = disp0, oracle = oracle)
}

# The Julia estimates should sit at a maximum of the independent likelihood
# along each coordinate (a profile check, one step either side).
b34_check_optimum <- function(res, step = 0.1, tol = 1e-6) {
  for (k in seq_along(res$beta)) for (s in c(-step, step)) {
    b2 <- res$beta; b2[[k]] <- b2[[k]] + s
    testthat::expect_lt(res$oracle(beta = b2), res$base + tol)
  }
  for (k in seq_along(res$alpha)) for (s in c(-step, step)) {
    a2 <- res$alpha; a2[[k]] <- a2[[k]] + s
    testthat::expect_lt(res$oracle(alpha = a2), res$base + tol)
  }
}

# Fixture for one structured intercept route. kind is "relmat", "animal" or
# "spatial". Returns the data (rows shuffled, id levels in name order), the
# kernel aligned to the levels (K), the kernel or coordinates exactly as the
# user supplies them in a different row order (given), and the group-level
# predictor z_level (not monotone in level order).
b34_struct_fixture <- function(kind, family, seed, repeats = 12L) {
  set.seed(seed)
  if (kind == "animal") {
    ped <- b34_inbred_pedigree()
    levels_id <- ped$names
    K <- ped$A
  } else if (kind == "relmat") {
    levels_id <- sprintf("g%02d", 1:40)
    coordinate <- (seq_along(levels_id) / 40)^1.7
    scale_k <- seq(0.7, 1.6, length.out = 40L)
    K <- outer(scale_k, scale_k) *
      exp(-abs(outer(coordinate, coordinate, `-`)) / 0.25)
    dimnames(K) <- list(levels_id, levels_id)
  } else {
    levels_id <- sprintf("s%02d", 1:40)
    coords <- cbind(east = stats::rnorm(40L), north = stats::rnorm(40L))
    rownames(coords) <- levels_id
    K <- b34_coord_kernel(coords)
  }
  G <- length(levels_id)
  order_given <- sample.int(G)
  given <- if (kind == "spatial") coords[order_given, , drop = FALSE]
           else K[order_given, order_given]
  z_level <- sample((seq_len(G) / G)^1.5 * 2 - 1)
  alpha <- c(log(0.6), 0.7)
  w <- drop(t(chol(K)) %*% stats::rnorm(G))
  u <- b34_sd(alpha, z_level) * w
  idx <- rep(seq_len(G), each = repeats)
  x <- stats::rnorm(length(idx))
  eta <- 0.3 + 0.25 * x + u[idx]
  y <- switch(
    family,
    gaussian = eta + stats::rnorm(length(eta), sd = 0.5),
    poisson = stats::rpois(length(eta), exp(eta)),
    nbinom2 = stats::rnbinom(length(eta), size = 1 / 0.42^2, mu = exp(eta)),
    gamma = stats::rgamma(length(eta), shape = 1 / 0.35^2,
                          rate = (1 / 0.35^2) / exp(eta))
  )
  dat <- data.frame(y = y, x = x, z = z_level[idx],
                    id = factor(levels_id[idx], levels = levels_id))
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  K_bugs <- if (kind == "spatial") {
    D <- sqrt(outer(coords[, 1L], coords[, 1L], `-`)^2 +
                outer(coords[, 2L], coords[, 2L], `-`)^2)
    Kw <- exp(-D / mean(D[D > 0])); diag(Kw) <- diag(Kw) + 1e-6
    dimnames(Kw) <- dimnames(K)
    list(range_mean_not_median = Kw)
  } else {
    list(cov2cor_K = stats::cov2cor(K))
  }
  list(data = dat, levels = levels_id, K = K, given = given, K_bugs = K_bugs,
       K_given = if (kind == "spatial") b34_coord_kernel(given) else given,
       z_level = z_level)
}
