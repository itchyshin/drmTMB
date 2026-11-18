# Batch 31 (group no) companion for the native NB2 rows
#   iid_additive_terms (group_factors): crossed independent fields, fitted as
#     (a) (1 | g1) + (1 | g2),  sd(g1) ~ z1, sd(g2) ~ z2
#     (b) (1 | g1) + (0 + x | g2),  sd(g1) ~ z1, sd(g2, coef = "x") ~ z2
#   phylo_interaction_intercept and phylo_interaction_numeric_slope (tree_pair):
#     phylo_interaction(1 | plant:pollinator, tree1, tree2) and the `0 + x`
#     form, sd(pair, level = "phylogenetic_interaction") ~ z_pair.
#
# Ledger deficiency addressed: no independent likelihood oracle with
# emulated-bug sensitivity for these NB2 routes. A base-R dense Laplace
# marginal (helper-sb26-oracle.R) is evaluated at the fitted parameters with
# SD vectors built by hand from the fitted coefficients (non-palindromic random
# selector grids). Pair kernel K = kronecker(cov2cor(vcv(tree2)), cov2cor(
# vcv(tree1))), pair order plant fastest, built with ape::vcv; the package
# tip covariance is compared against it. Trees have different sizes (8 and 4
# tips), height 3, shuffled tip labels; the supplied pair kernel is in reverse
# level order. Tolerance 1e-4 absolute on logLik; every emulated bug (swapped
# coefficient sets, reversed SD, flipped selector, K by position, K x 2, raw
# vcv Kronecker) must move the oracle by more than 0.1. No calibration,
# coverage or parity claim.

test_that("hand densities used across the b31no files agree with brute-force references", {
  skip_on_cran()
  b31no_check_densities()
})

b31no_nb2_iid_case <- function(second, seed) {
  set.seed(seed)
  f1 <- b29b_make_field("iid")
  f2 <- b29b_make_field("iid2")
  n <- 1000L
  x <- stats::rnorm(n)
  c1 <- sample(rep(f1$levels, length.out = n))
  c2 <- sample(rep(f2$levels, length.out = n))
  a1 <- c(log(0.9), 0.9)
  a2 <- c(log(0.7), -0.9)
  u1 <- stats::setNames(stats::rnorm(length(f1$levels)) *
                          exp(a1[[1L]] + a1[[2L]] * f1$zlev[f1$levels]), f1$levels)
  u2 <- stats::setNames(stats::rnorm(length(f2$levels)) *
                          exp(a2[[1L]] + a2[[2L]] * f2$zlev[f2$levels]), f2$levels)
  w2 <- if (second == "slope") x else 1
  eta <- 0.2 + 0.25 * x + u1[c1] + w2 * u2[c2]
  dat <- data.frame(y = stats::rnbinom(n, size = 1 / 0.4^2, mu = exp(eta)), x = x,
                    g1 = factor(c1, levels = f1$levels),
                    g2 = factor(c2, levels = f2$levels),
                    z1 = unname(f1$zlev[c1]), z2 = unname(f2$zlev[c2]))
  form <- if (second == "slope") {
    bf(y ~ x + (1 | g1) + (0 + x | g2), sigma ~ 1, sd(g1) ~ z1,
       sd(g2, coef = "x") ~ z2)
  } else {
    bf(y ~ x + (1 | g1) + (1 | g2), sigma ~ 1, sd(g1) ~ z1, sd(g2) ~ z2)
  }
  fit <- drmTMB(form, family = nbinom2(), data = dat,
                control = drm_control(se = FALSE))
  k2 <- if (second == "slope") 'sd(g2, coef = "x")' else "sd(g2)"
  co1 <- coef(fit, "sd(g1)")
  co2 <- coef(fit, k2)
  expect_named(co1, c("(Intercept)", "z1"))
  expect_named(co2, c("(Intercept)", "z2"))
  beta <- unname(coef(fit, "mu"))
  eta_fixed <- beta[[1L]] + beta[[2L]] * dat$x
  deriv <- sb26_deriv_nb2(dat$y, 1 / exp(unname(coef(fit, "sigma")[[1L]]))^2)
  terms <- list(b31no_term(f1, dat, "g1", 1, co1, f1$zlev, "g1_intercept"),
                b31no_term(f2, dat, "g2", w2, co2, f2$zlev, paste0("g2_", second)))
  b31no_check(fit, deriv, eta_fixed, terms, paste("nb2 iid additive", second))
}

