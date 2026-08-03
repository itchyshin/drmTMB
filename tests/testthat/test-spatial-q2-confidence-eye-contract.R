source(testthat::test_path("..", "..", "tools", "spatial-q2-confidence-eye-common.R"))

test_that("Confidence Eye designs are frozen and disjoint", {
  smoke <- ce_design("smoke")
  full <- ce_design("full")

  expect_equal(nrow(smoke), 60L)
  expect_equal(nrow(full), 1500L)
  expect_equal(as.integer(table(smoke$rung)), rep(20L, 3L))
  expect_equal(as.integer(table(full$rung)), rep(500L, 3L))
  expect_false(any(smoke$seed %in% full$seed))
  expect_equal(anyDuplicated(smoke$seed), 0L)
  expect_equal(anyDuplicated(full$seed), 0L)
  expect_equal(full$seed[full$rung == "L" & full$replicate == 1L], 260901001L)
  expect_equal(full$seed[full$rung == "H" & full$replicate == 500L], 260903500L)
})

test_that("Confidence Eye target identities preserve latent correlation", {
  targets <- ce_targets()

  expect_equal(nrow(targets), 3L)
  expect_equal(targets$tmb_parameter, c("log_sd_phylo", "log_sd_phylo", "eta_cor_phylo"))
  expect_equal(targets$index, c(1L, 2L, 1L))
  expect_equal(targets$transformation, c("exp", "exp", "tanh"))
  expect_match(targets$target[[3L]], "^cor:spatial:")
  expect_false(any(grepl("rho12", targets$target, fixed = TRUE)))
})

test_that("raw rows retain scheduler provenance", {
  design <- ce_design("smoke")[1L, , drop = FALSE]
  packet <- list(source_sha = "source", packet_sha256 = "packet")
  withr::local_envvar(c(
    SLURM_JOB_ID = "1001",
    SLURM_ARRAY_JOB_ID = "1000",
    SLURM_ARRAY_TASK_ID = "1"
  ))
  rows <- ce_base_rows(design, packet)

  expect_equal(unique(rows$slurm_job_id), "1001")
  expect_equal(unique(rows$slurm_array_job_id), "1000")
  expect_equal(unique(rows$slurm_array_task_id), "1")
})

test_that("common floor requires all targets at that and higher rungs", {
  summary <- expand.grid(
    rung = c("L", "M", "H"),
    target = ce_targets()$target,
    stringsAsFactors = FALSE
  )
  summary$target_pass <- TRUE
  expect_equal(ce_common_floor(summary), "L")

  summary$target_pass[summary$rung == "L" & summary$target == ce_targets()$target[[3L]]] <- FALSE
  expect_equal(ce_common_floor(summary), "M")

  summary$target_pass[summary$rung == "M" & summary$target == ce_targets()$target[[1L]]] <- FALSE
  expect_equal(ce_common_floor(summary), "H")

  summary$target_pass[summary$rung == "H" & summary$target == ce_targets()$target[[2L]]] <- FALSE
  expect_true(is.na(ce_common_floor(summary)))
})

test_that("all-attempt target summary applies both frozen gates", {
  rows <- data.frame(
    rung = "M",
    target = ce_targets()$target[[1L]],
    seed = seq_len(500L),
    covered = c(rep(TRUE, 475L), rep(FALSE, 25L)),
    finite_interval = c(rep(TRUE, 475L), rep(FALSE, 25L)),
    point_fit_valid = TRUE,
    fit_warning = "",
    profile_warning = "",
    elapsed_seconds = 1,
    failure_class = c(rep("", 475L), rep("profile_error", 25L)),
    stringsAsFactors = FALSE
  )
  summary <- ce_target_summary(rows, 500L)

  expect_equal(summary$coverage, 0.95)
  expect_equal(summary$finite_rate, 0.95)
  expect_true(summary$target_pass)

  rows$finite_interval[[475L]] <- FALSE
  summary <- ce_target_summary(rows, 500L)
  expect_false(summary$target_pass)
})

test_that("invalid point fits have a deterministic terminal class", {
  expect_equal(
    ce_fit_failure_detail(1L, TRUE, 10, c(0.5, 0.5, 0.4), TRUE),
    "fit_nonconvergence"
  )
  expect_equal(
    ce_fit_failure_detail(0L, FALSE, 10, c(0.5, 0.5, 0.4), TRUE),
    "fit_pdhess_false"
  )
  expect_equal(
    ce_fit_failure_detail(0L, TRUE, Inf, c(0.5, 0.5, 0.4), TRUE),
    "fit_nonfinite"
  )
  expect_equal(
    ce_fit_failure_detail(0L, TRUE, 10, c(0.5, 0.5, 0.4), FALSE),
    "fit_target_boundary"
  )
})

test_that("smoke reconciliation requires the exact 60 by 3 raw ledger", {
  input <- withr::local_tempdir()
  output <- withr::local_tempdir()
  packet <- list(source_sha = "source", packet_sha256 = "packet")
  design <- ce_design("smoke")
  for (i in seq_len(nrow(design))) {
    row <- design[i, , drop = FALSE]
    result <- ce_base_rows(row, packet)
    result$elapsed_seconds <- 1
    result$failure_class <- "profile_not_run_pointfit_invalid"
    result$failure_detail <- "fit_pdhess_false"
    path <- file.path(
      input,
      sprintf("smoke-%s-%03d.tsv", row$rung[[1L]], row$replicate[[1L]])
    )
    ce_atomic_write_tsv(result, path)
  }

  reconciled <- ce_reconcile("smoke", input, output, packet)
  expect_equal(nrow(reconciled$rows), 180L)
  expect_equal(nrow(reconciled$summary), 9L)
  expect_equal(reconciled$decision$verdict, "SMOKE_COMPLETE")
  expect_true(file.exists(file.path(output, "raw-target-outcomes.tsv")))
})
