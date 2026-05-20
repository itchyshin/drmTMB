test_that("Phase 18 replicate runner saves and resumes completed results", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  result_dir <- tempfile("phase18-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  cell <- data.frame(cell_id = "gaussian_ls_001", n = 4L)
  seed_row <- data.frame(
    cell_id = "gaussian_ls_001",
    cell_index = 1L,
    replicate = 2L,
    seed = 213L
  )
  dgp_fun <- function(cell, seed, cell_id, replicate) {
    phase18_with_seed(seed, function() {
      data.frame(
        y = stats::rnorm(cell$n[[1L]]),
        cell_id = cell_id,
        replicate = replicate
      )
    })
  }
  fit_fun <- function(data, cell) {
    list(estimate = mean(data$y), n = nrow(data))
  }
  summarise_fun <- function(fit, truth, cell_id, replicate, elapsed, warnings) {
    data.frame(
      cell_id = cell_id,
      replicate = replicate,
      parameter = "mean_y",
      estimate = fit$estimate,
      nobs = fit$n,
      elapsed = elapsed,
      warning_count = length(warnings)
    )
  }

  first <- phase18_run_replicate(
    cell,
    seed_row,
    dgp_fun,
    fit_fun,
    summarise_fun,
    result_dir = result_dir
  )
  second <- phase18_run_replicate(
    cell,
    seed_row,
    function(...) stop("should not run"),
    fit_fun,
    summarise_fun,
    result_dir = result_dir
  )

  expect_identical(first$status, "ok")
  expect_false(first$skipped)
  expect_true(file.exists(phase18_result_path(
    result_dir,
    "gaussian_ls_001",
    2L
  )))
  expect_true(second$skipped)
  expect_equal(second$summary, first$summary)
})

test_that("Phase 18 replicate runner can run a bounded replicate set", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  cells <- data.frame(
    cell_id = c("cell_001", "cell_002"),
    n = c(3L, 4L)
  )
  seeds <- data.frame(
    cell_id = c("cell_001", "cell_002", "cell_001"),
    cell_index = c(1L, 2L, 1L),
    replicate = c(1L, 1L, 2L),
    seed = c(101L, 102L, 103L)
  )
  dgp_fun <- function(cell, seed, cell_id, replicate) {
    phase18_with_seed(seed, function() {
      data.frame(
        y = stats::rnorm(cell$n[[1L]]),
        cell_id = cell_id,
        replicate = replicate
      )
    })
  }
  fit_fun <- function(data, cell) {
    list(estimate = mean(data$y), n = nrow(data))
  }
  summarise_fun <- function(fit, truth, cell_id, replicate, elapsed, warnings) {
    data.frame(
      cell_id = cell_id,
      replicate = replicate,
      parameter = "mean_y",
      estimate = fit$estimate,
      nobs = fit$n,
      elapsed = elapsed,
      warning_count = length(warnings)
    )
  }

  results <- phase18_run_replicates(
    cells = cells,
    seeds = seeds,
    dgp_fun = dgp_fun,
    fit_fun = fit_fun,
    summarise_fun = summarise_fun,
    cores = 10L
  )
  plan <- attr(results, "phase18_parallel", exact = TRUE)

  expect_equal(length(results), 3L)
  expect_equal(
    names(results),
    c("cell_001:rep0001", "cell_002:rep0001", "cell_001:rep0002")
  )
  expect_equal(
    unname(vapply(results, `[[`, character(1L), "status")),
    rep("ok", 3L)
  )
  expect_equal(plan$backend, "none")
  expect_equal(plan$requested_cores, 10L)
  expect_equal(plan$cores, 1L)
  if (.Platform$OS.type != "windows") {
    expect_equal(
      phase18_runner_parallel_plan(
        n_task = 25L,
        cores = 11L,
        backend = "multicore"
      )$cores,
      10L
    )
  }
  expect_error(
    phase18_runner_parallel_plan(n_task = 2L, cores = 11L, backend = "psock"),
    "none.*multicore"
  )
  expect_error(
    phase18_run_replicates(
      cells = cells,
      seeds = transform(seeds[1L, ], cell_index = 3L),
      dgp_fun = dgp_fun,
      fit_fun = fit_fun,
      summarise_fun = summarise_fun
    ),
    "cell_index"
  )
})

