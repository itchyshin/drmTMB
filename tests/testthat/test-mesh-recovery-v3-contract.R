helper_path <- testthat::test_path(
  "..", "..", "tools", "mesh-spde-recovery-v3-helpers.R"
)
sys.source(helper_path, envir = environment())

mesh_v3_fixture <- function(estimate = 1e-4, n = 50L) {
  data.frame(
    n_site = rep(128L, n), fit_ok = TRUE, convergence = 0L,
    pdHess = TRUE, objective = rep(10, n), max_gradient = rep(1e-6, n),
    estimate = rep(estimate, n)
  )
}

test_that("V3 seed ledger is exact, unique, and independent", {
  design <- mesh_v3_design()
  expect_equal(nrow(design), 100L)
  expect_equal(as.integer(table(design$n_site)), c(50L, 50L))
  expect_equal(anyDuplicated(design$seed), 0L)
  expect_length(intersect(design$seed, mesh_v3_prior_seeds()), 0L)
  expect_equal(nrow(mesh_v3_design(smoke = TRUE)), 2L)
})

test_that("V3 aggregation passes only a complete precise recovery rung", {
  result <- mesh_v3_mc_summary(mesh_v3_fixture())
  expect_true(result$gate_pass)
  expect_equal(result$usable, 50L)
  expect_equal(result$relative_bias, 0)
  expect_equal(result$rmse_log_scale, 0)
})

test_that("V3 aggregation fails closed on missing or boundary evidence", {
  bad <- mesh_v3_fixture()
  bad$estimate[[1L]] <- NA_real_
  expect_false(mesh_v3_mc_summary(bad)$gate_pass)

  bad <- mesh_v3_fixture()
  bad$estimate[[1L]] <- 0
  expect_false(mesh_v3_mc_summary(bad)$gate_pass)

  bad <- mesh_v3_fixture()
  bad$convergence[[1L]] <- 1L
  expect_false(mesh_v3_mc_summary(bad)$gate_pass)

  bad <- mesh_v3_fixture()
  bad$pdHess[[1L]] <- FALSE
  expect_false(mesh_v3_mc_summary(bad)$gate_pass)

  bad <- mesh_v3_fixture()
  bad$max_gradient[[1L]] <- 1
  expect_false(mesh_v3_mc_summary(bad)$gate_pass)
})

test_that("V3 aggregation withholds when Monte Carlo uncertainty crosses a gate", {
  estimates <- 1e-4 * c(rep(0.65, 25), rep(1.25, 25))
  result <- mesh_v3_mc_summary(mesh_v3_fixture(estimate = estimates))
  expect_false(result$gate_pass)
  expect_true(result$bias_ci_low < -0.15 || result$bias_ci_high > 0.15 ||
                result$rmse_ci_high > 0.30)
})

test_that("V3 smoke results can never promote the capability", {
  smoke <- mesh_v3_fixture(n = 1L)
  expect_false(mesh_v3_mc_summary(smoke, smoke = TRUE)$gate_pass)
})
