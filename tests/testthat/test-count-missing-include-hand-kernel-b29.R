# Batch 29 (strengthen-a) companion for the native count missing-include ids
#   native-count-structured-sd-missing-include-20261102r
#     (test-count-structured-sd-missing-include.R): phylo and spatial
#     structured-intercept rows, Poisson and NB2;
#   native-count-iid-slope-sd-missing-include-20261102r
#     (test-count-iid-slope-sd-missing-include.R): iid-plus-phylo intercept
#     rows and the phylo and spatial structured-slope rows, Poisson and NB2.
#
# Reviewer deficiency closed: in those tests the phylo and spatial covariance
# used by the oracle was built by drmTMB:::drm_phylo_tip_covariance and
# drmTMB:::drm_spatial_coords_precision, the helpers under test, and was never
# compared with an independent construction. Here:
#   * phylo: Sigma = cov2cor(ape::vcv(tree)) on a tree of height 3 (so the
#     correlation and covariance forms differ), and the package tip covariance
#     is compared with it (b26sa_check_phylo_cov);
#   * spatial: Sigma = exp(-d / median positive distance) + 1e-6 I rebuilt by
#     hand from irregular, shuffled coordinates, and the package implied
#     covariance solve(precision) is compared with it by site name.
# The oracle is a dense Laplace marginal in base R (sb26_laplace) scored on the
# observed rows only; empty groups keep their latent column, so they keep the
# prior term. SD surfaces are exp(a0 + a1 z) from the fitted sd() coefficients,
# by hand. Agreement tolerance 1e-5 absolute on logLik (about 1e-8 relative;
# a first run at n_id = 24 measured 2e-6 on one NB2 fit, from the engine's inner
# Newton tolerance, while the bug gaps are at least 0.5). Emulated bugs must
# move the oracle by more than b29_cmi_gap_floor (declared before the first
# run, not tuned): NA rows scored as observed zeros, reversed SD vector, the
# kernel read by row position instead of name, a wrong kernel scale (raw vcv
# for phylo, 2 K for spatial), and for the iid shape the two SD vectors
# swapped. Scope: likelihood agreement at fitted parameters on observed rows.
# No calibration, coverage or parity claim.

b29_cmi_gap_floor <- 0.5

b29_cmi_fixture <- function(kind, family, shape, seed, n_id = 40L, n_each = 12L,
                            n_site = 12L, na_groups = integer(0)) {
  set.seed(seed)
  lev <- sprintf("id%02d", seq_len(n_id))
  tree <- coords <- NULL
  if (identical(kind, "phylo")) {
    tree <- ape::rcoal(n_id)
    tree$edge.length <- 3 * tree$edge.length          # height != 1
    tree$tip.label <- sample(lev)
    K <- stats::cov2cor(ape::vcv(tree))[lev, lev]
    K_raw <- ape::vcv(tree)[lev, lev]
    K_positional <- stats::cov2cor(ape::vcv(tree))   # tip order, not name order
    dimnames(K_positional) <- list(lev, lev)
    K_scaled <- K_raw
  } else {
    coords_nat <- data.frame(east = stats::runif(n_id, 0, 3),
                             north = stats::runif(n_id, 0, 2), row.names = lev)
    K <- sb26_spatial_kernel(coords_nat, lev)
    coords <- coords_nat[sample(lev), , drop = FALSE]
    K_positional <- sb26_spatial_kernel(
      data.frame(east = coords$east, north = coords$north, row.names = lev), lev
    )
    K_scaled <- 2 * K
  }
  z_group <- stats::setNames(seq(-1, 1, length.out = n_id)[sample.int(n_id)], lev)
  tau <- exp(log(0.8) + 0.9 * z_group)
  u <- stats::setNames(drop(t(chol(K)) %*% stats::rnorm(n_id)), lev)
  data_levels <- rev(lev)
  id <- factor(rep(data_levels, each = n_each), levels = data_levels)
  n <- length(id)
  x <- stats::rnorm(n)
  site_levels <- sprintf("s%02d", seq_len(n_site))
  site <- factor(site_levels[c(seq_len(n_site), sample.int(n_site, n - n_site, TRUE))],
                 levels = site_levels)
  z_site <- stats::setNames(seq(-1, 1, length.out = n_site)[sample.int(n_site)],
                            site_levels)
  v <- stats::setNames(stats::rnorm(n_site) * exp(log(0.8) + 1.0 * z_site), site_levels)
  struct <- tau[as.character(id)] * u[as.character(id)]
  eta <- 0.3 + 0.3 * x + switch(shape,
    slope = x * struct, iid = struct + v[as.character(site)], intercept = struct)
  y <- if (identical(family, "poisson")) stats::rpois(n, exp(eta)) else
    stats::rnbinom(n, size = 1 / 0.4^2, mu = exp(eta))
  dat <- data.frame(y = y, x = x, id = id, site = site,
                    z = as.numeric(z_group[as.character(id)]),
                    z_site = as.numeric(z_site[as.character(site)]))
  dat$y[seq_len(n) %% 5L == 2L] <- NA
  for (g in na_groups) dat$y[as.character(dat$id) == lev[g]] <- NA
  list(data = dat, kind = kind, family = family, shape = shape, lev = lev,
       K = K, K_positional = K_positional, K_scaled = K_scaled, tree = tree,
       coords = coords, z_group = z_group, z_site = z_site,
       site_levels = site_levels)
}

