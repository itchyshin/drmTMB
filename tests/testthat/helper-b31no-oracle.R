# Batch 31 (group "no": native, non-Binomial families) shared oracle pieces for
# the test-*-oracle-b31no.R companions.
#
# Everything is base R plus ape::vcv. It builds on helper-sb26-oracle.R
# (Henderson tabular A, hand spatial kernel, dense Laplace, exact Gaussian
# marginal) and helper-b29b-binomial-oracle.R (inbred pedigree, field/kernel
# builder: kernels are built by hand, never by a drmTMB internal). The only
# package call anywhere is b31no_check_phylo_cov(), which compares the package
# tip covariance with cov2cor(ape::vcv(tree)).
#
# Densities that are not in base R (beta-binomial, hurdle NB2, zero-inflated
# Poisson, cumulative logit, zero-one-inflated Beta) are written by hand and
# checked in b31no_check_densities() against a brute-force sum or a numerical
# integral that uses base-R densities only. Their eta-derivatives for the
# Laplace oracle come from a five-point central stencil on the hand density.
#
# Scope: likelihood assembly, selector alignment and kernel alignment at the
# fitted parameters. No calibration, coverage, recovery or parity claim.

# ---- hand densities -------------------------------------------------------

b31no_lbeta <- function(a, b) lgamma(a) + lgamma(b) - lgamma(a + b)

b31no_dbeta_log <- function(y, mu, phi) {
  a <- mu * phi
  b <- (1 - mu) * phi
  -b31no_lbeta(a, b) + (a - 1) * log(y) + (b - 1) * log1p(-y)
}

b31no_dbetabinom_log <- function(k, n, a, b) {
  lgamma(n + 1) - lgamma(k + 1) - lgamma(n - k + 1) +
    b31no_lbeta(k + a, n - k + b) - b31no_lbeta(a, b)
}

b31no_dnb_log <- function(y, mu, size) {
  lgamma(y + size) - lgamma(size) - lgamma(y + 1) +
    size * log(size / (size + mu)) + y * log(mu / (size + mu))
}

b31no_dhurdlenb_log <- function(y, mu, size, hu) {
  lp0 <- size * log(size / (size + mu))
  ifelse(y == 0, log(hu),
         log1p(-hu) + b31no_dnb_log(y, mu, size) - log1p(-exp(lp0)))
}

b31no_dzip_log <- function(y, mu, zi) {
  ifelse(y == 0, log(zi + (1 - zi) * exp(-mu)),
         log1p(-zi) + y * log(mu) - mu - lgamma(y + 1))
}

# y is the integer category 1..K; P(Y <= k) = plogis(cut_k - eta).
b31no_dcumlogit_log <- function(y, eta, cuts) {
  cum <- vapply(seq_along(cuts), function(k) stats::plogis(cuts[[k]] - eta),
                numeric(length(eta)))
  cum <- cbind(0, matrix(cum, nrow = length(eta)), 1)
  log(cum[cbind(seq_along(y), y + 1L)] - cum[cbind(seq_along(y), y)])
}

# Boundary cells (0, 1) carry no mu; interior cells carry the Beta density.
b31no_dzob_log <- function(y, mu, phi, zoi, coi) {
  out <- numeric(length(y))
  z <- y == 0
  o <- y == 1
  i <- !(z | o)
  out[z] <- log(zoi) + log1p(-coi)
  out[o] <- log(zoi) + log(coi)
  out[i] <- log1p(-zoi) + b31no_dbeta_log(y[i], mu[i], phi)
  out
}

# Five-point central stencil: l(eta), dl/deta, d2l/deta2 from a log-density
# function of eta alone (vector in, vector out).
b31no_fd <- function(lfun, h = 1e-2) {
  function(eta) {
    f0 <- lfun(eta)
    fp1 <- lfun(eta + h)
    fm1 <- lfun(eta - h)
    fp2 <- lfun(eta + 2 * h)
    fm2 <- lfun(eta - 2 * h)
    list(l = f0,
         d1 = (-fp2 + 8 * fp1 - 8 * fm1 + fm2) / (12 * h),
         d2 = (-fp2 + 16 * fp1 - 30 * f0 + 16 * fm1 - fm2) / (12 * h^2))
  }
}

