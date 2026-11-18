# Batch 31 (group nb, native Binomial) shared oracle pieces for the companion
# tests test-binomial-*-oracle-b31nb.R.
#
# Everything here is base R plus ape::vcv. Dense Laplace, Henderson tabular A,
# hand relmat kernels, hand tree covariances (cov2cor(ape::vcv)) and, for mesh
# fields, a hand-built finite-element SPDE precision and barycentric
# projection all come from helper-sb26-oracle.R / helper-b29b-binomial-oracle.R
# (already independent of the package) or from this file. No drmTMB internal is
# used to build a kernel, a precision, a projection or the likelihood. The only
# package helpers called in the tests are drmTMB:::drm_phylo_tip_covariance
# (compared against ape::vcv) and the public make_mesh() / spatial_coords()
# constructors that produce the mesh the fit consumes; the mesh matrices the
# package derives from that mesh are compared against the hand build.
#
# Scope: likelihood assembly and selector / kernel alignment at the fitted
# parameters. No calibration, coverage, recovery or parity claim.

b31nb_links <- c("logit", "probit", "cloglog")

b31nb_report <- function(label, agree, gaps) {
  cat(sprintf("B31NB %s | agree %.2e | min gap %.3f (%s) | n gaps %d\n",
              label, agree, min(gaps), names(gaps)[[which.min(gaps)]],
              length(gaps)))
}

# True SD curve parameters. The probit coefficients are about 1/1.7 of the
# logit ones, so the SD level is scaled to carry comparable information.
b31nb_mult <- function(link) if (identical(link, "probit")) 1.7 else 1

# A shuffled, non-palindromic selector over the levels.
b31nb_selector <- function(lev) {
  stats::setNames(seq(-1, 1, length.out = length(lev))[sample.int(length(lev))],
                  lev)
}

# Hand relmat kernel with a NON-constant diagonal: an exponential kernel in two
# random coordinates rescaled by per-population variances in [0.6, 2.2], so
# cov2cor(K) is a real change (not a pure rescale).
b31nb_relmat_kernel <- function(n) {
  lev <- sprintf("pop%02d", seq_len(n))
  co <- matrix(stats::runif(2L * n), n, 2L, dimnames = list(lev, NULL))
  d <- as.matrix(stats::dist(co))
  Kc <- exp(-d / stats::median(d[d > 0])) + 1e-6 * diag(n)
  s <- sqrt(exp(seq(log(0.6), log(2.2), length.out = n))[sample.int(n)])
  K <- Kc * outer(s, s)
  dimnames(K) <- list(lev, lev)
  K
}

b31nb_phylo_tree <- function(n) {
  tree <- ape::rcoal(n)
  tree$edge.length <- 3 * tree$edge.length
  tree$tip.label <- sample(sprintf("sp%02d", seq_len(n)))
  tree
}

# One structured level set: levels (sorted), the unit-scale kernel with rows in
# the REVERSE of the level order (so any positional read is wrong), the objects
# the formula refers to.
b31nb_kernel <- function(kind, n_family = 3L, n_tip = 40L, n_pop = 30L) {
  out <- list(kind = kind)
  if (kind == "animal") {
    ped <- b29b_inbred_pedigree(n_family)
    A <- sb26_tabular_A(ped)
    stopifnot(max(diag(A)) > 1.6)
    lev <- sort(rownames(A))
    out$K <- A[rev(lev), rev(lev)]
    out$pedigree <- ped
  } else if (kind == "relmat") {
    K <- b31nb_relmat_kernel(n_pop)
    lev <- sort(rownames(K))
    stopifnot(diff(range(diag(K))) > 0.5)
    out$K <- K[rev(lev), rev(lev)]
  } else if (kind == "phylo") {
    tree <- b31nb_phylo_tree(n_tip)
    lev <- sort(tree$tip.label)
    out$tree <- tree
    out$K_raw <- ape::vcv(tree)[rev(lev), rev(lev)]
    out$K <- stats::cov2cor(ape::vcv(tree))[rev(lev), rev(lev)]
  } else stop("unknown kind")
  out$levels <- lev
  out$n <- length(lev)
  out
}

