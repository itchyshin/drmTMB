# Batch 31 (group ja) shared oracle pieces for the live Julia Binomial
# companions (test-julia-*-oracle-b31ja.R).
#
# Everything is base R (plus ape::vcv for the tree kernel). No drmTMB internal
# builds a kernel or the likelihood: the Henderson tabular A is built here from
# a pedigree with inbreeding, and the Laplace log marginal likelihood is a
# dense joint-Newton mode with hand-derived observed second derivatives of the
# Bernoulli logit / probit / cloglog likelihood.
#
# Claim scope: the live Julia logLik agrees with this independent oracle at the
# Julia estimates on the stated fixture, and each emulated bug moves the oracle
# far more than the agreement. No calibration, coverage or broad parity claim.

b31ja_link_terms <- function(link, eta, y) {
  if (identical(link, "logit")) {
    p <- stats::plogis(eta)
    list(f = pmax(eta, 0) + log1p(exp(-abs(eta))) - y * eta,
         d1 = p - y, d2 = p * (1 - p))
  } else if (identical(link, "probit")) {
    sgn <- ifelse(y == 1, 1, -1)
    q <- sgn * eta
    lam <- exp(stats::dnorm(q, log = TRUE) - stats::pnorm(q, log.p = TRUE))
    list(f = -stats::pnorm(q, log.p = TRUE), d1 = -sgn * lam,
         d2 = lam * (lam + q))
  } else if (identical(link, "cloglog")) {
    # eta is capped at 50 (exp(50) ~ 5e21) so absurd trial values stay finite.
    t <- exp(pmin(eta, 50))
    r <- exp(-t)
    one <- y == 1
    list(f = ifelse(one, -log(-expm1(-t)), t),
         d1 = ifelse(one, t * r / expm1(-t), t),
         d2 = ifelse(one, t * r * (t + expm1(-t)) / expm1(-t)^2, t))
  } else {
    stop("unsupported link", call. = FALSE)
  }
}

# Dense Laplace log marginal likelihood for eta = eta_fixed + M u, u ~ N(0, C)
# with precision Q = C^-1 supplied: -joint_nll(u*) + log|Q|/2 - log|H|/2,
# H = Q + M' W M (observed information).
b31ja_laplace <- function(link, y, eta_fixed, M, Q) {
  m <- ncol(M)
  nll <- function(u) {
    0.5 * sum(u * drop(Q %*% u)) +
      sum(b31ja_link_terms(link, eta_fixed + drop(M %*% u), y)$f)
  }
  u <- numeric(m)
  converged <- FALSE
  for (iteration in seq_len(200L)) {
    tm <- b31ja_link_terms(link, eta_fixed + drop(M %*% u), y)
    gradient <- drop(Q %*% u) + drop(crossprod(M, tm$d1))
    hessian <- Q + crossprod(M, M * tm$d2)
    step <- drop(solve(hessian, gradient))
    if (max(abs(step)) < 1e-6) {
      # A full Newton step this small is taken without a line search (roundoff
      # in the objective would otherwise accept a vanishing rate); the Laplace
      # value is stationary in u, so the remaining error is of order 1e-12.
      u <- u - step
      converged <- TRUE
      break
    }
    old <- nll(u)
    rate <- 1
    while (rate > 1e-8) {
      cand <- u - rate * step
      if (isTRUE(nll(cand) <= old)) {
        u <- cand
        break
      }
      rate <- rate / 2
    }
    if (rate <= 1e-8) stop("oracle line search failed", call. = FALSE)
  }
  if (!converged) stop("oracle mode exceeded iteration limit", call. = FALSE)
  tm <- b31ja_link_terms(link, eta_fixed + drop(M %*% u), y)
  hessian <- Q + crossprod(M, M * tm$d2)
  -nll(u) + 0.5 * as.numeric(determinant(Q, logarithm = TRUE)$modulus) -
    sum(log(diag(chol(hessian))))
}

