source_phase18_model_selection <- function(env = parent.frame()) {
  files <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/dgp/sim_dgp_model_selection.R",
    "sim/fit/sim_summarise_model_selection.R",
    "sim/run/sim_run_model_selection_smoke.R",
    "sim/run/sim_write_model_selection_smoke.R"
  )
  for (file in files) {
    source(system.file(file, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 model-selection conditions define paired AIC/BIC cases", {
  source_phase18_model_selection()

  conditions <- phase18_model_selection_conditions(
    n_continuous = 60L,
    n_count = 70L
  )

  expect_equal(nrow(conditions), 6L)
  expect_equal(conditions$cell_id, sprintf("model_selection_%03d", 1:6))
  expect_setequal(
    conditions$candidate_set,
    c("gaussian_student", "nb2_zinb2", "sigma_formula")
  )
  expect_equal(
    conditions$selection_target,
    c("Gaussian", "Student-t", "NB2", "ZINB2", "sigma ~ 1", "sigma ~ x")
  )
})

test_that("Phase 18 model-selection DGP records selection truth", {
  source_phase18_model_selection()

  cell <- phase18_model_selection_conditions(n_continuous = 48L)[2L, ,
    drop = FALSE
  ]
  dat <- phase18_dgp_model_selection_cell(
    cell = cell,
    seed = 20260609L,
    cell_id = cell$cell_id[[1L]],
    replicate = 1L
  )
  truth <- attr(dat, "truth", exact = TRUE)

  expect_equal(nrow(dat), 48L)
  expect_equal(truth$surface, "model_selection")
  expect_equal(truth$candidate_set, "gaussian_student")
  expect_equal(truth$selection_target, "Student-t")
  expect_true(all(c("y", "x", "mu", "sigma") %in% names(dat)))
})

test_that("Phase 18 model-selection summary computes criterion choices", {
  source_phase18_model_selection()

  replicates <- data.frame(
    scenario = rep("heavy_tail", 4L),
    candidate_set = rep("gaussian_student", 4L),
    selection_target = rep("Student-t", 4L),
    replicate = rep(1:2, each = 2L),
    candidate = rep(c("Gaussian", "Student-t"), 2L),
    selected_aic = c(FALSE, TRUE, TRUE, FALSE),
    selected_bic = c(FALSE, TRUE, TRUE, FALSE),
    truth_selected_aic = c(FALSE, TRUE, FALSE, FALSE),
    truth_selected_bic = c(FALSE, TRUE, FALSE, FALSE),
    delta_aic = c(4, 0, 0, 1),
    delta_bic = c(3, 0, 0, 2),
    converged = TRUE,
    pdHess = c(TRUE, TRUE, TRUE, FALSE),
    warning_count = c(0L, 0L, 0L, 1L),
    stringsAsFactors = FALSE
  )
  summary <- phase18_summarise_model_selection_choices(replicates)

  expect_equal(nrow(summary), 1L)
  expect_equal(summary$n_replicate, 2L)
  expect_equal(summary$aic_truth_selection_rate, 0.5)
  expect_equal(summary$bic_truth_selection_rate, 0.5)
  expect_equal(summary$candidate_convergence_rate, 1)
  expect_equal(summary$candidate_pdHess_rate, 0.75)
  expect_equal(summary$candidate_warning_rate, 0.25)
})

test_that("Phase 18 model-selection writer saves smoke artifacts", {
  source_phase18_model_selection()

  output_dir <- tempfile("phase18-model-selection-smoke-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_model_selection_conditions(n_continuous = 48L)[
    5L, ,
    drop = FALSE
  ]

  out <- phase18_write_model_selection_smoke_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260610L
  )

  expect_equal(out$surface, "model_selection_smoke")
  expect_equal(nrow(out$candidates), 2L)
  expect_equal(nrow(out$selection_summary), 1L)
  expect_equal(nrow(out$manifest), 1L)
  expect_true(all(out$artifact_manifest$exists))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_error(
    phase18_write_model_selection_smoke_outputs(
      output_dir = output_dir,
      conditions = conditions,
      n_rep = 1L,
      master_seed = 20260610L
    ),
    "already exists"
  )
})

test_that("Phase 18 model-selection writer can skip per-replicate RDS output", {
  source_phase18_model_selection()

  output_dir <- tempfile("phase18-model-selection-summary-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  conditions <- phase18_model_selection_conditions(n_continuous = 48L)[
    5L, ,
    drop = FALSE
  ]

  out <- phase18_write_model_selection_smoke_outputs(
    output_dir = output_dir,
    conditions = conditions,
    n_rep = 1L,
    master_seed = 20260611L,
    save_results = FALSE
  )

  expect_null(out$result_dir)
  expect_false(dir.exists(file.path(out$output_dir, "results")))
  expect_equal(nrow(out$candidates), 2L)
  expect_equal(nrow(out$manifest), 1L)
  expect_true(file.exists(out$paths$selection_summary_csv))
})
