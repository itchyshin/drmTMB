# Label utilities at the head of R/julia-bridge.R (not route admission).

test_that("drm_julia_bridge_blocks() returns ordered block prefixes", {
  blocks <- drmTMB:::drm_julia_bridge_blocks()
  expect_true("sd_phylo" %in% blocks)
  expect_true("mu" %in% blocks)
  expect_gt(length(blocks), 10L)
})

test_that("drm_julia_split_coef_name() prefers long block prefixes", {
  nm <- c("sd_phylo_log_mass_z", "mu_x", "resd_mu_id")
  sp <- drmTMB:::drm_julia_split_coef_name(nm)
  expect_identical(sp$dpar, c("sd_phylo", "mu", "resd_mu"))
  expect_identical(sp$term, c("log_mass_z", "x", "id"))
})

test_that("julia_bridge_supported_dpars() lists location-scale dpars", {
  dp <- drmTMB:::julia_bridge_supported_dpars()
  expect_true(all(c("mu", "sigma", "mu1", "rho12") %in% dp))
})

test_that("drm_julia_split_coef_name() handles sdtarget hashed labels", {
  nm <- "sdtarget_deadbeef_extra"
  sp <- drmTMB:::drm_julia_split_coef_name(nm)
  expect_match(sp$dpar[[1L]], "^sdtarget_")
  expect_equal(sp$term[[1L]], "extra")
})