# Henderson tabular additive relationship matrix. ped columns: id, dam, sire
# (NA = unknown founder); parents must precede offspring.
b31ja_tabular_A <- function(ped) {
  n <- nrow(ped)
  id <- as.character(ped$id)
  idx <- function(p) if (is.na(p)) NA_integer_ else match(as.character(p), id)
  dam <- vapply(ped$dam, idx, integer(1L))
  sire <- vapply(ped$sire, idx, integer(1L))
  A <- matrix(0, n, n, dimnames = list(id, id))
  for (i in seq_len(n)) {
    s <- sire[[i]]
    d <- dam[[i]]
    for (j in seq_len(i - 1L)) {
      a <- 0
      if (!is.na(s)) a <- a + A[j, s]
      if (!is.na(d)) a <- a + A[j, d]
      A[i, j] <- A[j, i] <- a / 2
    }
    A[i, i] <- 1 + if (!is.na(s) && !is.na(d)) A[s, d] / 2 else 0
  }
  A
}

# Repeated full-sib mating per family: founders, 1 to 5 generations of full-sib
# pairs (cycling over families) and four offspring of the last pair, so diag(A)
# of the offspring varies between 1.25 and about 1.67 and cov2cor(A) is a
# large, non-constant change.
b31ja_inbred_pedigree <- function(n_family) {
  one <- function(f) {
    id <- c(sprintf("f%dsire", f), sprintf("f%ddam", f))
    dam <- sire <- c(NA, NA)
    pm <- id[[1L]]
    pf <- id[[2L]]
    for (g in seq_len(c(1L, 2L, 3L, 4L, 5L)[(f - 1L) %% 5L + 1L])) {
      m <- sprintf("f%dg%dm", f, g)
      w <- sprintf("f%dg%df", f, g)
      id <- c(id, m, w)
      sire <- c(sire, pm, pm)
      dam <- c(dam, pf, pf)
      pm <- m
      pf <- w
    }
    kids <- sprintf("f%dk%d", f, 1:4)
    id <- c(id, kids)
    sire <- c(sire, rep(pm, 4L))
    dam <- c(dam, rep(pf, 4L))
    data.frame(id = id, dam = dam, sire = sire, stringsAsFactors = FALSE)
  }
  do.call(rbind, lapply(seq_len(n_family), one))
}

# Offspring-only inbred additive matrix with row/column order shuffled relative
# to sorted names; returns list(A, pedigree, ids = shuffled order).
b31ja_inbred_animals <- function(n_family) {
  ped <- b31ja_inbred_pedigree(n_family)
  Afull <- b31ja_tabular_A(ped)
  kids <- grep("k[0-9]$", ped$id, value = TRUE)
  kids <- sample(kids)
  A <- Afull[kids, kids]
  stopifnot(max(diag(A)) > 1.6, min(diag(A)) > 1.05,
            diff(range(diag(A))) > 0.3)
  list(A = A, pedigree = ped, ids = kids)
}

# Non-palindromic, non-monotone per-level selector (centred, unit variance).
b31ja_selector <- function(n) as.numeric(scale(stats::rnorm(n)))

# Standard bug-gap assertions. `gaps` are oracle(bug) - oracle(base).
b31ja_expect_gaps <- function(gaps, agreement_tol, info) {
  gap_min <- 20 * agreement_tol
  for (nm in names(gaps)) {
    testthat::expect_gt(abs(gaps[[nm]]), gap_min,
                        label = paste(info, nm, "oracle gap"))
  }
  testthat::expect_gt(min(abs(gaps)) / agreement_tol, 20)
  invisible(min(abs(gaps)))
}

b31ja_report <- function(tag, ll, base, gaps) {
  message(sprintf(
    "b31ja %s: ll=%.6f oracle=%.6f agreement=%.2e; min gap=%.4f (%s); gaps: %s",
    tag, ll, base, abs(ll - base), min(abs(gaps)), names(gaps)[which.min(abs(gaps))],
    paste(sprintf("%s=%.3f", names(gaps), gaps), collapse = ", ")))
}

# The Julia bridge stores each SD target under a hex-encoded key such as
# "id|animal|mu|x|none"; find the key whose decoded text contains `label`.
b31ja_target_key <- function(fit, label) {
  keys <- grep("^sdtarget_", names(fit$coefficients), value = TRUE)
  dec <- vapply(keys, function(k) {
    h <- sub("^sdtarget_", "", k)
    rawToChar(as.raw(strtoi(substring(h, seq(1L, nchar(h), 2L),
                                      seq(2L, nchar(h), 2L)), 16L)))
  }, character(1L))
  hit <- keys[grepl(label, dec, fixed = TRUE)]
  stopifnot(length(hit) == 1L)
  hit
}

