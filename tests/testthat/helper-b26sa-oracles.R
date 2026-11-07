# Batch 26 (lane sa) shared oracle helpers. Everything here is plain base R
# (plus ape for the tree); nothing calls drmTMB internals except
# b26sa_check_phylo_cov(), which compares the package tip-covariance helper
# against ape::vcv. Scope: likelihood agreement at fitted parameters plus
# emulated-bug sensitivity. No calibration, coverage or parity claim.

# Tabular (Henderson) additive relationship matrix. Parents must precede
# offspring; founders have NA dam and sire. Handles inbreeding.
b26sa_henderson_A <- function(ped) {
  ids <- as.character(ped$id)
  n <- length(ids)
  sire <- match(ped$sire, ids)
  dam <- match(ped$dam, ids)
  A <- matrix(0, n, n, dimnames = list(ids, ids))
  for (j in seq_len(n)) {
    s <- sire[[j]]
    d <- dam[[j]]
    if (j > 1L) {
      for (i in seq_len(j - 1L)) {
        v <- 0
        if (!is.na(s)) v <- v + A[i, s]
        if (!is.na(d)) v <- v + A[i, d]
        A[i, j] <- A[j, i] <- 0.5 * v
      }
    }
    f <- if (!is.na(s) && !is.na(d)) 0.5 * A[s, d] else 0
    A[j, j] <- 1 + f
  }
  A
}

# Pedigree with close-relative matings (so diag(A) > 1 for some animals).
# Call set.seed() first.
b26sa_pedigree <- function(n_found, n_total, window = 4L) {
  ids <- sprintf("an%02d", seq_len(n_total))
  sire <- dam <- rep(NA_character_, n_total)
  for (k in (n_found + 1L):n_total) {
    pool <- seq.int(max(1L, k - window), k - 1L)
    pr <- sample(pool, 2L)
    sire[[k]] <- ids[[pr[[1L]]]]
    dam[[k]] <- ids[[pr[[2L]]]]
  }
  data.frame(id = ids, dam = dam, sire = sire, stringsAsFactors = FALSE)
}

# Hand-built kernel: scale * exp(-d / median positive distance) + 1e-6 I.
b26sa_kernel <- function(coords, scale = 1.6) {
  d <- as.matrix(stats::dist(coords))
  med <- stats::median(d[d > 0])
  K <- scale * exp(-d / med) + 1e-6 * diag(nrow(d))
  dimnames(K) <- list(rownames(coords), rownames(coords))
  K
}

# Observation-level log-likelihood and first two eta-derivatives.
b26sa_family <- function(name, size = NULL) {
  switch(
    name,
    poisson = list(
      l = function(y, eta) stats::dpois(y, exp(eta), log = TRUE),
      d1 = function(y, eta) y - exp(eta),
      d2 = function(y, eta) -exp(eta)
    ),
    nbinom2 = list(
      l = function(y, eta) stats::dnbinom(y, size = size, mu = exp(eta), log = TRUE),
      d1 = function(y, eta) {
        mu <- exp(eta)
        size * (y - mu) / (size + mu)
      },
      d2 = function(y, eta) {
        mu <- exp(eta)
        -size * mu * (size + y) / (size + mu)^2
      }
    ),
    probit = , cloglog = {
      pq <- function(eta) {
        if (identical(name, "probit")) {
          p <- stats::pnorm(eta)
          p1 <- stats::dnorm(eta)
          p2 <- -eta * p1
        } else {
          e <- exp(eta)
          p <- -expm1(-e)
          p1 <- e * exp(-e)
          p2 <- p1 * (1 - e)
        }
        list(p = p, p1 = p1, p2 = p2)
      }
      list(
        l = function(y, eta) {
          p <- pq(eta)$p
          y * log(p) + (1 - y) * log1p(-p)
        },
        d1 = function(y, eta) {
          q <- pq(eta)
          q$p1 * (y - q$p) / (q$p * (1 - q$p))
        },
        d2 = function(y, eta) {
          q <- pq(eta)
          q$p2 * (y - q$p) / (q$p * (1 - q$p)) -
            q$p1^2 * (y / q$p^2 + (1 - y) / (1 - q$p)^2)
        }
      )
    },
    stop("unknown family")
  )
}

