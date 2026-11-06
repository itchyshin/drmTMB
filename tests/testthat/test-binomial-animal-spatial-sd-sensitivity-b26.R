# b26 companion for evidence id binomial-batch4-sd-20261101
# (test-binomial-batch4-sd-regression.R): probit and cloglog
#   animal(1 | id, A | Ainv | pedigree) + spatial(1 | site, coords)
# each with its own predictor-dependent SD.
#
# Ledger deficiencies addressed: the spatial covariance there came from
# solve(drmTMB:::drm_spatial_coords_precision(...)), the helper under test, and
# there was no emulated-bug sensitivity check. Here:
#   * the spatial kernel is hand-built from dist(coords): exp(-d / median
#     positive distance) + 1e-6 I, and used both to simulate and in the oracle;
#   * the additive relationship matrix is built by the Henderson tabular method
#     in helper-sb26-oracle.R from an inbred pedigree (diag(A) = 1.25);
#   * the dense Laplace marginal (base R, observed information) is evaluated at
#     the fitted parameters, tolerance 1e-4 absolute on logLik;
#   * emulated bugs must move the oracle by more than 0.1: the two SD selectors
#     swapped (each field given the other field's coefficient set), reversed
#     per-level SD vectors, cov2cor(A), and A or the coordinates read by
#     position instead of by name.
# No calibration, coverage or parity claim.

sb26_bin_fixture <- function(link, seed, n_family = 6L, n_site = 24L,
                             n_per_animal = 22L) {
  set.seed(seed)
  pedigree <- sb26_inbred_pedigree(n_family)
  A <- sb26_tabular_A(pedigree)
  animals <- rownames(A)
  n_animal <- length(animals)
  sites <- sprintf("s%02d", seq_len(n_site))
  coords_nat <- data.frame(east = stats::runif(n_site, 0, 3),
                           north = stats::runif(n_site, 0, 2), row.names = sites)
  Ks <- sb26_spatial_kernel(coords_nat, sites)
  z_animal <- stats::setNames(sample(rep(c(-1, 1), length.out = n_animal)), animals)
  z_site <- stats::setNames(sample(rep(c(-1, 1), length.out = n_site)), sites)
  alpha_animal <- c(log(0.8), 0.6)
  alpha_site <- c(log(0.7), -0.6)
  b_animal <- exp(alpha_animal[[1L]] + alpha_animal[[2L]] * z_animal) *
    drop(t(chol(A)) %*% stats::rnorm(n_animal))
  b_site <- exp(alpha_site[[1L]] + alpha_site[[2L]] * z_site) *
    drop(t(chol(Ks)) %*% stats::rnorm(n_site))
  animal <- rep(animals, each = n_per_animal)
  site <- sample(sites, length(animal), replace = TRUE)
  x <- stats::rnorm(length(animal))
  eta <- -0.1 + 0.3 * x + b_animal[animal] + b_site[site]
  y <- stats::rbinom(length(eta), 1L, stats::make.link(link)$linkinv(eta))
  d <- data.frame(
    y = y, x = x,
    animal_id = factor(animal, levels = sort(animals)),
    site = factor(site, levels = rev(sites)),
    z_animal = unname(z_animal[animal]), z_site = unname(z_site[site])
  )
  list(data = d, pedigree = pedigree, A = A, Ainv = solve(A),
       coords = coords_nat[sample(sites), , drop = FALSE], Ks = Ks,
       z_animal = z_animal, z_site = z_site)
}

sb26_bin_fit <- function(fx, link, provider) {
  coords <- fx$coords
  A <- fx$A
  Ainv <- fx$Ainv
  pedigree <- fx$pedigree
  rhs <- switch(
    provider,
    A = quote(animal(1 | animal_id, A = A)),
    Ainv = quote(animal(1 | animal_id, Ainv = Ainv)),
    pedigree = quote(animal(1 | animal_id, pedigree = pedigree))
  )
  mean_formula <- stats::as.formula(
    bquote(y ~ x + .(rhs) + spatial(1 | site, coords = coords)),
    env = environment()
  )
  drmTMB(
    bf(mean_formula,
       sd(animal_id, level = "animal") ~ z_animal,
       sd(site, level = "spatial") ~ z_site),
    family = stats::binomial(link = link), data = fx$data,
    control = drm_control(se = FALSE)
  )
}

