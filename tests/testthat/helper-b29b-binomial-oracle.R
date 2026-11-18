# Batch 29 (strengthening lane b) shared oracle pieces for the native
# Binomial two-field SD-regression companions (test-binomial-*-b29b.R).
#
# Everything is base R plus ape::vcv. It builds on the existing independent
# pieces in helper-sb26-oracle.R (Henderson tabular A, hand spatial kernel,
# dense Laplace) and helper-b26sa-oracles.R (hand relmat kernel, ape::vcv
# comparison). No drmTMB internal is used to build a kernel or the likelihood;
# b29b_check_phylo_cov() compares the package tip-covariance helper with
# ape::vcv and is the only place a package helper is called.
#
# A "field" is one random intercept with its own predictor-dependent SD:
#   iid / iid2  ordinary (1 | g)             K = I
#   animal      animal(1 | g, A|Ainv|pedigree)   K = Henderson A (inbred)
#   relmat      relmat(1 | g, K|Q)           K = hand exponential kernel, scale 1.6
#   phylo       phylo(1 | g, tree = tree)    K = cov2cor(ape::vcv(tree)), tree height 3
#   spatial     spatial(1 | g, coords)       K = hand exponential kernel + 1e-6 I
# Matrix row order is deliberately the reverse of the data factor order, and
# the tree tips / coordinate rows are shuffled, so a position-based alignment
# bug moves the likelihood.
#
# Scope: likelihood assembly and selector alignment at the fitted parameters.
# No calibration, coverage, recovery or parity claim.

b29b_deriv_binomial <- function(y, link) {
  function(eta) {
    if (identical(link, "logit")) {
      p <- stats::plogis(eta)
      list(l = y * stats::plogis(eta, log.p = TRUE) +
             (1 - y) * stats::plogis(-eta, log.p = TRUE),
           d1 = y - p, d2 = -p * (1 - p))
    } else {
      sb26_deriv_binary(y, link)(eta)
    }
  }
}