# Self-checks of every hand density against a reference that shares no code
# with it. Returns invisible(TRUE); expectations do the work.
b31no_check_densities <- function() {
  # Beta-binomial: sums to one over k and equals the numerical Beta mixture of
  # binomials (integrate over p with base dbinom/dbeta).
  n <- 9L
  a <- 1.7
  b <- 2.9
  lp <- b31no_dbetabinom_log(0:n, n, a, b)
  expect_equal(sum(exp(lp)), 1, tolerance = 1e-12)
  ref <- vapply(0:n, function(k) {
    stats::integrate(function(p) stats::dbinom(k, n, p) * stats::dbeta(p, a, b),
                     0, 1, rel.tol = 1e-12)$value
  }, numeric(1L))
  expect_equal(exp(lp), ref, tolerance = 1e-8)
  expect_equal(exp(b31no_dbetabinom_log(1, 1, 2, 3)), 2 / 5, tolerance = 1e-12)
  # Hurdle NB2: P(0) = hu, sums to one, positive part is NB2 / (1 - P_nb(0)).
  mu <- 2.3
  size <- 1.4
  hu <- 0.27
  ph <- exp(b31no_dhurdlenb_log(0:4000, mu, size, hu))
  expect_equal(sum(ph), 1, tolerance = 1e-9)
  expect_equal(ph[[1L]], hu, tolerance = 1e-12)
  expect_equal(ph[[4L]],
               (1 - hu) * stats::dnbinom(3, size = size, mu = mu) /
                 (1 - stats::dnbinom(0, size = size, mu = mu)), tolerance = 1e-10)
  expect_equal(exp(b31no_dnb_log(0:30, mu, size)),
               stats::dnbinom(0:30, size = size, mu = mu), tolerance = 1e-10)
  # Zero-inflated Poisson.
  pz <- exp(b31no_dzip_log(0:200, 3.1, 0.22))
  expect_equal(sum(pz), 1, tolerance = 1e-12)
  expect_equal(pz[[1L]], 0.22 + 0.78 * stats::dpois(0, 3.1), tolerance = 1e-12)
  expect_equal(pz[[6L]], 0.78 * stats::dpois(5, 3.1), tolerance = 1e-12)
  # Cumulative logit: category probability = integral of the logistic density
  # between the cutpoints (base dlogis), and rows sum to one.
  cuts <- c(-0.8, 0.5, 1.4)
  eta <- 0.35
  lc <- vapply(1:4, function(k) {
    exp(b31no_dcumlogit_log(k, eta, cuts))
  }, numeric(1L))
  expect_equal(sum(lc), 1, tolerance = 1e-12)
  edges <- c(-Inf, cuts, Inf)
  refc <- vapply(1:4, function(k) {
    stats::integrate(function(t) stats::dlogis(t, location = eta),
                     edges[[k]], edges[[k + 1L]], rel.tol = 1e-12)$value
  }, numeric(1L))
  expect_equal(lc, refc, tolerance = 1e-8)
  # Zero-one-inflated Beta: boundary cells plus the integral of the interior.
  phi <- 4.2
  mu <- 0.37
  zoi <- 0.15
  coi <- 0.4
  interior <- stats::integrate(function(y) {
    exp(b31no_dzob_log(y, rep(mu, length(y)), phi, zoi, coi))
  }, 0, 1, rel.tol = 1e-10)$value
  expect_equal(exp(b31no_dzob_log(0, mu, phi, zoi, coi)) +
                 exp(b31no_dzob_log(1, mu, phi, zoi, coi)) + interior, 1,
               tolerance = 1e-8)
  expect_equal(exp(b31no_dbeta_log(0.3, mu, phi)),
               stats::dbeta(0.3, mu * phi, (1 - mu) * phi), tolerance = 1e-12)
  # The stencil reproduces analytic Poisson derivatives.
  y <- c(0, 2, 5)
  fd <- b31no_fd(function(e) stats::dpois(y, exp(e), log = TRUE))(c(-0.4, 0.3, 0.9))
  an <- sb26_deriv_poisson(y)(c(-0.4, 0.3, 0.9))
  expect_equal(fd$d1, an$d1, tolerance = 1e-8)
  expect_equal(fd$d2, an$d2, tolerance = 1e-8)
  invisible(TRUE)
}

# The package tip covariance must equal cov2cor(ape::vcv(tree)) by label.
b31no_check_phylo_cov <- function(tree) {
  labs <- sort(tree$tip.label)
  expect_equal(
    unname(drmTMB:::drm_phylo_tip_covariance(tree)[labs, labs]),
    unname(stats::cov2cor(ape::vcv(tree))[labs, labs]),
    tolerance = 1e-8
  )
}

# ---- terms and the generic oracle ----------------------------------------

