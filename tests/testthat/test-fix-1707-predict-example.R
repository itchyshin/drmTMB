# Regression guard for #1707: help examples extracted with tools::Rd2ex() must
# fit convergent location-scale models (not the old six-row predict() demo).

source_or_installed_man_rd <- function(rd_file) {
  source_path <- testthat::test_path("..", "..", "man", rd_file)
  installed_path <- system.file("help", rd_file, package = "drmTMB")
  candidates <- c(source_path, installed_path)
  matches <- candidates[nzchar(candidates) & file.exists(candidates)]
  testthat::skip_if_not(
    length(matches) > 0L,
    paste("Rd file is not available:", rd_file)
  )
  matches[[1L]]
}

run_rd_examples <- function(rd_path) {
  ex <- tempfile(fileext = ".R")
  tools::Rd2ex(rd_path, out = ex)
  code <- readLines(ex, warn = FALSE)
  code <- code[!grepl("^###", code)]
  env <- new.env(parent = globalenv())
  state <- list(warnings = character())
  withCallingHandlers(
    eval(
      parse(text = paste(code, collapse = "\n")),
      envir = env
    ),
    warning = function(w) {
      state$warnings <- c(state$warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = env$fit, warnings = state$warnings)
}

assert_rd_example_converges <- function(rd_file) {
  result <- run_rd_examples(source_or_installed_man_rd(rd_file))
  testthat::expect_s3_class(result$fit, "drmTMB")
  testthat::expect_length(result$warnings, 0)
  testthat::expect_true(is_converged(result$fit))

  sig <- as.numeric(predict(result$fit, dpar = "sigma"))
  testthat::expect_true(all(is.finite(sig)))
  testthat::expect_true(all(sig > 0))
  testthat::expect_lt(max(sig) / min(sig), 1e3)
  invisible(result)
}

test_that("predict.drmTMB() Rd example (Rd2ex) converges with sane sigma", {
  assert_rd_example_converges("predict.drmTMB.Rd")
})

test_that("sigma.drmTMB() Rd example (Rd2ex) converges with sane sigma", {
  assert_rd_example_converges("sigma.drmTMB.Rd")
})