test_that("Phase 18 replicate runner supports per-replicate summary factories", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  cells <- data.frame(cell_id = "cell_001", n = 3L)
  seeds <- data.frame(
    cell_id = "cell_001",
    cell_index = 1L,
    replicate = c(1L, 2L),
    seed = c(101L, 102L)
  )
  dgp_fun <- function(cell, seed, cell_id, replicate) {
    data.frame(y = rep(seed, cell$n[[1L]]))
  }
  fit_fun <- function(data, cell) {
    list(value = mean(data$y))
  }
  summarise_fun_factory <- function(cell, seed_row) {
    offset <- seed_row$replicate[[1L]]
    function(fit, truth, cell_id, replicate, elapsed, warnings) {
      data.frame(
        cell_id = cell_id,
        replicate = replicate,
        parameter = "seed_plus_replicate",
        estimate = fit$value + offset
      )
    }
  }

  results <- phase18_run_replicates(
    cells = cells,
    seeds = seeds,
    dgp_fun = dgp_fun,
    fit_fun = fit_fun,
    summarise_fun_factory = summarise_fun_factory
  )
  summary <- phase18_result_summaries(results)

  expect_equal(summary$estimate, c(102, 104))
  expect_error(
    phase18_run_replicates(
      cells = cells,
      seeds = seeds[1L, , drop = FALSE],
      dgp_fun = dgp_fun,
      fit_fun = fit_fun,
      summarise_fun_factory = function(...) NULL
    ),
    "summarise_fun_factory"
  )
})

test_that("Phase 18 runner rejects nested parallel plans", {
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  expect_error(
    phase18_assert_no_nested_parallel(
      list(backend = "multicore", requested_cores = 4L, cores = 4L),
      list(backend = "multicore", requested_cores = 3L, cores = 3L)
    ),
    "either the replicate layer or the bootstrap layer"
  )
  expect_true(phase18_assert_no_nested_parallel(
    list(backend = "multicore", requested_cores = 4L, cores = 4L),
    list(backend = "none", requested_cores = 10L, cores = 1L)
  ))
})

test_that("Phase 18 grid artifact manifest records CSV rows", {
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  csv_path <- tempfile(fileext = ".csv")
  txt_path <- tempfile(fileext = ".txt")
  withr::defer(unlink(c(csv_path, txt_path)))
  utils::write.csv(data.frame(x = 1:3), csv_path, row.names = FALSE)
  writeLines("not a table", txt_path)

  manifest <- phase18_grid_artifact_manifest(
    surface = "demo_surface",
    paths = list(table_csv = csv_path, note_txt = txt_path)
  )

  expect_equal(nrow(manifest), 2L)
  expect_equal(manifest$surface, rep("demo_surface", 2L))
  expect_true(all(manifest$exists))
  expect_equal(manifest$n_row[manifest$artifact == "table_csv"], 3L)
  expect_true(is.na(manifest$n_row[manifest$artifact == "note_txt"]))
  expect_error(
    phase18_grid_artifact_manifest("", list(table_csv = csv_path)),
    "surface"
  )
  expect_error(
    phase18_grid_artifact_manifest("x", list(bad = character())),
    "artifact path"
  )
})

test_that("Phase 18 grid artifact manifests bind and summarise", {
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  first <- data.frame(
    surface = "surface_a",
    artifact = c("aggregate_csv", "failures_csv"),
    path = c("a.csv", "failures.csv"),
    exists = c(TRUE, TRUE),
    n_row = c(4L, 0L),
    stringsAsFactors = FALSE
  )
  second <- list(
    artifact_manifest = data.frame(
      surface = "surface_b",
      artifact = c("aggregate_csv", "missing_csv"),
      path = c("b.csv", "missing.csv"),
      exists = c(TRUE, FALSE),
      n_row = c(3L, NA_integer_),
      stringsAsFactors = FALSE
    )
  )

  bound <- phase18_bind_grid_artifact_manifests(first, second)
  status <- phase18_summarise_grid_artifact_manifests(bound)

  expect_equal(nrow(bound), 4L)
  expect_equal(bound$artifact_grain, rep("grid_artifact_manifest", 4L))
  expect_equal(nrow(status), 2L)
  expect_equal(
    status$n_missing[status$surface == "surface_b"],
    1L
  )
  expect_equal(
    status$n_empty_csv[status$surface == "surface_a"],
    1L
  )
  expect_equal(
    status$n_total_csv_rows[status$surface == "surface_a"],
    4L
  )
  expect_error(
    phase18_bind_grid_artifact_manifests(list(not_manifest = TRUE)),
    "artifact manifest"
  )
  expect_error(
    phase18_summarise_grid_artifact_manifests(data.frame(surface = "x")),
    "missing"
  )
})

