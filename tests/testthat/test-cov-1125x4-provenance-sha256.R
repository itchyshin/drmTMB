# R/provenance.R and R/sha256-portable.R.

test_that("drm_provenance() reports unavailable metadata under pkgload", {
  prov <- drm_provenance()
  expect_type(prov$package_version, "character")
  expect_true(prov$source %in% c("unavailable", "baked", "baked-without-git"))
  expect_true(is.logical(prov$git_dirty) || is.na(prov$git_dirty))
  expect_match(prov$queried_at, "^[0-9]{4}-[0-9]{2}-[0-9]{2}T")
})

test_that("sha256_file_portable() hashes a tempfile consistently", {
  tf <- tempfile()
  writeLines("drmTMB cov-1125x4", tf)
  on.exit(unlink(tf), add = TRUE)
  h1 <- drmTMB:::sha256_file_portable(tf)
  expect_length(h1, 1L)
  expect_match(h1, "^[0-9a-f]{64}$")
  h2 <- drmTMB:::sha256_file_portable(tf, backend = "sha256sum")
  expect_identical(h1, h2)
})

test_that("sha256_file_portable() errors on missing paths", {
  expect_error(
    drmTMB:::sha256_file_portable("/nonexistent/path/file.txt"),
    "No such file"
  )
})