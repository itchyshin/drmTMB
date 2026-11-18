# Batch 31 (group no) companion for the native animal rows
#   poisson  animal_numeric_slope  A_covariance, Ainv_precision
#   nbinom2  animal_numeric_slope  Ainv_precision, pedigree
#   gamma    animal_intercept      pedigree
#   gamma    animal_numeric_slope  pedigree
# Slope shape: `animal(1 + x | id, <provider>)`, two independent fields (rho
# fixed at 0), each with its own SD formula (selectors w0 / w1). Intercept
# shape (Gamma): `animal(1 | id, pedigree = pedigree)` with `sd(id, level =
# "animal") ~ w0`.
#
# Ledger deficiency addressed: no independent oracle and no emulated-bug
# sensitivity on these provider routes. A base-R dense Laplace marginal
# (helper-sb26-oracle.R) is evaluated at the fitted parameters with SD vectors
# built by hand from the fitted coefficients; the relationship matrix is the
# Henderson tabular A of an inbred pedigree (diag(A) up to about 1.7), supplied
# in reverse row order relative to the data factor levels. Tolerance 1e-4
# absolute on logLik; every emulated bug (swapped coefficient sets, reversed
# SD, flipped selector, K by position, K x 2, cov2cor(K)) must move the oracle
# by more than 0.1. No calibration, coverage or parity claim.

b31no_animal_case <- function(family, provider, shape, seed, per_animal = 12L) {
  set.seed(seed)
  field <- b29b_make_field("animal")
  expect_gt(max(diag(field$K)), 1.05)
  lev <- field$levels
  G <- length(lev)
  z0 <- field$zlev
  z1 <- b31no_selector(lev)
  a0 <- c(log(1.1), 0.9)
  a1 <- c(log(0.5), -0.9)
  L <- t(chol(field$K[lev, lev]))
  b0 <- stats::setNames(drop(L %*% stats::rnorm(G)) * exp(a0[[1L]] + a0[[2L]] * z0[lev]), lev)
  b1 <- stats::setNames(drop(L %*% stats::rnorm(G)) * exp(a1[[1L]] + a1[[2L]] * z1[lev]), lev)
  n <- G * per_animal
  chr <- sample(rep(lev, length.out = n))
  x <- stats::rnorm(n, 0.2, 1)
  eta <- 0.3 + 0.2 * x + b0[chr] + if (shape == "Ix") x * b1[chr] else 0
  sig <- 0.45
  y <- switch(family,
    poisson = stats::rpois(n, exp(eta)),
    nbinom2 = stats::rnbinom(n, size = 1 / sig^2, mu = exp(eta)),
    gamma = stats::rgamma(n, shape = 1 / sig^2, scale = exp(eta) * sig^2))
  dat <- data.frame(y = y, x = x, id = factor(chr, levels = lev),
                    w0 = unname(z0[chr]), w1 = unname(z1[chr]))
  A <- field$K
  Ainv <- solve(A)
  dimnames(Ainv) <- dimnames(A)
  pedigree <- field$pedigree
  prov <- switch(provider, A = "A = A", Ainv = "Ainv = Ainv",
                 pedigree = "pedigree = pedigree")
  lhs <- if (shape == "Ix") "1 + x" else "1"
  mu <- stats::as.formula(sprintf("y ~ x + animal(%s | id, %s)", lhs, prov))
  environment(mu) <- environment()
  if (shape == "Ix") {
    s0 <- stats::as.formula(
      'sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ w0')
    s1 <- stats::as.formula('sd(id, level = "animal", dpar = "mu", coef = "x") ~ w1')
    sds <- list(s0, s1)
    k0 <- 'sd_animal(id, dpar = "mu", coef = "(Intercept)")'
    k1 <- 'sd_animal(id, dpar = "mu", coef = "x")'
  } else {
    sds <- list(stats::as.formula('sd(id, level = "animal") ~ w0'))
    k0 <- "sd_animal(id)"
  }
  form <- do.call(bf, c(list(mu), if (family != "poisson") list(sigma ~ 1), sds))
  fam <- switch(family, poisson = stats::poisson(), nbinom2 = nbinom2(),
                gamma = stats::Gamma(link = "log"))
  fit <- drmTMB(form, family = fam, data = dat, control = drm_control(se = FALSE))
  info <- paste(family, provider, shape)
  co0 <- coef(fit, k0)
  expect_named(co0, c("(Intercept)", "w0"))
  beta <- unname(coef(fit, "mu"))
  eta_fixed <- beta[[1L]] + beta[[2L]] * dat$x
  size_or_shape <- if (family == "poisson") NA else
    1 / exp(unname(coef(fit, "sigma")[[1L]]))^2
  deriv <- switch(family,
    poisson = sb26_deriv_poisson(dat$y),
    nbinom2 = sb26_deriv_nb2(dat$y, size_or_shape),
    gamma = sb26_deriv_gamma(dat$y, size_or_shape))
  terms <- list(b31no_term(field, dat, "id", 1, co0, z0, "intercept"))
  if (shape == "Ix") {
    co1 <- coef(fit, k1)
    expect_named(co1, c("(Intercept)", "w1"))
    terms[[2L]] <- b31no_term(field, dat, "id", dat$x, co1, z1, "slope")
  }
  b31no_check(fit, deriv, eta_fixed, terms, info)
}

test_that("Poisson animal slope shape, A provider: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_animal_case("poisson", "A", "Ix", 31201L)
})
test_that("Poisson animal slope shape, Ainv provider: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_animal_case("poisson", "Ainv", "Ix", 31202L)
})
test_that("NB2 animal slope shape, Ainv provider: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_animal_case("nbinom2", "Ainv", "Ix", 31203L)
})
test_that("NB2 animal slope shape, pedigree provider: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_animal_case("nbinom2", "pedigree", "Ix", 31204L)
})
test_that("Gamma animal intercept, pedigree provider: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_animal_case("gamma", "pedigree", "I", 31205L)
})
test_that("Gamma animal slope shape, pedigree provider: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_animal_case("gamma", "pedigree", "Ix", 31206L)
})