# ---- single field: intercept or numeric slope, animal (A / Ainv) or relmat K

b31nb_single_fixture <- function(kind, term, link, seed, n_obs = 1500L) {
  set.seed(seed)
  f <- b31nb_kernel(kind)
  lev <- f$levels
  Ks <- f$K[lev, lev]
  a <- if (identical(term, "slope")) c(log(0.8), 0.8) else c(log(1.0), 0.9)
  a[[1L]] <- a[[1L]] + log(b31nb_mult(link))
  zlev <- b31nb_selector(lev)
  sdv <- exp(a[[1L]] + a[[2L]] * zlev)
  u <- stats::setNames(drop(t(chol(Ks)) %*% stats::rnorm(f$n)) * sdv, lev)
  idx <- sample(rep(seq_len(f$n), length.out = n_obs))
  chr <- lev[idx]
  x <- stats::rnorm(n_obs)
  eta <- -0.1 + 0.3 * x + if (identical(term, "slope")) x * u[chr] else u[chr]
  dat <- data.frame(
    x = x, g = factor(chr, levels = lev), z = unname(zlev[chr]),
    y = stats::rbinom(n_obs, 1L, stats::make.link(link)$linkinv(eta))
  )
  c(f, list(data = dat, zlev = zlev, term = term, link = link))
}

b31nb_single_fit <- function(fx, provider) {
  A <- K <- Ainv <- Q <- NULL
  if (fx$kind == "animal") {
    A <- fx$K
    Ainv <- solve(A)
    pedigree <- fx$pedigree
  } else {
    K <- fx$K
  }
  lhs <- if (identical(fx$term, "slope")) "0 + x" else "1"
  term <- switch(
    fx$kind,
    animal = switch(provider,
      A = sprintf("animal(%s | g, A = A)", lhs),
      Ainv = sprintf("animal(%s | g, Ainv = Ainv)", lhs),
      pedigree = sprintf("animal(%s | g, pedigree = pedigree)", lhs)),
    relmat = sprintf("relmat(%s | g, K = K)", lhs)
  )
  level <- if (fx$kind == "animal") "animal" else "relmat"
  fml <- eval(parse(text = sprintf(
    "bf(y ~ x + %s, sd(g, level = \"%s\") ~ z)", term, level
  )))
  drmTMB(fml, family = stats::binomial(link = fx$link), data = fx$data,
         control = drm_control(se = FALSE))
}