sb26_bin_check <- function(fit, fx, link, info) {
  d <- fx$data
  expect_identical(fit$opt$convergence, 0L, info = info)
  la <- levels(d$animal_id)
  ls <- levels(d$site)
  ka <- coef(fit, "sd_animal(animal_id)")
  ks <- coef(fit, "sd_spatial(site)")
  expect_named(ka, c("(Intercept)", "z_animal"))
  expect_named(ks, c("(Intercept)", "z_site"))
  curve <- function(k, z, lev) {
    s <- exp(k[[1L]] + k[[2L]] * z[lev])
    names(s) <- lev
    s
  }
  sa <- curve(ka, fx$z_animal, la)
  ss <- curve(ks, fx$z_site, ls)
  expect_gt(stats::sd(log(sa)), 0.05)
  expect_gt(stats::sd(log(ss)), 0.05)
  expect_equal(unname(predict(fit, dpar = "sd_animal(animal_id)")[la]),
               unname(sa), tolerance = 1e-8, info = info)
  expect_equal(unname(predict(fit, dpar = "sd_spatial(site)")[ls]),
               unname(ss), tolerance = 1e-8, info = info)

  mu <- coef(fit, "mu")
  eta_fixed <- mu[[1L]] + mu[[2L]] * d$x
  ia <- as.integer(d$animal_id)
  is <- as.integer(d$site)
  deriv <- sb26_deriv_binary(d$y, link)
  oracle <- function(A, Ks, sa, ss) {
    sb26_laplace(deriv, eta_fixed,
                 cbind(sb26_Z(ia, length(la), sa), sb26_Z(is, length(ls), ss)),
                 sb26_blockdiag(A[la, la], Ks[ls, ls]))
  }
  ref <- oracle(fx$A, fx$Ks, sa, ss)
  expect_lt(abs(as.numeric(logLik(fit)) - ref), 1e-4, label = info)

  # Emulated bugs.
  sa_swapped <- curve(ks, fx$z_animal, la)  # animal given the spatial coefficients
  ss_swapped <- curve(ka, fx$z_site, ls)
  expect_gt(abs(oracle(fx$A, fx$Ks, sa_swapped, ss_swapped) - ref), 0.1)
  expect_gt(abs(oracle(fx$A, fx$Ks, sb26_reverse(sa), sb26_reverse(ss)) - ref), 0.1)
  expect_gt(abs(oracle(stats::cov2cor(fx$A), fx$Ks, sa, ss) - ref), 0.1)
  A_pos <- fx$A
  dimnames(A_pos) <- list(la, la)
  expect_gt(abs(oracle(A_pos, fx$Ks, sa, ss) - ref), 0.1)
  K_pos <- sb26_spatial_kernel(
    data.frame(east = fx$coords$east, north = fx$coords$north, row.names = ls), ls
  )
  expect_gt(abs(oracle(fx$A, K_pos, sa, ss) - ref), 0.1)
  invisible(ref)
}

test_that("Binomial probit animal (A, Ainv, pedigree) plus spatial SDs match an independent dense Laplace oracle with sensitivity", {
  skip_on_cran()
  fx <- sb26_bin_fixture("probit", 20261231L)
  expect_false(identical(levels(fx$data$animal_id), rownames(fx$A)))
  refs <- vapply(c("A", "Ainv", "pedigree"), function(p) {
    fit <- sb26_bin_fit(fx, "probit", p)
    sb26_bin_check(fit, fx, "probit", paste("probit", p))
  }, numeric(1L))
  # Ainv and pedigree share the A likelihood, so the oracle values are equal.
  expect_lt(max(abs(refs - refs[[1L]])), 1e-3)
})

test_that("Binomial cloglog animal (A, Ainv, pedigree) plus spatial SDs match an independent dense Laplace oracle with sensitivity", {
  skip_on_cran()
  fx <- sb26_bin_fixture("cloglog", 20261232L)
  expect_false(identical(levels(fx$data$animal_id), rownames(fx$A)))
  refs <- vapply(c("A", "Ainv", "pedigree"), function(p) {
    fit <- sb26_bin_fit(fx, "cloglog", p)
    sb26_bin_check(fit, fx, "cloglog", paste("cloglog", p))
  }, numeric(1L))
  expect_lt(max(abs(refs - refs[[1L]])), 1e-3)
})
