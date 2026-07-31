test_that("AOI-3 private full-refit runner keeps its frozen execution boundary", {
  runner <- test_path("..", "..", "tools", "run-aoi3-bernoulli-nb2-full-refit.R")
  reducer <- test_path("..", "..", "tools", "summarize-aoi3-bernoulli-nb2-smoke.R")
  diagnostic_reducer <- test_path("..", "..", "tools", "summarize-aoi3r1-diagnostic-smoke.R")
  contract <- test_path("..", "..", "docs", "dev-log", "2026-07-31-aoi3-full-refit-calibration-contract.md")
  expect_silent(parse(file = runner))
  expect_silent(parse(file = reducer))
  expect_silent(parse(file = diagnostic_reducer))
  text <- paste(readLines(runner, warn = FALSE), collapse = "\n")
  expect_match(text, "drm_pair_general_eta_sandwich", fixed = TRUE)
  expect_match(text, "simulate_inner", fixed = TRUE)
  expect_match(text, "fit_complete", fixed = TRUE)
  expect_match(text, "outer-sandwich-covariance.csv", fixed = TRUE)

  inner_setup <- regexpr("row <- c(", text, fixed = TRUE)
  inherited_payload <- regexpr("row <- inherit_outer_payload(row, base)", text, fixed = TRUE)
  inner_eligibility <- regexpr("if (!is.null(fitted) && identical(base$outer_status, \"interior\") && identical(base$sandwich_status, \"ok\"))", text, fixed = TRUE)
  expect_gt(inner_setup, 0L)
  expect_gt(inherited_payload, 0L)
  expect_gt(inner_eligibility, 0L)
  expect_lt(inner_setup, inherited_payload)
  expect_lt(inherited_payload, inner_eligibility)
  expect_match(text, "if (!has_diagnostic_payload(outer)) return(row)", fixed = TRUE)
  expect_match(text, "diagnostic_payload_origin <- \"outer\"", fixed = TRUE)
  expect_match(text, "diagnostic_payload_origin <- \"inner\"", fixed = TRUE)
  expect_match(text, "diagnostic_eligibility_reason", fixed = TRUE)

  diagnostic_reducer_text <- paste(readLines(diagnostic_reducer, warn = FALSE), collapse = "\n")
  expect_match(diagnostic_reducer_text, "all(required_payload %in% names(inner))", fixed = TRUE)
  expect_match(diagnostic_reducer_text, "all(!is.na(inner$diagnostic_version))", fixed = TRUE)
  expect_match(diagnostic_reducer_text, "diagnostic_version", fixed = TRUE)
  contract_text <- paste(readLines(contract, warn = FALSE), collapse = "\n")
  expect_match(contract_text, "1,194,000", fixed = TRUE)
  expect_match(contract_text, "non-covering", fixed = TRUE)
  expect_match(contract_text, "AOI-2 point-recovery HOLD", fixed = TRUE)
})

test_that("AOI-3R inner rows inherit only a validated outer diagnostic payload", {
  runner <- test_path("..", "..", "tools", "run-aoi3-bernoulli-nb2-full-refit.R")
  expressions <- as.list(parse(file = runner))
  helper_names <- vapply(expressions, function(expression) {
    is.call(expression) && identical(expression[[1L]], as.name("<-")) &&
      as.character(expression[[2L]]) %in% c("has_diagnostic_payload", "inherit_outer_payload")
  }, logical(1L))
  helper_environment <- new.env(parent = baseenv())
  invisible(lapply(expressions[helper_names], eval, envir = helper_environment))

  outer <- list(
    outer_status = "interior",
    outer_message = "",
    sandwich_status = "unavailable",
    sandwich_reason = "association_step_unstable",
    diagnostic_version = "aoi3r1",
    diagnostic_status = "boundary_diagnostic",
    diagnostic_sandwich_status = "unavailable"
  )
  inherited <- helper_environment$inherit_outer_payload(
    list(inner_status = "not_eligible"), outer
  )
  expect_identical(inherited$diagnostic_payload_origin, "outer")
  expect_identical(inherited$diagnostic_version, "aoi3r1")
  expect_match(inherited$diagnostic_eligibility_reason, "outer_sandwich_reason=association_step_unstable", fixed = TRUE)

  unknown <- helper_environment$inherit_outer_payload(
    list(inner_status = "not_eligible"),
    list(outer_status = "unavailable", sandwich_status = "not_attempted", sandwich_reason = "")
  )
  expect_false("diagnostic_version" %in% names(unknown))
})