# One random-effect term of the stacked latent vector.
#   field  : list(levels, K, kind, K_raw (phylo only))   (K is named, any order)
#   group  : data column holding the level (factor or character)
#   w      : per-row weight (1 for an intercept, x for a slope)
#   co     : fitted SD coefficients c(intercept, selector slope)
#   z      : selector values, named by level
b31no_term <- function(field, dat, group, w, co, z, label) {
  lev <- field$levels
  list(label = label, field = field, lev = lev,
       idx = match(as.character(dat[[group]]), lev),
       w = w, co = unname(co), z = z[lev],
       sd = stats::setNames(exp(co[[1L]] + co[[2L]] * z[lev]), lev),
       K = field$K[lev, lev])
}

b31no_Sigma <- function(terms, rho = NULL, pair = NULL, Ks = NULL) {
  blocks <- lapply(seq_along(terms), function(j) {
    if (is.null(Ks)) terms[[j]]$K else Ks[[j]][terms[[j]]$lev, terms[[j]]$lev]
  })
  S <- do.call(sb26_blockdiag, blocks)
  if (!is.null(pair)) {
    G <- length(terms[[pair[[1L]]]]$lev)
    off <- c(0L, cumsum(vapply(terms, function(t) length(t$lev), integer(1L))))
    i <- off[[pair[[1L]]]] + seq_len(G)
    j <- off[[pair[[2L]]]] + seq_len(G)
    S[i, j] <- rho * blocks[[pair[[1L]]]]
    S[j, i] <- rho * blocks[[pair[[2L]]]]
  }
  S
}

b31no_Z <- function(terms, sds = NULL) {
  do.call(cbind, lapply(seq_along(terms), function(j) {
    t <- terms[[j]]
    s <- if (is.null(sds)) t$sd else sds[[j]]
    sb26_Z(t$idx, length(t$lev), unname(s), t$w)
  }))
}

# Dense Laplace log marginal (or exact Gaussian marginal when `gauss` is a list
# with y, mu, sigma) at the supplied terms.
b31no_oracle <- function(deriv, eta_fixed, terms, rho = NULL, pair = NULL,
                         sds = NULL, Ks = NULL, gauss = NULL) {
  Z <- b31no_Z(terms, sds)
  S <- b31no_Sigma(terms, rho, pair, Ks)
  if (is.null(gauss)) {
    sb26_laplace(deriv, eta_fixed, Z, S)
  } else {
    sb26_gauss_loglik(gauss$y, gauss$mu, gauss$sigma, Z, S)
  }
}