# ---- single structured animal field with an sd() formula --------------------
# eta = b0 + b1 x + w_i S_i u_i, u ~ N(0, A), S_i = exp(a0 + a1 z_i); w = 1
# (random intercept) or w = x (independent random numeric slope). A's row order
# differs from the factor level order and z is random per animal.
b31ja_single_fixture <- function(link, seed, slope, n_family = 12L,
                                 repeats = 24L) {
  set.seed(seed)
  an <- b31ja_inbred_animals(n_family)
  A <- an$A
  m <- nrow(A)
  lev <- sort(rownames(A))
  z <- stats::setNames(b31ja_selector(m), rownames(A))
  idx <- rep(seq_len(m), each = repeats)
  id <- factor(lev[idx], levels = lev)
  x <- stats::rnorm(length(id))
  a <- c(-0.5, 0.55)
  s <- exp(a[[1L]] + a[[2L]] * z)
  l <- stats::setNames(drop(t(chol(A)) %*% stats::rnorm(m)), rownames(A))
  key <- as.character(id)
  w <- if (slope) x else 1
  eta <- -0.1 + 0.3 * x + w * (s * l)[key]
  p <- switch(link, logit = stats::plogis(eta), probit = stats::pnorm(eta),
              cloglog = -expm1(-exp(eta)))
  data <- data.frame(y = stats::rbinom(length(eta), 1L, p), x = x,
                     z = z[key], id = id, row.names = NULL)
  list(data = data, A = A)
}

b31ja_single_oracle <- function(link, data, K, beta, a, slope, z = NULL) {
  rn <- rownames(K)
  m <- length(rn)
  idx <- match(as.character(data$id), rn)
  zm <- if (is.null(z)) data$z[match(rn, as.character(data$id))] else z
  s <- exp(a[[1L]] + a[[2L]] * zm)
  n <- nrow(data)
  M <- matrix(0, n, m)
  M[cbind(seq_len(n), idx)] <- if (slope) data$x else 1
  b31ja_laplace(link, data$y, beta[[1L]] + beta[[2L]] * data$x, M,
                solve(outer(s, s) * K))
}

# Fit-and-check for one (provider, link) route of the single animal field.
b31ja_single_check <- function(provider, link, slope, seed, tag,
                               agreement_tol = 1e-3, check_max = FALSE) {
  fx <- b31ja_single_fixture(link, seed, slope)
  A <- fx$A
  Ainv <- solve(A)
  term <- if (slope) {
    switch(provider,
           A = quote(animal(0 + x | id, A = A)),
           Ainv = quote(animal(0 + x | id, Ainv = Ainv)))
  } else {
    switch(provider,
           A = quote(animal(1 | id, A = A)),
           Ainv = quote(animal(1 | id, Ainv = Ainv)))
  }
  fml <- eval(bquote(bf(y ~ x + .(term),
                        sd(id, level = "animal") ~ z)))
  fit <- drmTMB(fml, family = stats::binomial(link = link), data = fx$data,
                engine = "julia")
  data <- fx$data
  testthat::expect_identical(fit$opt$convergence, 0L, info = tag)
  beta <- unname(coef(fit, dpar = "mu"))
  a <- coef(fit, dpar = "sd_animal(id)")
  testthat::expect_identical(names(a), c("(Intercept)", "z"))
  a <- unname(a)
  ll <- as.numeric(logLik(fit))
  oracle <- function(...) {
    args <- list(link = link, data = data, K = A, beta = beta, a = a,
                 slope = slope)
    over <- list(...)
    args[names(over)] <- over
    do.call(b31ja_single_oracle, args)
  }
  base <- oracle()
  testthat::expect_lt(abs(ll - base), agreement_tol,
                      label = paste(tag, "agreement"))
  rn <- rownames(A)
  zm <- data$z[match(rn, as.character(data$id))]
  K_pos <- A
  dimnames(K_pos) <- list(sort(rn), sort(rn))
  K_rev <- A
  dimnames(K_rev) <- list(rev(rn), rev(rn))
  testthat::expect_gt(diff(range(diag(A))), 0.3)
  gaps <- c(
    selector_slope_sign = oracle(a = c(a[[1L]], -a[[2L]])),
    reversed_sd_vector = oracle(z = rev(zm)),
    A_scale_2 = oracle(K = 2 * A),
    A_scale_1.3 = oracle(K = 1.3 * A),
    cov2cor_A = oracle(K = stats::cov2cor(A)),
    A_read_by_position = oracle(K = K_pos),
    A_dimnames_reversed = oracle(K = K_rev),
    wrong_field_type = oracle(slope = !slope)
  ) - base
  b31ja_expect_gaps(gaps, agreement_tol, tag)
  if (check_max) {
    for (k in 1:2) {
      for (sgn in c(-0.1, 0.1)) {
        b <- beta; b[[k]] <- b[[k]] + sgn
        p <- a; p[[k]] <- p[[k]] + sgn
        testthat::expect_lt(oracle(beta = b), base + agreement_tol)
        testthat::expect_lt(oracle(a = p), base + agreement_tol)
      }
    }
  }
  b31ja_report(tag, ll, base, gaps)
  invisible(list(ll = ll, base = base, min_gap = min(abs(gaps))))
}

