source_phase18_animal_relmat_q4 <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_animal_relmat_q4.R",
    "sim/fit/sim_summarise_animal_relmat_q4.R",
    "sim/run/sim_run_animal_relmat_q4_smoke.R",
    "sim/run/sim_summary_animal_relmat_q4_smoke.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 animal/relmat q4 DGP records all-four known-matrix truth", {
  source_phase18_animal_relmat_q4()

  dat <- phase18_dgp_animal_relmat_q4(
    n_level = 8L,
    n_per_level = 5L,
    surface = "animal",
    matrix_argument = "precision",
    seed = 20260602L
  )
  again <- phase18_dgp_animal_relmat_q4(
    n_level = 8L,
    n_per_level = 5L,
    surface = "animal",
    matrix_argument = "precision",
    seed = 20260602L
  )
  truth <- attr(dat, "truth", exact = TRUE)

  expect_equal(dat, again)
  expect_equal(nrow(dat), 40L)
  expect_equal(truth$surface, "animal_relmat_q4")
  expect_equal(truth$structured_surface, "animal")
  expect_equal(truth$matrix_argument, "precision")
  expect_equal(dim(truth$K), c(8L, 8L))
  expect_equal(truth$Q, solve(truth$K), tolerance = 1e-10)
  expect_named(truth$beta_mu1, c("(Intercept)", "x"))
  expect_named(truth$beta_mu2, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma1, c("(Intercept)", "z"))
  expect_named(truth$beta_sigma2, c("(Intercept)", "z"))
  expect_named(truth$sd_struct, c("mu1", "mu2", "sigma1", "sigma2"))
  expect_named(
    phase18_animal_relmat_q4_cor_vector(truth$cor_struct),
    c(
      "mu1_mu2",
      "mu1_sigma1",
      "mu1_sigma2",
      "mu2_sigma1",
      "mu2_sigma2",
      "sigma1_sigma2"
    )
  )
  expect_equal(
    dat$residual_covariance,
    dat$rho12 * dat$sigma1 * dat$sigma2,
    tolerance = 1e-12
  )

  ped_dat <- phase18_dgp_animal_relmat_q4(
    n_level = 8L,
    n_per_level = 5L,
    surface = "animal",
    matrix_argument = "pedigree",
    seed = 20260603L
  )
  ped_truth <- attr(ped_dat, "truth", exact = TRUE)
  expect_s3_class(ped_truth$pedigree, "data.frame")
  expect_named(ped_truth$pedigree, c("id", "dam", "sire"))
  expect_equal(
    ped_truth$K,
    drmTMB:::drm_pedigree_additive_relationship(ped_truth$pedigree)
  )
  expect_equal(ped_truth$Q, solve(ped_truth$K), tolerance = 1e-10)
})

test_that("Phase 18 animal/relmat q4 smoke runner completes and resumes", {
  skip_on_cran()
  source_phase18_animal_relmat_q4()
  result_dir <- tempfile("phase18-animal-relmat-q4-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_animal_relmat_q4_conditions(
    structured_surface = c("animal", "relmat"),
    matrix_argument = "precision",
    n_level = 12L,
    n_per_level = 7L
  )

  first <- phase18_run_animal_relmat_q4_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 253L,
    result_dir = result_dir,
    cores = 10L
  )
  second <- phase18_run_animal_relmat_q4_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 253L,
    result_dir = result_dir,
    cores = 10L
  )

  expect_identical(first$surface, "animal_relmat_q4")
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
  expect_equal(nrow(first$summary), 38L)
  expect_equal(unique(first$summary$surface), "animal_relmat_q4")
  expect_equal(first$summary$artifact_grain, rep("replicate", 38L))
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
      "sigma1:(Intercept)",
      "sigma1:z",
      "sigma2:(Intercept)",
      "sigma2:z",
      "animal:sd_mu1",
      "animal:sd_mu2",
      "animal:sd_sigma1",
      "animal:sd_sigma2",
      "animal:cor_mu1_mu2",
      "animal:cor_mu1_sigma1",
      "animal:cor_mu1_sigma2",
      "animal:cor_mu2_sigma1",
      "animal:cor_mu2_sigma2",
      "animal:cor_sigma1_sigma2",
      "relmat:sd_mu1",
      "relmat:sd_mu2",
      "relmat:sd_sigma1",
      "relmat:sd_sigma2",
      "relmat:cor_mu1_mu2",
      "relmat:cor_mu1_sigma1",
      "relmat:cor_mu1_sigma2",
      "relmat:cor_mu2_sigma1",
      "relmat:cor_mu2_sigma2",
      "relmat:cor_sigma1_sigma2",
      "rho12"
    )
  )
  expect_true(all(is.finite(first$summary$estimate)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "animal_relmat_q4_001",
    1L
  )))
  expect_equal(second$summary, first$summary)
})

test_that("Phase 18 animal/relmat q4 summary records derived interval boundary", {
  skip_on_cran()
  source_phase18_animal_relmat_q4()
  conditions <- phase18_animal_relmat_q4_conditions(
    structured_surface = "relmat",
    matrix_argument = "precision",
    n_level = 12L,
    n_per_level = 7L
  )

  out <- phase18_summarise_animal_relmat_q4_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 257L,
    profile_parameters = "relmat:cor_mu1_mu2"
  )
  requested <- out$profile_intervals[
    out$profile_intervals$parameter == "relmat:cor_mu1_mu2",
    ,
    drop = FALSE
  ]

  expect_equal(nrow(out$replicates), 19L)
  expect_equal(nrow(out$wald_intervals), 0L)
  expect_equal(nrow(out$profile_intervals), 19L)
  expect_equal(nrow(requested), 1L)
  expect_equal(requested$profile.status, "derived_interval_unavailable")
  expect_match(requested$profile.message, "derived")
  expect_equal(requested$interval_status, "failed")
  expect_equal(nrow(out$profile_coverage), 1L)
  expect_equal(nrow(out$interval_evidence), 19L)
})

test_that("Phase 18 animal/relmat q4 smoke helpers validate inputs", {
  source_phase18_animal_relmat_q4()

  expect_error(
    phase18_dgp_animal_relmat_q4(0L, 5L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_animal_relmat_q4(
      8L,
      5L,
      sd_struct = c(mu1 = 0.4, mu2 = 0.3, sigma1 = -0.2, sigma2 = 0.1)
    ),
    "four positive"
  )
  expect_error(
    phase18_dgp_animal_relmat_q4(8L, 5L, matrix_decay = -0.1),
    "non-negative"
  )
  expect_error(
    phase18_dgp_animal_relmat_q4(
      8L,
      5L,
      surface = "relmat",
      matrix_argument = "pedigree"
    ),
    "only available"
  )
  expect_error(
    phase18_animal_relmat_q4_conditions(
      structured_surface = "relmat",
      matrix_argument = "pedigree"
    ),
    "only available"
  )
  bad_cor <- phase18_animal_relmat_q4_cor_matrix()
  bad_cor["mu1", "mu2"] <- bad_cor["mu2", "mu1"] <- 0.99
  bad_cor["mu1", "sigma1"] <- bad_cor["sigma1", "mu1"] <- 0.99
  expect_error(
    phase18_dgp_animal_relmat_q4(8L, 5L, cor_struct = bad_cor),
    "positive definite"
  )
  expect_error(
    phase18_dgp_animal_relmat_q4_cell(
      cell = data.frame(cell_id = "animal_relmat_q4_bad"),
      seed = 1L,
      cell_id = "animal_relmat_q4_bad",
      replicate = 1L
    ),
    "must contain"
  )
})