test_that("Phase 18 replicate runner captures warnings and errors", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  cell <- data.frame(cell_id = "meta_v_001", n = 3L)
  seed_row <- data.frame(
    cell_id = "meta_v_001",
    cell_index = 1L,
    replicate = 1L,
    seed = 214L
  )
  warn_dgp <- function(cell, seed, cell_id, replicate) {
    warning("pilot warning", call. = FALSE)
    data.frame(
      y = seq_len(cell$n[[1L]]),
      cell_id = cell_id,
      replicate = replicate
    )
  }
  fail_fit <- function(data, cell) {
    stop("pilot failure", call. = FALSE)
  }
  summarise_fun <- function(fit, truth, cell_id, replicate, elapsed, warnings) {
    data.frame()
  }

  result <- phase18_run_replicate(
    cell,
    seed_row,
    warn_dgp,
    fail_fit,
    summarise_fun
  )

  expect_identical(result$status, "error")
  expect_equal(result$warnings, "pilot warning")
  expect_equal(result$error, "pilot failure")
  expect_null(result$summary)
})

test_that("Phase 18 replicate runner validates malformed inputs", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  cell <- data.frame(cell_id = "x")
  seed_row <- data.frame(cell_id = "x", replicate = 1L, seed = 1L)
  ok_fun <- function(...) NULL

  expect_error(
    phase18_run_replicate(data.frame(), seed_row, ok_fun, ok_fun, ok_fun),
    "one-row data frame"
  )
  expect_error(
    phase18_run_replicate(
      cell,
      data.frame(cell_id = "y", replicate = 1L, seed = 1L),
      ok_fun,
      ok_fun,
      ok_fun
    ),
    "same `cell_id`"
  )
  expect_error(
    phase18_run_replicate(cell, seed_row, NULL, ok_fun, ok_fun),
    "dgp_fun"
  )
  expect_error(
    phase18_result_path("", "cell", 1L),
    "result_dir"
  )
})

test_that("Phase 18 replicate runner builds compact result manifests", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  results <- list(
    list(
      cell_id = "cell_001",
      replicate = 1L,
      seed = 101L,
      status = "ok",
      warnings = character(),
      error = NULL,
      elapsed = 0.1,
      skipped = FALSE
    ),
    list(
      cell_id = "cell_001",
      replicate = 2L,
      seed = 102L,
      status = "error",
      warnings = c("careful"),
      error = "failed",
      elapsed = 0.2,
      skipped = TRUE
    )
  )

  manifest <- phase18_result_manifest(results)

  expect_equal(nrow(manifest), 2L)
  expect_equal(
    names(manifest),
    c(
      "cell_id",
      "replicate",
      "seed",
      "status",
      "skipped",
      "warning_count",
      "error",
      "elapsed"
    )
  )
  expect_equal(manifest$status, c("ok", "error"))
  expect_equal(manifest$warning_count, c(0L, 1L))
  expect_true(is.na(manifest$error[[1L]]))
  expect_equal(manifest$error[[2L]], "failed")
  expect_true(manifest$skipped[[2L]])
  expect_error(
    phase18_result_manifest(list(list(cell_id = "x"))),
    "must contain"
  )
})

