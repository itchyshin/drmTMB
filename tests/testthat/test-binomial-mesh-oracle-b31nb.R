# Batch 31 (group nb) companion: native Binomial mesh spatial intercept and
# numeric slope with a site-level SD regression, fixed kappa (logit, probit,
# cloglog). The SPDE precision (c0, g1, g2 and Q = kappa^4 c0 + 2 kappa^2 g1 +
# g2) and the barycentric projection are rebuilt by hand from the mesh
# triangulation and compared with the package matrices (1e-9 / 1e-8); the oracle
# is a base-R dense Laplace with the hand Q and hand projection, 1e-4 on
# logLik. Emulated bugs (reversed site SD, precision x 2, kappa doubled,
# projection nodes reversed, dropped slope design) must move it by > 0.1.
# Scope: likelihood assembly and alignment; no calibration or parity claim.

test_that("Binomial mesh spatial intercept SD (fixed kappa): hand SPDE oracle and sensitivity", {
  skip_on_cran()
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")
  for (link in b31nb_links) {
    fx <- b31nb_mesh_fixture("intercept", link, 31600L + match(link, b31nb_links))
    b31nb_check_mesh(fx, paste("mesh intercept", link))
  }
})

test_that("Binomial mesh spatial slope SD (fixed kappa): hand SPDE oracle and sensitivity", {
  skip_on_cran()
  skip_if_not_installed("sf")
  skip_if_not_installed("fmesher")
  for (link in b31nb_links) {
    fx <- b31nb_mesh_fixture("slope", link, 31700L + match(link, b31nb_links))
    b31nb_check_mesh(fx, paste("mesh slope", link))
  }
})
