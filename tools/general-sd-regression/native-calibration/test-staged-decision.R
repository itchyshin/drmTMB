decision_path <- if (file.exists("staged-decision.R")) {
  "staged-decision.R"
} else {
  "tools/general-sd-regression/native-calibration/staged-decision.R"
}
sys.source(decision_path, envir = environment())

staged_attempts <- function(n_per_truth, coverage_per_truth, false_positives = 0L) {
  truths <- c(-0.5, 0, 0.5)
  out <- lapply(truths, function(truth) {
    n <- n_per_truth
    lower <- rep(truth - 0.1, n)
    upper <- rep(truth + 0.1, n)
    n_noncover <- n - coverage_per_truth[[as.character(truth)]]
    if (truth == 0 && false_positives > 0L) {
      ix_fp <- seq_len(false_positives)
      lower[ix_fp] <- 0.1
      upper[ix_fp] <- 0.2
      remaining <- setdiff(seq_len(n), ix_fp)
      ix_other <- head(remaining, max(0L, n_noncover - false_positives))
      lower[ix_other] <- -0.2
      upper[ix_other] <- -0.1
    } else if (n_noncover > 0L) {
      ix <- seq_len(n_noncover)
      if (truth > 0) {
        lower[ix] <- truth + 0.1
        upper[ix] <- truth + 0.2
      } else {
        lower[ix] <- truth - 0.2
        upper[ix] <- truth - 0.1
      }
    }
    data.frame(
      truth = rep(truth, n),
      estimate = rep(truth, n),
      lower = lower,
      upper = upper,
      valid = rep(TRUE, n),
      status = rep("completed", n),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

test_that("look one accepts only when every adjusted-precision gate passes", {
  attempts <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 950L, "0.5" = 950L),
    false_positives = 50L
  )
  result <- native_sd_staged_decision(
    attempts, manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )

  expect_identical(result$decision, "accept")
  coverage <- result$metrics[result$metrics$metric == "coverage", , drop = FALSE]
  expect_equal(coverage$n, rep(1000L, 3L))
  expect_equal(coverage$success, rep(950L, 3L))
  expect_equal(
    coverage$ci_lower[[1L]],
    stats::binom.test(950L, 1000L, conf.level = 0.975)$conf.int[[1L]]
  )
  false_positive <- result$metrics[result$metrics$metric == "false_positive", , drop = FALSE]
  expect_equal(false_positive$success, 50L)
  expect_true(all(result$gates$state == "pass"))
})

test_that("look one fails a gate only when its confidence interval is outside", {
  attempts <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 950L, "0.5" = 800L),
    false_positives = 50L
  )
  result <- native_sd_staged_decision(
    attempts, manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )

  expect_identical(result$decision, "fail")
  bad <- result$gates[result$gates$truth == 0.5 &
                        result$gates$metric == "coverage", , drop = FALSE]
  expect_identical(bad$state, "fail")
})

test_that("relative exp(a) bias is reported without an unvalidated gate", {
  attempts <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 950L, "0.5" = 950L),
    false_positives = 50L
  )
  positive_rows <- which(attempts$truth == 0.5)
  jitter <- seq(-0.001, 0.001, length.out = length(positive_rows))
  attempts$estimate[positive_rows] <-
    attempts$estimate[positive_rows] + 0.097 + jitter
  result <- native_sd_staged_decision(
    attempts, manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )

  expect_identical(result$decision, "accept")
  expect_false(any(result$gates$metric %in% c(
    "log_sd_bias", "relative_exp_a_bias"
  )))
  bias <- result$metrics[result$metrics$truth == 0.5 &
                            result$metrics$metric == "log_sd_bias", , drop = FALSE]
  expected <- stats::t.test(
    attempts$estimate[attempts$truth == 0.5] - 0.5,
    conf.level = 0.975
  )$conf.int
  expect_equal(bias$ci_lower, unname(expected[[1L]]))
  expect_equal(bias$ci_upper, unname(expected[[2L]]))
})

test_that("approximate bias intervals are diagnostics, not acceptance gates", {
  attempts <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 950L, "0.5" = 950L),
    false_positives = 50L
  )
  attempts$estimate <- attempts$estimate + 0.20

  result <- native_sd_staged_decision(
    attempts, manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )

  expect_identical(result$decision, "accept")
  expect_false(any(result$gates$metric %in% c(
    "log_sd_bias", "relative_exp_a_bias"
  )))
  expect_true(all(c("log_sd_bias", "relative_exp_a_bias") %in%
                    result$metrics$metric))
  expect_equal(
    result$metrics$estimate[result$metrics$truth == 0.5 &
                               result$metrics$metric == "log_sd_bias"],
    0.20
  )
})

