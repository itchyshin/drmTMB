source_phase18_biv_gaussian_q4_location <- function() {
  env <- parent.frame()
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_biv_gaussian_q4_location.R",
    "sim/fit/sim_summarise_biv_gaussian_q4_location.R",
    "sim/run/sim_run_biv_gaussian_q4_location_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q4_location_smoke.R",
    "sim/run/sim_write_biv_gaussian_q4_location_grid.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 bivariate Gaussian q4 location DGP is seeded", {
  source_phase18_biv_gaussian_q4_location()

  conditions <- phase18_biv_gaussian_q4_location_conditions(
    n_id = 12L,
    n_each = 5L
  )
  dat <- phase18_dgp_biv_gaussian_q4_location(
    n_id = 12L,
    n_each = 5L,
    seed = 239L,
    cell_id = "biv_gaussian_q4_location_001",
    replicate = 1L
  )
  again <- phase18_dgp_biv_gaussian_q4_location(
    n_id = 12L,
    n_each = 5L,
    seed = 239L,
    cell_id = "biv_gaussian_q4_location_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 1L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 60L)
  expect_named(
    dat,
    c(
      "y1",
      "y2",
      "x",
      "id",
      "mu1",
      "mu2",
      "sigma1",
      "sigma2",
      "cell_id",
      "replicate"
    )
  )
  expect_identical(truth$surface, "biv_gaussian_q4_location")
  expect_named(truth$beta_mu1, c("(Intercept)", "x"))
  expect_named(truth$beta_mu2, c("(Intercept)", "x"))
  expect_named(truth$sd_mu, phase18_biv_gaussian_q4_location_sd_names())
  expect_named(truth$cor_mu, phase18_biv_gaussian_q4_location_cor_names())
})

test_that("Phase 18 bivariate Gaussian q4 location smoke runner summarises output", {
  source_phase18_biv_gaussian_q4_location()

  result_dir <- tempfile("phase18-biv-gaussian-q4-location-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_q4_location_conditions(
    n_id = 36L,
    n_each = 5L,
    residual_rho = 0.10
  )

  out <- phase18_summarise_biv_gaussian_q4_location_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 239L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "biv_gaussian_q4_location")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 17L)
  expect_equal(nrow(out$aggregate), 17L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_setequal(
    out$run$summary$parameter_class,
    c(
      "fixed_mu1",
      "fixed_mu2",
      "residual_sigma",
      "random_sd",
      "derived_random_correlation",
      "residual_rho12"
    )
  )
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu1:(Intercept)",
      "mu1:x",
      "mu2:(Intercept)",
      "mu2:x",
      "sigma1",
      "sigma2",
      paste0("sd:mu:", phase18_biv_gaussian_q4_location_sd_names()),
      paste0("cor:re_cov:", phase18_biv_gaussian_q4_location_cor_names()),
      "rho12"
    )
  )
  class_by_parameter <- stats::setNames(
    out$run$summary$parameter_class,
    out$run$summary$parameter
  )
  expect_identical(
    class_by_parameter[[
      "cor:re_cov:cor(mu1:x,mu2:x | p | id)"
    ]],
    "derived_random_correlation"
  )
  expect_identical(class_by_parameter[["rho12"]], "residual_rho12")
  expect_false(any(
    out$run$summary$parameter_class == "residual_rho12" &
      grepl("^cor:re_cov:", out$run$summary$parameter)
  ))
  expect_true(all(out$run$summary$converged))
  expect_type(out$run$summary$pdHess, "logical")
  expect_false(anyNA(out$run$summary$pdHess))
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "biv_gaussian_q4_location_001",
    1L
  )))
})

test_that("Phase 18 bivariate Gaussian q4 location grid writer saves artifacts", {
  source_phase18_biv_gaussian_q4_location()

  output_dir <- tempfile("phase18-biv-gaussian-q4-location-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_q4_location_conditions(
    n_id = 36L,
    n_each = 5L,
    residual_rho = 0.10
  )

  out <- phase18_write_biv_gaussian_q4_location_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 239L
  )

  expect_identical(out$surface, "biv_gaussian_q4_location_grid")
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_equal(nrow(out$summary$manifest), 1L)
  aggregate <- utils::read.csv(out$paths$aggregate_csv, check.names = FALSE)
  replicates <- utils::read.csv(out$paths$replicate_csv, check.names = FALSE)
  expect_equal(nrow(aggregate), 17L)
  expect_equal(nrow(replicates), 17L)
  expect_identical(
    replicates$parameter_class[match("rho12", replicates$parameter)],
    "residual_rho12"
  )
  expect_true(all(
    replicates$parameter_class[grepl("^cor:re_cov:", replicates$parameter)] ==
      "derived_random_correlation"
  ))
  expect_false(any(
    aggregate$parameter_class == "residual_rho12" &
      grepl("^cor:re_cov:", aggregate$parameter)
  ))
  expect_equal(nrow(utils::read.csv(out$paths$manifest_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$failures_csv)), 0L)
  expect_error(
    phase18_write_biv_gaussian_q4_location_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 239L
    ),
    "already exists"
  )
  expect_silent(phase18_write_biv_gaussian_q4_location_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 239L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 bivariate Gaussian q4 location helpers reject malformed inputs", {
  source_phase18_biv_gaussian_q4_location()

  expect_error(
    phase18_dgp_biv_gaussian_q4_location(0L, 5L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q4_location(12L, 5L, residual_rho = 1),
    "absolute value below 1"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q4_location(
      12L,
      5L,
      sd_mu = c(1, 1, 1)
    ),
    "length 4"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q4_location_cell(
      data.frame(cell_id = "bad"),
      seed = 239L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})
