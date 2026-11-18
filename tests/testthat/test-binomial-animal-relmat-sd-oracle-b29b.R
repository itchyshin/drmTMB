# Batch 29 (lane b) companion to the native Binomial animal + relmat SD tests
# (probit and cloglog):
#   test-binomial-animal-relmat-nonlogit-sd.R,
#   test-binomial-animal-relmat-q-nonlogit-sd.R,
#   test-binomial-animal-relmat-kernel-equivalence-nonlogit-sd.R
#     (animal A | Ainv | pedigree  x  relmat K | Q, probit and cloglog),
#
# Reviewer deficiency closed: no independent likelihood oracle and no
# emulated-bug sensitivity (kernel equivalence and recovery bounds only).
# Each fit is compared with a base-R dense Laplace marginal at the fitted
# parameters (1e-4 absolute on logLik) with a Henderson tabular A from an
# inbred pedigree (diag(A) above 1.6), a hand relmat kernel (scale 1.6) and a
# hand spatial kernel. Emulated bugs (swapped selector coefficient sets,
# reversed per-level SD, cov2cor(K), K x 2, kernel read by position) must move
# the oracle by more than 0.1 (1000x the tolerance). Scope: likelihood
# assembly and alignment at one seed; no calibration, coverage or parity claim.

links2 <- c("probit", "cloglog")

test_that("Binomial animal (A, Ainv, pedigree) + relmat (K, Q) SDs (probit, cloglog): dense Laplace oracle and sensitivity", {
  skip_on_cran()
  for (link in links2) {
    fx <- b29b_fixture(c("animal", "relmat"), link, 29630L + match(link, links2),
                       n_obs = 1000L, boost = c(animal = 1.6, relmat = 0.7))
    refs <- c()
    for (a in c("A", "Ainv", "pedigree")) {
      for (r in c("K", "Q")) {
        refs <- c(refs, b29b_check(
          fx, c(animal = a, relmat = r), paste(link, "animal", a, "+ relmat", r)
        )$ref)
      }
    }
    expect_lt(max(abs(refs - refs[[1L]])), 1e-6)  # one likelihood, six input forms
  }
})