test_that("Phase 18 replicate runner extracts warning and error rows", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  results <- list(
    list(
      cell_id = "cell_001",
      replicate = 1L,
      seed = 101L,
      status = "ok",
      warnings = character(),
      error = NULL,
      elapsed = 0.1,
      skipped = FALSE
    ),
    list(
      cell_id = "cell_001",
      replicate = 2L,
      seed = 102L,
      status = "error",
      warnings = c("careful", "careful", "still careful"),
      error = "failed",
      elapsed = 0.2,
      skipped = FALSE
    )
  )

  failures <- phase18_result_failures(results)

  expect_equal(nrow(failures), 3L)
  expect_equal(failures$severity, c("error", "warning", "warning"))
  expect_equal(failures$message, c("failed", "careful", "still careful"))
  expect_equal(failures$replicate, rep(2L, 3L))
  expect_equal(
    nrow(phase18_result_failures(results[1L])),
    0L
  )
})

test_that("Phase 18 replicate runner reads saved result directories", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  result_dir <- tempfile("phase18-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  ok <- list(
    cell_id = "cell 001",
    replicate = 1L,
    seed = 101L,
    status = "ok",
    warnings = character(),
    error = NULL,
    elapsed = 0.1,
    skipped = FALSE
  )
  failed <- list(
    cell_id = "cell 001",
    replicate = 2L,
    seed = 102L,
    status = "error",
    warnings = "careful",
    error = "failed",
    elapsed = 0.2,
    skipped = FALSE
  )
  ok_path <- phase18_result_path(result_dir, ok$cell_id, ok$replicate)
  failed_path <- phase18_result_path(
    result_dir,
    failed$cell_id,
    failed$replicate
  )
  dir.create(dirname(ok_path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(ok, ok_path)
  saveRDS(
    failed,
    failed_path
  )
  writeLines("ignored", file.path(result_dir, "notes.txt"))

  results <- phase18_read_result_dir(result_dir)
  manifest <- phase18_result_manifest(results)
  failures <- phase18_result_failures(results)

  expect_equal(length(results), 2L)
  expect_true(all(file.exists(vapply(
    results,
    function(result) result$source_path,
    character(1L)
  ))))
  expect_equal(manifest$replicate, c(1L, 2L))
  expect_equal(manifest$status, c("ok", "error"))
  expect_equal(nrow(failures), 2L)
  expect_equal(failures$severity, c("error", "warning"))
})

test_that("Phase 18 replicate runner binds replicate-level summaries", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  results <- list(
    list(
      cell_id = "cell_001",
      replicate = 1L,
      seed = 101L,
      status = "ok",
      summary = data.frame(
        cell_id = "cell_001",
        replicate = 1L,
        parameter = "mu:x",
        error = 0.1
      ),
      warnings = character(),
      elapsed = 0.1
    ),
    list(
      cell_id = "cell_001",
      replicate = 2L,
      seed = 102L,
      status = "ok",
      summary = data.frame(
        cell_id = "cell_001",
        replicate = 2L,
        parameter = "mu:x",
        error = -0.1
      ),
      warnings = character(),
      elapsed = 0.1
    )
  )

  out <- phase18_result_summaries(results)

  expect_equal(nrow(out), 2L)
  expect_equal(out$replicate, c(1L, 2L))
  expect_equal(out$artifact_grain, rep("replicate", 2L))
  expect_equal(
    phase18_result_summaries(
      list(list(summary = data.frame())),
      artifact_grain = "simulation_replicate"
    ),
    data.frame()
  )
  expect_error(phase18_result_summaries(list()), "non-empty list")
  expect_error(phase18_result_summaries(results, artifact_grain = ""), "grain")
})

test_that("Phase 18 replicate runner validates result directory reads", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  result_dir <- tempfile("phase18-empty-results-")
  dir.create(result_dir)
  withr::defer(unlink(result_dir, recursive = TRUE))

  expect_error(
    phase18_read_result_dir(file.path(result_dir, "missing")),
    "existing directory"
  )
  expect_error(
    phase18_read_result_dir(result_dir),
    "does not contain"
  )
  expect_error(
    phase18_read_result_dir(result_dir, pattern = ""),
    "pattern"
  )

  invalid_path <- phase18_result_path(result_dir, "bad", 1L)
  dir.create(dirname(invalid_path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(list(cell_id = "bad"), invalid_path)
  expect_error(
    phase18_read_result_dir(result_dir),
    "not a valid Phase 18 replicate result"
  )
})