# Dense Laplace marginal log-likelihood for eta = eta0 + sum_b Z_b f_b,
# f_b ~ N(0, outer(sd_b, sd_b) * K_b), working in whitened coordinates.
# blocks: list(list(index = level index per row, sd = per-level SD, K = base
# covariance)).
b26sa_laplace <- function(y, eta0, blocks, fam) {
  n <- length(y)
  G <- NULL
  for (b in blocks) {
    m <- length(b$sd)
    Z <- matrix(0, n, m)
    Z[cbind(seq_len(n), b$index)] <- 1
    Sigma <- outer(b$sd, b$sd) * b$K
    Sigma <- (Sigma + t(Sigma)) / 2
    G <- cbind(G, Z %*% t(chol(Sigma)))
  }
  m <- ncol(G)
  pen <- function(v) sum(fam$l(y, eta0 + drop(G %*% v))) - 0.5 * sum(v^2)
  v <- numeric(m)
  for (it in seq_len(300L)) {
    eta <- eta0 + drop(G %*% v)
    grad <- drop(crossprod(G, fam$d1(y, eta))) - v
    H <- crossprod(G, G * (-fam$d2(y, eta))) + diag(m)
    step <- drop(solve(H, grad))
    s <- 1
    p0 <- pen(v)
    ok <- function(val) is.finite(val) && val >= p0 - 1e-12
    while (!ok(pen(v + s * step)) && s > 1e-8) s <- s / 2
    v <- v + s * step
    if (max(abs(s * step)) < 1e-11) break
  }
  eta <- eta0 + drop(G %*% v)
  grad <- drop(crossprod(G, fam$d1(y, eta))) - v
  W <- -fam$d2(y, eta)
  logdet <- as.numeric(determinant(
    diag(m) + crossprod(G, G * W), logarithm = TRUE
  )$modulus)
  structure(
    sum(fam$l(y, eta)) - 0.5 * sum(v^2) - 0.5 * logdet,
    max_grad = max(abs(grad))
  )
}

# Gaussian joint mu/sigma random-effect Laplace oracle (mean random effects
# Zm u, sigma random effects Zs u, optional known variance V added to the
# residual variance), u ~ N(0, P^-1) with log det of the covariance supplied.
b26sa_gauss_laplace <- function(y, X, beta, s0, V, Zm, Zs, P, logdet_cov) {
  m <- ncol(Zm)
  mu0 <- as.numeric(X %*% beta)
  obs <- function(u) {
    r <- y - mu0 - as.numeric(Zm %*% u)
    s <- exp(2 * (s0 + as.numeric(Zs %*% u)))
    list(r = r, s = s, T = s + V)
  }
  nll <- function(u) {
    o <- obs(u)
    sum(0.5 * log(2 * pi) + 0.5 * log(o$T) + 0.5 * o$r^2 / o$T) +
      0.5 * sum(u * (P %*% u)) + 0.5 * logdet_cov + 0.5 * m * log(2 * pi)
  }
  grad <- function(u) {
    o <- obs(u)
    f_eta <- o$s / o$T - o$r^2 * o$s / o$T^2
    as.numeric(-crossprod(Zm, o$r / o$T) + crossprod(Zs, f_eta) + P %*% u)
  }
  hess <- function(u) {
    o <- obs(u)
    f_re <- -2 * o$r * o$s / o$T^2
    f_ee <- 2 * o$s * V / o$T^2 - 2 * o$r^2 * o$s * (V - o$s) / o$T^3
    cross <- crossprod(Zm, f_re * Zs)
    crossprod(Zm, Zm / o$T) - cross - t(cross) + crossprod(Zs, f_ee * Zs) + P
  }
  u <- stats::nlminb(rep(0, m), nll, grad)$par
  for (k in seq_len(50L)) {
    g <- grad(u)
    if (max(abs(g)) < 1e-10) break
    u <- u - solve(hess(u), g)
  }
  H <- hess(u)
  list(
    loglik = -nll(u) + 0.5 * m * log(2 * pi) -
      0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus),
    max_grad = max(abs(grad(u))),
    min_eig = min(eigen(H, symmetric = TRUE, only.values = TRUE)$values)
  )
}

b26sa_indicator <- function(index, n_level) {
  out <- matrix(0, length(index), n_level)
  out[cbind(seq_along(index), index)] <- 1
  out
}