b29_cmi_fit <- function(fx) {
  tree <- fx$tree
  coords <- fx$coords
  slope <- identical(fx$shape, "slope")
  term <- if (identical(fx$kind, "phylo")) {
    sprintf("phylo(%s | id, tree = tree)", if (slope) "0 + x" else "1")
  } else {
    sprintf("spatial(%s | id, coords = coords)", if (slope) "0 + x" else "1")
  }
  level <- if (identical(fx$kind, "phylo")) "phylogenetic" else "spatial"
  iid <- identical(fx$shape, "iid")
  parts <- paste("y ~ x +", term, if (iid) "+ (1 | site)")
  parts <- c(parts, sprintf('sd(id, level = "%s") ~ z', level))
  if (iid) parts <- c(parts, "sd(site) ~ z_site")
  if (identical(fx$family, "nbinom2")) parts <- append(parts, "sigma ~ 1", after = 1L)
  f <- eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", "))))
  drmTMB(f, family = if (identical(fx$family, "poisson")) stats::poisson() else nbinom2(),
         data = fx$data, missing = miss_control(response = "include"),
         control = drm_control(se = FALSE))
}

b29_cmi_oracle <- function(fx, fit, K = fx$K, tau = NULL, tau_site = NULL,
                           na_as_zero = FALSE) {
  d <- fx$data
  slope <- identical(fx$shape, "slope")
  iid <- identical(fx$shape, "iid")
  nm <- grep("^sd", names(fit$sdpars), value = TRUE)
  nm_site <- grep("site", nm, value = TRUE)
  nm_struct <- grep("site", nm, value = TRUE, invert = TRUE)
  stopifnot(length(nm_struct) == 1L)
  curve <- function(a, z) unname(exp(a[[1L]] + a[[2L]] * z))
  if (is.null(tau)) tau <- curve(coef(fit, nm_struct), fx$z_group[fx$lev])
  if (iid && is.null(tau_site)) {
    stopifnot(length(nm_site) == 1L)
    tau_site <- curve(coef(fit, nm_site), fx$z_site[fx$site_levels])
  }
  beta <- coef(fit, "mu")
  eta0 <- as.numeric(beta[["(Intercept)"]] + beta[["x"]] * d$x)
  y <- d$y
  keep <- if (na_as_zero) rep(TRUE, nrow(d)) else !is.na(y)
  y[is.na(y)] <- 0
  deriv <- if (identical(fx$family, "poisson")) sb26_deriv_poisson(y[keep]) else
    sb26_deriv_nb2(y[keep], 1 / exp(coef(fit, "sigma")[["(Intercept)"]])^2)
  gi <- match(as.character(d$id), fx$lev)[keep]
  G <- length(fx$lev)
  Z <- sb26_Z(gi, G, tau, if (slope) d$x[keep] else 1)
  Sigma <- K
  if (iid) {
    si <- match(as.character(d$site), fx$site_levels)[keep]
    Z <- cbind(Z, sb26_Z(si, length(fx$site_levels), tau_site))
    Sigma <- sb26_blockdiag(K, diag(length(fx$site_levels)))
  }
  sb26_laplace(deriv, eta0[keep], Z, Sigma)
}