# Hand-derived link terms agree with dbinom and central differences.
b31ja_expect_link_terms <- function() {
  eta <- c(-3, -1, -0.2, 0.4, 1.5)
  for (link in c("logit", "probit", "cloglog")) {
    p <- stats::binomial(link = link)$linkinv(eta)
    for (y in 0:1) {
      yy <- rep(y, length(eta))
      tm <- b31ja_link_terms(link, eta, yy)
      h <- 1e-5
      fp <- b31ja_link_terms(link, eta + h, yy)
      fm <- b31ja_link_terms(link, eta - h, yy)
      testthat::expect_equal(tm$f, -stats::dbinom(yy, 1, p, log = TRUE),
                             tolerance = 1e-6)
      testthat::expect_equal(tm$d1, (fp$f - fm$f) / (2 * h), tolerance = 1e-6)
      testthat::expect_equal(tm$d2, (fp$d1 - fm$d1) / (2 * h), tolerance = 1e-6)
    }
  }
}

# ---- per-group adaptive Gauss-Hermite oracle --------------------------------
# The live Julia route for ordinary (1 + x | id) correlated Binomial blocks with
# sd() formulas integrates each group's q-dimensional random effect with
# adaptive Gauss-Hermite quadrature (5 nodes per axis by default), not a
# Laplace approximation. This oracle is an independent base-R implementation:
# Golub-Welsch nodes, the group's observed-information mode and curvature, and
# a tensor grid, so Julia and the oracle can agree to a tight tolerance when
# both use K nodes, and a higher K shows how far the 5-node value is from the
# exact marginal likelihood.
b31ja_gh_rule <- function(K) {
  if (K == 1L) return(list(x = 0, w = sqrt(pi)))
  J <- matrix(0, K, K)
  off <- sqrt(seq_len(K - 1L) / 2)
  J[cbind(seq_len(K - 1L), seq_len(K - 1L) + 1L)] <- off
  J[cbind(seq_len(K - 1L) + 1L, seq_len(K - 1L))] <- off
  e <- eigen(J, symmetric = TRUE)
  o <- order(e$values)
  list(x = e$values[o], w = sqrt(pi) * e$vectors[1L, o]^2)
}

