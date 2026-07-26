runner_path <- testthat::test_path("..", "..", "tools", "run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R")
source(runner_path, local = TRUE)

test_that("F3R accepts only its frozen CLI shape", {
  sha <- paste(rep("a", 40), collapse = "")
  expect_equal(f3r_parse_args(c(paste0("--expected-sha=", sha), "--out-dir=attempt-001"))$expected_sha, sha)
  expect_error(f3r_parse_args(c("--out-dir=x")), "Usage")
  expect_error(f3r_parse_args(c("--expected-sha", sha, "--out-dir", "attempt-001")), "Usage")
  expect_error(f3r_parse_args(c("--expected-sha=short", "--out-dir=x")), "40-character")
})

test_that("F3R status CSV has exact columns, precedence, and no interval", {
  status <- f3r_status(paste(rep("a", 40), collapse = ""), "bernoulli_margin", "bernoulli_margin_failure")
  expect_identical(names(status), f3r_status_columns)
  expect_identical(status$terminal_stage, "bernoulli_margin")
  expect_identical(status$terminal_status, "bernoulli_margin_failure")
  expect_false(status$private_result_available)
  expect_identical(status$interval_status, "not_attempted")
  expect_error(f3r_status(paste(rep("a", 40), collapse = ""), "complete", "delta_failure"), "not permitted")
  expect_error(f3r_status(paste(rep("a", 40), collapse = ""), "rectangle", "bread_solve_failure"), "not permitted")
  expect_identical(f3r_sandwich_terminal(list(reason = "eta_delta_unstable")), c("delta", "eta_delta_unstable"))
  expect_identical(f3r_sandwich_terminal(list(reason = "association_step_unstable")), c("rectangle", "association_step_unstable"))
})

test_that("F3R source guard does not execute f3r_main", {
  source_text <- readLines(runner_path)
  expect_true(any(grepl("if \\(sys.nframe\\(\\) == 0L\\) f3r_main\\(\\)", source_text)))
})

test_that("F3R rectangle gate requires every association row numeric to be ok", {
  expect_true(f3r_rectangle_available(list(diagnostics = list(count_interval = list(row_numerics = data.frame(status = c("ok", "ok")))))))
  expect_false(f3r_rectangle_available(list(diagnostics = list(count_interval = list(row_numerics = data.frame(status = c("ok", "unresolved")))))))
})

test_that("F3R records the serialized dataset hash, not the inspection CSV hash", {
  source_text <- paste(readLines(runner_path), collapse = "\n")
  expect_match(source_text, 'saveRDS\\(dat, file.path\\(opts\\$out_dir, "input", "dataset.rds"\\)\\)')
  expect_match(source_text, 'f3r_hash_file\\(file.path\\(opts\\$out_dir, "input", "dataset.rds"\\)')
})

test_that("F3R preflight stops for an existing directory and SHA mismatch", {
  root <- tempfile("f3r-root-"); dir.create(root); dir.create(file.path(root, "R")); file.create(file.path(root, "DESCRIPTION"))
  sha <- paste(rep("a", 40), collapse = ""); out <- f3r_expected_out_dir(root, sha); dir.create(out, recursive = TRUE); helper <- new.env(parent = emptyenv()); assign("drm_pair_nbinom2_quantile_from_normal", TRUE, helper); assign("drm_pair_general_eta_sandwich", TRUE, helper)
  ok_runner <- function(command, args, stdout, stderr) if (identical(args, c("status", "--porcelain"))) character() else paste(rep("a", 40), collapse = "")
  expect_error(f3r_preflight(sha, out, root, ok_runner, function(x) c(shasum = "/x", sha256sum = ""), helper), "clobber")
})

test_that("F3R rejects an output directory other than the frozen SHA-specific attempt", {
  sha <- paste(rep("a", 40), collapse = "")
  root <- tempfile("f3r-root-"); dir.create(root)
  expected <- f3r_expected_out_dir(root, sha)
  expect_silent(f3r_check_out_dir(expected, root, sha))
  expect_error(f3r_check_out_dir(file.path(root, "attempt-002"), root, sha), "frozen F3R")
})

test_that("F3R stage ledger has nine ordered rows and retains a DGP-like terminal", {
  ledger <- f3r_stage_ledger("dgp_harness", "serialization error")
  expect_identical(ledger$stage, f3r_stages)
  expect_identical(ledger$status[[1L]], "failed")
  expect_true(all(ledger$status[-1L] == "not_attempted"))
})

