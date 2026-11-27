# Baked build-provenance path in R/provenance.R (complements unavailable-path tests in
# test-provenance.R, which skip when a DCF is present).

test_that("drm_provenance() reads the installed bake when build-provenance.dcf exists", {
  baked <- system.file("build-provenance.dcf", package = "drmTMB")
  skip_if(!nzchar(baked) || !file.exists(baked), "installed build has no baked provenance DCF")

  rec <- drm_provenance()
  expect_identical(rec$source, "baked")
  expect_false(is.na(rec$git_sha))
  expect_match(rec$git_sha, "^[0-9a-f]{40}$")
  expect_true(is.logical(rec$git_dirty))
  expect_false(is.na(rec$build_time))
  expect_match(rec$build_time, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$")
  expect_true(is.na(rec$reason))
  expect_equal(rec$package_version, as.character(utils::packageVersion("drmTMB")))
})