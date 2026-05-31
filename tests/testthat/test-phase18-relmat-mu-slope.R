source_phase18_relmat_mu_slope <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_relmat_mu_slope.R",
    "sim/fit/sim_summarise_relmat_mu_slope.R",
    "sim/run/sim_run_relmat_mu_slope_smoke.R",
    "sim/run/sim_summary_relmat_mu_slope_smoke.R",
    "sim/run/sim_write_relmat_mu_slope_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 relmat mu slope DGP is seeded and self-describing", {
  source_phase18_relmat_mu_slope()

  conditions <- phase18_relmat_mu_slope_conditions(
    n_id = 8L,
    n_each = 6L
  )
  dat <- phase18_dgp_relmat_mu_slope(
    n_id = 8L,
    n_each = 6L,
    seed = 244L,
    cell_id = "relmat_mu_slope_001",
    replicate = 1L
  )
  again <- phase18_dgp_relmat_mu_slope(
    n_id = 8L,
    n_each = 6L,
    seed = 244L,
    cell_id = "relmat_mu_slope_001",
    replicate = 1L
  )
  truth <- attr(dat, "truth")

  expect_equal(nrow(conditions), 1L)
  expect_equal(dat, again)
  expect_equal(nrow(dat), 48L)
  expect_named(
    dat,
    c("y", "x", "id", "mu", "sigma", "cell_id", "replicate")
  )
  expect_identical(truth$surface, "relmat_mu_slope")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(
    truth$sd,
    c("relmat(1 | id)", "relmat(0 + x | id)")
  )
  expect_equal(dim(truth$K), c(8L, 8L))
  expect_equal(dim(truth$Q), c(8L, 8L))
  expect_equal(row.names(truth$K), paste0("id_", seq_len(8L)))
  expect_named(truth$relmat_intercept, paste0("id_", seq_len(8L)))
  expect_named(truth$relmat_slope, paste0("id_", seq_len(8L)))
  expect_length(truth$relmat_intercept, 8L)
  expect_length(truth$relmat_slope, 8L)

  fit <- phase18_fit_relmat_mu_slope(dat, conditions)
  expect_equal(fit$corpars, list())
  expect_named(
    fit$sdpars$mu,
    c("relmat(1 | id)", "relmat(0 + x | id)")
  )
})

test_that("Phase 18 relmat mu slope smoke runner summarises output", {
  source_phase18_relmat_mu_slope()

  result_dir <- tempfile("phase18-relmat-mu-slope-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))
  conditions <- phase18_relmat_mu_slope_conditions(
    n_id = 8L,
    n_each = 7L
  )

  out <- phase18_summarise_relmat_mu_slope_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 244L,
    result_dir = result_dir
  )

  expect_identical(out$surface, "relmat_mu_slope")
  expect_equal(out$run$parallel$backend, "none")
  expect_equal(out$run$parallel$cores, 1L)
  expect_equal(nrow(out$run$summary), 5L)
  expect_equal(nrow(out$aggregate), 5L)
  expect_equal(nrow(out$manifest), 1L)
  expect_identical(out$manifest$status, "ok")
  expect_equal(nrow(out$failures), 0L)
  expect_equal(out$aggregate$n_replicate, rep(1L, 5L))
  expect_setequal(
    out$run$summary$parameter_class,
    c("fixed_mu", "residual_sigma", "relmat_sd")
  )
  expect_equal(
    out$run$summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma",
      "sd:mu:relmat(1 | id)",
      "sd:mu:relmat(0 + x | id)"
    )
  )
  expect_true(all(out$run$summary$converged))
  expect_type(out$run$summary$pdHess, "logical")
  expect_false(anyNA(out$run$summary$pdHess))
  expect_true(all(is.finite(out$run$summary$estimate)))
  expect_true(all(is.finite(out$run$summary$error)))
  expect_true(all(
    is.na(out$run$summary$std.error) | out$run$summary$std.error > 0
  ))
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "relmat_mu_slope_001",
    1L
  )))
})

test_that("Phase 18 relmat mu slope grid writer creates artifacts", {
  source_phase18_relmat_mu_slope()

  output_dir <- tempfile("phase18-relmat-mu-slope-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_relmat_mu_slope_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_relmat_mu_slope_conditions(
      n_id = 8L,
      n_each = 7L
    ),
    n_rep = 1L,
    master_seed = 245L,
    cores = 10L
  )

  expect_equal(out$surface, "relmat_mu_slope_grid")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(all(out$artifact_manifest$exists))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 5L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 5L)
  expect_error(
    phase18_write_relmat_mu_slope_grid_outputs(
      output_dir = output_dir,
      conditions = phase18_relmat_mu_slope_conditions(
        n_id = 8L,
        n_each = 7L
      ),
      n_rep = 1L,
      master_seed = 245L
    ),
    "already exists"
  )
})

test_that("Phase 18 relmat mu slope helpers reject malformed inputs", {
  source_phase18_relmat_mu_slope()

  expect_error(
    phase18_dgp_relmat_mu_slope(1L, 5L),
    "at least 2"
  )
  expect_error(
    phase18_dgp_relmat_mu_slope(8L, 1L),
    "at least 2"
  )
  expect_error(
    phase18_dgp_relmat_mu_slope(8L, 5L, sd = c(0.4, -0.2)),
    "positive"
  )
  expect_error(
    phase18_dgp_relmat_mu_slope(
      8L,
      5L,
      matrix_decay = 1
    ),
    "matrix_decay"
  )
  expect_error(
    phase18_dgp_relmat_mu_slope_cell(
      data.frame(cell_id = "bad"),
      seed = 244L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_write_relmat_mu_slope_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})