# Repeated full-sib mating: each family has founders, five generations of
# full-sib pairs (inbreeding coefficient rising to about 0.66) and four
# offspring of the last pair, so diag(A) reaches about 1.7 for many animals and
# cov2cor(A) is a large change.
b29b_inbred_pedigree <- function(n_family) {
  one <- function(f) {
    id <- c(sprintf("f%dsire", f), sprintf("f%ddam", f))
    dam <- sire <- c(NA, NA)
    pm <- id[[1L]]
    pf <- id[[2L]]
    for (g in 1:5) {
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

b29b_field_defaults <- list(
  iid = list(n = 24L, group = "g_iid", z = "w", a = c(log(1.0), 1.0)),
  iid2 = list(n = 20L, group = "g_two", z = "v", a = c(log(0.9), -0.9)),
  animal = list(n = 48L, group = "animal_id", z = "z_animal",
                a = c(log(2.0), 0.8)),
  relmat = list(n = 30L, group = "population", z = "z_population",
                a = c(log(1.0), -0.9)),
  phylo = list(n = 24L, group = "species", z = "z_tree",
               a = c(log(1.8), -0.7)),
  spatial = list(n = 24L, group = "site", z = "z_site", a = c(log(1.0), 0.9))
)

# Build one field: levels, unit-scale kernel (row order reversed vs levels),
# the objects the formula refers to, and per-level z / SD curve.
b29b_make_field <- function(kind, sd_mult = 1) {
  d <- b29b_field_defaults[[kind]]
  out <- c(list(kind = kind), d)
  if (kind %in% c("iid", "iid2")) {
    lev <- sprintf("%s%02d", if (kind == "iid") "i" else "j", seq_len(d$n))
    K <- diag(d$n)
    dimnames(K) <- list(lev, lev)
    out$K <- K
  } else if (kind == "animal") {
    ped <- b29b_inbred_pedigree(3L)
    A <- sb26_tabular_A(ped)
    stopifnot(max(diag(A)) > 1.6, nrow(A) == d$n)
    lev <- sort(rownames(A))
    out$K <- A[rev(lev), rev(lev)]
    out$pedigree <- ped
  } else if (kind == "relmat") {
    lev <- sprintf("pop%02d", seq_len(d$n))
    co <- matrix(stats::runif(2L * d$n), d$n, 2L, dimnames = list(lev, NULL))
    out$K <- b26sa_kernel(co, scale = 1.6)[rev(lev), rev(lev)]
  } else if (kind == "phylo") {
    tree <- ape::rcoal(d$n)
    tree$edge.length <- 3 * tree$edge.length
    tree$tip.label <- sample(sprintf("sp%02d", seq_len(d$n)))
    lev <- sort(tree$tip.label)
    out$tree <- tree
    out$K_raw <- ape::vcv(tree)[lev, lev]
    out$K <- stats::cov2cor(out$K_raw)[rev(lev), rev(lev)]
  } else {
    lev <- sprintf("s%02d", seq_len(d$n))
    co <- data.frame(east = stats::runif(d$n, 0, 3), north = stats::runif(d$n, 0, 2),
                     row.names = lev)
    out$coords <- co[sample(lev), , drop = FALSE]
    out$K <- sb26_spatial_kernel(co, lev)[rev(lev), rev(lev)]
  }
  out$levels <- lev
  zv <- seq(-1, 1, length.out = d$n)[sample.int(d$n)]
  out$zlev <- stats::setNames(zv, lev)
  # Latent field with the true per-level SD.
  sdv <- sd_mult * exp(d$a[[1L]] + d$a[[2L]] * out$zlev)
  Ks <- out$K[lev, lev]
  out$u <- stats::setNames(
    drop(t(chol(Ks)) %*% stats::rnorm(d$n)) * sdv, lev
  )
  out
}

# Provider term for a field.
b29b_term <- function(f, provider) {
  g <- f$group
  switch(
    f$kind,
    iid = , iid2 = sprintf("(1 | %s)", g),
    animal = switch(provider,
      A = sprintf("animal(1 | %s, A = A)", g),
      Ainv = sprintf("animal(1 | %s, Ainv = Ainv)", g),
      pedigree = sprintf("animal(1 | %s, pedigree = pedigree)", g)),
    relmat = switch(provider,
      K = sprintf("relmat(1 | %s, K = K)", g),
      Q = sprintf("relmat(1 | %s, Q = Q)", g)),
    phylo = sprintf("phylo(1 | %s, tree = tree)", g),
    spatial = sprintf("spatial(1 | %s, coords = coords)", g)
  )
}
b29b_sd_lhs <- function(f) {
  lev <- c(iid = NA, iid2 = NA, animal = "animal", relmat = "relmat",
           phylo = "phylogenetic", spatial = "spatial")[[f$kind]]
  if (is.na(lev)) sprintf("sd(%s)", f$group) else
    sprintf("sd(%s, level = \"%s\")", f$group, lev)
}
b29b_dpar <- function(f) {
  switch(f$kind, iid = , iid2 = sprintf("sd(%s)", f$group),
         animal = sprintf("sd_animal(%s)", f$group),
         relmat = sprintf("sd_relmat(%s)", f$group),
         phylo = sprintf("sd_phylo(%s)", f$group),
         spatial = sprintf("sd_spatial(%s)", f$group))
}

# fields: list of fields (one or two); returns data + fields.
b29b_fixture <- function(kinds, link, seed, n_obs = 1000L, boost = NULL) {
  set.seed(seed)
  # probit coefficients are about 1/1.7 of logit ones; scale the true SDs so
  # every link carries comparable information.
  # `boost`: optional named per-kind multiplier on the true SDs.
  fields <- lapply(kinds, function(k) {
    b29b_make_field(
      k, sd_mult = (if (identical(link, "probit")) 1.7 else 1) *
        (if (k %in% names(boost)) boost[[k]] else 1)
    )
  })
  names(fields) <- kinds
  x <- stats::rnorm(n_obs)
  eta <- -0.1 + 0.3 * x
  dat <- data.frame(x = x)
  for (f in fields) {
    idx <- sample(rep(seq_len(f$n), length.out = n_obs))
    chr <- f$levels[idx]
    eta <- eta + f$u[chr]
    dat[[f$group]] <- factor(chr, levels = f$levels)
    dat[[f$z]] <- unname(f$zlev[chr])
  }
  dat$y <- stats::rbinom(n_obs, 1L, stats::make.link(link)$linkinv(eta))
  list(data = dat, fields = fields, link = link)
}

# Fit. `providers`: named character vector, names = kinds.
b29b_fit <- function(fx, providers) {
  # Objects referenced by the formula terms, created here so the formula
  # environment holds them.
  A <- fx$fields$animal$K
  Ainv <- if (!is.null(A)) solve(A)
  pedigree <- fx$fields$animal$pedigree
  K <- Q <- NULL
  if (!is.null(fx$fields$relmat)) {
    K <- fx$fields$relmat$K
    Q <- solve(K)
  }
  tree <- fx$fields$phylo$tree
  coords <- fx$fields$spatial$coords
  terms <- vapply(fx$fields, function(f) {
    b29b_term(f, providers[[f$kind]])
  }, character(1L))
  sds <- vapply(fx$fields, function(f) {
    sprintf("%s ~ %s", b29b_sd_lhs(f), f$z)
  }, character(1L))
  fml <- eval(parse(text = sprintf(
    "bf(y ~ x + %s, %s)", paste(terms, collapse = " + "),
    paste(sds, collapse = ", ")
  )))
  drmTMB(fml, family = stats::binomial(link = fx$link), data = fx$data,
         control = drm_control(se = FALSE))
}

b29b_curve <- function(co, z) unname(exp(co[[1L]] + co[[2L]] * z))

# Fit, compare with the dense Laplace oracle at the fitted parameters
# (tolerance 1e-4 absolute on logLik), then emulate bugs, each of which must
# move the oracle by more than `gap` = 0.1 (1000x the tolerance).
b29b_check <- function(fx, providers, info, gap = 0.1) {
  fit <- b29b_fit(fx, providers)
  expect_identical(fit$opt$convergence, 0L, info = info)
  fields <- fx$fields
  dat <- fx$data
  kinds <- names(fields)
  co <- lapply(fields, function(f) coef(fit, b29b_dpar(f)))
  for (k in kinds) {
    expect_identical(names(co[[k]]), c("(Intercept)", fields[[k]]$z),
                     info = paste(info, k))
  }
  mu <- coef(fit, "mu")
  eta_fixed <- mu[[1L]] + mu[[2L]] * dat$x
  deriv <- b29b_deriv_binomial(dat$y, fx$link)
  idx <- lapply(fields, function(f) as.integer(dat[[f$group]]))
  sdv <- function(k, co_k = co[[k]]) {
    f <- fields[[k]]
    stats::setNames(b29b_curve(co_k, f$zlev[f$levels]), f$levels)
  }
  oracle <- function(sds = lapply(kinds, sdv), Ks = lapply(fields, function(f) f$K)) {
    Z <- NULL
    blocks <- list()
    for (i in seq_along(kinds)) {
      f <- fields[[i]]
      Z <- cbind(Z, sb26_Z(idx[[i]], f$n, sds[[i]]))
      blocks[[i]] <- Ks[[i]][f$levels, f$levels]
    }
    sb26_laplace(deriv, eta_fixed, Z, do.call(sb26_blockdiag, blocks))
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - ref), 1e-4, label = info)
  # The fit must have separated the SD curves (so a swap or reversal is a real
  # change, not a no-op on a flat curve).
  # Fixture-validity guards: each fitted SD curve varies and is not collapsed
  # to zero, so a swap or reversal is a real change.
  for (k in kinds) {
    expect_gt(stats::sd(log(sdv(k))), 0.02, label = paste(info, k))
    expect_gt(stats::median(sdv(k)), 0.15, label = paste(info, k, "median SD"))
    expect_gt(max(sdv(k)) / min(sdv(k)), 1.3, label = paste(info, k, "SD range"))
  }
  gaps <- numeric(0)
  add <- function(nm, val) gaps[[nm]] <<- abs(val - ref)
  if (length(kinds) == 2L) {
    sw <- list(sdv(kinds[[1L]], co[[2L]]), sdv(kinds[[2L]], co[[1L]]))
    add("swapped_selector_coefs", oracle(sds = sw))
  }
  for (i in seq_along(kinds)) {
    s <- lapply(kinds, sdv)
    s[[i]] <- sb26_reverse(s[[i]])
    add(paste0("reversed_sd_", kinds[[i]]), oracle(sds = s))
    f <- fields[[i]]
    Ks <- lapply(fields, function(g) g$K)
    if (f$kind %in% c("animal", "relmat")) {
      Ks[[i]] <- stats::cov2cor(f$K)
      add(paste0("cov2cor_K_", f$kind), oracle(Ks = Ks))
      Ks[[i]] <- 2 * f$K
      add(paste0("K_scale_x2_", f$kind), oracle(Ks = Ks))
    } else if (f$kind == "phylo") {
      Ks[[i]] <- f$K_raw
      add("raw_vcv_phylo_K", oracle(Ks = Ks))
    }
    if (f$kind != "iid" && f$kind != "iid2") {
      Kp <- f$K
      dimnames(Kp) <- list(f$levels, f$levels)   # read rows by position
      Ks[[i]] <- Kp
      add(paste0("K_read_by_position_", f$kind), oracle(Ks = Ks))
    }
  }
  for (nm in names(gaps)) {
    expect_gt(gaps[[nm]], gap, label = paste(info, nm))
  }
  if (nzchar(Sys.getenv("B29B_SHOW_GAPS"))) {
    cat(sprintf("GAP %s | ll-ref %.2e | min gap %.3f (%s)\n", info, ll - ref,
                min(gaps), names(gaps)[[which.min(gaps)]]))
  }
  invisible(list(ref = ref, ll = ll, gaps = gaps))
}