b31nb_check_single <- function(fx, provider, info, gap = 0.1) {
  fit <- b31nb_single_fit(fx, provider)
  expect_identical(fit$opt$convergence, 0L, info = info)
  dpar <- if (fx$kind == "animal") "sd_animal(g)" else "sd_relmat(g)"
  co <- coef(fit, dpar)
  expect_identical(names(co), c("(Intercept)", "z"), info = info)
  dat <- fx$data
  lev <- fx$levels
  idx <- as.integer(dat$g)
  w <- if (identical(fx$term, "slope")) dat$x else 1
  mu <- coef(fit, "mu")
  eta_fixed <- mu[[1L]] + mu[[2L]] * dat$x
  deriv <- b29b_deriv_binomial(dat$y, fx$link)
  sdv <- stats::setNames(unname(exp(co[[1L]] + co[[2L]] * fx$zlev[lev])), lev)
  K0 <- fx$K[lev, lev]
  oracle <- function(s = sdv, Ks = K0, wt = w) {
    sb26_laplace(deriv, eta_fixed, sb26_Z(idx, fx$n, s, wt), Ks)
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  agree <- abs(ll - ref)
  expect_lt(agree, 1e-4, label = info)
  # Fixture validity: a non-flat, non-collapsed fitted SD curve.
  expect_gt(stats::sd(log(sdv)), 0.05, label = paste(info, "SD varies"))
  expect_gt(stats::median(sdv), 0.15, label = paste(info, "median SD"))
  expect_gt(max(sdv) / min(sdv), 1.3, label = paste(info, "SD range"))
  gaps <- c(
    reversed_sd = abs(oracle(s = sb26_reverse(sdv)) - ref),
    K_read_by_position = {
      Kp <- fx$K
      dimnames(Kp) <- list(lev, lev)
      abs(oracle(Ks = Kp) - ref)
    },
    K_times_2 = abs(oracle(Ks = 2 * K0) - ref)
  )
  gaps[["cov2cor_K"]] <- abs(oracle(Ks = stats::cov2cor(K0)) - ref)
  if (identical(fx$term, "slope")) {
    gaps[["slope_design_dropped"]] <- abs(oracle(wt = 1) - ref)
  }
  for (nm in names(gaps)) {
    expect_gt(gaps[[nm]], gap, label = paste(info, nm))
  }
  b31nb_report(info, agree, gaps)
  invisible(list(ref = ref, ll = ll, agree = agree, gaps = gaps))
}

# ---- q2 block (intercept + numeric slope, two coefficient SDs), animal / phylo

b31nb_q2_fixture <- function(kind, link, seed, repeats = 30L) {
  set.seed(seed)
  f <- b31nb_kernel(kind, n_tip = 40L)
  lev <- f$levels
  Ks <- f$K[lev, lev]
  m <- b31nb_mult(link)
  a0 <- c(log(1.1 * m), 0.7)
  a1 <- c(log(0.9 * m), -0.7)
  z0 <- b31nb_selector(lev)
  z1 <- b31nb_selector(lev)
  L <- t(chol(Ks))
  u0 <- drop(L %*% stats::rnorm(f$n)) * exp(a0[[1L]] + a0[[2L]] * z0)
  u1 <- drop(L %*% stats::rnorm(f$n)) * exp(a1[[1L]] + a1[[2L]] * z1)
  chr <- rep(lev, each = repeats)
  x <- rep(seq(-1.2, 1.2, length.out = repeats), times = f$n)
  eta <- -0.1 + 0.3 * x + u0[match(chr, lev)] + x * u1[match(chr, lev)]
  dat <- data.frame(
    x = x, g = factor(chr, levels = lev), z0 = unname(z0[chr]),
    z1 = unname(z1[chr]),
    y = stats::rbinom(length(chr), 1L, stats::make.link(link)$linkinv(eta))
  )
  c(f, list(data = dat, z0 = z0, z1 = z1, link = link))
}

b31nb_q2_fit <- function(fx) {
  A <- fx$K
  tree <- fx$tree
  term <- if (fx$kind == "animal") "animal(1 + x | g, A = A)" else
    "phylo(1 + x | g, tree = tree)"
  level <- if (fx$kind == "animal") "animal" else "phylogenetic"
  fml <- eval(parse(text = sprintf(paste0(
    "bf(y ~ x + %s, sd(g, level = \"%s\", dpar = \"mu\", coef = \"(Intercept)\") ~ z0, ",
    "sd(g, level = \"%s\", dpar = \"mu\", coef = \"x\") ~ z1)"
  ), term, level, level)))
  drmTMB(fml, family = stats::binomial(link = fx$link), data = fx$data,
         control = drm_control(se = FALSE))
}

b31nb_check_q2 <- function(fx, info, gap = 0.1) {
  fit <- b31nb_q2_fit(fx)
  expect_identical(fit$opt$convergence, 0L, info = info)
  level <- if (fx$kind == "animal") "sd_animal" else "sd_phylo"
  k0 <- sprintf("%s(g, dpar = \"mu\", coef = \"(Intercept)\")", level)
  k1 <- sprintf("%s(g, dpar = \"mu\", coef = \"x\")", level)
  c0 <- coef(fit, k0)
  c1 <- coef(fit, k1)
  expect_identical(names(c0), c("(Intercept)", "z0"), info = info)
  expect_identical(names(c1), c("(Intercept)", "z1"), info = info)
  # The unlabelled native q2 block fixes the intercept-slope correlation at 0.
  expect_length(fit$corpars, 0L)
  dat <- fx$data
  lev <- fx$levels
  n <- fx$n
  idx <- as.integer(dat$g)
  mu <- coef(fit, "mu")
  eta_fixed <- mu[[1L]] + mu[[2L]] * dat$x
  deriv <- b29b_deriv_binomial(dat$y, fx$link)
  curve <- function(co, z) {
    stats::setNames(unname(exp(co[[1L]] + co[[2L]] * z[lev])), lev)
  }
  s0 <- curve(c0, fx$z0)
  s1 <- curve(c1, fx$z1)
  K0 <- fx$K[lev, lev]
  oracle <- function(a = s0, b = s1, Ks = K0, rho = 0) {
    Z <- cbind(sb26_Z(idx, n, a), sb26_Z(idx, n, b, dat$x))
    sb26_laplace(deriv, eta_fixed, Z,
                 kronecker(matrix(c(1, rho, rho, 1), 2L), Ks))
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  agree <- abs(ll - ref)
  expect_lt(agree, 1e-4, label = info)
  for (s in list(s0, s1)) {
    expect_gt(stats::sd(log(s)), 0.05, label = paste(info, "SD varies"))
    expect_gt(max(s) / min(s), 1.3, label = paste(info, "SD range"))
    expect_gt(stats::median(s), 0.15, label = paste(info, "median SD"))
  }
  Kp <- fx$K
  dimnames(Kp) <- list(lev, lev)
  gaps <- c(
    swapped_selector_coefs = abs(oracle(a = curve(c1, fx$z0),
                                        b = curve(c0, fx$z1)) - ref),
    reversed_sd_intercept = abs(oracle(a = sb26_reverse(s0)) - ref),
    reversed_sd_slope = abs(oracle(b = sb26_reverse(s1)) - ref),
    swapped_intercept_slope_sd = abs(oracle(a = s1, b = s0) - ref),
    K_read_by_position = abs(oracle(Ks = Kp) - ref),
    K_times_2 = abs(oracle(Ks = 2 * K0) - ref),
    rho_plus_0.6 = abs(oracle(rho = 0.6) - ref),
    rho_minus_0.6 = abs(oracle(rho = -0.6) - ref)
  )
  if (fx$kind == "animal") {
    gaps[["cov2cor_K"]] <- abs(oracle(Ks = stats::cov2cor(K0)) - ref)
  } else {
    gaps[["raw_vcv_K"]] <- abs(oracle(Ks = fx$K_raw[lev, lev]) - ref)
  }
  for (nm in names(gaps)) {
    expect_gt(gaps[[nm]], gap, label = paste(info, nm))
  }
  b31nb_report(info, agree, gaps)
  invisible(list(ref = ref, ll = ll, agree = agree, gaps = gaps))
}

# ---- phylogenetic interaction numeric slope (pair-level, kron(K_poll, K_plant))

b31nb_pi_fixture <- function(link, seed, n1 = 8L, n2 = 8L, n_each = 24L) {
  set.seed(seed)
  mk <- function(n, pre) {
    tr <- ape::rcoal(n)
    tr$edge.length <- 3 * tr$edge.length
    tr$tip.label <- sample(sprintf("%s%02d", pre, seq_len(n)))
    tr
  }
  plant_tree <- mk(n1, "pl")
  poll_tree <- mk(n2, "po")
  K1 <- stats::cov2cor(ape::vcv(plant_tree))
  K2 <- stats::cov2cor(ape::vcv(poll_tree))
  grid <- expand.grid(plant = sort(plant_tree$tip.label),
                      pollinator = sort(poll_tree$tip.label),
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  grid$pair <- paste(grid$plant, grid$pollinator, sep = ":")
  # kron(K_poll, K_plant): pollinator slowest, plant fastest, in the order of
  # `grid`; named by the pair label.
  Kpair <- kronecker(K2[sort(rownames(K2)), sort(rownames(K2))],
                     K1[sort(rownames(K1)), sort(rownames(K1))])
  dimnames(Kpair) <- list(grid$pair, grid$pair)
  Kpair_swapped <- kronecker(K1[sort(rownames(K1)), sort(rownames(K1))],
                             K2[sort(rownames(K2)), sort(rownames(K2))])
  dimnames(Kpair_swapped) <- list(grid$pair, grid$pair)
  np <- nrow(grid)
  zp <- stats::setNames(seq(-1, 1, length.out = np)[sample.int(np)], grid$pair)
  a <- c(log(0.6 * b31nb_mult(link)), 0.8)
  u <- stats::setNames(
    drop(t(chol(Kpair)) %*% stats::rnorm(np)) * exp(a[[1L]] + a[[2L]] * zp),
    grid$pair
  )
  pair_idx <- sample(rep(seq_len(np), length.out = np * n_each))
  chr <- grid$pair[pair_idx]
  x <- stats::rnorm(length(chr))
  eta <- -0.1 + 0.4 * x + x * u[chr]
  # data in a shuffled pair order; the pair factor levels are the sorted labels
  dat <- data.frame(
    plant = grid$plant[pair_idx], pollinator = grid$pollinator[pair_idx],
    pair = chr, x = x, z_pair = unname(zp[chr]),
    y = stats::rbinom(length(chr), 1L, stats::make.link(link)$linkinv(eta))
  )
  list(data = dat, plant_tree = plant_tree, poll_tree = poll_tree,
       K1 = K1, K2 = K2, Kpair = Kpair, Kpair_swapped = Kpair_swapped,
       pairs = sort(grid$pair), zp = zp, link = link, n = np)
}

b31nb_pi_fit <- function(fx) {
  plant_tree <- fx$plant_tree
  pollinator_tree <- fx$poll_tree
  drmTMB(
    bf(y ~ x + phylo_interaction(0 + x | plant:pollinator,
                                 tree1 = plant_tree, tree2 = pollinator_tree),
       sd(pair, level = "phylogenetic_interaction") ~ z_pair),
    family = stats::binomial(link = fx$link), data = fx$data,
    control = drm_control(se = FALSE)
  )
}

b31nb_check_pi <- function(fx, info, gap = 0.1) {
  fit <- b31nb_pi_fit(fx)
  expect_identical(fit$opt$convergence, 0L, info = info)
  co <- coef(fit, "sd_phylo(pair)")
  expect_identical(names(co), c("(Intercept)", "z_pair"), info = info)
  dat <- fx$data
  lev <- fx$pairs
  idx <- match(dat$pair, lev)
  mu <- coef(fit, "mu")
  eta_fixed <- mu[[1L]] + mu[[2L]] * dat$x
  deriv <- b29b_deriv_binomial(dat$y, fx$link)
  sdv <- stats::setNames(unname(exp(co[[1L]] + co[[2L]] * fx$zp[lev])), lev)
  K0 <- fx$Kpair[lev, lev]
  oracle <- function(s = sdv, Ks = K0, wt = dat$x) {
    sb26_laplace(deriv, eta_fixed, sb26_Z(idx, fx$n, s, wt), Ks)
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  agree <- abs(ll - ref)
  expect_lt(agree, 1e-4, label = info)
  expect_gt(stats::sd(log(sdv)), 0.05, label = paste(info, "SD varies"))
  expect_gt(max(sdv) / min(sdv), 1.3, label = paste(info, "SD range"))
  expect_gt(stats::median(sdv), 0.15, label = paste(info, "median SD"))
  Kp <- unname(fx$Kpair)
  dimnames(Kp) <- list(lev, lev)
  gaps <- c(
    reversed_sd = abs(oracle(s = sb26_reverse(sdv)) - ref),
    pair_kernel_read_by_position = abs(oracle(Ks = Kp) - ref),
    kron_factor_order_swapped = abs(oracle(Ks = fx$Kpair_swapped[lev, lev]) - ref),
    K_times_2 = abs(oracle(Ks = 2 * K0) - ref),
    slope_design_dropped = abs(oracle(wt = 1) - ref)
  )
  for (nm in names(gaps)) {
    expect_gt(gaps[[nm]], gap, label = paste(info, nm))
  }
  b31nb_report(info, agree, gaps)
  invisible(list(ref = ref, ll = ll, agree = agree, gaps = gaps))
}

# ---- mesh (SPDE, fixed kappa): hand FEM precision and barycentric projection

# Finite-element matrices of the triangulation, by hand: lumped mass c0,
# stiffness g1, g2 = g1 c0^-1 g1 (the standard SPDE building blocks).
b31nb_fem <- function(loc, tv) {
  n <- nrow(loc)
  c0 <- numeric(n)
  g1 <- matrix(0, n, n)
  for (t in seq_len(nrow(tv))) {
    v <- tv[t, ]
    p <- loc[v, , drop = FALSE]
    b <- c(p[2L, 2L] - p[3L, 2L], p[3L, 2L] - p[1L, 2L], p[1L, 2L] - p[2L, 2L])
    cc <- c(p[3L, 1L] - p[2L, 1L], p[1L, 1L] - p[3L, 1L], p[2L, 1L] - p[1L, 1L])
    area <- abs((p[2L, 1L] - p[1L, 1L]) * (p[3L, 2L] - p[1L, 2L]) -
                  (p[3L, 1L] - p[1L, 1L]) * (p[2L, 2L] - p[1L, 2L])) / 2
    g1[v, v] <- g1[v, v] + (outer(b, b) + outer(cc, cc)) / (4 * area)
    c0[v] <- c0[v] + area / 3
  }
  list(c0 = c0, g1 = g1, g2 = g1 %*% diag(1 / c0, n) %*% g1)
}

# Barycentric projection of points onto the triangulation.
b31nb_project <- function(xy, loc, tv) {
  n <- nrow(loc)
  one <- function(pt) {
    for (t in seq_len(nrow(tv))) {
      v <- tv[t, ]
      p <- loc[v, , drop = FALSE]
      lam <- solve(t(rbind(p[1L, ] - p[3L, ], p[2L, ] - p[3L, ])), pt - p[3L, ])
      w <- c(lam, 1 - sum(lam))
      if (all(w > -1e-9)) {
        out <- numeric(n)
        out[v] <- w
        return(out)
      }
    }
    stop("point outside the triangulation")
  }
  t(apply(xy, 1L, one))
}

b31nb_mesh_fixture <- function(term, link, seed) {
  set.seed(seed)
  n_site <- 32L
  n_each <- 40L
  site_xy <- cbind(
    longitude = rep(seq(-123.10, -123.03, length.out = 8L), each = 4L),
    latitude = rep(seq(49.20, 49.23, length.out = 4L), times = 8L)
  )
  site <- factor(rep(seq_len(n_site), each = n_each))
  zs <- seq(-1, 1, length.out = n_site)[sample.int(n_site)]
  x <- rep(rep(c(-1, 1), each = n_each / 2L), times = n_site)
  dat <- data.frame(
    y = 0L, site = site, x = x, z_site = rep(zs, each = n_each),
    longitude = rep(site_xy[, 1L], each = n_each),
    latitude = rep(site_xy[, 2L], each = n_each)
  )
  rownames(dat) <- paste0("obs_", seq_len(nrow(dat)))
  coords <- spatial_coords(dat, longitude, latitude, crs_out = 32610)
  mesh <- make_mesh(coords, kappa = 1 / 1000)
  loc <- mesh$mesh$loc[, 1:2]
  tv <- mesh$mesh$graph$tv
  fem <- b31nb_fem(loc, tv)
  kappa <- mesh$kappa
  Q <- kappa^4 * diag(fem$c0) + 2 * kappa^2 * fem$g1 + fem$g2
  Aproj <- b31nb_project(as.matrix(mesh$loc_xy[, 1:2]), loc, tv)
  # The package matrices derived from the same triangulation must equal the
  # hand build.
  expect_equal(unname(fem$c0), unname(Matrix::diag(mesh$spde$c0)), tolerance = 1e-9)
  expect_equal(unname(fem$g1), unname(as.matrix(mesh$spde$g1)), tolerance = 1e-9)
  expect_equal(unname(fem$g2), unname(as.matrix(mesh$spde$g2)), tolerance = 1e-9)
  expect_equal(unname(Aproj), unname(as.matrix(mesh$A_st)), tolerance = 1e-8)
  a <- if (identical(term, "slope")) c(log(0.5), 0.8) else c(log(0.6), 0.8)
  a[[1L]] <- a[[1L]] + log(b31nb_mult(link))
  Sigma <- solve(Q)
  u <- drop(t(chol(Sigma)) %*% stats::rnorm(ncol(Q)))
  field <- drop(Aproj %*% u)
  field <- field / stats::sd(field)
  sdv <- exp(a[[1L]] + a[[2L]] * dat$z_site)
  eta <- -0.15 + 0.3 * x +
    sdv * field * if (identical(term, "slope")) x else 1
  dat$y <- stats::rbinom(nrow(dat), 1L, stats::make.link(link)$linkinv(eta))
  list(data = dat, mesh = mesh, Q = Q, Sigma = Sigma, Aproj = Aproj,
       zs = zs, term = term, link = link, n_site = n_site)
}

b31nb_mesh_fit <- function(fx) {
  mesh <- fx$mesh
  fml <- if (identical(fx$term, "slope")) {
    bf(y ~ 1 + x + spatial(0 + x | site, mesh = mesh),
       sd(site, level = "spatial", coef = "x") ~ z_site)
  } else {
    bf(y ~ 1 + x + spatial(1 | site, mesh = mesh),
       sd(site, level = "spatial") ~ z_site)
  }
  drmTMB(fml, family = stats::binomial(link = fx$link), data = fx$data,
         control = drm_control(se = FALSE))
}

b31nb_check_mesh <- function(fx, info, gap = 0.1) {
  fit <- b31nb_mesh_fit(fx)
  expect_identical(fit$opt$convergence, 0L, info = info)
  co <- coef(fit, "sd_spatial(site)")
  expect_identical(names(co), c("(Intercept)", "z_site"), info = info)
  dat <- fx$data
  mu <- coef(fit, "mu")
  eta_fixed <- mu[[1L]] + mu[[2L]] * dat$x
  deriv <- b29b_deriv_binomial(dat$y, fx$link)
  w <- if (identical(fx$term, "slope")) dat$x else 1
  sd_obs <- exp(co[[1L]] + co[[2L]] * dat$z_site)
  oracle <- function(sd_o = sd_obs, A = fx$Aproj, Sig = fx$Sigma, wt = w) {
    sb26_laplace(deriv, eta_fixed, wt * sd_o * A, Sig)
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  agree <- abs(ll - ref)
  expect_lt(agree, 1e-4, label = info)
  sd_site <- tapply(sd_obs, dat$site, unique)
  expect_gt(stats::sd(log(sd_site)), 0.05, label = paste(info, "SD varies"))
  expect_gt(max(sd_site) / min(sd_site), 1.3, label = paste(info, "SD range"))
  # SD on the unit-precision field scale is tiny (metre coordinates); judge the
  # median SD by the marginal SD it gives the projected field.
  fsd <- sqrt(stats::median(rowSums((fx$Aproj %*% fx$Sigma) * fx$Aproj)))
  expect_gt(stats::median(sd_site) * fsd, 0.15, label = paste(info, "median field SD"))
  rev_site <- as.numeric(sd_site[rev(seq_along(sd_site))])[as.integer(dat$site)]
  kappa <- fx$mesh$kappa
  loc <- fx$mesh$mesh$loc[, 1:2]
  fem <- b31nb_fem(loc, fx$mesh$mesh$graph$tv)
  Q_k2 <- (2 * kappa)^4 * diag(fem$c0) + 2 * (2 * kappa)^2 * fem$g1 + fem$g2
  Aperm <- fx$Aproj[, rev(seq_len(ncol(fx$Aproj)))]
  gaps <- c(
    reversed_sd_by_site = abs(oracle(sd_o = rev_site) - ref),
    precision_times_2 = abs(oracle(Sig = fx$Sigma / 2) - ref),
    kappa_doubled = abs(oracle(Sig = solve(Q_k2)) - ref),
    projection_node_order_reversed = abs(oracle(A = Aperm) - ref)
  )
  if (identical(fx$term, "slope")) {
    gaps[["slope_design_dropped"]] <- abs(oracle(wt = 1) - ref)
  }
  for (nm in names(gaps)) {
    expect_gt(gaps[[nm]], gap, label = paste(info, nm))
  }
  b31nb_report(info, agree, gaps)
  invisible(list(ref = ref, ll = ll, agree = agree, gaps = gaps))
}
