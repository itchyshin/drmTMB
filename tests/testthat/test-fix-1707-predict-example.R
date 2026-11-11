# Regression guard for #1707: help examples extracted with tools::Rd2ex() must
# fit convergent location-scale models (not the old six-row predict() demo).

get_installed_rd_topic <- function(rd_file) {
  rd <- tools::Rd_db("drmTMB")[[rd_file]]
  if (is.null(rd)) {
    man_path <- testthat::test_path("..", "..", "man", rd_file)
    if (!file.exists(man_path)) {
      testthat::fail(paste0("Missing Rd topic in tools::Rd_db(\"drmTMB\"): ", rd_file))
    }
    rd <- tools::parse_Rd(man_path)
  }
  rd
}

extract_rd_example_code <- function(rd) {
  ex <- tempfile(fileext = ".R")
  tools::Rd2ex(rd, out = ex)
  code <- readLines(ex, warn = FALSE)
  code <- code[!grepl("^###", code)]
  parse(text = paste(code, collapse = "\n"))
}

eval_rd_example <- function(rd) {
  env <- new.env(parent = globalenv())
  exprs <- extract_rd_example_code(rd)
  testthat::expect_no_warning(
    eval(exprs, envir = env)
  )
  env$fit
}

assert_rd_example_converges <- function(rd_file) {
  fit <- eval_rd_example(get_installed_rd_topic(rd_file))
  testthat::expect_s3_class(fit, "drmTMB")
  testthat::expect_true(is_converged(fit))

  sig <- as.numeric(predict(fit, dpar = "sigma"))
  testthat::expect_true(all(is.finite(sig)))
  testthat::expect_true(all(sig > 0))
  testthat::expect_lt(max(sig) / min(sig), 1e3)
  invisible(fit)
}

test_that("predict.drmTMB() Rd example (Rd2ex) converges with sane sigma", {
  assert_rd_example_converges("predict.drmTMB.Rd")
})

test_that("sigma.drmTMB() Rd example (Rd2ex) converges with sane sigma", {
  assert_rd_example_converges("sigma.drmTMB.Rd")
})