b29_cmi_check <- function(kind, family, shape, seed, na_groups = integer(0)) {
  fx <- b29_cmi_fixture(kind, family, shape, seed, na_groups = na_groups)
  d <- fx$data
  expect_true(anyNA(d$y))
  if (length(na_groups) > 0L) {
    expect_true(all(is.na(d$y[as.character(d$id) %in% fx$lev[na_groups]])))
  } else {
    expect_true(all(tapply(!is.na(d$y), d$id, any)))
  }
  # Independent kernel construction versus the package helpers.
  if (identical(kind, "phylo")) {
    b26sa_check_phylo_cov(fx$tree)
  } else {
    P <- as.matrix(drmTMB:::drm_spatial_coords_precision(
      fx$coords, site = fx$lev, group = "id")$precision)
    rownames(P) <- colnames(P) <- NULL
    expect_equal(unname(solve(P)), unname(fx$K), tolerance = 1e-8)
  }
  fit <- b29_cmi_fit(fx)
  expect_equal(as.integer(fit$opt$convergence), 0L)
  expect_equal(nobs(fit), sum(!is.na(d$y)))
  base <- b29_cmi_oracle(fx, fit)
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - base), 1e-5)

  nm_struct <- grep("^sd", names(fit$sdpars), value = TRUE)
  nm_struct <- grep("site", nm_struct, value = TRUE, invert = TRUE)
  a_struct <- coef(fit, nm_struct)
  tau <- unname(exp(a_struct[[1L]] + a_struct[[2L]] * fx$z_group[fx$lev]))
  expect_gt(stats::sd(log(tau)), 0.2)
  bugs <- list(
    na_as_observed_zero = b29_cmi_oracle(fx, fit, na_as_zero = TRUE),
    reversed_sd = b29_cmi_oracle(fx, fit, tau = rev(tau)),
    kernel_by_position = b29_cmi_oracle(fx, fit, K = fx$K_positional),
    wrong_kernel_scale = b29_cmi_oracle(fx, fit, K = fx$K_scaled)
  )
  if (identical(shape, "iid")) {
    nm_site <- grep("site", grep("^sd", names(fit$sdpars), value = TRUE), value = TRUE)
    a_site <- coef(fit, nm_site)
    ts <- unname(exp(a_site[[1L]] + a_site[[2L]] * fx$z_site[fx$site_levels]))
    bugs$reversed_site_sd <- b29_cmi_oracle(fx, fit, tau_site = rev(ts))
  }
  if (nzchar(Sys.getenv("B29_PRINT"))) print(round(c(sapply(bugs, function(b) abs(ll - b)), logLik_vs_oracle = abs(ll - base)), 6))
  for (nmb in names(bugs)) {
    expect_gt(abs(ll - bugs[[nmb]]), b29_cmi_gap_floor,
              label = paste(kind, family, shape, "gap for", nmb))
  }
  invisible(fit)
}

for (b29_family in c("poisson", "nbinom2")) {
  for (b29_kind in c("phylo", "spatial")) {
    local({
      family <- b29_family
      kind <- b29_kind
      seed <- 2026130000L + 10L * match(kind, c("phylo", "spatial")) +
        match(family, c("poisson", "nbinom2"))
      test_that(sprintf("%s %s structured intercept SD include matches a hand-kernel oracle", family, kind), {
        skip_on_cran()
        skip_if_not_installed("ape")
        b29_cmi_check(kind, family, "intercept", seed)
      })
      test_that(sprintf("%s %s structured intercept SD include with all-NA groups keeps the prior", family, kind), {
        skip_on_cran()
        skip_if_not_installed("ape")
        b29_cmi_check(kind, family, "intercept", seed + 5L, na_groups = c(3L, 17L, 29L))
      })
      test_that(sprintf("%s %s structured slope-only SD include matches a hand-kernel oracle", family, kind), {
        skip_on_cran()
        skip_if_not_installed("ape")
        b29_cmi_check(kind, family, "slope", seed + 8L)
      })
      if (identical(kind, "phylo")) {
        test_that(sprintf("%s phylo plus ordinary intercept SD include matches a hand-kernel oracle", family), {
          skip_on_cran()
          skip_if_not_installed("ape")
          b29_cmi_check(kind, family, "iid", seed + 9L)
        })
      }
    })
  }
}
