# Batch 31 (group no) companion for the native correlated q2 rows
#   poisson  animal  (A_covariance), spatial (coordinates)
#   nbinom2  phylo   (tree)
#   gamma    relmat  (K_covariance), phylo (tree)
# fitted as `<provider>(1 + x | id, ...)` with one predictor-dependent SD
# formula per coefficient (intercept and slope), log link, unlabelled block
# (the two coefficient fields are independent: rho fixed at 0, the 'fixed'
# layout of these rows; the native labelled form is refused for these routes).
#
# Ledger deficiency addressed: those rows had only simulation/missing-data
# tests with no independent likelihood oracle and no emulated-bug sensitivity.
# Here a base-R dense Laplace marginal (helper-sb26-oracle.R) is evaluated at
# the fitted parameters. Latent fields a, b ~ N(0, K) independent; row r on group g adds sd0[g] a[g] + x_r sd1[g] b[g]. SD vectors are
# built by hand from the fitted coefficients and the fixture selectors (random
# permutation grids, so not palindromic). Kernels are built by hand (Henderson
# A with inbreeding, hand exponential kernels, cov2cor(ape::vcv) for trees,
# tree height 3); the supplied kernel rows are in reverse level order and tree
# tips / coordinates are shuffled, so position-based alignment is detected.
# Agreement tolerance 1e-4 absolute on logLik; every emulated bug (swapped
# coefficient sets, reversed SD vectors, flipped selector, flipped rho, rho = 0,
# K x 2, cov2cor(K), raw vcv, kernel by position) must move the oracle by more
# than 0.1. No calibration, coverage or parity claim.

b31no_q2_case <- function(family, kind, seed, groups_obs = 18L) {
  set.seed(seed)
  field <- b29b_make_field(kind)
  if (kind == "relmat") field <- b31no_nonunit(field)
  lev <- field$levels
  G <- length(lev)
  z0 <- field$zlev
  z1 <- b31no_selector(lev)
  rho_true <- 0  # unlabelled block: rho fixed at 0 (ledger layout 'fixed')
  a0 <- c(log(0.8), 0.8)
  a1 <- c(log(0.6), -0.8)
  f0 <- drop(t(chol(field$K[lev, lev])) %*% stats::rnorm(G))
  f1 <- rho_true * f0 + sqrt(1 - rho_true^2) *
    drop(t(chol(field$K[lev, lev])) %*% stats::rnorm(G))
  b0 <- stats::setNames(f0 * exp(a0[[1L]] + a0[[2L]] * z0[lev]), lev)
  b1 <- stats::setNames(f1 * exp(a1[[1L]] + a1[[2L]] * z1[lev]), lev)
  n <- G * groups_obs
  chr <- sample(rep(lev, length.out = n))
  x <- stats::rnorm(n, 0.3, 1)
  eta <- 0.3 + 0.2 * x + b0[chr] + x * b1[chr]
  sig <- 0.45
  y <- switch(family,
    poisson = stats::rpois(n, exp(eta)),
    nbinom2 = stats::rnbinom(n, size = 1 / sig^2, mu = exp(eta)),
    gamma = stats::rgamma(n, shape = 1 / sig^2, scale = exp(eta) * sig^2))
  dat <- data.frame(y = y, x = x, id = factor(chr, levels = lev),
                    w0 = unname(z0[chr]), w1 = unname(z1[chr]))
  obj <- b31no_provider_objects(field)
  K <- obj$K
  A <- obj$A
  tree <- obj$tree
  coords <- obj$coords
  if (kind == "phylo") b31no_check_phylo_cov(tree)
  term <- switch(kind,
    animal = "animal(1 + x | id, A = A)",
    relmat = "relmat(1 + x | id, K = K)",
    phylo = "phylo(1 + x | id, tree = tree)",
    spatial = "spatial(1 + x | id, coords = coords)")
  level <- c(animal = "animal", relmat = "relmat", phylo = "phylogenetic",
             spatial = "spatial")[[kind]]
  pre <- c(animal = "sd_animal", relmat = "sd_relmat", phylo = "sd_phylo",
           spatial = "sd_spatial")[[kind]]
  mu <- stats::as.formula(paste("y ~ x +", term))
  environment(mu) <- environment()
  s0 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "(Intercept)") ~ w0', level))
  s1 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "x") ~ w1', level))
  form <- if (family == "poisson") bf(mu, s0, s1) else bf(mu, sigma ~ 1, s0, s1)
  fam <- switch(family, poisson = stats::poisson(), nbinom2 = nbinom2(),
                gamma = stats::Gamma(link = "log"))
  fit <- drmTMB(form, family = fam, data = dat, control = drm_control(se = FALSE))
  info <- paste(family, kind, "q2")
  co0 <- coef(fit, sprintf('%s(id, dpar = "mu", coef = "(Intercept)")', pre))
  co1 <- coef(fit, sprintf('%s(id, dpar = "mu", coef = "x")', pre))
  expect_named(co0, c("(Intercept)", "w0"))
  expect_named(co1, c("(Intercept)", "w1"))
  expect_length(fit$corpars, 0L)   # no fitted correlation: rho fixed at 0
  beta <- unname(coef(fit, "mu"))
  eta_fixed <- beta[[1L]] + beta[[2L]] * dat$x
  deriv <- switch(family,
    poisson = sb26_deriv_poisson(dat$y),
    nbinom2 = sb26_deriv_nb2(dat$y, 1 / exp(unname(coef(fit, "sigma")[[1L]]))^2),
    gamma = sb26_deriv_gamma(dat$y, 1 / exp(unname(coef(fit, "sigma")[[1L]]))^2))
  terms <- list(
    b31no_term(field, dat, "id", 1, co0, z0, "intercept"),
    b31no_term(field, dat, "id", dat$x, co1, z1, "slope"))
  b31no_check(fit, deriv, eta_fixed, terms, info)
}

test_that("Poisson animal (A) correlated q2: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_q2_case("poisson", "animal", 31101L)
})
test_that("Poisson spatial correlated q2: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_q2_case("poisson", "spatial", 31102L)
})
test_that("NB2 phylo correlated q2: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_q2_case("nbinom2", "phylo", 31103L)
})
test_that("Gamma relmat (K) correlated q2: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_q2_case("gamma", "relmat", 31104L)
})
test_that("Gamma phylo correlated q2: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_q2_case("gamma", "phylo", 31105L)
})
