# b26 companion for evidence id native-gamma-ordinary-sd-beside-structured-20261101d
# (test-gamma-ordinary-sd-beside-structured.R).
#
# Ledger deficiency addressed: that test regresses only the ordinary SD
# (sd(g) ~ zg); the structured field has a constant SD, so the three
# provider-pair rows iid+animal(A), iid+animal(Ainv) and iid+phylo are only
# partly supported. Native admits a predictor-dependent SD on BOTH fields (see
# test-gamma-iid-structured-sd-regression.R), so here each pair is fitted with
#   y ~ x + (1 | g) + <provider>(1 | p), sigma ~ 1,
#   sd(g) ~ zg, sd(p, level = <provider level>) ~ zp
# (Gamma, log link) and compared with an independent dense Laplace oracle
# (helper-sb26-oracle.R) at the fitted parameters, tolerance 1e-4 on logLik.
# Kernels: A by the Henderson tabular method from an inbred pedigree (Ainv is
# its inverse), phylogenetic K = ape::vcv / tree height. Emulated bugs must
# move the oracle by more than 0.1: the two SD selectors swapped (each field
# given the other's coefficient set), reversed per-level SD vectors, cov2cor(A)
# or the unstandardised vcv, and K read by position. No calibration, coverage
# or parity claim.

sb26_gam_row <- function(provider, seed, n_g = 24L, reps = 2L, shape = 6) {
  set.seed(seed)
  tree <- NULL
  if (provider == "phylo") {
    p_ids <- sprintf("p%02d", 1:20)
    tree <- ape::rcoal(length(p_ids))
    tree$tip.label <- sample(p_ids)
    K <- sb26_phylo_K(tree, p_ids)
    alt <- ape::vcv(tree)[p_ids, p_ids]
    expect_gt(max(diag(alt)), 1.05)
  } else {
    K <- sb26_tabular_A(sb26_inbred_pedigree(3L))
    p_ids <- rownames(K)
    alt <- stats::cov2cor(K)
  }
  n_p <- length(p_ids)
  g_ids <- sprintf("g%02d", seq_len(n_g))
  zg <- stats::setNames(sample(rep(c(-1, 1), length.out = n_g)), g_ids)
  zp <- stats::setNames(sample(rep(c(-1, 1), length.out = n_p)), p_ids)
  b_g <- exp(log(0.35) + 0.8 * zg) * stats::rnorm(n_g)
  b_p <- exp(log(0.4) - 0.8 * zp) * drop(t(chol(K)) %*% stats::rnorm(n_p))
  design <- expand.grid(rep = seq_len(reps), gi = seq_len(n_g), pi = seq_len(n_p))
  d <- data.frame(
    x = stats::rnorm(nrow(design)),
    g = factor(g_ids[design$gi], levels = g_ids),
    p = factor(p_ids[design$pi], levels = sort(p_ids, decreasing = TRUE))
  )
  d$zg <- unname(zg[as.character(d$g)])
  d$zp <- unname(zp[as.character(d$p)])
  mu <- exp(0.2 + 0.3 * d$x + b_g[as.character(d$g)] + b_p[as.character(d$p)])
  d$y <- stats::rgamma(nrow(d), shape = shape, scale = mu / shape)
  expect_false(identical(levels(d$p), p_ids))

  sup <- sample(p_ids)
  Ksup <- K[sup, sup]
  Ainv_sup <- solve(Ksup)
  dimnames(Ainv_sup) <- dimnames(Ksup)
  rhs <- switch(provider, animal_A = "animal(1 | p, A = Ksup)",
                animal_Ainv = "animal(1 | p, Ainv = Ainv_sup)",
                phylo = "phylo(1 | p, tree = tree)")
  level <- if (provider == "phylo") "phylogenetic" else "animal"
  f <- stats::as.formula(paste("y ~ x + (1 | g) +", rhs), env = environment())
  s_g <- stats::as.formula("sd(g) ~ zg", env = environment())
  s_p <- stats::as.formula(sprintf('sd(p, level = "%s") ~ zp', level),
                           env = environment())
  fit <- drmTMB(bf(f, sigma ~ 1, s_g, s_p), family = Gamma(link = "log"),
                data = d, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L, info = provider)

  dpar_p <- if (provider == "phylo") "sd_phylo(p)" else "sd_animal(p)"
  expect_setequal(setdiff(names(coef(fit)), c("mu", "sigma")), c("sd(g)", dpar_p))
  ag <- coef(fit, "sd(g)")
  ap <- coef(fit, dpar_p)
  expect_named(ag, c("(Intercept)", "zg"))
  expect_named(ap, c("(Intercept)", "zp"))
  lg <- levels(d$g)
  lp <- levels(d$p)
  curve <- function(k, z, lev) {
    s <- exp(k[[1L]] + k[[2L]] * z[lev])
    names(s) <- lev
    s
  }
  tg <- curve(ag, zg, lg)
  tp <- curve(ap, zp, lp)
  expect_gt(stats::sd(log(tg)), 0.1)
  expect_gt(stats::sd(log(tp)), 0.1)
  expect_equal(unname(predict(fit, dpar = "sd(g)")[lg]), unname(tg), tolerance = 1e-8)
  expect_equal(unname(predict(fit, dpar = dpar_p)[lp]), unname(tp), tolerance = 1e-8)

  beta <- coef(fit, "mu")
  eta_fixed <- beta[[1L]] + beta[[2L]] * d$x
  deriv <- sb26_deriv_gamma(d$y, exp(-2 * coef(fit, "sigma")[[1L]]))
  ig <- as.integer(d$g)
  ip <- as.integer(d$p)
  oracle <- function(Kmat, tg, tp) {
    sb26_laplace(deriv, eta_fixed,
                 cbind(sb26_Z(ig, n_g, tg), sb26_Z(ip, n_p, tp)),
                 sb26_blockdiag(diag(n_g), Kmat[lp, lp]))
  }
  ref <- oracle(K, tg, tp)
  expect_lt(abs(as.numeric(logLik(fit)) - ref), 1e-4, label = provider)

  gap <- function(Kmat, tg, tp) abs(oracle(Kmat, tg, tp) - ref)
  # Selectors swapped: each field given the other field's coefficient set.
  expect_gt(gap(K, curve(ap, zg, lg), curve(ag, zp, lp)), 0.1,
            label = paste(provider, "swapped selectors"))
  expect_gt(gap(K, sb26_reverse(tg), sb26_reverse(tp)), 0.1,
            label = paste(provider, "reversed SDs"))
  expect_gt(gap(alt, tg, tp), 0.1, label = paste(provider, "wrong K scale"))
  K_pos <- K
  dimnames(K_pos) <- list(lp, lp)
  expect_gt(gap(K_pos, tg, tp), 0.1, label = paste(provider, "K by position"))
  invisible(fit)
}

test_that("Gamma iid + animal (A and Ainv) with SD regressions on both fields matches an independent oracle", {
  skip_on_cran()
  ref_A <- sb26_gam_row("animal_A", 20261401L)
  ref_Ainv <- sb26_gam_row("animal_Ainv", 20261401L)
  # Same seed and data: the Ainv fit reproduces the A fit.
  expect_equal(as.numeric(logLik(ref_Ainv)), as.numeric(logLik(ref_A)),
               tolerance = 1e-5)
})

test_that("Gamma iid + phylo with SD regressions on both fields matches an independent oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  sb26_gam_row("phylo", 20261402L)
})
