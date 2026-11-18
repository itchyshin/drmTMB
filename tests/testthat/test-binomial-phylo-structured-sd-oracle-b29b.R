# Batch 29 (lane b) companion to the native Binomial phylo + structured SD tests:
#   test-binomial-phylo-animal-sd.R, test-binomial-phylo-animal-ainv-sd.R,
#   test-binomial-phylo-animal-pedigree-sd.R (logit rows),
#   test-binomial-phylo-relmat-sd.R, test-binomial-phylo-relmat-q-nonlogit-sd.R
#   (K and Q, logit/probit/cloglog),
#   test-binomial-phylo-spatial-sd.R (logit/probit/cloglog).
#
# Reviewer deficiency closed: no independent likelihood oracle (recovery bounds
# of 0.35-0.6 and K-versus-Q equality only) and no emulated-bug sensitivity.
# Here each fit is compared with a base-R dense Laplace marginal at the fitted
# parameters (1e-4 absolute on logLik) using ape::vcv through cov2cor for the
# tree (the package helper is compared with it), a Henderson tabular A from an
# inbred pedigree, a hand relmat kernel and a hand spatial kernel; each
# emulated bug (swapped selector coefficient sets, reversed per-level SD, raw
# vcv, cov2cor(K), K x 2, kernel read by position) must move the oracle by
# more than 0.1 (1000x the tolerance). The probit and cloglog phylo + animal
# rows are covered by test-binomial-batch3-sensitivity-b26.R and are not
# repeated. Scope: likelihood assembly and alignment at one seed; no
# calibration, coverage or parity claim.

links3 <- c("logit", "probit", "cloglog")

test_that("phylo tip covariance equals cov2cor(ape::vcv) on the b29b phylo + structured trees", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (kinds in list(c("phylo", "animal"), c("phylo", "relmat"), c("phylo", "spatial"))) {
    fx <- b29b_fixture(kinds, "logit", 29500L)
    b26sa_check_phylo_cov(fx$fields$phylo$tree)
  }
})

test_that("Binomial logit phylo + animal (A, Ainv, pedigree) SDs: dense Laplace oracle and sensitivity", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- b29b_fixture(c("phylo", "animal"), "logit", 29501L)
  refs <- vapply(c("A", "Ainv", "pedigree"), function(p) {
    b29b_check(fx, c(phylo = NA, animal = p), paste("logit phylo+animal", p))$ref
  }, numeric(1L))
  expect_lt(max(abs(refs - refs[[1L]])), 1e-6)
})

test_that("Binomial phylo + relmat (K, Q) SDs: dense Laplace oracle and sensitivity", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (link in links3) {
    fx <- b29b_fixture(c("phylo", "relmat"), link, 29510L + match(link, links3))
    refs <- vapply(c("K", "Q"), function(p) {
      b29b_check(fx, c(phylo = NA, relmat = p), paste(link, "phylo+relmat", p))$ref
    }, numeric(1L))
    expect_lt(abs(refs[[1L]] - refs[[2L]]), 1e-6)
  }
})

test_that("Binomial phylo + coordinate-spatial SDs: dense Laplace oracle and sensitivity", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (link in links3) {
    fx <- b29b_fixture(c("phylo", "spatial"), link, 29520L + match(link, links3))
    b29b_check(fx, c(phylo = NA, spatial = NA), paste(link, "phylo+spatial"))
  }
})
