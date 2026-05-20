source_phase18_biv_rho12 <- function(env = parent.frame()) {
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
      "sim/R/sim_bootstrap.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_biv_rho12.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_biv_rho12.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_biv_rho12_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 bivariate rho12 DGP records fixed-effect truth", {
  source_phase18_biv_rho12()

  dat <- phase18_dgp_biv_rho12(n = 20L, seed = 20260626L)
  truth <- attr(dat, "truth", exact = TRUE)

  expect_equal(nrow(dat), 20L)
  expect_equal(truth$surface, "biv_rho12")
  expect_named(truth$beta_mu1, c("(Intercept)", "x"))
  expect_named(truth$beta_mu2, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma1, c("(Intercept)", "z1"))
  expect_named(truth$beta_sigma2, c("(Intercept)", "z2"))
  expect_named(truth$beta_rho12, c("(Intercept)", "w"))
  expect_true(all(abs(dat$rho12) < 1))
  expect_equal(
    dat$residual_covariance,
    dat$rho12 * dat$sigma1 * dat$sigma2,
    tolerance = 1e-12
  )
})

test_that("Phase 18 bivariate rho12 smoke runner completes and resumes", {
  source_phase18_biv_rho12()
  result_dir <- tempfile("phase18-biv-rho12-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_biv_rho12_conditions(
    n = 180L,
    delta0 = atanh(0.20),
    delta1 = 0.20,
    sigma_ratio = 1.1,
    rho_xw = 0.1
  )

  first <- phase18_run_biv_rho12_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 216L,
    result_dir = result_dir
  )
  second <- phase18_run_biv_rho12_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 216L,
    result_dir = result_dir
  )

  expect_identical(first$surface, "biv_rho12")
  expect_equal(nrow(first$registry$cells), 1L)
  expect_equal(length(first$results), 1L)
  expect_equal(first$parallel$backend, "none")
  expect_equal(first$parallel$cores, 1L)
  expect_identical(first$results[[1L]]$status, "ok")
  expect_false(first$results[[1L]]$skipped)
  expect_true(second$results[[1L]]$skipped)
  expect_equal(nrow(first$summary), 10L)
  expect_equal(first$summary$surface, rep("biv_rho12", 10L))
  expect_equal(first$summary$artifact_grain, rep("replicate", 10L))
  expect_equal(
    first$summary$parameter,
    c(
      "mu1:(Intercept)",
      "mu1:x",
      "mu2:(Intercept)",
      "mu2:x",
      "sigma1:(Intercept)",
      "sigma1:z1",
      "sigma2:(Intercept)",
      "sigma2:z2",
      "rho12:(Intercept)",
      "rho12:w"
    )
  )
  expect_true(all(is.finite(first$summary$estimate)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "biv_rho12_001",
    1L
  )))
  expect_equal(second$summary, first$summary)
})

test_that("Phase 18 bivariate rho12 smoke runner validates cells", {
  source_phase18_biv_rho12()

  bad_cell <- data.frame(cell_id = "biv_rho12_bad")
  expect_error(
    phase18_dgp_biv_rho12_cell(
      cell = bad_cell,
      seed = 216L,
      cell_id = "biv_rho12_bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_run_biv_rho12_smoke(
      conditions = phase18_biv_rho12_conditions(n = 20L),
      n_rep = 0L
    ),
    "positive whole number"
  )
})

test_that("Phase 18 bivariate rho12 runner rejects nested parallel bootstrap", {
  skip_on_os("windows")
  source_phase18_biv_rho12()

  expect_error(
    phase18_run_biv_rho12_smoke(
      conditions = phase18_biv_rho12_conditions(
        n = 180L,
        delta0 = atanh(0.20),
        delta1 = 0.20,
        sigma_ratio = 1.1,
        rho_xw = 0.1
      ),
      n_rep = 2L,
      master_seed = 227L,
      bootstrap_nsim = 2L,
      cores = 2L,
      backend = "multicore",
      bootstrap_cores = 2L,
      bootstrap_backend = "multicore"
    ),
    "either the replicate layer or the bootstrap layer"
  )
})
