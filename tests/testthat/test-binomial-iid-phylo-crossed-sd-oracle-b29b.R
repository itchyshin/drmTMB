# Batch 29 (lane b) companion to the native Binomial ordinary + structured and
# crossed SD tests:
#   test-binomial-ordinary-phylo-sd.R, test-binomial-ordinary-phylo-nonlogit-sd.R
#   test-binomial-crossed-nonlogit-sd.R
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

test_that("phylo tip covariance equals cov2cor(ape::vcv) on the b29b tree", {
  skip_on_cran()
  skip_if_not_installed("ape")
  set.seed(29001L)
  fx <- b29b_fixture(c("iid", "phylo"), "logit", 29001L)
  b26sa_check_phylo_cov(fx$fields$phylo$tree)
})

test_that("Binomial ordinary (1 | g) + phylo SDs: dense Laplace oracle and sensitivity", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (link in c("logit", "probit", "cloglog")) {
    fx <- b29b_fixture(c("iid", "phylo"), link, 29200L + match(link, c("logit", "probit", "cloglog")))
    b29b_check(fx, c(iid = NA, phylo = NA), paste(link, "iid+phylo"))
  }
})

test_that("Binomial crossed (1 | g) + (1 | h) SDs (probit, cloglog): dense Laplace oracle and sensitivity", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- b29b_fixture(c("iid", "iid2"), link, 29400L + match(link, c("probit", "cloglog")))
    b29b_check(fx, c(iid = NA, iid2 = NA), paste(link, "crossed"))
  }
})
