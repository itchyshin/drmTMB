# Batch 29 (lane b) companion to the native Binomial ordinary + structured and
# crossed SD tests:
#   test-binomial-ordinary-animal-kernel-equivalence-sd.R (logit)
#   test-binomial-ordinary-animal-kernel-equivalence-nonlogit-sd.R
#   test-binomial-iid-relmat-kernel-equivalence-nonlogit-sd.R (animal and relmat only; phylo and
#   crossed are in test-binomial-iid-phylo-crossed-sd-oracle-b29b.R)
#
# Reviewer deficiency closed: those tests assert provider equivalence and
# coefficient recovery with loose bounds and have no independent likelihood
# oracle and no emulated-bug sensitivity. Here every fit is compared with a
# base-R dense Laplace marginal evaluated at the fitted parameters (logLik
# tolerance 1e-4 absolute) with hand-built kernels (Henderson tabular A from an
# inbred pedigree, hand relmat kernel, ape::vcv through cov2cor), and each
# emulated bug (swapped selector coefficient sets, reversed per-level SD
# vector, cov2cor(K), raw vcv, kernel read by position) must move the oracle by
# more than 0.1 (1000x the tolerance). Scope: likelihood assembly and selector
# alignment at one seed; no calibration, coverage or parity claim.

test_that("Binomial ordinary (1 | g) + animal (A, Ainv, pedigree) SDs: dense Laplace oracle and sensitivity", {
  skip_on_cran()
  for (link in c("logit", "probit", "cloglog")) {
    fx <- b29b_fixture(c("iid", "animal"), link, 29100L + match(link, c("logit", "probit", "cloglog")))
    refs <- vapply(c("A", "Ainv", "pedigree"), function(p) {
      b29b_check(fx, c(iid = NA, animal = p), paste(link, "iid+animal", p))$ref
    }, numeric(1L))
    expect_lt(max(abs(refs - refs[[1L]])), 1e-6)  # same likelihood for all three providers
  }
})

test_that("Binomial ordinary (1 | g) + relmat (K, Q) SDs: dense Laplace oracle and sensitivity", {
  skip_on_cran()
  for (link in c("logit", "probit", "cloglog")) {
    fx <- b29b_fixture(c("iid", "relmat"), link, 29300L + match(link, c("logit", "probit", "cloglog")))
    refs <- vapply(c("K", "Q"), function(p) {
      b29b_check(fx, c(iid = NA, relmat = p), paste(link, "iid+relmat", p))$ref
    }, numeric(1L))
    expect_lt(abs(refs[[1L]] - refs[[2L]]), 1e-6)
  }
})