# The package phylo tip covariance must equal ape::vcv on shared labels.
# The package default (correlation = TRUE) is the correlation form,
# cov2cor(ape::vcv(tree)); correlation = FALSE is ape::vcv itself.
b26sa_check_phylo_cov <- function(tree) {
  labs <- sort(tree$tip.label)
  expect_equal(
    unname(drmTMB:::drm_phylo_tip_covariance(tree)[labs, labs]),
    unname(stats::cov2cor(ape::vcv(tree))[labs, labs]),
    tolerance = 1e-8
  )
  expect_equal(
    unname(drmTMB:::drm_phylo_tip_covariance(tree, correlation = FALSE)[labs, labs]),
    unname(ape::vcv(tree)[labs, labs]),
    tolerance = 1e-8
  )
}

# ---- IID (ordinary, `site`) plus one structured intercept (`id`) ----------

b26sa_alpha_id <- c(`(Intercept)` = log(0.6), z_id = 0.8)
b26sa_alpha_site <- c(`(Intercept)` = log(0.4), z_site = -0.7)

# kind: "relmat" (hand kernel), "animal" (Henderson A with inbreeding),
# "phylo" (ape::vcv). family: "poisson" or "nbinom2".
b26sa_iid_struct_fixture <- function(kind, family, seed, n_id = 40L,
                                     n_site = 24L, n_each = 10L,
                                     nb_sigma = 0.35) {
  set.seed(seed)
  tree <- ped <- K_raw <- NULL
  if (identical(kind, "relmat")) {
    coords <- matrix(stats::runif(2L * n_id), n_id, 2L,
                     dimnames = list(sprintf("id%02d", seq_len(n_id)), NULL))
    K <- b26sa_kernel(coords)
  } else if (identical(kind, "animal")) {
    ped <- b26sa_pedigree(8L, n_id, window = 4L)
    K <- b26sa_henderson_A(ped)
    stopifnot(max(diag(K)) > 1.05)
  } else {
    tree <- ape::rcoal(n_id)
    tree$edge.length <- 3 * tree$edge.length     # tree height != 1
    tree$tip.label <- sample(sprintf("id%02d", seq_len(n_id)))
    K_raw <- ape::vcv(tree)
    K <- stats::cov2cor(K_raw)                   # what phylo() uses
  }
  id_levels <- sort(rownames(K))
  K <- K[rev(id_levels), rev(id_levels)]          # matrix order != data order
  site_levels <- sprintf("site%02d", seq_len(n_site))
  z_id <- stats::setNames(seq(-1, 1, length.out = n_id)[sample.int(n_id)],
                          id_levels)
  z_site <- stats::setNames(seq(-1, 1, length.out = n_site)[sample.int(n_site)],
                            site_levels)
  sd_id <- exp(b26sa_alpha_id[[1L]] + b26sa_alpha_id[[2L]] * z_id)
  sd_site <- exp(b26sa_alpha_site[[1L]] + b26sa_alpha_site[[2L]] * z_site)
  u <- as.vector(t(chol(K[id_levels, id_levels])) %*% stats::rnorm(n_id)) *
    sd_id[id_levels]
  names(u) <- id_levels
  v <- stats::rnorm(n_site) * sd_site
  n_obs <- n_id * n_each
  id_chr <- rep(id_levels, each = n_each)
  site_chr <- site_levels[sample.int(n_site, n_obs, replace = TRUE)]
  x <- stats::rnorm(n_obs)
  mu <- exp(0.3 + 0.2 * x + u[id_chr] + v[site_chr])
  y <- if (identical(family, "poisson")) {
    stats::rpois(n_obs, mu)
  } else {
    stats::rnbinom(n_obs, size = 1 / nb_sigma^2, mu = mu)
  }
  data <- data.frame(
    y = y, x = x,
    id = factor(id_chr, levels = id_levels),
    site = factor(site_chr, levels = site_levels),
    z_id = unname(z_id[id_chr]), z_site = unname(z_site[site_chr])
  )
  if (!is.null(K_raw)) K_raw <- K_raw[rev(id_levels), rev(id_levels)]
  list(data = data, K = K, K_raw = K_raw, Q = solve(K), tree = tree, z_id = z_id,
       z_site = z_site, id_levels = id_levels, site_levels = site_levels,
       family = family)
}

