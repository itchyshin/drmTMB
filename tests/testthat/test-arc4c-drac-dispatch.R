dispatch_path <- testthat::test_path("..", "..", "tools", "prepare-arc4c-drac-dispatch.R")
if (!file.exists(dispatch_path)) {
  test_that("Arc 4c DRAC dispatch contract is available in a source checkout", {
    skip("Top-level tools are intentionally excluded from the source tarball")
  })
} else {
  dispatch_env <- new.env(parent = baseenv())
  sys.source(dispatch_path, envir = dispatch_env)

test_that("Arc 4c full manifest is a stable 1,440-task bijection", {
  approved <- expand.grid(cell_id = dispatch_env$arc4c_cells$cell_id, M = dispatch_env$arc4c_M, stringsAsFactors = FALSE)
  manifest <- dispatch_env$arc4c_make_full_manifest(approved)

  expect_equal(nrow(manifest), 1440L)
  expect_identical(manifest$logical_task_id, 1:1440)
  expect_identical(manifest$array_index, 1:1440)
  expect_equal(manifest$logical_task_id[manifest$cell_id == "mc-0464" & manifest$M == 16L & manifest$shard == 1L], 121L)
  expect_equal(manifest$logical_task_id[manifest$cell_id == "mc-0539" & manifest$M == 8L & manifest$shard == 1L], 481L)
  expect_equal(manifest$logical_task_id[manifest$cell_id == "mc-0575" & manifest$M == 64L & manifest$shard == 120L], 1440L)

  per_cell <- split(manifest, interaction(manifest$cell_id, manifest$M, drop = TRUE))
  for (x in per_cell) {
    expect_identical(unlist(Map(seq.int, x$replicate_start, x$replicate_end), use.names = FALSE), 1:1200)
    expect_equal(nrow(x), 120L)
  }
})

test_that("smoke manifest is the exact eight-column 12-task selector contract", {
  smoke <- dispatch_env$arc4c_make_smoke_manifest()
  expect_identical(names(smoke), c("array_index", "logical_task_id", "cell_id", "family", "M", "shard", "replicate_start", "replicate_end"))
  expect_equal(nrow(smoke), 12L)
  expect_identical(smoke$array_index, 1:12)
  expect_true(all(smoke$shard == 0L & smoke$replicate_start == 1L & smoke$replicate_end == 1L))
})

test_that("smoke selection excludes only M=8 and halts a family after non-exploratory failure", {
  smoke <- dispatch_env$arc4c_make_smoke_manifest()[c("cell_id", "M")]
  smoke$smoke_pass <- TRUE
  m8_fail <- smoke
  m8_fail$smoke_pass[m8_fail$cell_id == "mc-0464" & m8_fail$M == 8L] <- FALSE
  selected <- dispatch_env$arc4c_select_smoke(m8_fail)
  expect_equal(selected$family$family_status[selected$family$cell_id == "mc-0464"], "eligible_for_full_array")
  expect_false(any(selected$approved$cell_id == "mc-0464" & selected$approved$M == 8L))
  expect_equal(selected$approved$M[selected$approved$cell_id == "mc-0464"], c(16L, 32L, 64L))

  nonexploratory_fail <- smoke
  nonexploratory_fail$smoke_pass[nonexploratory_fail$cell_id == "mc-0539" & nonexploratory_fail$M == 32L] <- FALSE
  halted <- dispatch_env$arc4c_select_smoke(nonexploratory_fail)
  expect_equal(halted$family$family_status[halted$family$cell_id == "mc-0539"], "halted_nonexploratory_smoke_failure")
  expect_false(any(halted$approved$cell_id == "mc-0539"))
  expect_true(all(c("mc-0464", "mc-0575") %in% halted$approved$cell_id))
})

test_that("partitioning preserves logical IDs and caps aggregate concurrency", {
  approved <- expand.grid(cell_id = dispatch_env$arc4c_cells$cell_id, M = dispatch_env$arc4c_M, stringsAsFactors = FALSE)
  manifest <- dispatch_env$arc4c_make_full_manifest(approved)
  direct <- dispatch_env$arc4c_partition_manifest(manifest, max_array_size = 10000L)
  expect_equal(nrow(direct$plan), 1L)
  expect_equal(direct$plan$n_tasks, 1440L)
  expect_equal(direct$plan$concurrency_cap, 96L)

  split_plan <- dispatch_env$arc4c_partition_manifest(manifest, max_array_size = 500L)
  expect_equal(nrow(split_plan$plan), 3L)
  expect_true(all(split_plan$plan$n_tasks <= 500L))
  expect_equal(sum(split_plan$plan$concurrency_cap), 96L)
  expect_identical(unlist(lapply(split_plan$partitions, `[[`, "logical_task_id"), use.names = FALSE), manifest$logical_task_id)
  expect_error(dispatch_env$arc4c_partition_manifest(manifest, max_array_size = 1L), "BLOCKED_RESOURCE_LAYOUT")
  expect_error(dispatch_env$arc4c_partition_manifest(manifest, max_array_size = 10000L, concurrency = 97L), "cannot exceed 96")
})

test_that("resource sizing uses the frozen smoke-derived guards", {
  expect_equal(dispatch_env$arc4c_size_resources(1, 2.1)$wall_minutes, 60)
  expect_equal(dispatch_env$arc4c_size_resources(1, 2.1)$memory_gb, 5)
  expect_error(dispatch_env$arc4c_size_resources(145, 4), "BLOCKED_RESOURCE_SIZING")
  expect_error(dispatch_env$arc4c_size_resources(1, 16.1), "BLOCKED_RESOURCE_SIZING")
})

test_that("dispatch CLI rejects duplicates and mode-specific extras", {
  expect_error(
    dispatch_env$arc4c_parse_args(c("--mode=smoke-manifest", "--mode=full-manifest")),
    "Duplicate argument"
  )
  expect_error(
    dispatch_env$arc4c_main(c("--mode=smoke-manifest", "--out=x", "--seed=1")),
    "Unsupported argument"
  )
  expect_error(dispatch_env$arc4c_parse_args("--out="), "nonempty")
})

test_that("the shared compute-node preflight receipt fails closed", {
  receipt <- data.frame(
    key = dispatch_env$arc4c_preflight_required_keys,
    value = c("abc", "abc", "tree", "clean", "source", "dll", "/project/rlib", "R 4.4.0", "gcc 12.3", "TMB 1.9.0", "modules", "session", "module-hash", "session-hash"),
    stringsAsFactors = FALSE
  )
  expect_silent(dispatch_env$arc4c_validate_preflight_receipt(receipt, "abc"))
  expect_error(dispatch_env$arc4c_validate_preflight_receipt(receipt[-1L, ], "abc"), "incomplete")
  receipt$value[receipt$key == "git_status"] <- "dirty"
  expect_error(dispatch_env$arc4c_validate_preflight_receipt(receipt, "abc"), "clean")
})

test_that("workers pin native libraries, stage scratch safely, copy back, and aggregate afterok", {
  scripts <- c(
    coverage = testthat::test_path("..", "..", "tools", "slurm", "arc4c-mu-slope-coverage.sbatch"),
    smoke = testthat::test_path("..", "..", "tools", "slurm", "arc4c-mu-slope-coverage-smoke.sbatch"),
    aggregate = testthat::test_path("..", "..", "tools", "slurm", "arc4c-mu-slope-coverage-aggregate.sbatch")
  )
  text <- lapply(scripts, readLines, warn = FALSE)
  runner_text <- readLines(testthat::test_path("..", "..", "tools", "run-arc4c-mu-slope-coverage.R"), warn = FALSE)
  for (x in text) {
    expect_true(any(grepl("#SBATCH --account=def-snakagaw_cpu", x, fixed = TRUE)))
    expect_true(any(grepl("StdEnv/2023 gcc/12.3 r/4.4.0", x, fixed = TRUE)))
    expect_true(any(grepl("OMP_NUM_THREADS=1", x, fixed = TRUE)))
    expect_true(any(grepl("OPENBLAS_NUM_THREADS=1", x, fixed = TRUE)))
    expect_true(any(grepl("FLEXIBLAS_NUM_THREADS=1", x, fixed = TRUE)))
    expect_true(any(grepl("BLIS_NUM_THREADS=1", x, fixed = TRUE)))
    expect_true(any(grepl("MKL_NUM_THREADS=1", x, fixed = TRUE)))
    expect_true(any(grepl("TMB_NTHREADS=1", x, fixed = TRUE)))
    expect_true(any(grepl("Refusing login-node execution", x, fixed = TRUE)))
  }
  for (x in text[c("coverage", "smoke")]) {
    expect_true(any(grepl("--cpus-per-task=1", x, fixed = TRUE)))
    expect_true(any(grepl("SLURM_TMPDIR", x, fixed = TRUE)))
    expect_true(any(grepl("copy_back()", x, fixed = TRUE)))
    expect_true(any(grepl("trap on_exit EXIT", x, fixed = TRUE)))
    expect_true(any(grepl("rsync -a", x, fixed = TRUE)))
    expect_true(any(grepl("PREFLIGHT_DIR", x, fixed = TRUE)))
    expect_true(any(grepl("receipt.tsv", x, fixed = TRUE)))
  }
  for (x in text[c("coverage", "smoke")]) {
    expect_true(any(grepl("Rscript --no-init-file \"$RUNNER\"", x, fixed = TRUE)))
    expect_false(any(grepl("source(Sys.getenv", x, fixed = TRUE)))
    expect_true(any(grepl("PREFLIGHT_DIR", x, fixed = TRUE)))
    expect_false(any(grepl("-print -delete", x, fixed = TRUE)))
    expect_true(any(grepl("SHARD_BASENAME", x, fixed = TRUE)))
    expect_true(any(grepl("$SHARD_BASENAME.md5", x, fixed = TRUE)))
    expect_true(any(grepl("quarantine", x, ignore.case = TRUE)))
    expect_false(any(grepl("Incomplete canonical", x, fixed = TRUE)))
    expect_true(any(grepl("hostname=", x, fixed = TRUE)))
    expect_true(any(grepl("slurm_job_id=", x, fixed = TRUE)))
    expect_true(any(grepl("slurm_array_job_id=", x, fixed = TRUE)))
    expect_true(any(grepl("slurm_array_task_id=", x, fixed = TRUE)))
    expect_true(any(grepl("env | sort", x, fixed = TRUE)))
    expect_true(any(grepl("runner-", x, fixed = TRUE)))
    expect_true(any(grepl(".stdout", x, fixed = TRUE)))
    expect_true(any(grepl(".stderr", x, fixed = TRUE)))
  }
  expect_true(any(grepl("pkgload::load_all", runner_text, fixed = TRUE)))
  expect_true(any(grepl("recompile = FALSE", runner_text, fixed = TRUE)))
  expect_true(any(grepl("#SBATCH --array=1-1440%96", text$coverage, fixed = TRUE)))
  expect_true(any(grepl("#SBATCH --array=1-12%12", text$smoke, fixed = TRUE)))
  expect_true(any(grepl("--dependency=afterok:<array-job-id>", text$aggregate, fixed = TRUE)))
  expect_true(any(grepl("sha256sum -c", text$coverage, fixed = TRUE)))
  expect_true(any(grepl("DRMTMB_ARC4C_PREFLIGHT_ONLY", text$coverage, fixed = TRUE)))
  expect_true(any(grepl("--manifest=\"$MANIFEST\"", text$aggregate, fixed = TRUE)))
  expect_true(any(grepl("DRMTMB_ARC4C_AGGREGATE_MODE", text$aggregate, fixed = TRUE)))
  expect_true(any(grepl("DRMTMB_ARC4C_SMOKE_MANIFEST", text$aggregate, fixed = TRUE)))
  expect_true(any(grepl("--mode=\"$MODE\"", text$aggregate, fixed = TRUE)))
  expect_true(any(grepl("afterok:<smoke-array-job-id>", text$aggregate, fixed = TRUE)))
  expect_true(any(grepl("slurm_job_dependency=", text$aggregate, fixed = TRUE)))
  expect_true(any(grepl("environment-aggregate-job_", text$aggregate, fixed = TRUE)))
  expect_true(any(grepl("runner-aggregate-job_", text$aggregate, fixed = TRUE)))
  expect_true(any(grepl("module_list_sha256", text$coverage, fixed = TRUE)))
  expect_true(any(grepl("session_info_sha256", text$coverage, fixed = TRUE)))
  expect_true(any(grepl("provenance-logical_${LOGICAL_TASK_ID}", text$coverage, fixed = TRUE)))
  expect_true(any(grepl("manifest-logical_${LOGICAL_TASK_ID}", text$coverage, fixed = TRUE)))
  expect_true(any(grepl("provenance-smoke-logical_${LOGICAL_SMOKE_ID}", text$smoke, fixed = TRUE)))
  expect_equal(sum(grepl("recompile = TRUE", text$coverage, fixed = TRUE)), 1L)
  expect_false(any(grepl("recompile = TRUE", text$smoke, fixed = TRUE)))
  expect_false(any(grepl("rsync -a --delete", text$coverage, fixed = TRUE)))
  expect_false(any(grepl("rsync -a --delete", text$smoke, fixed = TRUE)))
})
}
