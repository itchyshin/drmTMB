source_phase18_biv_gaussian_q8_endpoint <- function() {
  env <- parent.frame()
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R",
    "sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R",
    "sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_summary_biv_gaussian_q8_endpoint_smoke.R",
    "sim/run/sim_write_biv_gaussian_q8_endpoint_grid.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 bivariate Gaussian q8 endpoint DGP is seeded", {
  source_phase18_biv_gaussian_q8_endpoint()

  conditions <- phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 12L,
    n_each = 6L
  )
  dat <- phase18_dgp_biv_gaussian_q8_endpoint(
    n_id = 12L,
    n_each = 6L,
    seed = 241L,
    cell_id = "biv_gaussian_q8_endpoint_001",
    replicate = 1L
  )
  again <- phase18_dgp_biv_gaussian_q8_endpoint(
    n_id = 12L,
    n_each = 6L,
    seed = 241L,
    cell_id = "biv_gaussian_q8_endpoint_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 1L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 72L)
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
  expect_identical(truth$surface, "biv_gaussian_q8_endpoint")
  expect_named(truth$beta_mu1, c("(Intercept)", "x"))
  expect_named(truth$beta_mu2, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma1, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma2, c("(Intercept)", "x"))
  expect_named(truth$sd_mu, phase18_biv_gaussian_q8_endpoint_sd_mu_names())
  expect_named(
    truth$sd_sigma,
    phase18_biv_gaussian_q8_endpoint_sd_sigma_names()
  )
  expect_named(truth$cor_re_cov, phase18_biv_gaussian_q8_endpoint_cor_names())
})

test_that("Phase 18 bivariate Gaussian q8 endpoint smoke runner summarises output", {
  source_phase18_biv_gaussian_q8_endpoint()

  result_dir <- tempfile("phase18-biv-gaussian-q8-endpoint-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 24L,
    n_each = 6L
  )

  out <- phase18_summarise_biv_gaussian_q8_endpoint_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260634L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "biv_gaussian_q8_endpoint")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 45L)
  expect_equal(nrow(out$aggregate), 45L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_setequal(
    out$run$summary$parameter_class,
    c(
      "fixed_mu1",
      "fixed_mu2",
      "fixed_sigma1",
      "fixed_sigma2",
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
      "sigma1:(Intercept)",
      "sigma1:x",
      "sigma2:(Intercept)",
      "sigma2:x",
      paste0("sd:mu:", phase18_biv_gaussian_q8_endpoint_sd_mu_names()),
      paste0("sd:sigma:", phase18_biv_gaussian_q8_endpoint_sd_sigma_names()),
      paste0("cor:re_cov:", phase18_biv_gaussian_q8_endpoint_cor_names()),
      "rho12"
    )
  )
  class_by_parameter <- stats::setNames(
    out$run$summary$parameter_class,
    out$run$summary$parameter
  )
  expect_identical(
    class_by_parameter[[
      "cor:re_cov:cor(sigma1:x,sigma2:x | p | id)"
    ]],
    "derived_random_correlation"
  )
  expect_identical(class_by_parameter[["rho12"]], "residual_rho12")
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "biv_gaussian_q8_endpoint_001",
    1L
  )))
})

test_that("Phase 18 bivariate Gaussian q8 endpoint grid writer saves artifacts", {
  source_phase18_biv_gaussian_q8_endpoint()

  output_dir <- tempfile("phase18-biv-gaussian-q8-endpoint-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_q8_endpoint_conditions(
    n_id = 24L,
    n_each = 6L
  )

  out <- phase18_write_biv_gaussian_q8_endpoint_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260634L
  )

  expect_identical(out$surface, "biv_gaussian_q8_endpoint_grid")
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_equal(nrow(out$summary$manifest), 1L)
  aggregate <- utils::read.csv(out$paths$aggregate_csv, check.names = FALSE)
  replicates <- utils::read.csv(out$paths$replicate_csv, check.names = FALSE)
  expect_equal(nrow(aggregate), 45L)
  expect_equal(nrow(replicates), 45L)
  expect_true(all(
    replicates$parameter_class[grepl("^cor:re_cov:", replicates$parameter)] ==
      "derived_random_correlation"
  ))
  expect_equal(nrow(utils::read.csv(out$paths$manifest_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$failures_csv)), 0L)
  expect_error(
    phase18_write_biv_gaussian_q8_endpoint_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 20260634L
    ),
    "already exists"
  )
  expect_silent(phase18_write_biv_gaussian_q8_endpoint_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260634L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 bivariate Gaussian q8 endpoint helpers reject malformed inputs", {
  source_phase18_biv_gaussian_q8_endpoint()

  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint(0L, 6L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint(12L, 6L, residual_rho = 1),
    "absolute value below 1"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint(
      12L,
      6L,
      sd_mu = c(1, 1, 1)
    ),
    "length 4"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint(
      12L,
      6L,
      cor_re_cov = rep(1, 28L)
    ),
    "absolute value below 1"
  )
  expect_error(
    phase18_dgp_biv_gaussian_q8_endpoint_cell(
      data.frame(cell_id = "bad"),
      seed = 241L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})
