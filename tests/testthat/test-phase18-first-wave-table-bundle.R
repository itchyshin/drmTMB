source_phase18_first_wave_table_bundle <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_first_wave_table_bundle.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 first-wave table bundle collects grid artifact tables", {
  source_phase18_first_wave_table_bundle()
  root <- tempfile("phase18-first-wave-tables-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE))

  first_aggregate <- file.path(root, "first-aggregate.csv")
  second_aggregate <- file.path(root, "second-aggregate.csv")
  first_replicates <- file.path(root, "first-replicates.csv")
  first_failures <- file.path(root, "first-failures.csv")
  write.csv(
    data.frame(
      parameter = "mu:x",
      bias = 0.02,
      artifact_grain = "aggregate"
    ),
    first_aggregate,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      parameter = "sigma:z",
      rmse = 0.11,
      artifact_grain = "aggregate"
    ),
    second_aggregate,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      parameter = "mu:x",
      replicate = 1:2,
      estimate = c(0.9, 1.1),
      artifact_grain = "replicate"
    ),
    first_replicates,
    row.names = FALSE
  )
  write.csv(
    data.frame(
      cell_id = character(),
      severity = character(),
      message = character()
    ),
    first_failures,
    row.names = FALSE
  )
  grid_outputs <- list(
    list(
      surface = "gaussian_ls_grid",
      paths = list(
        aggregate_csv = first_aggregate,
        replicate_csv = first_replicates,
        failures_csv = first_failures
      )
    ),
    list(
      surface = "student_shape_grid",
      paths = list(aggregate_csv = second_aggregate)
    )
  )

  out <- phase18_write_first_wave_table_bundle(
    output_dir = file.path(root, "bundle"),
    grid_outputs = grid_outputs,
    artifacts = c(
      "aggregate_csv",
      "replicate_csv",
      "failures_csv",
      "wald_coverage_csv"
    )
  )

  aggregate <- out$tables$aggregate_csv
  replicates <- out$tables$replicate_csv
  failures <- out$tables$failures_csv
  missing <- out$tables$wald_coverage_csv
  grain_status <- out$grain_status

  expect_equal(out$surface, "phase18_first_wave_table_bundle")
  expect_equal(nrow(aggregate), 2L)
  expect_equal(nrow(replicates), 2L)
  expect_equal(
    aggregate$source_surface,
    c("gaussian_ls_grid", "student_shape_grid")
  )
  expect_equal(aggregate$source_artifact, rep("aggregate_csv", 2L))
  expect_equal(
    names(aggregate)[seq_len(2L)],
    c("source_surface", "source_artifact")
  )
  expect_true("bias" %in% names(aggregate))
  expect_true("rmse" %in% names(aggregate))
  expect_true(is.na(aggregate$rmse[[1L]]))
  expect_true(is.na(aggregate$bias[[2L]]))
  expect_equal(
    unique(replicates$source_artifact),
    "replicate_csv"
  )
  expect_true(all(replicates$artifact_grain == "replicate"))
  expect_equal(nrow(failures), 0L)
  expect_equal(names(failures), c("source_surface", "source_artifact"))
  expect_equal(nrow(missing), 0L)
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(file.exists(out$paths$artifact_grain_status_csv))
  expect_equal(
    grain_status$grain_status[
      grain_status$source_artifact == "replicate_csv" &
        grain_status$source_surface == "gaussian_ls_grid"
    ],
    "replicate_ready"
  )
  expect_true(
    grain_status$replicate_cloud_allowed[
      grain_status$source_artifact == "replicate_csv" &
        grain_status$source_surface == "gaussian_ls_grid"
    ]
  )
  expect_equal(
    grain_status$grain_status[
      grain_status$source_artifact == "aggregate_csv" &
        grain_status$source_surface == "student_shape_grid"
    ],
    "aggregate_only"
  )
  expect_false(
    grain_status$replicate_cloud_allowed[
      grain_status$source_artifact == "aggregate_csv" &
        grain_status$source_surface == "student_shape_grid"
    ]
  )
  expect_equal(
    grain_status$grain_status[
      grain_status$source_artifact == "wald_coverage_csv"
    ],
    rep("missing_artifact", 2L)
  )
  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = file.path(root, "bundle"),
      grid_outputs = grid_outputs,
      artifacts = "aggregate_csv"
    ),
    "already exists"
  )
  expect_silent(phase18_write_first_wave_table_bundle(
    output_dir = file.path(root, "bundle"),
    grid_outputs = grid_outputs,
    artifacts = "aggregate_csv",
    overwrite = TRUE
  ))
})