b31ja_aghq <- function(link, y, eta_fixed, M, Q, K = 5L) {
  q <- ncol(M)
  nll <- function(u) {
    0.5 * sum(u * drop(Q %*% u)) +
      sum(b31ja_link_terms(link, eta_fixed + drop(M %*% u), y)$f)
  }
  u <- numeric(q)
  for (iteration in seq_len(200L)) {
    tm <- b31ja_link_terms(link, eta_fixed + drop(M %*% u), y)
    gradient <- drop(Q %*% u) + drop(crossprod(M, tm$d1))
    hessian <- Q + crossprod(M, M * tm$d2)
    step <- drop(solve(hessian, gradient))
    if (max(abs(step)) < 1e-6) {
      u <- u - step
      break
    }
    old <- nll(u)
    rate <- 1
    while (rate > 1e-8) {
      cand <- u - rate * step
      if (isTRUE(nll(cand) <= old)) {
        u <- cand
        break
      }
      rate <- rate / 2
    }
    if (rate <= 1e-8) stop("oracle line search failed", call. = FALSE)
  }
  tm <- b31ja_link_terms(link, eta_fixed + drop(M %*% u), y)
  H <- Q + crossprod(M, M * tm$d2)
  # H = R'R (R upper); C = R^-1 satisfies C C' = H^-1 (the root used by the
  # node transform b = bhat + sqrt(2) C z).
  Cl <- solve(chol(H))
  gh <- b31ja_gh_rule(K)
  grid <- as.matrix(expand.grid(rep(list(seq_len(K)), q)))
  Z <- matrix(gh$x[grid], nrow(grid), q)
  lw <- rowSums(matrix(log(gh$w)[grid], nrow(grid), q)) + rowSums(Z^2)
  B <- sweep(sqrt(2) * Z %*% t(Cl), 2L, u, "+")   # nodes in b-space (rows)
  fvals <- vapply(seq_len(nrow(B)), function(j) -nll(B[j, ]), numeric(1L))
  a <- lw + fvals
  logint <- max(a) + log(sum(exp(a - max(a)))) + q * 0.5 * log(2) +
    sum(log(diag(Cl)))
  logint - 0.5 * q * log(2 * pi) +
    0.5 * as.numeric(determinant(Q, logarithm = TRUE)$modulus)
}

# ---- ordinary (1 + x1 [+ x2] | id) correlated block, sd() on each coefficient ----
b31ja_iid_fixture <- function(q, link, seed, groups, repeats) {
  set.seed(seed)
  id <- factor(sprintf("g%03d", rep(seq_len(groups), each = repeats)))
  n <- length(id)
  xs <- c("x1", "x2")[seq_len(q - 1L)]
  X <- vapply(xs, function(v) stats::rnorm(n), numeric(n))
  sel_names <- paste0("w", seq_len(q) - 1L)
  sel <- lapply(sel_names, function(v) b31ja_selector(groups))
  a <- list(c(-0.7, 0.45), c(-0.65, -0.4), c(-0.75, 0.5))[seq_len(q)]
  tau <- vapply(seq_len(q), function(k) exp(a[[k]][[1L]] + a[[k]][[2L]] * sel[[k]]),
                numeric(groups))
  partial <- c(0.5, -0.35, 0.4)[seq_len(q * (q - 1L) / 2L)]
  Lc <- matrix(0, q, q)
  pos <- 0L
  for (i in seq_len(q)) {
    pr <- 1
    for (j in seq_len(i - 1L)) {
      pos <- pos + 1L
      Lc[i, j] <- pr * partial[[pos]]
      pr <- pr * sqrt(1 - partial[[pos]]^2)
    }
    Lc[i, i] <- pr
  }
  u <- vapply(seq_len(groups), function(g) drop(diag(tau[g, ]) %*% Lc %*%
                                                  stats::rnorm(q)), numeric(q))
  gi <- as.integer(id)
  eta <- -0.1 + 0.2 * X[, 1L] + u[1L, gi] + u[2L, gi] * X[, 1L] +
    (if (q == 3L) -0.15 * X[, 2L] + u[3L, gi] * X[, 2L] else 0)
  p <- switch(link, logit = stats::plogis(eta), probit = stats::pnorm(eta),
              cloglog = -expm1(-exp(eta)))
  dat <- data.frame(y = stats::rbinom(n, 1L, p), X, id)
  for (k in seq_len(q)) dat[[sel_names[[k]]]] <- rep(sel[[k]], each = repeats)
  list(data = dat, sel = sel, xs = xs, sel_names = sel_names)
}

