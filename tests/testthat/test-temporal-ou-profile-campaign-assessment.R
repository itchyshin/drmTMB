assessment_path <- testthat::test_path(
  "..", "..", "tools", "temporal-ou-profile-campaign-assessment.R"
)
assessment_environment <- new.env(parent = baseenv())
sys.source(assessment_path, envir = assessment_environment)

test_that("temporal OU campaign assessment applies all predeclared criteria", {
  z <- stats::qnorm(0.975)
  reference <- data.frame(
    n_attempted = 1000L,
    availability = 0.99,
    coverage_all = 0.95,
    coverage_mcse = sqrt(0.95 * 0.05 / 1000),
    bias = 0.05,
    empirical_sd = 1,
    mean_interval_width = 2 * z,
    stringsAsFactors = FALSE
  )
  pass <- assessment_environment$temporal_ou_profile_campaign_assess(reference)
  expect_identical(pass$qualification, "qualified_in_simulated_cell")
  expect_equal(pass$mean_profile_se_analogue, 1)
  expect_equal(pass$profile_se_analogue_ratio, 1)

  cases <- rbind(reference, reference, reference, reference)
  cases$coverage_all[[1L]] <- 0.93
  cases$coverage_mcse[[1L]] <- sqrt(0.93 * 0.07 / 1000)
  cases$availability[[2L]] <- 0.989
  cases$bias[[3L]] <- 0.101
  cases$mean_interval_width[[4L]] <- 2 * z * 0.89
  assessed <- assessment_environment$temporal_ou_profile_campaign_assess(cases)
  expect_false(any(assessed$criterion_coverage[[1L]]))
  expect_false(assessed$criterion_availability[[2L]])
  expect_false(assessed$criterion_bias[[3L]])
  expect_false(assessed$criterion_profile_se[[4L]])
  expect_true(all(assessed$qualification == "unqualified_in_simulated_cell"))
})

test_that("temporal OU campaign assessment fails closed for incomplete summaries", {
  expect_error(
    assessment_environment$temporal_ou_profile_campaign_assess(data.frame(availability = 1)),
    "lacks fields"
  )
})
