source_phase18_animal_relmat_q2 <- function(env = parent.frame()) {
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
      "sim/dgp/sim_dgp_animal_relmat_q2.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_animal_relmat_q2.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_animal_relmat_q2_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 animal/relmat q2 DGP records known-matrix truth", {
  source_phase18_animal_relmat_q2()

  dat <- phase18_dgp_animal_relmat_q2(
    n_level = 8L,
    n_per_level = 5L,
    surface = "animal",
    matrix_argument = "precision",
    seed = 20260630L
  )
  again <- phase18_dgp_animal_relmat_q2(
    n_level = 8L,
    n_per_level = 5L,
    surface = "animal",
    matrix_argument = "precision",
    seed = 20260630L
  )
  truth <- attr(dat, "truth", exact = TRUE)

  expect_equal(dat, again)
  expect_equal(nrow(dat), 40L)
  expect_equal(truth$surface, "animal_relmat_q2")
  expect_equal(truth$structured_surface, "animal")
  expect_equal(truth$matrix_argument, "precision")
  expect_equal(dim(truth$K), c(8L, 8L))
  expect_equal(truth$Q, solve(truth$K), tolerance = 1e-10)
  expect_named(truth$beta_mu1, c("(Intercept)", "x"))
  expect_named(truth$beta_mu2, c("(Intercept)", "x"))
  expect_equal(
    dat$residual_covariance,
    dat$rho12 * dat$sigma1 * dat$sigma2,
    tolerance = 1e-12
  )
})

test_that("Phase 18 animal/relmat q2 smoke runner completes and resumes", {
  source_phase18_animal_relmat_q2()
  result_dir <- tempfile("phase18-animal-relmat-q2-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_animal_relmat_q2_conditions(
    structured_surface = c("animal", "relmat"),
    matrix_argument = "precision",
    n_level = 10L,
    n_per_level = 6L,
    matrix_decay = 0.40,
    sd_struct1 = 0.60,
    sd_struct2 = 0.50,
    rho_struct = 0.35,
    sigma1 = 0.22,
    sigma2 = 0.24,
    rho12 = -0.10
  )

  first <- phase18_run_animal_relmat_q2_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 217L,
    result_dir = result_dir,
    cores = 10L
  )
  second <- phase18_run_animal_relmat_q2_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 217L,
    result_dir = result_dir,
    cores = 10L
  )

  expect_identical(first$surface, "animal_relmat_q2")
  expect_equal(nrow(first$registry$cells), 2L)
  expect_equal(length(first$results), 2L)
  expect_equal(first$parallel$requested_cores, 10L)
  expect_equal(first$parallel$backend, "none")
  expect_equal(first$parallel$cores, 1L)
  expect_equal(
    unname(vapply(first$results, function(result) result$status, character(1))),
    rep("ok", 2L)
  )
  expect_true(all(vapply(
    second$results,
    function(result) result$skipped,
    TRUE
  )))
  expect_equal(nrow(first$summary), 20L)
  expect_equal(unique(first$summary$surface), "animal_relmat_q2")
  expect_equal(first$summary$artifact_grain, rep("replicate", 20L))
  expect_setequal(
    unique(first$summary$structured_surface),
    c("animal", "relmat")
  )
  expect_setequal(
    first$summary$parameter,
    c(
      "mu1:(Intercept)",
      "mu1:x",
      "mu2:(Intercept)",
      "mu2:x",
      "sigma1",
      "sigma2",
      "animal:sd1",
      "animal:sd2",
      "animal:cor",
      "relmat:sd1",
      "relmat:sd2",
      "relmat:cor",
      "rho12"
    )
  )
  expect_true(all(is.finite(first$summary$estimate)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "animal_relmat_q2_001",
    1L
  )))
  expect_equal(second$summary, first$summary)
})

test_that("Phase 18 animal/relmat q2 smoke helpers validate inputs", {
  source_phase18_animal_relmat_q2()

  expect_error(
    phase18_dgp_animal_relmat_q2(0L, 5L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_animal_relmat_q2(8L, 5L, sd_struct = c(0.4, -0.2)),
    "two positive"
  )
  expect_error(
    phase18_dgp_animal_relmat_q2(8L, 5L, matrix_decay = -0.1),
    "non-negative"
  )
  expect_error(
    phase18_dgp_animal_relmat_q2_cell(
      cell = data.frame(cell_id = "animal_relmat_q2_bad"),
      seed = 217L,
      cell_id = "animal_relmat_q2_bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_run_animal_relmat_q2_smoke(
      conditions = phase18_animal_relmat_q2_conditions(),
      n_rep = 0L
    ),
    "positive whole number"
  )
})
