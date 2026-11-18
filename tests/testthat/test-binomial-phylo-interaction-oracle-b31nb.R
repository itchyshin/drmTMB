# Batch 31 (group nb) companion: native Binomial phylo_interaction numeric
# slope with a pair-level SD regression (logit, probit, cloglog). Oracle: dense
# Laplace with the pair kernel kron(cov2cor(vcv(poll)), cov2cor(vcv(plant)))
# built by hand from ape::vcv, named by pair label; shuffled tips and data
# order. Emulated bugs (reversed pair SD, pair kernel by position, Kronecker
# factors swapped, K x 2, dropped slope design) must move the oracle by > 0.1.
# Scope: likelihood assembly and alignment; no calibration or parity claim.

test_that("Binomial phylo_interaction slope SD: dense Laplace oracle and sensitivity", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (link in b31nb_links) {
    fx <- b31nb_pi_fixture(link, 31500L + match(link, b31nb_links))
    b26sa_check_phylo_cov(fx$plant_tree)
    b26sa_check_phylo_cov(fx$poll_tree)
    b31nb_check_pi(fx, paste("phylo_interaction slope", link))
  }
})
