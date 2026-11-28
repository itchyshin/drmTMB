# Portable hashing in R/sha256-portable.R.

test_that("sha256_file_portable() hashes a temp file (auto backend)", {
  path <- tempfile(fileext = ".txt")
  writeLines("drmTMB cov 1125x6", path)
  on.exit(unlink(path), add = TRUE)
  digest <- drmTMB:::sha256_file_portable(path, backend = "auto")
  expect_type(digest, "character")
  expect_length(digest, 1L)
  expect_match(digest, "^[0-9a-f]{64}$")
  expect_equal(digest, drmTMB:::sha256_file_portable(path, backend = "auto"))
  expect_gt(nchar(digest), 60L)
})

test_that("sha256_file_portable() rejects missing paths", {
  missing <- file.path(tempdir(), paste0("missing-", Sys.getpid(), ".bin"))
  expect_error(drmTMB:::sha256_file_portable(missing, backend = "auto"))
})