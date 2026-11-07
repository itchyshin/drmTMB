# Batch 31 (group ja) independent-oracle companion for the live Julia Binomial
# simultaneous ordinary-IID plus structured intercepts, each with its own
# sd() formula. Covers 4 ledger rows (simultaneous_iid_structured):
#   (1 | site) + phylo(1 | species, tree = tree): logit, probit, cloglog
#   (1 | site) + animal(1 | id, pedigree = pedigree): logit
# The existing tests (test-julia-binomial-phylo-iid-sd-bridge.R,
# -animal-iid-nonlogit-sd-bridge.R) compare Julia with native TMB at loose
# tolerances (0.08-0.1 on logLik); there is no independent oracle or
# emulated-bug sensitivity, and their selectors are monotone grids.
#
# Here a base-R dense joint-Newton Laplace oracle (helper-b31ja-oracle.R) with
# eta = X b + S_iid[site] u_site + S_str[g] u_g, u_site ~ N(0, I), u_g ~ N(0, K)
# is evaluated at the Julia estimates. K is cov2cor(ape::vcv(tree)) for the
# tree (tip labels shuffled so tip order differs from the sorted factor levels;
# the package tip covariance is compared with it) and a hand-built Henderson
# tabular A for an inbred pedigree (diag(A) from 1.25 to 1.67). SD vectors are
# built by hand from the fitted coefficients with random, non-palindromic
# selectors. Julia's logLik must agree to 1e-3 absolute; each emulated bug
# (swapped selector coefficient sets, reversed SD vector for each field,
# raw ape::vcv in place of its correlation form (phylo) / K * 2 / K * 1.5, cov2cor(A) for the animal field, K read by
# position, flipped selector slope) must move the oracle by more than 20 times
# that.
# Scope: one fixture per route; no calibration, coverage or broad parity claim.

b31ja_pair_oracle <- function(link, data, beta, a_iid, a_str, w_iid, z_str, K,
                              iid_col = "site", str_col) {
  il <- levels(data[[iid_col]])
  rn <- rownames(K)
  ii <- match(as.character(data[[iid_col]]), il)
  si <- match(as.character(data[[str_col]]), rn)
  s_iid <- exp(a_iid[[1L]] + a_iid[[2L]] * w_iid[il])
  s_str <- exp(a_str[[1L]] + a_str[[2L]] * z_str[rn])
  n <- nrow(data)
  M <- matrix(0, n, length(il) + length(rn))
  M[cbind(seq_len(n), ii)] <- s_iid[ii]
  M[cbind(seq_len(n), length(il) + si)] <- s_str[si]
  Q <- matrix(0, ncol(M), ncol(M))
  diag(Q)[seq_along(il)] <- 1
  Q[length(il) + seq_along(rn), length(il) + seq_along(rn)] <- solve(K)
  b31ja_laplace(link, data$y, beta[[1L]] + beta[[2L]] * data$x, M, Q)
}

b31ja_pair_fixture <- function(kind, link, seed) {
  set.seed(seed)
  if (kind == "phylo") {
    n_str <- 24L
    tree <- ape::rcoal(n_str)
    tree$edge.length <- 3 * tree$edge.length
    tree$tip.label <- sample(sprintf("sp%02d", seq_len(n_str)))
    lev <- sort(tree$tip.label)
    K_raw <- ape::vcv(tree)[lev, lev]
    K <- stats::cov2cor(K_raw)[rev(lev), rev(lev)]  # matrix order != levels
    extra <- list(tree = tree, K_raw = K_raw)
    n_iid <- 36L
    reps <- 2L
  } else {
    an <- b31ja_inbred_animals(12L)
    K <- an$A
    lev <- sort(rownames(K))
    n_str <- length(lev)
    extra <- list(pedigree = an$pedigree)
    n_iid <- 30L
    reps <- 2L
  }
  iid_lev <- sprintf("site%02d", seq_len(n_iid))
  w_iid <- stats::setNames(b31ja_selector(n_iid), iid_lev)
  z_str <- stats::setNames(b31ja_selector(n_str), lev)
  grid <- expand.grid(i = seq_len(n_iid), g = seq_len(n_str), r = seq_len(reps))
  data <- data.frame(
    x = stats::rnorm(nrow(grid)),
    site = factor(iid_lev[grid$i], levels = iid_lev),
    str = factor(lev[grid$g], levels = lev)
  )
  data$w <- w_iid[as.character(data$site)]
  data$z <- z_str[as.character(data$str)]
  a_iid <- c(-0.6, 0.9)
  a_str <- c(-0.4, -0.8)
  u_i <- stats::rnorm(n_iid) * exp(a_iid[[1L]] + a_iid[[2L]] * w_iid)
  Ks <- K[lev, lev]
  u_g <- drop(t(chol(Ks)) %*% stats::rnorm(n_str)) *
    exp(a_str[[1L]] + a_str[[2L]] * z_str)
  names(u_g) <- lev
  eta <- -0.15 + 0.25 * data$x + u_i[as.character(data$site)] +
    u_g[as.character(data$str)]
  p <- switch(link, logit = stats::plogis(eta), probit = stats::pnorm(eta),
              cloglog = -expm1(-exp(eta)))
  data$y <- stats::rbinom(nrow(data), 1L, p)
  c(list(data = data, K = K, w_iid = w_iid, z_str = z_str, kind = kind), extra)
}

