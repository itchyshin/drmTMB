profile_ties_fixture <- function(parameter, objective) {
  structure(
    data.frame(target = parameter, value = objective),
    class = c("tmbprofile", "data.frame")
  )
}

test_that("profile interval inversion explicitly averages tied objective coordinates", {
  prof <- profile_ties_fixture(
    c(-2, -1, -0.5, 0, 0.5, 1, 2),
    17 + c(3, 1, 1, 0, 1, 1, 3)
  )
  # The upstream method may warn while resolving its implicit default ties.
  # Only the numerical result is the compatibility oracle: an upstream
  # warning fix must not itself break this regression test.
  expected <- suppressWarnings(stats::confint(prof))
  got <- NULL
  expect_warning(
    got <- drmTMB:::drm_tmbprofile_confint(prof, "target", 0.95),
    NA
  )
  expect_equal(got, expected, tolerance = 0)
  cutoff <- 0.5 * stats::qchisq(0.95, df = 1)
  distance <- 0.75 + (cutoff - 1) * (2 - 0.75) / (3 - 1)
  expect_equal(unname(got[1, ]), c(-distance, distance), tolerance = 1e-14)
})

test_that("profile interval inversion preserves unique-point TMB semantics", {
  prof <- profile_ties_fixture(c(-2, -1, 0, 1, 2), c(4, 1, 0, 1.5, 4))
  expect_identical(
    drmTMB:::drm_tmbprofile_confint(prof, "target", 0.95),
    stats::confint(prof, level = 0.95)
  )
})

test_that("profile inversion preserves the first minimum split and outside-range NA", {
  prof <- profile_ties_fixture(
    c(-3, -2, -1, 0, 0.25, 1, 2, 3),
    c(4, 2, 2, 0, 0, 2, 2, 4)
  )
  expected <- suppressWarnings(stats::confint(prof, level = 0.95))
  got <- NULL
  expect_warning(
    got <- drmTMB:::drm_tmbprofile_confint(prof, "target", 0.95),
    NA
  )
  expect_identical(got, expected)
  outside <- NULL
  expect_warning(
    outside <- drmTMB:::drm_tmbprofile_confint(prof, "target", 0.99999),
    NA
  )
  expect_true(all(is.na(outside)))
  expect_identical(
    outside,
    suppressWarnings(stats::confint(prof, level = 0.99999))
  )
})