test_that("overlap at look one requests look two and overlap at look two is inconclusive", {
  first <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 950L, "0.5" = 925L),
    false_positives = 50L
  )
  first_result <- native_sd_staged_decision(
    first, manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )
  expect_identical(first_result$decision, "look2_required")
  expect_true(any(first_result$gates$state == "ambiguous"))

  second <- staged_attempts(
    4000L,
    c("-0.5" = 3800L, "0" = 3800L, "0.5" = 3700L),
    false_positives = 200L
  )
  second_result <- native_sd_staged_decision(
    second, manifest_count = 12000L, look = 2L,
    completed_campaign = TRUE
  )
  expect_identical(second_result$decision, "inconclusive")
  expect_true(any(second_result$gates$state == "ambiguous"))
})

test_that("incomplete and inconsistent denominators cannot qualify", {
  attempts <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 950L, "0.5" = 950L),
    false_positives = 50L
  )
  incomplete <- native_sd_staged_decision(
    attempts[-1L, ], manifest_count = 3000L, look = 1L,
    completed_campaign = FALSE
  )
  expect_identical(incomplete$decision, "incomplete")

  missing <- native_sd_staged_decision(
    attempts[-1L, ], manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )
  expect_identical(missing$decision, "integrity_failure")
})

test_that("failed attempts remain in denominators without automatic health collapse", {
  attempts <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 950L, "0.5" = 950L),
    false_positives = 50L
  )
  failed_ix <- which(attempts$truth == 0.5)[[1L]]
  attempts$status[[failed_ix]] <- "error"
  attempts$valid[[failed_ix]] <- FALSE
  attempts$estimate[[failed_ix]] <- NA_real_

  result <- native_sd_staged_decision(
    attempts, manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )

  expect_identical(result$decision, "accept")
  positive <- result$metrics[result$metrics$truth == 0.5, , drop = FALSE]
  valid_fraction <- positive[positive$metric == "valid_fraction", , drop = FALSE]
  coverage <- positive[positive$metric == "coverage", , drop = FALSE]
  bias <- positive[positive$metric == "log_sd_bias", , drop = FALSE]
  expect_equal(valid_fraction$success, 999L)
  expect_equal(coverage$success, 950L)
  expect_equal(coverage$n, 1000L)
  expect_equal(bias$n, 999L)
  expect_false("log_sd_bias" %in% result$gates$metric)
})

test_that("contradictory validity and terminal status fail integrity checks", {
  attempts <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 950L, "0.5" = 950L),
    false_positives = 50L
  )
  attempts$status[[1L]] <- "timeout"
  result <- native_sd_staged_decision(
    attempts, manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )
  expect_identical(result$decision, "integrity_failure")
})

test_that("completed campaign cannot contain unresolved supervisor states", {
  attempts <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 950L, "0.5" = 950L),
    false_positives = 50L
  )
  attempts$status[[1L]] <- "not_started"
  result <- native_sd_staged_decision(
    attempts, manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )
  expect_identical(result$decision, "integrity_failure")
})

test_that("zero-truth planned coverage, false positives, and validity partition attempts", {
  attempts <- staged_attempts(
    1000L,
    c("-0.5" = 950L, "0" = 900L, "0.5" = 950L),
    false_positives = 100L
  )
  zero_rows <- which(attempts$truth == 0)
  # Endpoint equality remains coverage and is not a false positive.
  attempts$lower[zero_rows[[31L]]] <- 0
  attempts$upper[zero_rows[[31L]]] <- 0.1
  attempts$lower[zero_rows[[32L]]] <- -0.1
  attempts$upper[zero_rows[[32L]]] <- 0
  invalid_rows <- zero_rows[seq_len(30L)]
  attempts$valid[invalid_rows] <- FALSE
  attempts$status[invalid_rows] <- "timeout"
  attempts$estimate[invalid_rows] <- NA_real_
  attempts$lower[invalid_rows] <- NA_real_
  attempts$upper[invalid_rows] <- NA_real_

  result <- native_sd_staged_decision(
    attempts, manifest_count = 3000L, look = 1L,
    completed_campaign = TRUE
  )
  zero_metrics <- result$metrics[result$metrics$truth == 0, , drop = FALSE]
  coverage <- zero_metrics[zero_metrics$metric == "coverage", , drop = FALSE]
  false_positive <- zero_metrics[zero_metrics$metric == "false_positive", , drop = FALSE]
  valid <- zero_metrics[zero_metrics$metric == "valid_fraction", , drop = FALSE]

  expect_equal(coverage$success + false_positive$success, valid$success)
  expect_equal(coverage$estimate + false_positive$estimate, valid$estimate)
  expect_equal(
    coverage$success / valid$success + false_positive$success / valid$success,
    1
  )
  expect_equal(coverage$n, 1000L)
  expect_equal(valid$n, 1000L)
})