b31ja_iid_check <- function(q, link, seed, groups, repeats,
                            agreement_tol = 1e-3) {
  tag <- paste0("iid q", q, " ", link)
  fx <- b31ja_iid_fixture(q, link, seed, groups, repeats)
  dat <- fx$data
  coefs <- c("(Intercept)", fx$xs)
  keys <- paste0('sd(id, dpar = "mu", coef = "', coefs, '")')
  main <- stats::as.formula(paste0(
    "y ~ ", paste(fx$xs, collapse = " + "),
    " + (1 + ", paste(fx$xs, collapse = " + "), " | id)"
  ))
  sds <- lapply(seq_len(q), function(k) {
    stats::as.formula(paste0(keys[[k]], " ~ ", fx$sel_names[[k]]),
                      env = globalenv())
  })
  fit <- drmTMB(do.call(bf, c(list(main), sds)),
                family = stats::binomial(link = link), data = dat,
                engine = "julia")
  testthat::expect_identical(fit$opt$convergence, 0L, info = tag)
  co <- lapply(keys, function(k) coef(fit, k))
  for (k in seq_len(q)) {
    testthat::expect_identical(names(co[[k]]), c("(Intercept)", fx$sel_names[[k]]),
                     info = tag)
  }
  curve <- function(cf, w) unname(exp(cf[[1L]] + cf[[2L]] * w))
  S0 <- vapply(seq_len(q), function(k) curve(co[[k]], fx$sel[[k]]),
               numeric(groups))
  cors <- fit$corpars$mu
  testthat::expect_length(cors, q * (q - 1L) / 2L)
  R <- diag(q)
  for (nm in names(cors)) {
    inner <- sub("^cor\\((.*) \\| id\\)$", "\\1", nm)
    pr <- trimws(strsplit(inner, ",", fixed = TRUE)[[1L]])
    i <- match(pr[[1L]], coefs)
    j <- match(pr[[2L]], coefs)
    testthat::expect_false(anyNA(c(i, j)), info = nm)
    R[i, j] <- R[j, i] <- unname(cors[[nm]])
  }
  mu <- unname(coef(fit, "mu"))
  Xf <- cbind(1, as.matrix(dat[, fx$xs, drop = FALSE]))
  eta_fixed <- mu[[1L]] + drop(as.matrix(dat[, fx$xs, drop = FALSE]) %*% mu[-1L])
  gi <- as.integer(dat$id)
  rows <- split(seq_len(nrow(dat)), gi)
  oracle <- function(S = S0, Rm = R, nodes = 5L) {
    sum(vapply(seq_len(groups), function(g) {
      r <- rows[[g]]
      Sg <- diag(S[g, ], q)
      b31ja_aghq(link, dat$y[r], eta_fixed[r], Xf[r, , drop = FALSE],
                 solve(Sg %*% Rm %*% Sg), K = nodes)
    }, numeric(1L)))
  }
  base <- oracle()
  ll <- as.numeric(logLik(fit))
  testthat::expect_lt(abs(ll - base), agreement_tol, label = paste(tag, "agreement"))
  for (k in seq_len(q)) testthat::expect_gt(stats::sd(log(S0[, k])), 0.05)
  flipR <- R
  flipR[1L, 2L] <- flipR[2L, 1L] <- -R[1L, 2L]
  rev_col <- function(k) {
    S <- S0
    S[, k] <- rev(S[, k])
    S
  }
  gaps <- unlist(c(
    list(rotated_coef_sets = oracle(S = vapply(seq_len(q), function(k) {
      curve(co[[k %% q + 1L]], fx$sel[[k]])
    }, numeric(groups)))),
    stats::setNames(lapply(seq_len(q), function(k) oracle(S = rev_col(k))),
                    paste0("reversed_sd_", coefs)),
    list(flipped_cor_first = oracle(Rm = flipR), R_identity = oracle(Rm = diag(q)))
  )) - base
  b31ja_expect_gaps(gaps, agreement_tol, tag)
  b31ja_report(tag, ll, base, gaps)
  if (q == 2L) {
    message(sprintf("b31ja %s: 15-node oracle %.4f (5-node %.4f, Julia %.4f)",
                    tag, oracle(nodes = 15L), base, ll))
  }
  invisible(list(ll = ll, base = base, min_gap = min(abs(gaps)),
                 cors = cors))
}