test_that("NB2 iid additive terms (two intercepts): dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_nb2_iid_case("intercept", 31301L)
})
test_that("NB2 iid additive terms (intercept + slope): dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_nb2_iid_case("slope", 31302L)
})

b31no_nb2_pi_case <- function(kind, seed, n_each = 14L) {
  set.seed(seed)
  mk <- function(n, prefix) {
    tr <- ape::rcoal(n)
    tr$edge.length <- 3 * tr$edge.length
    tr$tip.label <- sample(sprintf("%s%02d", prefix, seq_len(n)))
    tr
  }
  tree1 <- mk(8L, "plant_")
  tree2 <- mk(4L, "poll_")
  b31no_check_phylo_cov(tree1)
  b31no_check_phylo_cov(tree2)
  l1 <- sort(tree1$tip.label)
  l2 <- sort(tree2$tip.label)
  grid <- expand.grid(plant = l1, pollinator = l2, KEEP.OUT.ATTRS = FALSE,
                      stringsAsFactors = FALSE)
  grid$pair <- paste(grid$plant, grid$pollinator, sep = ":")
  pairs <- grid$pair
  V1 <- ape::vcv(tree1)[l1, l1]
  V2 <- ape::vcv(tree2)[l2, l2]
  Kc <- kronecker(stats::cov2cor(V2), stats::cov2cor(V1))
  Kr <- kronecker(V2, V1)
  dimnames(Kc) <- dimnames(Kr) <- list(pairs, pairs)
  rv <- rev(pairs)
  field <- list(kind = "phylo", levels = pairs, K = Kc[rv, rv], K_raw = Kr)
  stopifnot(max(diag(Kr)) > 1.05)
  z_pair <- stats::setNames(seq(-1.5, 1.5, length.out = length(pairs))[
    sample.int(length(pairs))], pairs)
  a <- c(log(0.7), 0.7)
  sdv <- exp(a[[1L]] + a[[2L]] * z_pair)
  f <- stats::setNames(drop(t(chol(Kc)) %*% stats::rnorm(length(pairs))) * sdv, pairs)
  rows <- sample(rep(seq_along(pairs), each = n_each))
  dat <- grid[rows, , drop = FALSE]
  rownames(dat) <- NULL
  dat$z_pair <- unname(z_pair[dat$pair])
  dat$x <- stats::rnorm(nrow(dat))
  value <- if (kind == "slope") dat$x else 1
  eta <- 0.8 + 0.3 * dat$x + value * unname(f[dat$pair])
  dat$y <- stats::rnbinom(nrow(dat), mu = exp(eta), size = 1 / 0.3^2)
  part <- if (kind == "slope") "0 + x" else "1"
  form <- eval(parse(text = sprintf(paste0(
    "bf(y ~ x + phylo_interaction(%s | plant:pollinator, tree1 = tree1, ",
    "tree2 = tree2), sigma ~ 1, ",
    "sd(pair, level = \"phylogenetic_interaction\") ~ z_pair)"), part)))
  fit <- drmTMB(form, family = nbinom2(), data = dat,
                control = drm_control(se = FALSE))
  key <- setdiff(names(coef(fit)), c("mu", "sigma"))
  expect_length(key, 1L)
  co <- coef(fit, key)
  expect_named(co, c("(Intercept)", "z_pair"))
  beta <- unname(coef(fit, "mu"))
  eta_fixed <- beta[[1L]] + beta[[2L]] * dat$x
  deriv <- sb26_deriv_nb2(dat$y, 1 / exp(unname(coef(fit, "sigma")[[1L]]))^2)
  terms <- list(b31no_term(field, dat, "pair", value, co, z_pair, "pair"))
  b31no_check(fit, deriv, eta_fixed, terms, paste("nb2 phylo_interaction", kind))
}

test_that("NB2 phylo_interaction intercept: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_nb2_pi_case("intercept", 31303L)
})
test_that("NB2 phylo_interaction slope: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_nb2_pi_case("slope", 31304L)
})
