# Batch 29 (lane b) companion to the native Binomial logit animal + relmat,
# animal + spatial and single-field animal SD tests:
#   test-binomial-animal-relmat-q-precision-sd.R,
#   test-binomial-animal-ainv-relmat-sd.R, test-binomial-animal-pedigree-relmat-sd.R
#     (logit, animal + relmat),
#   test-binomial-phylo-spatial-sd.R (animal + spatial logit rows),
#   test-binomial-animal-sd-regression.R, -ainv-sd-regression.R,
#   -pedigree-sd-regression.R (single-field animal intercept, logit).
#
# Reviewer deficiency closed: no independent likelihood oracle and no
# emulated-bug sensitivity (kernel equivalence and recovery bounds only).
# Each fit is compared with a base-R dense Laplace marginal at the fitted
# parameters (1e-4 absolute on logLik) with a Henderson tabular A from an
# inbred pedigree (diag(A) up to 1.25), a hand relmat kernel (scale 1.6) and a
# hand spatial kernel. Emulated bugs (swapped selector coefficient sets,
# reversed per-level SD, cov2cor(K), K x 2, kernel read by position) must move
# the oracle by more than 0.1 (1000x the tolerance). Scope: likelihood
# assembly and alignment at one seed; no calibration, coverage or parity claim.

test_that("Binomial logit animal (A, Ainv, pedigree) + relmat (K; Q for A) SDs: dense Laplace oracle and sensitivity", {
  skip_on_cran()
  fx <- b29b_fixture(c("animal", "relmat"), "logit", 29601L, n_obs = 1400L)
  refs <- c()
  for (pr in list(c("A", "K"), c("A", "Q"), c("Ainv", "K"), c("pedigree", "K"))) {
    refs <- c(refs, b29b_check(
      fx, c(animal = pr[[1L]], relmat = pr[[2L]]),
      paste("logit animal", pr[[1L]], "+ relmat", pr[[2L]])
    )$ref)
  }
  expect_lt(max(abs(refs - refs[[1L]])), 1e-6)
})

test_that("Binomial animal (A, Ainv, pedigree) + coordinate-spatial SDs (logit): dense Laplace oracle and sensitivity", {
  skip_on_cran()
  fx <- b29b_fixture(c("animal", "spatial"), "logit", 29640L, n_obs = 1400L)
  refs <- vapply(c("A", "Ainv", "pedigree"), function(p) {
    b29b_check(fx, c(animal = p, spatial = NA), paste("logit animal", p, "+ spatial"))$ref
  }, numeric(1L))
  expect_lt(max(abs(refs - refs[[1L]])), 1e-6)
})

test_that("Binomial single-field animal intercept SD (A, Ainv, pedigree, logit): dense Laplace oracle and sensitivity", {
  skip_on_cran()
  fx <- b29b_fixture("animal", "logit", 29620L, n_obs = 1400L)
  refs <- vapply(c("A", "Ainv", "pedigree"), function(p) {
    b29b_check(fx, c(animal = p), paste("logit animal-only", p))$ref
  }, numeric(1L))
  expect_lt(max(abs(refs - refs[[1L]])), 1e-6)
})