test_that("Phase 18 first-wave table bundle inventories artifact grain", {
  source_phase18_first_wave_table_bundle()
  root <- tempfile("phase18-first-wave-grain-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE))

  aggregate <- file.path(root, "aggregate.csv")
  replicates <- file.path(root, "replicates.csv")
  mixed <- file.path(root, "mixed.csv")
  legacy <- file.path(root, "legacy.csv")
  empty <- file.path(root, "empty.csv")
  write.csv(
    data.frame(metric = "bias", artifact_grain = "aggregate"),
    aggregate,
    row.names = FALSE
  )
  write.csv(
    data.frame(replicate = 1:2, artifact_grain = "replicate"),
    replicates,
    row.names = FALSE
  )
  write.csv(
    data.frame(row = 1:2, artifact_grain = c("aggregate", "replicate")),
    mixed,
    row.names = FALSE
  )
  write.csv(
    data.frame(metric = "bias"),
    legacy,
    row.names = FALSE
  )
  write.csv(
    data.frame(metric = character(), artifact_grain = character()),
    empty,
    row.names = FALSE
  )
  grid_outputs <- list(
    list(
      surface = "grain_grid",
      paths = list(
        aggregate_csv = aggregate,
        replicate_csv = replicates,
        mixed_csv = mixed,
        legacy_csv = legacy,
        empty_csv = empty
      )
    )
  )

  status <- phase18_first_wave_artifact_grain_status(
    grid_outputs,
    artifacts = c(
      "aggregate_csv",
      "replicate_csv",
      "mixed_csv",
      "legacy_csv",
      "empty_csv",
      "absent_csv"
    )
  )
  row.names(status) <- status$source_artifact

  expect_equal(status["aggregate_csv", "grain_status"], "aggregate_only")
  expect_equal(
    status["aggregate_csv", "plot_geometry"],
    "aggregate_points_bars_mcse_only"
  )
  expect_false(status["aggregate_csv", "replicate_cloud_allowed"])
  expect_equal(status["replicate_csv", "grain_status"], "replicate_ready")
  expect_equal(
    status["replicate_csv", "plot_geometry"],
    "replicate_clouds_allowed"
  )
  expect_true(status["replicate_csv", "replicate_cloud_allowed"])
  expect_equal(status["mixed_csv", "grain_status"], "mixed_grain")
  expect_equal(status["legacy_csv", "grain_status"], "missing_grain")
  expect_equal(status["empty_csv", "grain_status"], "empty_artifact")
  expect_equal(status["absent_csv", "grain_status"], "missing_artifact")
})

test_that("Phase 18 first-wave table bundle validates inputs", {
  source_phase18_first_wave_table_bundle()

  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = "",
      grid_outputs = list(list(paths = list()))
    ),
    "output_dir"
  )
  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = tempfile(),
      grid_outputs = list(list(paths = list())),
      overwrite = NA
    ),
    "overwrite"
  )
  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = tempfile(),
      grid_outputs = list()
    ),
    "grid_outputs"
  )
  expect_error(
    phase18_write_first_wave_table_bundle(
      output_dir = tempfile(),
      grid_outputs = list(list(paths = list())),
      artifacts = character()
    ),
    "artifacts"
  )
  expect_error(
    phase18_collect_first_wave_table(
      grid_outputs = list(list(not_paths = TRUE)),
      artifact = "aggregate_csv"
    ),
    "paths"
  )
})
