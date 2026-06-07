source_phase18_biv_gaussian_mu_sigma_slope <- function() {
  env <- parent.frame()
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_biv_gaussian_mu_sigma_slope.R",
    "sim/fit/sim_summarise_biv_gaussian_mu_sigma_slope.R",
    "sim/run/sim_run_biv_gaussian_mu_sigma_slope_smoke.R",
    "sim/run/sim_summary_biv_gaussian_mu_sigma_slope_smoke.R",
    "sim/run/sim_write_biv_gaussian_mu_sigma_slope_grid.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 bivariate Gaussian mu/sigma slope DGP is seeded", {
  source_phase18_biv_gaussian_mu_sigma_slope()

  conditions <- phase18_biv_gaussian_mu_sigma_slope_conditions(
    n_id = 12L,
    n_each = 8L
  )
  dat <- phase18_dgp_biv_gaussian_mu_sigma_slope(
    n_id = 12L,
    n_each = 8L,
    seed = 241L,
    cell_id = "biv_gaussian_mu_sigma_slope_001",
    replicate = 1L
  )
  again <- phase18_dgp_biv_gaussian_mu_sigma_slope(
    n_id = 12L,
    n_each = 8L,
    seed = 241L,
    cell_id = "biv_gaussian_mu_sigma_slope_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 1L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 96L)
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
  expect_identical(truth$surface, "biv_gaussian_mu_sigma_slope")
  expect_named(truth$beta_mu1, c("(Intercept)", "x"))
  expect_named(truth$beta_mu2, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma1, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma2, c("(Intercept)", "x"))
  expect_named(
    truth$sd_mu,
    phase18_biv_gaussian_mu_sigma_slope_sd_mu_name()
  )
  expect_named(
    truth$sd_sigma,
    phase18_biv_gaussian_mu_sigma_slope_sd_sigma_name()
  )
  expect_named(
    truth$cor_mu_sigma,
    phase18_biv_gaussian_mu_sigma_slope_cor_name()
  )
  expect_named(truth$residual_rho, "rho12")
})

test_that("Phase 18 bivariate Gaussian mu/sigma slope smoke runner summarises output", {
  source_phase18_biv_gaussian_mu_sigma_slope()

  result_dir <- tempfile("phase18-biv-gaussian-mu-sigma-slope-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_mu_sigma_slope_conditions(
    n_id = 72L,
    n_each = 10L,
    residual_rho = 0.18
  )

  out <- phase18_summarise_biv_gaussian_mu_sigma_slope_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260629L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "biv_gaussian_mu_sigma_slope")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 12L)
  expect_equal(nrow(out$aggregate), 12L)
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
      paste0("sd:mu:", phase18_biv_gaussian_mu_sigma_slope_sd_mu_name()),
      paste0(
        "sd:sigma:",
        phase18_biv_gaussian_mu_sigma_slope_sd_sigma_name()
      ),
      paste0("cor:mu_sigma:", phase18_biv_gaussian_mu_sigma_slope_cor_name()),
      "rho12"
    )
  )
  class_by_parameter <- stats::setNames(
    out$run$summary$parameter_class,
    out$run$summary$parameter
  )
  expect_identical(
    class_by_parameter[[
      "cor:mu_sigma:cor(mu1:x,sigma1:x | p | id)"
    ]],
    "derived_random_correlation"
  )
  expect_identical(class_by_parameter[["rho12"]], "residual_rho12")
  expect_false(any(
    out$run$summary$parameter_class == "residual_rho12" &
      grepl("^cor:mu_sigma:", out$run$summary$parameter)
  ))
  expect_true(all(out$run$summary$converged))
  expect_type(out$run$summary$pdHess, "logical")
  expect_false(anyNA(out$run$summary$pdHess))
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "biv_gaussian_mu_sigma_slope_001",
    1L
  )))
})

test_that("Phase 18 bivariate Gaussian mu/sigma slope grid writer saves artifacts", {
  source_phase18_biv_gaussian_mu_sigma_slope()

  output_dir <- tempfile("phase18-biv-gaussian-mu-sigma-slope-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_biv_gaussian_mu_sigma_slope_conditions(
    n_id = 72L,
    n_each = 10L,
    residual_rho = 0.18
  )

  out <- phase18_write_biv_gaussian_mu_sigma_slope_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260629L
  )

  expect_identical(out$surface, "biv_gaussian_mu_sigma_slope_grid")
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_equal(nrow(out$summary$manifest), 1L)
  aggregate <- utils::read.csv(out$paths$aggregate_csv, check.names = FALSE)
  replicates <- utils::read.csv(out$paths$replicate_csv, check.names = FALSE)
  expect_equal(nrow(aggregate), 12L)
  expect_equal(nrow(replicates), 12L)
  expect_identical(
    replicates$parameter_class[match("rho12", replicates$parameter)],
    "residual_rho12"
  )
  expect_true(all(
    replicates$parameter_class[grepl("^cor:mu_sigma:", replicates$parameter)] ==
      "derived_random_correlation"
  ))
  expect_false(any(
    aggregate$parameter_class == "residual_rho12" &
      grepl("^cor:mu_sigma:", aggregate$parameter)
  ))
  expect_equal(nrow(utils::read.csv(out$paths$manifest_csv)), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$failures_csv)), 0L)
  expect_error(
    phase18_write_biv_gaussian_mu_sigma_slope_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 20260629L
    ),
    "already exists"
  )
  expect_silent(phase18_write_biv_gaussian_mu_sigma_slope_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260629L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 bivariate Gaussian mu/sigma slope helpers reject malformed inputs", {
  source_phase18_biv_gaussian_mu_sigma_slope()

  expect_error(
    phase18_dgp_biv_gaussian_mu_sigma_slope(0L, 8L),
    "positive whole number"
  )
  expect_error(
    phase18_dgp_biv_gaussian_mu_sigma_slope(12L, 8L, residual_rho = 1),
    "absolute value below 1"
  )
  expect_error(
    phase18_dgp_biv_gaussian_mu_sigma_slope(12L, 8L, cor_mu_sigma = 1),
    "absolute value below 1"
  )
  expect_error(
    phase18_dgp_biv_gaussian_mu_sigma_slope(12L, 8L, sd_mu = c(1, 1)),
    "length 1"
  )
  expect_error(
    phase18_dgp_biv_gaussian_mu_sigma_slope_cell(
      data.frame(cell_id = "bad"),
      seed = 241L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
})