b26sa_providers <- list(
  relmat_K = list(term = "relmat(1 | id, K = K)", level = "relmat",
                  dpar = "sd_relmat(id)", kind = "relmat"),
  relmat_Q = list(term = "relmat(1 | id, Q = Q)", level = "relmat",
                  dpar = "sd_relmat(id)", kind = "relmat"),
  animal_A = list(term = "animal(1 | id, A = A)", level = "animal",
                  dpar = "sd_animal(id)", kind = "animal"),
  animal_Ainv = list(term = "animal(1 | id, Ainv = Ainv)", level = "animal",
                     dpar = "sd_animal(id)", kind = "animal"),
  phylo = list(term = "phylo(1 | id, tree = tree)", level = "phylogenetic",
               dpar = "sd_phylo(id)", kind = "phylo")
)

b26sa_iid_struct_fit <- function(fx, provider) {
  K <- fx$K
  Q <- fx$Q[rownames(K), rownames(K)]
  A <- K
  Ainv <- Q
  tree <- fx$tree
  spec <- b26sa_providers[[provider]]
  parts <- c(
    paste("y ~ x +", spec$term, "+ (1 | site)"),
    if (identical(fx$family, "nbinom2")) "sigma ~ 1",
    sprintf("sd(id, level = \"%s\") ~ z_id", spec$level),
    "sd(site) ~ z_site"
  )
  fml <- eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", "))))
  fam <- if (identical(fx$family, "poisson")) stats::poisson() else nbinom2()
  drmTMB(fml, family = fam, data = fx$data, control = drm_control(se = FALSE))
}

# Fit, compare with the hand oracle at 1e-4, then emulate four bugs.
b26sa_check_iid_struct <- function(fx, provider) {
  spec <- b26sa_providers[[provider]]
  fit <- b26sa_iid_struct_fit(fx, provider)
  expect_equal(fit$opt$convergence, 0L, info = provider)
  cs <- coef(fit, spec$dpar)
  ci <- coef(fit, "sd(site)")
  expect_identical(names(cs), c("(Intercept)", "z_id"), info = provider)
  expect_identical(names(ci), c("(Intercept)", "z_site"), info = provider)
  ids <- fx$id_levels
  sites <- fx$site_levels
  K <- fx$K[ids, ids]
  dat <- fx$data
  eta0 <- coef(fit, "mu")[["(Intercept)"]] + coef(fit, "mu")[["x"]] * dat$x
  size <- if (identical(fx$family, "nbinom2")) {
    1 / exp(unname(coef(fit, "sigma")[["(Intercept)"]]))^2
  }
  fam <- b26sa_family(fx$family, size)
  curve <- function(co, z) unname(exp(co[[1L]] + co[[2L]] * z))
  oracle <- function(sd_s = curve(cs, fx$z_id[ids]),
                     sd_i = curve(ci, fx$z_site[sites]), Ks = K) {
    b26sa_laplace(
      dat$y, eta0,
      list(list(index = match(as.character(dat$id), ids), sd = sd_s, K = Ks),
           list(index = match(as.character(dat$site), sites), sd = sd_i,
                K = diag(length(sites)))),
      fam
    )
  }
  ll <- as.numeric(logLik(fit))
  base <- oracle()
  expect_lt(abs(ll - base), 1e-4, label = provider)
  expect_lt(attr(base, "max_grad"), 1e-5)
  # Emulated bugs: each must move the oracle by far more than the tolerance.
  sd_s <- curve(cs, fx$z_id[ids])
  sd_i <- curve(ci, fx$z_site[sites])
  bugs <- c(
    reversed_structured_sd = oracle(sd_s = rev(sd_s)),
    reversed_iid_sd = oracle(sd_i = rev(sd_i)),
    swapped_selector_coefs = oracle(
      sd_s = curve(ci, fx$z_id[ids]), sd_i = curve(cs, fx$z_site[sites])
    ),
    wrong_K_scale = if (is.null(fx$K_raw)) {
      oracle(Ks = stats::cov2cor(K))          # relmat / animal: K is not a correlation
    } else {
      oracle(Ks = fx$K_raw[ids, ids])         # phylo: raw ape::vcv instead of cov2cor
    }
  )
  for (nm in names(bugs)) {
    expect_gt(abs(ll - bugs[[nm]]), 0.1, label = paste(provider, nm))
  }
  invisible(list(fit = fit, bugs = bugs, ll = ll))
}
