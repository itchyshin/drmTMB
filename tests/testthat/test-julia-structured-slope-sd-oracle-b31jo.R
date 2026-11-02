# Batch 31 (group jo): live Julia structured-field predictor-dependent-SD routes
# against an independent base-R dense Laplace oracle evaluated at the Julia
# estimates (agreement asserted to 1e-3 absolute on the logLik; observed
# agreement is far tighter, see the messages):
#   - Gamma phylogenetic random intercept (tree; unit-height ultrametric tree),
#   - Poisson animal slope with the relationship matrix supplied as A and as Ainv
#     (Henderson tabular A from an inbred pedigree, max diag(A) = 1.25),
#   - Gamma and NB2 relmat slope (hand kernel with non-constant diagonal),
#   - Gamma and NB2 coordinate spatial slope (hand exponential kernel).
# The data factor's level order is a permutation of the kernel's row names, so a
# by-position kernel read is one of the emulated bugs. Each emulated bug (swapped,
# sign-flipped or dropped selector coefficients, reversed per-level SD vector,
# K x 2, cov2cor(K) where the diagonal varies, kernel read by position) must move
# the oracle by more than 0.1. One fixed draw per route; no calibration,
# coverage or broad parity claim.

test_that("package phylo tip covariance equals cov2cor(ape::vcv) and the hand kernels are well formed", {
  skip_if_not_installed("ape")
  fx <- b31jo_struct_fixture("phylo", "gamma", 20261102L)
  labs <- sort(fx$tree$tip.label)
  expect_equal(
    unname(drmTMB:::drm_phylo_tip_covariance(fx$tree)[labs, labs]),
    unname(stats::cov2cor(ape::vcv(fx$tree))[labs, labs]), tolerance = 1e-8
  )
  expect_equal(max(diag(ape::vcv(fx$tree))), 1, tolerance = 1e-10)
  an <- b31jo_struct_fixture("animal", "poisson", 20261102L)
  expect_gt(max(diag(an$A)), 1.05)
  expect_equal(unname(an$A %*% solve(an$A)), diag(nrow(an$A)), tolerance = 1e-8)
  expect_false(isTRUE(all.equal(rownames(an$A), levels(an$data$id))))
  rm <- b31jo_struct_fixture("relmat", "gamma", 20261101L)
  expect_gt(diff(range(diag(rm$K))), 0.2)
})

test_that("Julia Gamma phylogenetic SD intercept matches the independent oracle", {
  b31jo_skip_unless_live_julia()
  b31jo_expect_struct_route("phylo", "gamma", "tree", 20261102L)
})

test_that("Julia Poisson animal slope SD (A input) matches the independent oracle", {
  b31jo_skip_unless_live_julia()
  b31jo_expect_struct_route("animal", "poisson", "A", 20261102L)
})

test_that("Julia Poisson animal slope SD (Ainv input) matches the independent oracle", {
  b31jo_skip_unless_live_julia()
  b31jo_expect_struct_route("animal", "poisson", "Ainv", 20261102L)
})

test_that("Julia Gamma relmat slope SD matches the independent oracle", {
  b31jo_skip_unless_live_julia()
  b31jo_expect_struct_route("relmat", "gamma", "K", 20261101L)
})

test_that("Julia Gamma spatial slope SD matches the independent oracle", {
  b31jo_skip_unless_live_julia()
  b31jo_expect_struct_route("spatial", "gamma", "coords", 20261101L)
})

test_that("Julia NB2 relmat slope SD matches the independent oracle", {
  b31jo_skip_unless_live_julia()
  b31jo_expect_struct_route("relmat", "nbinom2", "K", 20261101L)
})

test_that("Julia NB2 spatial slope SD matches the independent oracle", {
  b31jo_skip_unless_live_julia()
  b31jo_expect_struct_route("spatial", "nbinom2", "coords", 20261104L)
})
