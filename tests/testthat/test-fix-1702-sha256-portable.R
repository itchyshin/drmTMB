.sha256_test_oracle_abc <- "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
.sha256_test_oracle_empty <- "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

.sha256_test_artifact_dir <- function() {
  dir <- file.path(tempdir(), "drmTMB sha256 portable tests")
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  abc_path <- file.path(dir, "abc content.txt")
  empty_path <- file.path(dir, "empty content.bin")
  writeBin(charToRaw("abc"), abc_path)
  writeBin(raw(0), empty_path)
  list(dir = dir, abc = abc_path, empty = empty_path)
}

.sha256_test_expect_oracles <- function(backend) {
  art <- .sha256_test_artifact_dir()
  expect_identical(
    drmTMB:::sha256_file_portable(art$abc, backend = backend),
  .sha256_test_oracle_abc
  )
  expect_identical(
    drmTMB:::sha256_file_portable(art$empty, backend = backend),
    .sha256_test_oracle_empty
  )
}

test_that("forced tools backend matches SHA-256 oracles", {
  skip_if_not(
    exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE),
    "tools::sha256sum is not exported on this R version"
  )
  .sha256_test_expect_oracles("tools")
})

test_that("forced openssl backend matches SHA-256 oracles", {
  skip_if_not_installed("openssl")
  .sha256_test_expect_oracles("openssl")
})

test_that("forced digest backend matches SHA-256 oracles", {
  skip_if_not_installed("digest")
  .sha256_test_expect_oracles("digest")
})

test_that("forced sha256sum backend matches SHA-256 oracles", {
  skip_if_not(nzchar(Sys.which("sha256sum")), "sha256sum binary is not on PATH")
  .sha256_test_expect_oracles("sha256sum")
})

test_that("forced shasum backend matches SHA-256 oracles", {
  skip_if_not(nzchar(Sys.which("shasum")), "shasum binary is not on PATH")
  .sha256_test_expect_oracles("shasum")
})

test_that("auto backend uses a non-tools fallback when tools::sha256sum is masked", {
  skip_if_not(
    exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE),
    "tools::sha256sum is not exported; auto already exercises fallbacks"
  )
  has_fallback <- nzchar(Sys.which("sha256sum")) ||
    nzchar(Sys.which("shasum")) ||
    requireNamespace("openssl", quietly = TRUE) ||
    requireNamespace("digest", quietly = TRUE)
  skip_if_not(has_fallback, "no non-tools SHA-256 backend available")
  testthat::local_mocked_bindings(
    sha256sum = function(...) stop("tools::sha256sum masked for #1702 test", call. = FALSE),
    .package = "tools"
  )
  .sha256_test_expect_oracles("auto")
})

test_that("sha256_file_portable handles paths containing spaces", {
  skip_if_not(nzchar(Sys.which("sha256sum")), "sha256sum binary is not on PATH")
  art <- .sha256_test_artifact_dir()
  expect_identical(
    drmTMB:::sha256_file_portable(art$abc, backend = "sha256sum"),
    .sha256_test_oracle_abc
  )
})