# Fit-versus-oracle agreement plus emulated-bug sensitivity. Returns the
# achieved agreement and the smallest gap. `ll_tol` is 1e-4 for native fits.
#   independent terms: reversed SD per term, sign-flipped selector per term,
#     swapped coefficient sets (first two terms), K by position, K x 2,
#     cov2cor(K) (kernels with non-constant diagonal), raw vcv (phylo);
#   correlated pair: flipped rho and rho = 0 as well.
b31no_check <- function(fit, deriv, eta_fixed, terms, info, rho = NULL,
                        pair = NULL, gauss = NULL, ll_tol = 1e-4, gap = 0.1) {
  expect_identical(fit$opt$convergence, 0L, info = info)
  oracle <- function(...) {
    b31no_oracle(deriv, eta_fixed, terms, rho = rho, pair = pair,
                 gauss = gauss, ...)
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - ref), ll_tol, label = paste(info, "oracle agreement"))
  for (t in terms) {
    expect_gt(stats::sd(log(t$sd)), 0.05, label = paste(info, t$label, "SD varies"))
    expect_gt(max(t$sd) / min(t$sd), 1.3, label = paste(info, t$label, "SD range"))
  }
  gaps <- numeric(0)
  add <- function(nm, val) gaps[[nm]] <<- abs(val - ref)
  base_sds <- lapply(terms, function(t) t$sd)
  for (j in seq_along(terms)) {
    t <- terms[[j]]
    s <- base_sds
    s[[j]] <- sb26_reverse(t$sd)
    add(paste0("reversed_sd_", t$label), oracle(sds = s))
    s <- base_sds
    s[[j]] <- exp(t$co[[1L]] - t$co[[2L]] * t$z)
    add(paste0("flipped_selector_", t$label), oracle(sds = s))
    f <- t$field
    Ks <- lapply(terms, function(u) u$K)
    if (!(f$kind %in% c("iid", "iid2"))) {
      Kp <- f$K                          # supplied row order (not lev order)
      dimnames(Kp) <- list(t$lev, t$lev)   # read the kernel by position
      Ks[[j]] <- Kp
      add(paste0("K_read_by_position_", t$label), oracle(Ks = Ks))
      Ks <- lapply(terms, function(u) u$K)
      Ks[[j]] <- 2 * t$K
      add(paste0("K_x2_", t$label), oracle(Ks = Ks))
      if (f$kind %in% c("animal", "relmat")) {
        expect_gt(max(diag(t$K)) - min(diag(t$K)), 0.05,
                  label = paste(info, t$label, "non-constant diagonal"))
        Ks[[j]] <- stats::cov2cor(t$K)
        add(paste0("cov2cor_K_", t$label), oracle(Ks = Ks))
      }
      if (f$kind %in% c("phylo") && !is.null(f$K_raw)) {
        Ks[[j]] <- f$K_raw[t$lev, t$lev]
        add(paste0("raw_vcv_K_", t$label), oracle(Ks = Ks))
      }
    }
  }
  if (length(terms) >= 2L) {
    s <- base_sds
    s[[1L]] <- exp(terms[[2L]]$co[[1L]] + terms[[2L]]$co[[2L]] * terms[[1L]]$z)
    s[[2L]] <- exp(terms[[1L]]$co[[1L]] + terms[[1L]]$co[[2L]] * terms[[2L]]$z)
    add("swapped_selector_coefs", oracle(sds = s))
  }
  if (!is.null(pair)) {
    expect_gt(abs(rho), 0.1, label = paste(info, "fitted rho"))
    flip <- b31no_oracle(deriv, eta_fixed, terms, rho = -rho, pair = pair,
                         gauss = gauss)
    zero <- b31no_oracle(deriv, eta_fixed, terms, rho = 0, pair = pair,
                         gauss = gauss)
    gaps[["flipped_rho"]] <- abs(flip - ref)
    gaps[["rho_zero"]] <- abs(zero - ref)
  }
  for (nm in names(gaps)) {
    expect_gt(gaps[[nm]], gap, label = paste(info, nm))
  }
  if (nzchar(Sys.getenv("B31NO_SHOW_GAPS"))) {
    cat(sprintf("GAP %s | ll-ref %.2e | min gap %.3f (%s)\n", info, ll - ref,
                min(gaps), names(gaps)[[which.min(gaps)]]))
  }
  invisible(list(agree = abs(ll - ref), min_gap = min(gaps), ref = ref))
}

# ---- fixtures -------------------------------------------------------------

# Selector for each level: a random permutation of an evenly spaced grid, so
# no SD vector is palindromic and reversal is a real change.
b31no_selector <- function(lev, span = 1) {
  stats::setNames(seq(-span, span, length.out = length(lev))[sample.int(length(lev))],
                  lev)
}

# Latent unit-scale field draw for a kernel, scaled by the true SD curve.
b31no_latent <- function(field, a, z) {
  lev <- field$levels
  G <- length(lev)
  u <- drop(t(chol(field$K[lev, lev])) %*% stats::rnorm(G))
  stats::setNames(u * exp(a[[1L]] + a[[2L]] * z[lev]), lev)
}

# Build one kernel field via the (independent, by-hand) b29b field builder and
# attach a data column and an extra selector.
b31no_field <- function(kind) {
  f <- b29b_make_field(kind)
  f
}

# Phylo field with a tree of height 3 (raw vcv differs from cov2cor).
b31no_provider_objects <- function(field, provider) {
  list(
    A = field$K, Ainv = {Q <- solve(field$K); dimnames(Q) <- dimnames(field$K); Q},
    K = field$K, Q = {Q <- solve(field$K); dimnames(Q) <- dimnames(field$K); Q},
    pedigree = field$pedigree, tree = field$tree, coords = field$coords
  )
}

b31no_stage <- function(dat, field, group, n_obs, seed_shift = 0L) {
  # Row-to-level assignment, balanced and shuffled.
  idx <- sample(rep(seq_len(length(field$levels)), length.out = n_obs))
  dat[[group]] <- factor(field$levels[idx], levels = field$levels)
  dat
}

# Give a relmat kernel a non-constant diagonal (D K D with D in [0.8, 1.6],
# shuffled), keeping the supplied (reversed) row order, so cov2cor(K) is a
# real change.
b31no_nonunit <- function(field) {
  lev <- field$levels
  d <- stats::setNames(seq(0.8, 1.6, length.out = length(lev))[sample.int(length(lev))],
                       lev)
  nm <- rownames(field$K)
  field$K <- field$K * outer(d[nm], d[nm])
  field
}