test_that("F3R stage ledger marks reached stages ok and never attempts interval", {
  ledger <- f3r_stage_ledger("complete", "success")
  expect_true(all(ledger$status[seq_len(8L)] == "ok"))
  expect_identical(ledger$status[[9L]], "not_attempted")
})

test_that("F3R receipt-finalization failure is recorded as provenance mismatch", {
  root <- tempfile("f3r-finalize-"); dir.create(root); out <- file.path(root, "attempt-001"); f3r_layout(out)
  gate <- list(source_sha = paste(rep("a", 40), collapse = ""), source_blobs = f3r_blobs, sha256_command = c("shasum", "-a", "256"))
  opts <- list(out_dir = out)
  expect_error(
    f3r_finalize_receipt(
      f3r_status(gate$source_sha, "complete", "success"), "delta", "delta_failure", gate, opts, NA_character_,
      metadata_writer = function(...) stop("forced metadata write failure")
    ),
    "receipt finalization failed"
  )
  status <- utils::read.csv(file.path(out, "status.csv"), stringsAsFactors = FALSE)
  expect_identical(status$terminal_stage, "dgp_harness")
  expect_identical(status$terminal_status, "provenance_mismatch")
  ledger <- utils::read.csv(file.path(out, "stage-status.csv"), stringsAsFactors = FALSE)
  expect_identical(ledger$status[[1L]], "failed")
  expect_true(all(ledger$status[-1L] == "not_attempted"))
})

test_that("F3R post-transition error receipt records the reached stage", {
  for (case in list(c("bernoulli_margin", "bernoulli_margin_failure"), c("nb2_dispersion", "nb2_dispersion_failure"))) {
    root <- tempfile("f3r-transition-"); dir.create(root); out <- file.path(root, "attempt-001"); f3r_layout(out)
    gate <- list(source_sha = paste(rep("a", 40), collapse = ""), source_blobs = f3r_blobs, sha256_command = c("shasum", "-a", "256"))
    f3r_finalize_receipt(NULL, case[[1L]], case[[2L]], gate, list(out_dir = out), NA_character_, metadata_writer = function(...) invisible(NULL))
    status <- utils::read.csv(file.path(out, "status.csv"), stringsAsFactors = FALSE)
    expect_identical(status$terminal_stage, case[[1L]])
    expect_identical(status$terminal_status, case[[2L]])
    ledger <- utils::read.csv(file.path(out, "stage-status.csv"), stringsAsFactors = FALSE)
    expect_identical(ledger$status[[match(case[[1L]], ledger$stage)]], "failed")
  }
  expect_false(any(grepl("active_(stage|status) <<-", readLines(runner_path))))
})

test_that("F3R summary availability fields are independent", {
  status <- f3r_status(paste(rep("a", 40), collapse = ""), "sandwich", "sandwich_failure", private_result_available = TRUE, alpha_godambe_available = TRUE, eta_delta_available = FALSE)
  expect_true(status$private_result_available)
  expect_true(status$alpha_godambe_available)
  expect_false(status$eta_delta_available)
})

test_that("F3R fingerprints through the supplied local namespace", {
  local_namespace <- new.env(parent = emptyenv())
  assign("drm_pair_fingerprint", function(x) paste0("local-", x), local_namespace)
  expect_identical(f3r_fit_id("fit", local_namespace), "local-fit")
})

test_that("F3R selects a loaded local namespace without a fit", {
  root <- tempfile("f3r-local-"); dir.create(root)
  called <- NULL
  ns <- asNamespace("drmTMB")
  expect_error(f3r_load_local_namespace(root,
    loader = function(path, quiet, export_all) { called <<- path; invisible(NULL) },
    namespace_getter = function(...) ns
  ), "not the preflighted")
  expect_identical(called, root)
})

test_that("F3R restores RNG state without generating data or fitting", {
  set.seed(41); old_kind <- RNGkind(); old_seed <- .Random.seed
  f3r_with_rng({ expect_identical(RNGkind(), c("Mersenne-Twister", "Inversion", "Rejection")); runif(1) })
  expect_identical(RNGkind(), old_kind); expect_identical(.Random.seed, old_seed)
})
