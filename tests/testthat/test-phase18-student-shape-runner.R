source_phase18_student_shape <- function(env = parent.frame()) {
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
      "sim/dgp/sim_dgp_student_shape.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_student_shape.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_student_shape_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 Student-t shape DGP records link-scale shape truth", {
  source_phase18_student_shape()

  dat <- phase18_dgp_student_shape(n = 24L, seed = 20260629L)
  truth <- attr(dat, "truth", exact = TRUE)

  expect_equal(nrow(dat), 24L)
  expect_equal(truth$surface, "student_shape")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma, c("(Intercept)", "z"))
  expect_named(truth$beta_nu, c("(Intercept)", "w"))
  expect_true(all(dat$nu > 2))
  expect_equal(dat$nu, 2 + exp(dat$eta_nu), tolerance = 1e-12)
})

test_that("Phase 18 Student-t shape smoke runner completes and resumes", {
  source_phase18_student_shape()
  result_dir <- tempfile("phase18-student-shape-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_student_shape_conditions(
    n = 240L,
    nu_intercept = log(6),
    nu_slope = 0.20,
    sigma_slope = 0.20,
    rho_xw = 0.1
  )

  first <- phase18_run_student_shape_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 219L,
    result_dir = result_dir
  )
  second <- phase18_run_student_shape_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 219L,
    result_dir = result_dir
  )

  expect_identical(first$surface, "student_shape")
  expect_equal(nrow(first$registry$cells), 1L)
  expect_equal(length(first$results), 1L)
  expect_equal(first$parallel$backend, "none")
  expect_equal(first$parallel$cores, 1L)
  expect_identical(first$results[[1L]]$status, "ok")
  expect_false(first$results[[1L]]$skipped)
  expect_true(second$results[[1L]]$skipped)
  expect_equal(nrow(first$summary), 6L)
  expect_equal(first$summary$surface, rep("student_shape", 6L))
  expect_equal(first$summary$artifact_grain, rep("replicate", 6L))
  expect_equal(
    first$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma:(Intercept)",
      "sigma:z",
      "nu:(Intercept)",
      "nu:w"
    )
  )
  expect_true(all(is.finite(first$summary$estimate)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "student_shape_001",
    1L
  )))
  expect_equal(second$summary, first$summary)
})

test_that("Phase 18 Student-t shape smoke runner validates cells", {
  source_phase18_student_shape()

  bad_cell <- data.frame(cell_id = "student_shape_bad")
  expect_error(
    phase18_dgp_student_shape_cell(
      cell = bad_cell,
      seed = 219L,
      cell_id = "student_shape_bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_run_student_shape_smoke(
      conditions = phase18_student_shape_conditions(n = 20L),
      n_rep = 0L
    ),
    "positive whole number"
  )
})

test_that("Phase 18 Student-t shape runner rejects nested parallel bootstrap", {
  skip_on_os("windows")
  source_phase18_student_shape()

  expect_error(
    phase18_run_student_shape_smoke(
      conditions = phase18_student_shape_conditions(
        n = 240L,
        nu_intercept = log(6),
        nu_slope = 0.20,
        sigma_slope = 0.20,
        rho_xw = 0.1
      ),
      n_rep = 2L,
      master_seed = 226L,
      bootstrap_nsim = 2L,
      cores = 2L,
      backend = "multicore",
      bootstrap_cores = 2L,
      bootstrap_backend = "multicore"
    ),
    "either the replicate layer or the bootstrap layer"
  )
})
