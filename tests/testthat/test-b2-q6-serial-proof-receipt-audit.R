# The q6 serial proof audit has two halves with different evidence bases.
#
# The PROVENANCE half reconstructs the frozen runner identity out of git
# history: it resolves `<runner_source_sha>^{tree}` and reads
# `<runner_source_sha>:tools/...` to confirm the runner enforced serial
# execution. That commit -- a8d068e641105473b3f30723a92c909467a46fac,
# "feat: supervise q6 retained profile cohort" -- was never pushed. No remote
# ref contains it (`git branch -r --contains` is empty) and the GitHub API
# returns 422 for it, so no clone made from the remote can hold the object,
# shallow or full; `fetch-depth: 0` would not help. Measured in a history-free
# checkout of this tree: `rev-parse` exits 128 and the audit stops with
# "Runner tree does not match authorization." -- byte-identical to the CI
# failure. So this half is gated on the object being present: it runs in full
# in a clone that still carries the unpushed commit, and says why it cannot
# run anywhere else, rather than failing on a premise the published repository
# cannot supply.
#
# The INTEGRITY half needs no git history at all -- the receipt, trace and
# interval artefacts are committed. It is asserted unconditionally below, so
# this file keeps real coverage in CI instead of going dark behind the gate.

b2_q6_authorization_path <- function(root) {
  file.path(root, "docs", "dev-log", "interval-campaign-bindings",
            "2026-07-31-b2-q6-proof-serial-approved-execution-authorization.tsv")
}

b2_q6_read_authorization <- function(root) {
  utils::read.delim(b2_q6_authorization_path(root), check.names = FALSE,
                    stringsAsFactors = FALSE, colClasses = "character")
}

b2_q6_audit_env <- function(root) {
  e <- new.env(parent = globalenv())
  sys.source(file.path(root, "tools", "audit-b2-q6-serial-proof-cohort.R"), envir = e)
  e
}

b2_q6_runner_commit_present <- function(root, sha) {
  identical(
    system2("git", c("-C", shQuote(root), "cat-file", "-e", shQuote(paste0(sha, "^{commit}"))),
            stdout = FALSE, stderr = FALSE),
    0L
  )
}

test_that("q6 serial receipt audit derives the supervised result root", {
  root <- normalizePath(test_path("..", ".."), mustWork = TRUE)
  audit_path <- file.path(root, "tools", "audit-b2-q6-serial-proof-cohort.R")
  if (!file.exists(audit_path)) {
    skip("Top-level tools are intentionally excluded from the source tarball")
  }
  sha <- unique(b2_q6_read_authorization(root)$runner_source_sha)
  expect_length(sha, 1L)
  if (!b2_q6_runner_commit_present(root, sha)) {
    skip(paste0(
      "frozen runner source commit ", substr(sha, 1L, 9L), " is absent from this clone: ",
      "it was never pushed to the remote, so the audit's git-history provenance premise ",
      "cannot be reconstructed here (receipt integrity is asserted unconditionally below)"
    ))
  }
  e <- b2_q6_audit_env(root)
  out <- tempfile(fileext = ".tsv")
  audit <- e$b2_q6_audit_run(root, b2_q6_authorization_path(root), out)
  expect_identical(audit$cell_id, c("mc-0102", "mc-0124", "mc-0146", "mc-0168"))
  expect_true(all(audit$declared_root_is_stale))
  expect_true(all(audit$source_enforces_serial))
  expect_true(all(audit$artifact_chronology_ok))
  expect_true(all(audit$recommendation_eligible))
  expect_true(file.exists(out))
})

test_that("committed q6 proof receipts still match their own artefacts and acceptance", {
  root <- normalizePath(test_path("..", ".."), mustWork = TRUE)
  audit_path <- file.path(root, "tools", "audit-b2-q6-serial-proof-cohort.R")
  if (!file.exists(audit_path)) {
    skip("Top-level tools are intentionally excluded from the source tarball")
  }
  e <- b2_q6_audit_env(root)
  auth <- b2_q6_read_authorization(root)
  expect_identical(auth$cell_id, c("mc-0102", "mc-0124", "mc-0146", "mc-0168"))
  for (i in seq_len(nrow(auth))) {
    row <- auth[i, , drop = FALSE]
    dir <- e$b2_q6_audit_result_dir(root, row)
    trace_path <- e$b2_q6_audit_one_file(dir, "trace", row$cell_id)
    interval_path <- e$b2_q6_audit_one_file(dir, "interval", row$cell_id)
    receipt_path <- e$b2_q6_audit_one_file(dir, "receipt", row$cell_id)
    receipt <- utils::read.delim(receipt_path, check.names = FALSE,
                                 stringsAsFactors = FALSE, colClasses = "character")
    expect_identical(nrow(receipt), 1L)
    expect_identical(receipt$cell_id, row$cell_id)
    expect_identical(receipt$target_id, row$target_id)
    expect_identical(receipt$runner_source_sha, row$runner_source_sha)
    expect_identical(receipt$trace_sha256, e$b2_q6_audit_hash(trace_path))
    expect_identical(receipt$interval_sha256, e$b2_q6_audit_hash(interval_path))
    expect_identical(receipt$conf_status, "profile")
    expect_identical(receipt$convergence, "0")
    expect_identical(receipt$pdHess, "TRUE")
    expect_identical(receipt$profile_boundary, "FALSE")
    expect_identical(receipt$trace_complete, "TRUE")
    expect_false(nzchar(receipt$failure_reason))
    values <- as.numeric(c(receipt$estimate, receipt$lower, receipt$upper))
    expect_true(all(is.finite(values)))
    expect_lt(values[[2L]], values[[3L]])
    expect_gte(values[[1L]], values[[2L]])
    expect_lte(values[[1L]], values[[3L]])
  }
})
