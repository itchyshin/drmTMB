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
      warnings = c("careful", "still careful"),
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
