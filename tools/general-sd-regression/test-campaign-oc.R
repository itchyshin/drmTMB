library(testthat)
source("tools/general-sd-regression/campaign-oc.R")

test_that("campaign OC is reproducible and partitions outcomes", {
  scenarios <- campaign_oc_scenarios()[1:3, , drop = FALSE]
  first <- campaign_oc(12L, seed = 9041L, scenarios = scenarios)
  second <- campaign_oc(12L, seed = 9041L, scenarios = scenarios)

  expect_equal(first, second)
  expect_equal(first$accept + first$fail + first$inconclusive,
               first$n_campaigns)
  expect_true(all(first$expected_attempts >= 3000))
  expect_true(all(first$expected_attempts <= 12000))
  expect_true(all(first$accept_mc_lower <= first$accept_mc_upper))
})

test_that("attempt generator keeps coverage and false positives on one interval", {
  set.seed(19L)
  scenario <- campaign_oc_scenarios()[1L, , drop = FALSE]
  attempts <- simulate_campaign_attempts(1000L, scenario)
  zero <- attempts[attempts$truth == 0, , drop = FALSE]
  covered <- zero$valid & zero$lower <= 0 & zero$upper >= 0
  false_positive <- zero$valid & (zero$lower > 0 | zero$upper < 0)
  expect_equal(sum(covered) + sum(false_positive), sum(zero$valid))
  expect_true(all(zero$status == "completed"))
  expect_true(all(is.na(zero$lower[!zero$valid])))
})

test_that("the full frozen helper drives both looks", {
  scenarios <- campaign_oc_scenarios()
  set.seed(2026L)
  nominal <- simulate_one_campaign(scenarios[1L, , drop = FALSE])
  set.seed(2026L)
  biased <- simulate_one_campaign(scenarios[4L, , drop = FALSE])
  expect_true(nominal$decision %in% c("accept", "fail", "inconclusive"))
  expect_true(biased$decision %in% c("accept", "fail", "inconclusive"))
  expect_true(nominal$attempts %in% c(3000L, 12000L))
  expect_equal(nominal$look2, nominal$attempts == 12000L)
  expect_equal(biased$look2, biased$attempts == 12000L)
})

test_that("informative invalidity is represented as dependence", {
  scenarios <- campaign_oc_scenarios()
  expect_equal(scenarios$validity_error_correlation[[1L]], 0)
  expect_gt(scenarios$validity_error_correlation[scenarios$scenario == "informative_invalidity"][[1L]], 0)
  set.seed(37L)
  rows <- simulate_campaign_attempts(5000L, scenarios[scenarios$scenario == "informative_invalidity", , drop = FALSE])
  error <- rows$estimate - rows$truth - scenarios$bias[scenarios$scenario == "informative_invalidity"][[1L]]
  expect_gt(abs(cor(error, as.numeric(rows$valid))), 0.05)
})

test_that("campaign OC reports uncertainty for the complete stopping rule", {
  scenarios <- campaign_oc_scenarios()[1:2, , drop = FALSE]
  result <- campaign_oc(20L, seed = 7081L, scenarios = scenarios)
  required <- c(
    "early_accept", "early_fail", "look2_required", "look2_accept",
    "look2_fail", "look2_inconclusive", "expected_attempts",
    "expected_attempts_mc_lower", "expected_attempts_mc_upper",
    "look2_required_mc_lower", "look2_required_mc_upper",
    "early_fail_mc_lower", "early_fail_mc_upper"
  )
  expect_true(all(required %in% names(result)))
  expect_equal(result$early_accept + result$early_fail + result$look2_required,
               result$n_campaigns)
  expect_equal(result$look2_accept + result$look2_fail +
                 result$look2_inconclusive, result$look2_required)
  expect_true(all(result$expected_attempts_mc_lower <= result$expected_attempts))
  expect_true(all(result$expected_attempts_mc_upper >= result$expected_attempts))
  expect_true(all(is.na(result$look2_accept_given_look2_probability) |
                    result$look2_accept_given_look2_probability >= 0))
  observed <- !is.na(result$look2_accept_given_look2_probability)
  expect_true(all(result$look2_accept_given_look2_mc_lower[observed] <=
                    result$look2_accept_given_look2_probability[observed]))
  expect_true(all(result$look2_accept_given_look2_mc_upper[observed] >=
                    result$look2_accept_given_look2_probability[observed]))
})

