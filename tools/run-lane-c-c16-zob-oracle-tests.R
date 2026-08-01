#!/usr/bin/env Rscript

# Source-pinned execution receipt for the model-15 structured zero-one-beta
# oracle, gradient, endpoint, and neighbour-rejection tests.  The test file
# contains the independent complete-mixture-plus-precision oracles; this
# runner records that they were executed at a particular source SHA.

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)

out <- Sys.getenv(
  "DRMTMB_RECOVERY_OUT",
  unset = file.path(root, "docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-wave-a-oracle-tests")
)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner_md5 <- unname(tools::md5sum(script))

exit_status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("-e", shQuote("devtools::test(filter = '^zero-one-beta$')"))
)
status <- if (identical(exit_status, 0L)) "PASS" else paste0("FAIL: child R exit status ", exit_status)

cells <- data.frame(
  cell_id = c(sprintf("mc-%04d", 583:587), sprintf("mc-%04d", 593:597)),
  dpar = c(rep("mu", 5L), rep("sigma", 5L)),
  provider = rep(c("phylo", "animal", "relmat", "spatial", "phylo_interaction"), 2L),
  source_sha = sha,
  runner_md5 = runner_md5,
  test_file = "tests/testthat/test-zero-one-beta.R",
  command = "testthat::test_file(..., StopReporter)",
  result = status,
  stringsAsFactors = FALSE
)
write_tsv(cells, file.path(out, "oracle-test-receipt.tsv"))
if (!identical(status, "PASS")) quit(status = 1L)