b31ja_pair_check <- function(kind, link, seed, agreement_tol = 1e-3) {
  tag <- paste("iid +", kind, link)
  fx <- b31ja_pair_fixture(kind, link, seed)
  data <- fx$data
  K <- fx$K
  if (kind == "phylo") {
    names(data)[names(data) == "str"] <- "species"
    tree <- fx$tree
    fml <- bf(y ~ x + (1 | site) + phylo(1 | species, tree = tree),
              sd(site) ~ w,
              sd(species, level = "phylogenetic") ~ z)
    str_col <- "species"
    str_key <- "sd_phylo(species)"
    # The package tip covariance is the correlation form of ape::vcv(tree).
    Kpkg <- drmTMB:::drm_phylo_tip_covariance(tree)
    if (!is.null(rownames(Kpkg))) Kpkg <- Kpkg[rownames(K), colnames(K)]
    expect_equal(unname(Kpkg), unname(K), tolerance = 1e-8,
                 label = "package tip covariance vs cov2cor(ape::vcv)")
  } else {
    names(data)[names(data) == "str"] <- "id"
    pedigree <- fx$pedigree
    fml <- bf(y ~ x + animal(1 | id, pedigree = pedigree) + (1 | site),
              sd(id, level = "animal") ~ z,
              sd(site) ~ w)
    str_col <- "id"
    str_key <- "sd_animal(id)"
  }
  fit <- drmTMB(fml, family = stats::binomial(link = link), data = data,
                engine = "julia")
  expect_identical(fit$opt$convergence, 0L, info = tag)
  beta <- unname(coef(fit, dpar = "mu"))
  a_iid <- coef(fit, dpar = "sd(site)")
  a_str <- coef(fit, dpar = str_key)
  expect_identical(names(a_iid), c("(Intercept)", "w"))
  expect_identical(names(a_str), c("(Intercept)", "z"))
  a_iid <- unname(a_iid)
  a_str <- unname(a_str)
  ll <- as.numeric(logLik(fit))
  oracle <- function(...) {
    args <- list(link = link, data = data, beta = beta, a_iid = a_iid,
                 a_str = a_str, w_iid = fx$w_iid, z_str = fx$z_str, K = K,
                 str_col = str_col)
    over <- list(...)
    args[names(over)] <- over
    do.call(b31ja_pair_oracle, args)
  }
  base <- oracle()
  expect_lt(abs(ll - base), agreement_tol, label = paste(tag, "agreement"))
  rn <- rownames(K)
  K_pos <- K
  dimnames(K_pos) <- list(sort(rn), sort(rn))
  rev_named <- function(v) stats::setNames(rev(v), names(v))
  gaps <- c(
    swapped_coef_sets = oracle(a_iid = a_str, a_str = a_iid),
    iid_slope_sign = oracle(a_iid = c(a_iid[[1L]], -a_iid[[2L]])),
    structured_slope_sign = oracle(a_str = c(a_str[[1L]], -a_str[[2L]])),
    reversed_iid_sd_vector = oracle(w_iid = rev_named(fx$w_iid)),
    reversed_structured_sd_vector = oracle(z_str = rev_named(fx$z_str)),
    K_scale_2 = oracle(K = 2 * K),
    K_scale_1.5 = oracle(K = 1.5 * K),
    K_read_by_position = oracle(K = K_pos)
  )
  if (kind == "phylo") {
    # Raw vcv (branch-length scale) in place of the correlation form.
    gaps[["K_raw_vcv"]] <- oracle(K = fx$K_raw[rn, rn])
  } else {
    expect_gt(diff(range(diag(K))), 0.3)
    gaps[["cov2cor_A"]] <- oracle(K = stats::cov2cor(K))
  }
  gaps <- gaps - base
  b31ja_expect_gaps(gaps, agreement_tol, tag)
  b31ja_report(tag, ll, base, gaps)
  invisible(list(ll = ll, base = base, min_gap = min(abs(gaps))))
}

test_that("Julia Binomial simultaneous IID + phylo (3 links) and IID + animal pedigree (logit) match a dense Laplace oracle and every emulated bug moves it far", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  b31ja_expect_link_terms()
  links <- c("logit", "probit", "cloglog")
  for (i in seq_along(links)) {
    b31ja_pair_check("phylo", links[[i]], seed = 20261150L + i)
  }
  b31ja_pair_check("animal", "logit", seed = 20261160L)
})
