source_phase18_spatial_q2 <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/R/sim_uncertainty.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_spatial_q2.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_spatial_q2.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_spatial_q2_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 spatial q2 DGP is seeded and self-describing", {
  source_phase18_spatial_q2()
  conditions <- phase18_spatial_q2_conditions(
    n_site = 8L,
    n_each = 5L,
    geometry = c("ring", "stretched")
  )
  dat <- phase18_dgp_spatial_q2(
    n_site = 8L,
    n_each = 5L,
    geometry = "ring",
    seed = 20260711L,
    cell_id = "spatial_q2_001",
    replicate = 1L
  )
  again <- phase18_dgp_spatial_q2(
    n_site = 8L,
    n_each = 5L,
    geometry = "ring",
    seed = 20260711L,
    cell_id = "spatial_q2_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth", exact = TRUE)
  precision <- drmTMB:::drm_spatial_coords_precision(
    truth$coords,
    site = row.names(truth$coords),
    group = "site"
  )

  expect_equal(nrow(conditions), 2L)
  expect_equal(dat, again)
  expect_equal(truth$surface, "spatial_q2")
  expect_equal(truth$geometry, "ring")
  expect_equal(dim(truth$covariance), c(8L, 8L))
  expect_equal(row.names(truth$coords), paste0("site_", seq_len(8L)))
  expect_equal(
    truth$covariance,
    solve(as.matrix(precision$precision)),
    tolerance = 1e-10
  )
  expect_equal(
    dat$residual_covariance,
    dat$rho12 * dat$sigma1 * dat$sigma2,
    tolerance = 1e-12
  )
})

test_that("Phase 18 spatial q2 smoke runner fits admitted spelling", {
  source_phase18_spatial_q2()
  conditions <- phase18_spatial_q2_conditions(
    n_site = 8L,
    n_each = 5L,
    geometry = "ring",
    sd_spatial1 = 0.48,
    sd_spatial2 = 0.40,
    rho_spatial = 0.25,
    sigma1 = 0.18,
    sigma2 = 0.20,
    rho12 = -0.08
  )

  result <- phase18_run_spatial_q2_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 241L
  )

  expect_equal(result$surface, "spatial_q2")
  expect_equal(nrow(result$registry$cells), 1L)
  expect_equal(
    unname(vapply(
      result$results,
      function(result) result$status,
      character(1)
    )),
    "ok"
  )
  expect_equal(unique(result$summary$surface), "spatial_q2")
  expect_equal(unique(result$summary$geometry), "ring")
  expect_setequal(
    result$summary$parameter,
    c(
      "mu1:(Intercept)",
      "mu1:x",
      "mu2:(Intercept)",
      "mu2:x",
      "sigma1",
      "sigma2",
      "spatial:sd1",
      "spatial:sd2",
      "spatial:cor",
      "rho12"
    )
  )
  expect_true(all(result$summary$profile.status == "not_requested"))
})

test_that("Phase 18 spatial q2 helpers validate inputs", {
  source_phase18_spatial_q2()

  expect_error(
    phase18_dgp_spatial_q2(1L, 5L),
    "at least two"
  )
  expect_error(
    phase18_dgp_spatial_q2(8L, 5L, sd_spatial = c(0.4, -0.2)),
    "positive"
  )
  expect_error(
    phase18_dgp_spatial_q2(8L, 5L, rho_spatial = 1.2),
    "absolute value below 1"
  )
  expect_error(
    phase18_dgp_spatial_q2_cell(
      cell = data.frame(cell_id = "spatial_q2_bad"),
      seed = 1L,
      cell_id = "spatial_q2_bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_run_spatial_q2_smoke(
      conditions = phase18_spatial_q2_conditions(),
      n_rep = 0L
    ),
    "positive"
  )
})
