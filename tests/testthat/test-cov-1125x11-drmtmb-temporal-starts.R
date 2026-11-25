# Coverage: temporal multistart helpers in R/drmTMB.R.

mock_obj <- function(theta = 0.1) {
  list(par = c(beta = 0, theta_temporal = theta))
}

test_that("drm_temporal_persistence_starts builds ar1 opposing signs", {
  obj <- mock_obj()
  temporal <- list(structure = "ar1", n_occasions = 5L, gap = 1:5)
  starts <- drmTMB:::drm_temporal_persistence_starts(obj, temporal)
  expect_length(starts, 2L)
  expect_gt(starts[[1L]][["theta_temporal"]], 0)
  expect_lt(starts[[2L]][["theta_temporal"]], 0)
})

test_that("drm_temporal_persistence_starts fills homtoep thetas", {
  obj <- list(par = structure(rep(0, 4), names = rep("theta_temporal", 4)))
  temporal <- list(structure = "homtoep", n_occasions = 5L, gap = 1:5)
  starts <- drmTMB:::drm_temporal_persistence_starts(obj, temporal)
  expect_length(starts, 1L)
  expect_length(starts[[1L]], length(obj$par))
  theta_vals <- starts[[1L]][names(starts[[1L]]) == "theta_temporal"]
  expect_length(theta_vals, 4L)
  expect_true(all(theta_vals > 0))
})

test_that("drm_temporal_persistence_starts scales OU by reference gap", {
  obj <- mock_obj(0)
  temporal <- list(
    structure = "ou",
    n_occasions = 4L,
    gap = c(0, 2, 4, 7)
  )
  starts <- drmTMB:::drm_temporal_persistence_starts(obj, temporal)
  expect_length(starts, 2L)
  expect_true(all(vapply(starts, function(s) is.finite(unname(s["theta_temporal"])), TRUE)))
  expect_false(
    identical(
      unname(starts[[1L]]["theta_temporal"]),
      unname(starts[[2L]]["theta_temporal"])
    )
  )
})

test_that("drm_temporal_persistence_starts aborts on missing theta or bad schedule", {
  obj <- list(par = c(beta = 0))
  temporal <- list(structure = "ar1", n_occasions = 3L, gap = 1:3)
  expect_error(
    drmTMB:::drm_temporal_persistence_starts(obj, temporal),
    "theta_temporal"
  )
  obj2 <- list(par = c(theta_temporal = 0))
  temporal2 <- list(structure = "homtoep", n_occasions = 4L, gap = 1:4)
  expect_error(
    drmTMB:::drm_temporal_persistence_starts(obj2, temporal2),
    "HOMTOEP"
  )
  temporal3 <- list(structure = "ou", n_occasions = 3L, gap = c(0, 0, 0))
  expect_error(
    drmTMB:::drm_temporal_persistence_starts(mock_obj(), temporal3),
    "positive elapsed"
  )
})

test_that("structured_mu_q reads q from phylo metadata", {
  expect_equal(drmTMB:::structured_mu_q(list(q = 3L)), 3L)
  expect_equal(drmTMB:::structured_mu_q(list(coef_names = c("a", "b"))), 2L)
  expect_equal(drmTMB:::structured_mu_q(list()), 1L)
})

test_that("phylo_mu_has_cross_dpar detects mixed endpoints", {
  cross <- list(has = TRUE, q = 2L, dpars = c("mu1", "sigma2"))
  expect_true(drmTMB:::phylo_mu_has_cross_dpar(cross))
  same <- list(has = TRUE, q = 2L, dpars = c("mu1", "mu2"))
  expect_false(drmTMB:::phylo_mu_has_cross_dpar(same))
  expect_false(drmTMB:::phylo_mu_has_cross_dpar(list(has = FALSE)))
})