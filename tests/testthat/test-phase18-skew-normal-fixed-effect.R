source_phase18_skew_normal_fe <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_skew_normal_fixed_effect.R",
    "sim/fit/sim_summarise_skew_normal_fixed_effect.R",
    "sim/run/sim_run_skew_normal_fixed_effect_smoke.R",
    "sim/run/sim_summary_skew_normal_fixed_effect_smoke.R",
    "sim/run/sim_write_skew_normal_fixed_effect_grid.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 skew-normal fixed-effect DGP is seeded and regime-aware", {
  source_phase18_skew_normal_fe()

  conditions <- phase18_skew_normal_fe_conditions(
    skew_regime = c("left", "symmetric", "right"),
    n = 120L,
    rho_xz = 0.10
  )
  left <- phase18_dgp_skew_normal_fe(
    n = 120L,
    skew_regime = "left",
    beta_nu = c("(Intercept)" = -1.2),
    rho_xz = 0.10,
    seed = 20260636L,
    cell_id = "skew_normal_fixed_effect_001",
    replicate = 1L
  )
  again <- phase18_dgp_skew_normal_fe(
    n = 120L,
    skew_regime = "left",
    beta_nu = c("(Intercept)" = -1.2),
    rho_xz = 0.10,
    seed = 20260636L,
    cell_id = "skew_normal_fixed_effect_001",
    replicate = 1L
  )

  expect_equal(nrow(conditions), 3L)
  expect_setequal(conditions$skew_regime, c("left", "symmetric", "right"))
  expect_equal(
    stats::setNames(
      conditions$beta_nu_intercept,
      conditions$skew_regime
    )[c("left", "symmetric", "right")],
    c(left = -1.2, symmetric = 0, right = 1.2)
  )
  expect_equal(left, again)
  expect_equal(nrow(left), 120L)
  expect_named(
    left,
    c(
      "y",
      "x",
      "z",
      "mu",
      "eta_sigma",
      "sigma",
      "nu",
      "skew_regime",
      "cell_id",
      "replicate"
    )
  )
  expect_true(all(is.finite(left$y)))
  expect_true(all(left$sigma > 0))
  expect_equal(unique(left$skew_regime), "left")
  expect_lt(unique(left$nu), 0)
  expect_identical(attr(left, "truth")$surface, "skew_normal_fixed_effect")
  expect_named(attr(left, "truth")$beta_nu, "(Intercept)")

  false_positive <- phase18_skew_normal_fe_false_positive_conditions(
    n = 120L,
    beta_sigma_z = c(0, 0.20),
    rho_xz = c(0, 0.10)
  )
  expect_equal(nrow(false_positive), 4L)
  expect_equal(unique(false_positive$skew_regime), "symmetric")
  expect_equal(unique(false_positive$beta_nu_intercept), 0)
  expect_setequal(false_positive$beta_sigma_z, c(0, 0.20))
})

test_that("Phase 18 skew-normal fixed-effect smoke returns diagnostic artifacts", {
  source_phase18_skew_normal_fe()
  conditions <- phase18_skew_normal_fe_conditions(
    skew_regime = "right",
    n = 320L,
    rho_xz = 0.10
  )

  summary <- phase18_summarise_skew_normal_fe_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260637L
  )

  expect_equal(summary$surface, "skew_normal_fixed_effect")
  expect_equal(nrow(summary$replicates), 5L)
  expect_equal(nrow(summary$aggregate), 5L)
  expect_equal(nrow(summary$manifest), 1L)
  expect_equal(nrow(summary$failures), 0L)
  expect_equal(nrow(summary$diagnostics), 1L)
  expect_equal(summary$replicates$artifact_grain, rep("replicate", 5L))
  expect_equal(summary$aggregate$artifact_grain, rep("aggregate", 5L))
  expect_setequal(
    summary$replicates$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma:(Intercept)",
      "sigma:z",
      "nu:(Intercept)"
    )
  )
  expect_true(all(summary$replicates$converged))
  expect_true(all(is.finite(summary$replicates$estimate)))
  expect_true(all(is.finite(summary$replicates$error)))
  expect_equal(unique(summary$replicates$skew_normal_nu_status), "ok")
  expect_equal(summary$diagnostics$n_fit, 1L)
  expect_equal(summary$diagnostics$convergence_rate, 1)
  expect_true(is.finite(summary$diagnostics$max_fitted_nu_abs))
})

