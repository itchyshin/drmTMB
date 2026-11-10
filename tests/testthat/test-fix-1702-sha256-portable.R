test_that("sha256_file_portable matches tools::sha256sum on a temp file when exported", {
  skip_if_not(
    exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE),
    "tools::sha256sum is not exported on this R version"
  )
  f <- tempfile("drmTMB-sha256-")
  on.exit(unlink(f), add = TRUE)
  writeLines("drmTMB #1702 portable SHA-256", f)
  got <- drmTMB:::sha256_file_portable(f)
  expect_identical(got, unname(tools::sha256sum(f)[[1L]]))
})

test_that("sha256_file_portable matches a fixed digest without tools::sha256sum", {
  skip_if(
    exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE),
    "tools::sha256sum is exported; covered by the temp-file test"
  )
  f <- tempfile("drmTMB-sha256-empty-")
  on.exit(unlink(f), add = TRUE)
  writeBin(raw(0), f)
  expect_identical(
    drmTMB:::sha256_file_portable(f),
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  )
})
