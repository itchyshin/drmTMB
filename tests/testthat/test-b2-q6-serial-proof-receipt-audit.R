test_that("q6 serial receipt audit derives the supervised result root", {
  root <- normalizePath(test_path("..", ".."), mustWork = TRUE)
  audit_path <- file.path(root, "tools", "audit-b2-q6-serial-proof-cohort.R")
  if (!file.exists(audit_path)) {
    skip("Top-level tools are intentionally excluded from the source tarball")
  }
  e <- new.env(parent = globalenv())
  sys.source(audit_path, envir = e)
  auth <- file.path(root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-31-b2-q6-proof-serial-approved-execution-authorization.tsv")
  out <- tempfile(fileext = ".tsv")
  audit <- e$b2_q6_audit_run(root, auth, out)
  expect_identical(audit$cell_id, c("mc-0102", "mc-0124", "mc-0146", "mc-0168"))
  expect_true(all(audit$declared_root_is_stale))
  expect_true(all(audit$source_enforces_serial))
  expect_true(all(audit$artifact_chronology_ok))
  expect_true(all(audit$recommendation_eligible))
  expect_true(file.exists(out))
})
