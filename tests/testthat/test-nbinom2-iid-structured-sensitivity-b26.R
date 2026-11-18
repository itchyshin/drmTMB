# Batch 26 (lane sa) companion to the existing test-nbinom2-batch5-sd-regression.R test: independent
# oracle plus emulated-bug sensitivity for nbinom2 IID (ordinary) intercept plus one
# structured intercept, each with its own SD formula and a DIFFERENT predictor
# and coefficient set (so a selector or coefficient swap is detectable).
# Oracles are written here in base R: hand kernel exp(-d/median) scaled and
# nuggetted, tabular (Henderson) A with inbreeding, and cov2cor(ape::vcv) for the tree (the package phylo() uses the correlation form);
# dense Laplace at the fitted parameters, logLik tolerance 1e-4 (not loosened).
# Emulated bugs (reversed SD vectors, swapped selector coefficient sets,
# wrong K scale: cov2cor(K) for relmat/animal, raw ape::vcv for phylo) must move the oracle logLik by more than 0.1.
# Scope: likelihood agreement at the fitted parameters. No calibration,
# coverage or parity claim.

test_that("nbinom2 relmat (K and Q) plus IID: oracle and bug sensitivity", {
  skip_on_cran()
  fx <- b26sa_iid_struct_fixture("relmat", "nbinom2", 20261601L)
  expect_false(identical(levels(fx$data$id), rownames(fx$K)))
  r_k <- b26sa_check_iid_struct(fx, "relmat_K")
  r_q <- b26sa_check_iid_struct(fx, "relmat_Q")
  expect_lt(abs(r_k$ll - r_q$ll), 1e-3)
})

test_that("nbinom2 animal (A and Ainv, Henderson A with inbreeding) plus IID: oracle and bug sensitivity", {
  skip_on_cran()
  fx <- b26sa_iid_struct_fixture("animal", "nbinom2", 20261601L + 10L)
  expect_gt(max(diag(fx$K)), 1.05)
  r_a <- b26sa_check_iid_struct(fx, "animal_A")
  r_ainv <- b26sa_check_iid_struct(fx, "animal_Ainv")
  expect_lt(abs(r_a$ll - r_ainv$ll), 1e-3)
})

test_that("nbinom2 phylo plus IID: package tip covariance equals cov2cor(ape::vcv), oracle and bug sensitivity", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- b26sa_iid_struct_fixture("phylo", "nbinom2", 20261601L + 20L)
  b26sa_check_phylo_cov(fx$tree)
  expect_false(identical(levels(fx$data$id), fx$tree$tip.label))
  b26sa_check_iid_struct(fx, "phylo")
})
