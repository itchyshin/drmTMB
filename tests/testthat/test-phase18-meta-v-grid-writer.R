source_phase18_meta_v_grid_writer <- function(env = parent.frame()) {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_runner.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_aggregate.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file("sim/R/sim_uncertainty.R", package = "drmTMB", mustWork = TRUE),
    local = env
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/fit/sim_summarise_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_run_meta_v_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_summary_meta_v_smoke.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_write_meta_v_grid.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
  source(
    system.file(
      "sim/run/sim_meta_v_b3_contract.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

test_that("Phase 18 meta_V B3 contract freezes the formal grid and sentinel", {
  source_phase18_meta_v_grid_writer()
  make_smoke_fixture <- function(contract, smoke_approval_path) {
    registry <- phase18_meta_v_b3_smoke_registry()
    intervals <- do.call(rbind, lapply(c("mu:(Intercept)", "mu:x", "sigma"), function(parameter) {
      transform(
        registry$seeds,
        parameter = parameter,
        truth = if (identical(parameter, "mu:(Intercept)")) 0.20 else if (identical(parameter, "mu:x")) 0.45 else 0.10,
        result_status = "ok",
        converged = TRUE,
        pdHess = TRUE,
        attempt_status = "ok",
        interval_status = "ok",
        conf.low = 0.01,
        conf.high = 0.80,
        warning_count = 0L,
        result_error = NA_character_,
        elapsed = 0.01,
        finite_interval = TRUE
      )
    }))
    intervals$elapsed <- rep(c(0.01, 0.02), times = 3L)
    boundary <- intervals$cell_id == "meta_v_b3_smoke_001" & intervals$parameter == "sigma"
    intervals$conf.low[boundary] <- 0
    intervals$conf.high[boundary] <- Inf
    intervals$interval_status[boundary] <- "degenerate_zero_infinite"
    intervals$attempt_status[boundary] <- "degenerate_interval"
    intervals$finite_interval[boundary] <- FALSE
    list(
      manifest = phase18_meta_v_attempt_manifest(intervals),
      wald_intervals = intervals,
      receipt = list(
        campaign_id = contract$campaign_id,
        contract_fingerprint = phase18_meta_v_b3_contract_fingerprint(contract),
        source_hashes = contract$source_hashes,
        runtime = list(host = "fixture"),
        host_label = "Totoro",
        approval_receipt = list(
          path = normalizePath(smoke_approval_path, mustWork = TRUE),
          sha256 = phase18_meta_v_b3_sha256(smoke_approval_path)
        )
      ),
      finite_and_covering_rate_all_attempt = phase18_meta_v_all_attempt_coverage(
        intervals, by = c("cell_id", "parameter")
      ),
      conditional_finite_interval_coverage = phase18_meta_v_conditional_finite_coverage(
        intervals, by = c("cell_id", "parameter")
      )
    )
  }
  contract <- phase18_meta_v_b3_contract("test-sha")
  smoke <- phase18_meta_v_b3_smoke_registry()

  expect_equal(nrow(contract$registry$cells), 14L)
  expect_equal(nrow(contract$registry$seeds), 16800L)
  expect_equal(contract$n_parameter_attempt, 50400L)
  expect_equal(contract$n_shard, 96L)
  expect_equal(contract$attempts_per_shard, 175L)
  expect_equal(as.integer(table(contract$shards$shard_id)), rep(175L, 96L))
  expect_equal(smoke$seeds$seed, c(4L, 20260722L))
  expect_identical(smoke$cells$smoke_role[[1L]], "boundary_seed4_sentinel")
  expect_error(
    phase18_meta_v_b3_formal_registry(n_rep = 5L),
    "exactly `n_rep = 1200`"
  )
  withr::local_envvar(c(
    DRMTMB_META_V_B3_EXECUTION_APPROVED = "",
    OPENBLAS_NUM_THREADS = ""
  ))
  expect_error(
    phase18_assert_meta_v_b3_execution_approved(contract),
    "explicit maintainer approval"
  )
  smoke_approval_path <- tempfile("meta-v-b3-smoke-approval-", fileext = ".rds")
  campaign_approval_path <- tempfile("meta-v-b3-campaign-approval-", fileext = ".rds")
  smoke_output_dir <- tempfile("meta-v-b3-smoke-output-")
  withr::defer(unlink(c(smoke_approval_path, campaign_approval_path, smoke_output_dir), recursive = TRUE))
  phase18_write_meta_v_b3_approval_receipt(
    contract, smoke_approval_path, approved_by = "Shinichi Nakagawa", scope = "smoke"
  )
  withr::local_envvar(c(
    DRMTMB_META_V_B3_EXECUTION_APPROVED = "yes",
    OPENBLAS_NUM_THREADS = "1",
    DRMTMB_META_V_B3_APPROVAL_RECEIPT = smoke_approval_path
  ))
  approval <- phase18_assert_meta_v_b3_execution_approved(contract, scope = "smoke")
  expect_identical(approval$path, normalizePath(smoke_approval_path, mustWork = TRUE))
  expect_true(nzchar(approval$sha256))
  expect_error(
    phase18_assert_meta_v_b3_execution_approved(contract, scope = "campaign"),
    "scope"
  )
  smoke_fixture <- make_smoke_fixture(contract, smoke_approval_path)
  phase18_write_meta_v_b3_smoke_outputs(smoke_fixture, smoke_output_dir)
  expect_true(file.exists(file.path(smoke_output_dir, "meta-v-b3-smoke-approval.rds")))
  unlink(smoke_approval_path)
  phase18_write_meta_v_b3_approval_receipt(
    contract, campaign_approval_path, approved_by = "Shinichi Nakagawa",
    scope = "campaign", smoke_output_dir = smoke_output_dir, totoro_load_one = 24
  )
  Sys.setenv(DRMTMB_META_V_B3_APPROVAL_RECEIPT = campaign_approval_path)
  campaign_approval <- phase18_assert_meta_v_b3_execution_approved(contract, scope = "campaign")
  expect_identical(campaign_approval$path, normalizePath(campaign_approval_path, mustWork = TRUE))
  expect_identical(
    readRDS(campaign_approval_path)$host_selection$host,
    "Totoro"
  )
  expect_identical(
    phase18_meta_v_b3_select_host(c(1, 2), totoro_load_one = 96)$host,
    "DRAC"
  )
  expect_identical(
    phase18_meta_v_b3_select_host(c(1, 2), totoro_load_one = 24, totoro_available = FALSE)$host,
    "DRAC"
  )
  expect_identical(
    phase18_meta_v_b3_select_host(c(200, 1), totoro_load_one = 24)$host,
    "DRAC"
  )
  receipt_dir <- tempfile("meta-v-b3-receipts-")
  dir.create(receipt_dir)
  withr::defer(unlink(receipt_dir, recursive = TRUE))
  for (shard_id in seq_len(contract$n_shard)) {
    saveRDS(list(
      campaign_id = contract$campaign_id,
      contract_fingerprint = phase18_meta_v_b3_contract_fingerprint(contract),
      shard_id = shard_id,
      source_hashes = contract$source_hashes,
      runtime = list(host = "totoro-fixture"),
      approval_receipt = campaign_approval,
      host_label = "Totoro"
    ), file.path(receipt_dir, sprintf("b3-shard-%03d-receipt.rds", shard_id)))
  }
  expect_silent(phase18_validate_meta_v_b3_shard_receipts(contract, receipt_dir))
  bad_receipt <- readRDS(file.path(receipt_dir, "b3-shard-096-receipt.rds"))
  bad_receipt$host_label <- "DRAC"
  saveRDS(bad_receipt, file.path(receipt_dir, "b3-shard-096-receipt.rds"))
  expect_error(
    phase18_validate_meta_v_b3_shard_receipts(contract, receipt_dir),
    "provenance"
  )
  expect_error(
    phase18_write_meta_v_b3_approval_receipt(
      contract, tempfile(fileext = ".rds"), approved_by = "Shinichi Nakagawa",
      scope = "campaign", smoke_output_dir = tempfile(), totoro_load_one = 24
    ),
    "requires retained smoke"
  )
})

test_that("Phase 18 meta_V B3 contract writes and checks complete artifacts", {
  source_phase18_meta_v_grid_writer()
  for (runner in c("tools/run-meta-v-b3-smoke.R", "tools/run-meta-v-b3-shard.R")) {
    runner_path <- testthat::test_path("..", "..", runner)
    expect_match(
      paste(readLines(runner_path, warn = FALSE), collapse = "\n"),
      "suppressPackageStartupMessages\\(library\\(drmTMB\\)\\)"
    )
  }
  contract <- phase18_meta_v_b3_contract("test-sha")
  output_dir <- tempfile("phase18-meta-v-b3-contract-")
  withr::defer(unlink(output_dir, recursive = TRUE))
  paths <- phase18_write_meta_v_b3_contract(contract, output_dir)
  expect_true(all(file.exists(paths)))
  expect_true(all(nzchar(readRDS(paths[["contract_rds"]])$artifact_hashes$sha256)))
  expect_identical(
    phase18_meta_v_b3_contract_fingerprint(readRDS(paths[["contract_rds"]])),
    phase18_meta_v_b3_contract_fingerprint(contract)
  )
  for (field in c("n_attempt", "n_parameter_attempt", "n_shard", "attempts_per_shard")) {
    altered <- contract
    altered[[field]] <- altered[[field]] - 1L
    expect_false(identical(
      phase18_meta_v_b3_contract_fingerprint(altered),
      phase18_meta_v_b3_contract_fingerprint(contract)
    ))
  }
  mismatched_contract <- contract
  mismatched_contract$source_hashes$sha256[[1L]] <- "not-the-installed-source"
  expect_error(
    phase18_validate_meta_v_b3_source(mismatched_contract),
    "do not match"
  )

  completion_contract <- contract
  completion_contract$registry$seeds <- completion_contract$registry$seeds[1:2, , drop = FALSE]
  completion_contract$n_attempt <- 2L
  completion_contract$n_parameter_attempt <- 6L
  replicates <- do.call(rbind, lapply(c("mu:(Intercept)", "mu:x", "sigma"), function(parameter) {
    transform(
      completion_contract$registry$seeds,
      parameter = parameter,
      truth = if (identical(parameter, "mu:(Intercept)")) 0.20 else if (identical(parameter, "mu:x")) 0.45 else 0.10,
      result_status = "ok",
      converged = TRUE,
      pdHess = TRUE,
      attempt_status = "ok",
      interval_status = "ok",
      conf.low = 0,
      conf.high = 1,
      warning_count = 0L,
      result_error = NA_character_,
      elapsed = 0.01,
      finite_interval = TRUE
    )
  }))
  manifest <- phase18_meta_v_attempt_manifest(replicates)
  expect_true(phase18_validate_meta_v_b3_completion(manifest, replicates, completion_contract))
  expect_equal(nrow(phase18_meta_v_b3_shard_seeds(contract, 1L)), 175L)
  expect_error(
    phase18_validate_meta_v_b3_completion(manifest[-1L, ], replicates, completion_contract),
    "each and only each scheduled attempt"
  )
  wrong_parameter <- replicates
  wrong_parameter$parameter[[1L]] <- "not-a-b3-parameter"
  expect_error(
    phase18_validate_meta_v_b3_completion(manifest, wrong_parameter, completion_contract),
    "scheduled parameter map"
  )
  manifest$n_interval_degenerate[[1L]] <- 1L
  expect_error(
    phase18_validate_meta_v_b3_completion(manifest, replicates, completion_contract),
    "status counts"
  )
})

test_that("Phase 18 meta_V B3 smoke validator keeps the seed-4 boundary separate", {
  source_phase18_meta_v_grid_writer()
  registry <- phase18_meta_v_b3_smoke_registry()
  intervals <- do.call(rbind, lapply(c("mu:(Intercept)", "mu:x", "sigma"), function(parameter) {
    transform(
      registry$seeds,
      parameter = parameter,
      truth = if (identical(parameter, "mu:(Intercept)")) 0.20 else if (identical(parameter, "mu:x")) 0.45 else 0.10,
      result_status = "ok",
      converged = TRUE,
      pdHess = TRUE,
      attempt_status = "ok",
      interval_status = "ok",
      conf.low = 0.01,
      conf.high = 0.80,
      warning_count = 0L,
      result_error = NA_character_,
      elapsed = 0.01,
      finite_interval = TRUE
    )
  }))
  boundary <- intervals$cell_id == "meta_v_b3_smoke_001" & intervals$parameter == "sigma"
  intervals$conf.low[boundary] <- 0
  intervals$conf.high[boundary] <- Inf
  intervals$interval_status[boundary] <- "degenerate_zero_infinite"
  intervals$attempt_status[boundary] <- "degenerate_interval"
  intervals$finite_interval[boundary] <- FALSE
  smoke <- list(
    manifest = phase18_meta_v_attempt_manifest(intervals),
    wald_intervals = intervals,
    receipt = list(
      campaign_id = "phase18_meta_v_b3",
      source_hashes = data.frame(sha256 = "fixture"),
      runtime = list(host = "fixture"),
      approval_receipt = list(sha256 = "fixture")
    ),
    finite_and_covering_rate_all_attempt = phase18_meta_v_all_attempt_coverage(
      intervals, by = c("cell_id", "parameter")
    ),
    conditional_finite_interval_coverage = phase18_meta_v_conditional_finite_coverage(
      intervals, by = c("cell_id", "parameter")
    )
  )
  expect_true(phase18_validate_meta_v_b3_smoke(smoke))
  intervals$interval_status[boundary] <- "ok"
  expect_error(
    phase18_validate_meta_v_b3_smoke(list(
      manifest = smoke$manifest, wald_intervals = intervals,
      receipt = smoke$receipt,
      finite_and_covering_rate_all_attempt = smoke$finite_and_covering_rate_all_attempt,
      conditional_finite_interval_coverage = smoke$conditional_finite_interval_coverage
    )),
    "required degenerate interval"
  )
})

test_that("Phase 18 meta_V grid writer creates table artifacts", {
  source_phase18_meta_v_grid_writer()
  output_dir <- tempfile("phase18-meta-v-grid-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_write_meta_v_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_meta_v_conditions(
      n_study = 32L,
      known_v_type = c("vector", "dense"),
      sigma = 0.25,
      sampling_sd = 0.14,
      sampling_rho = c(0, 0.20)
    ),
    n_rep = 1L,
    master_seed = 229L,
    cores = 10L
  )

  expect_equal(out$surface, "meta_v_grid")
  expect_equal(out$summary$run$parallel$backend, "none")
  expect_equal(out$summary$run$parallel$requested_cores, 10L)
  expect_equal(out$summary$run$parallel$cores, 1L)
  expect_equal(nrow(out$artifact_manifest), length(out$paths))
  expect_true(all(out$artifact_manifest$exists))
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$table_dir))
  expect_true(all(file.exists(unlist(out$paths, use.names = FALSE))))
  expect_equal(nrow(out$summary$replicates), 9L)
  expect_equal(nrow(out$summary$aggregate), 9L)
  expect_equal(nrow(utils::read.csv(out$paths$replicate_csv)), 9L)
  expect_equal(nrow(utils::read.csv(out$paths$wald_intervals_csv)), 9L)
  expect_equal(
    nrow(utils::read.csv(out$paths$finite_and_covering_rate_all_attempt_csv)),
    9L
  )
  expect_equal(
    nrow(utils::read.csv(out$paths$conditional_finite_interval_coverage_csv)),
    9L
  )
  expect_setequal(
    unique(out$summary$replicates$known_v_type),
    c("vector", "dense")
  )
  expect_error(
    phase18_write_meta_v_grid_outputs(
      output_dir = output_dir,
      conditions = phase18_meta_v_conditions(
        n_study = 32L,
        known_v_type = c("vector", "dense"),
        sigma = 0.25,
        sampling_sd = 0.14,
        sampling_rho = c(0, 0.20)
      ),
      n_rep = 1L,
      master_seed = 229L
    ),
    "already exists"
  )
  expect_silent(phase18_write_meta_v_grid_outputs(
    output_dir = output_dir,
    conditions = phase18_meta_v_conditions(
      n_study = 32L,
      known_v_type = c("vector", "dense"),
      sigma = 0.25,
      sampling_sd = 0.14,
      sampling_rho = c(0, 0.20)
    ),
    n_rep = 1L,
    master_seed = 229L,
    overwrite = TRUE
  ))
})

test_that("Phase 18 meta_V grid writer validates output inputs", {
  source_phase18_meta_v_grid_writer()

  expect_error(
    phase18_write_meta_v_grid_outputs(output_dir = ""),
    "output_dir"
  )
  expect_error(
    phase18_write_meta_v_grid_outputs(
      output_dir = tempfile(),
      overwrite = NA
    ),
    "overwrite"
  )
})
