# Batch 31 (group nb) companion: native Binomial q2 block (intercept + numeric
# slope, one SD regression per coefficient): animal(1 + x | g, A) across the
# three links and phylo(1 + x | g, tree) (logit). The native unlabelled block
# fixes the intercept-slope correlation at 0; the oracle uses that and emulates
# rho = +/-0.6. Oracle: base-R dense Laplace with Henderson A (inbred) or
# cov2cor(ape::vcv(tree)); 1e-4 on logLik; each emulated bug (swapped selector
# coefficient sets, reversed or intercept/slope-swapped SD vectors, K by
# position, K x 2, cov2cor(K) or raw vcv, rho) must move the oracle by > 0.1.
# Scope: likelihood assembly and alignment; no calibration or parity claim.

test_that("phylo tip covariance equals cov2cor(ape::vcv) on the b31nb tree", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- b31nb_q2_fixture("phylo", "logit", 31400L)
  b26sa_check_phylo_cov(fx$tree)
})

test_that("Binomial animal q2 block (A): dense Laplace oracle and sensitivity", {
  skip_on_cran()
  for (link in b31nb_links) {
    fx <- b31nb_q2_fixture("animal", link, 31430L + match(link, b31nb_links))
    b31nb_check_q2(fx, paste("animal q2", link))
  }
})

test_that("Binomial phylo q2 block (logit): dense Laplace oracle and sensitivity", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- b31nb_q2_fixture("phylo", "logit", 31420L)
  b31nb_check_q2(fx, "phylo q2 logit")
})