test_that("look-two rates distinguish unconditional and conditional probabilities", {
  summary <- summarize_look2_outcomes(
    c("accept", "accept", "fail", NA_character_), n_campaigns = 4L
  )
  expect_equal(summary$look2_required, 3L)
  expect_equal(summary$look2_accept_probability, 0.5)
  expect_equal(summary$look2_accept_given_look2_probability, 2 / 3)
  expect_equal(summary$look2_fail_given_look2_probability, 1 / 3)
  expect_true(summary$look2_accept_given_look2_mc_lower <= 2 / 3)
  expect_true(summary$look2_accept_given_look2_mc_upper >= 2 / 3)

  none <- summarize_look2_outcomes(rep(NA_character_, 4L), n_campaigns = 4L)
  expect_equal(none$look2_required, 0L)
  expect_equal(none$look2_accept_probability, 0)
  expect_equal(none$look2_accept_mc_lower, 0)
  expect_gt(none$look2_accept_mc_upper, 0)
  expect_true(is.na(none$look2_accept_given_look2_probability))
  expect_true(is.na(none$look2_accept_given_look2_mc_lower))
  expect_error(
    summarize_look2_outcomes(c("unexpected", NA_character_), n_campaigns = 2L),
    "unexpected look-two outcome"
  )
})

test_that("OC scenarios include coherent joint boundaries and estimator failures", {
  scenarios <- campaign_oc_scenarios()
  expect_true(all(c("joint_lower_boundary", "joint_upper_boundary",
                    "log_bias_boundary", "relative_bias_boundary",
                    "fit_failures") %in% scenarios$scenario))
  boundary <- scenarios[scenarios$scenario == "joint_lower_boundary", ]
  expect_equal(boundary$valid_fraction, 0.95)
  expect_equal(boundary$valid_fraction *
                 (2 * stats::pnorm(boundary$interval_width) - 1),
               0.925, tolerance = 1e-10)
  upper <- scenarios[scenarios$scenario == "joint_upper_boundary", ]
  expect_equal(upper$valid_fraction, 1)
  expect_equal(2 * stats::pnorm(upper$interval_width) - 1,
               0.975, tolerance = 1e-10)
  failures <- scenarios[scenarios$scenario == "fit_failures", ]
  expect_gt(failures$fit_failure_fraction, 0)
  set.seed(991L)
  attempts <- simulate_campaign_attempts(5000L, failures)
  expect_lt(abs(sum(attempts$status == "error") -
                   round(15000 * failures$fit_failure_fraction)), 100)
  expect_true(all(!attempts$valid[attempts$status == "error"]))
  expect_true(all(is.na(attempts$estimate[attempts$status == "error"])))
})

test_that("zero-truth interval outcomes retain their three-way dependence", {
  scenarios <- campaign_oc_scenarios()
  set.seed(402L)
  for (i in seq_len(nrow(scenarios))) {
    attempts <- simulate_campaign_attempts(2000L, scenarios[i, , drop = FALSE])
    zero <- attempts[attempts$truth == 0, , drop = FALSE]
    covered <- zero$valid & zero$lower <= 0 & zero$upper >= 0
    excluded <- zero$valid & (zero$lower > 0 | zero$upper < 0)
    invalid <- !zero$valid
    expect_equal(sum(covered) + sum(excluded) + sum(invalid), nrow(zero))
    expect_equal(sum(covered) + sum(excluded), sum(zero$valid))
    expect_true(all(!covered | !excluded))
  }
})

test_that("bias boundary scenarios retain nominal interval gates", {
  scenarios <- campaign_oc_scenarios()
  for (name in c("log_bias_boundary", "relative_bias_boundary")) {
    s <- scenarios[scenarios$scenario == name, , drop = FALSE]
    shift <- s$bias / s$estimator_sd
    conditional_coverage <- stats::pnorm(s$interval_width - shift) -
      stats::pnorm(-s$interval_width - shift)
    conditional_false_positive <- stats::pnorm(-s$interval_width - shift) +
      1 - stats::pnorm(s$interval_width - shift)
    expect_equal(s$valid_fraction * conditional_coverage, 0.99 * 0.95,
                 tolerance = 1e-8)
    expect_equal(s$valid_fraction * conditional_false_positive, 0.99 * 0.05,
                 tolerance = 1e-8)
  }
  log_edge <- scenarios$bias[scenarios$scenario == "log_bias_boundary"]
  relative_edge <- scenarios$bias[scenarios$scenario == "relative_bias_boundary"]
  sd <- scenarios$estimator_sd[[1L]]
  expect_gt(exp(log_edge + 0.5 * sd^2) - 1, 0.10)
  expect_equal(exp(relative_edge + 0.5 * sd^2) - 1, 0.10,
               tolerance = 1e-12)
})