test_that("Phase 18 skew-normal fixed-effect grid writer creates table artifacts", {
  source_phase18_skew_normal_fe()
  output_dir <- tempfile("phase18-skew-normal-fe-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_skew_normal_fe_conditions(
    skew_regime = "symmetric",
    n = 300L,
    rho_xz = 0.10
  )

  out <- phase18_write_skew_normal_fe_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260638L,
    cores = 10L
  )

  expect_equal(out$surface, "skew_normal_fixed_effect_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 5L)
  expect_equal(nrow(out$summary$aggregate), 5L)
  expect_equal(nrow(out$summary$diagnostics), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 5L)
  expect_equal(nrow(utils::read.csv(out$paths$diagnostics_csv)), 1L)
  expect_error(
    phase18_write_skew_normal_fe_grid_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 20260638L
    ),
    "already exists"
  )
})

test_that("Phase 18 skew-normal fixed-effect false-positive artifacts are explicit", {
  source_phase18_skew_normal_fe()
  conditions <- phase18_skew_normal_fe_false_positive_conditions(
    n = 300L,
    beta_sigma_z = 0.15,
    rho_xz = 0.10
  )

  summary <- phase18_summarise_skew_normal_fe_false_positive_smoke(
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260640L
  )

  expect_equal(summary$surface, "skew_normal_fixed_effect_false_positive")
  expect_equal(nrow(summary$replicates), 5L)
  expect_equal(nrow(summary$false_positive_summary), 1L)
  expect_equal(unique(summary$replicates$skew_regime), "symmetric")
  expect_equal(
    summary$replicates$truth[
      summary$replicates$parameter == "nu:(Intercept)"
    ],
    0
  )
  expect_equal(unique(summary$replicates$skew_normal_nu_status), "ok")
  expect_true(is.finite(summary$false_positive_summary$max_fitted_nu_abs))
  expect_equal(summary$false_positive_summary$nu_abs_threshold, 0.5)

  synthetic <- summary$replicates
  synthetic$fitted_nu_max_abs <- rep(
    c(0.20, 0.80),
    length.out = nrow(synthetic)
  )
  synthetic$cell_id <- rep(c("a", "b"), length.out = nrow(synthetic))
  synthetic$replicate <- rep(c(1L, 1L), length.out = nrow(synthetic))
  synthetic$skew_normal_nu_status <- rep(
    c("ok", "note"),
    length.out = nrow(synthetic)
  )
  synthetic_summary <- phase18_summarise_skew_normal_fe_false_positive(
    synthetic,
    by = c("surface", "skew_regime"),
    nu_abs_threshold = 0.5
  )
  expect_equal(synthetic_summary$n_fit, 2L)
  expect_equal(synthetic_summary$nu_false_positive_rate, 0.5)
  expect_equal(synthetic_summary$skew_normal_nu_note_rate, 0.5)
  expect_error(
    phase18_summarise_skew_normal_fe_false_positive(
      synthetic,
      nu_abs_threshold = 0
    ),
    "nu_abs_threshold"
  )
})

test_that("Phase 18 skew-normal fixed-effect false-positive writer saves artifacts", {
  source_phase18_skew_normal_fe()
  output_dir <- tempfile("phase18-skew-normal-fe-false-positive-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_skew_normal_fe_false_positive_conditions(
    n = 300L,
    beta_sigma_z = 0.15,
    rho_xz = 0.10
  )

  out <- phase18_write_skew_normal_fe_false_positive_grid_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260641L,
    cores = 10L
  )

  expect_equal(out$surface, "skew_normal_fixed_effect_false_positive_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 5L)
  expect_equal(nrow(out$summary$diagnostics), 1L)
  expect_equal(nrow(out$summary$false_positive_summary), 1L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 5L)
  expect_equal(
    nrow(utils::read.csv(out$paths$false_positive_summary_csv)),
    1L
  )
})

test_that("Phase 18 skew-normal fixed-effect helpers reject malformed inputs", {
  source_phase18_skew_normal_fe()

  expect_error(
    phase18_skew_normal_fe_conditions(skew_regime = "extreme"),
    "skew_regime"
  )
  expect_error(
    phase18_dgp_skew_normal_fe(n = 0L, skew_regime = "right"),
    "n"
  )
  expect_error(
    phase18_dgp_skew_normal_fe(
      n = 80L,
      skew_regime = "right",
      beta_nu = c(a = 1)
    ),
    "beta_nu"
  )
  expect_error(
    phase18_dgp_skew_normal_fe(n = 80L, skew_regime = "right", rho_xz = 2),
    "rho_xz"
  )
  expect_error(
    phase18_dgp_skew_normal_fe_cell(
      data.frame(cell_id = "bad"),
      seed = 241L,
      cell_id = "bad",
      replicate = 1L
    ),
    "must contain"
  )
  expect_error(
    phase18_write_skew_normal_fe_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_skew_normal_fe_false_positive_grid_outputs(output_dir = ""),
    "output_dir"
  )
})
