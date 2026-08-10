# Regression: the B1 dispatch helper must locate its own sibling contract file
# regardless of how R was launched.
#
# `tools/prepare-b1-drac-dispatch.R` sources `tools/b1-breadth-contract.R` from a
# directory it derives for itself. It used to take that directory from the
# `--file=` entry in commandArgs(), which names the script R was *launched* with.
# Run directly that is this file; sourced from another script — a test runner,
# for instance — it is the caller, and the sibling lookup then pointed at the
# caller's directory. The file existed, the outer source() succeeded, and the
# failure surfaced one frame deeper as "cannot open the connection", turning the
# whole package suite red for anyone who ran the tests via `Rscript runner.R`.

dispatch_path <- testthat::test_path("..", "..", "tools", "prepare-b1-drac-dispatch.R")

test_that("the dispatch helper loads when --file= names an unrelated script", {
  skip_on_cran()
  skip_if_not(file.exists(dispatch_path), "top-level tools are excluded from the tarball")
  skip_if_not(nzchar(Sys.which("Rscript")), "Rscript not on PATH")

  repo_root <- normalizePath(testthat::test_path("..", ".."))
  # A caller in a directory that has no b1-breadth-contract.R sibling. If the
  # helper trusts --file=, it looks here, finds nothing, and errors.
  caller_dir <- withr::local_tempdir()
  caller <- file.path(caller_dir, "unrelated-runner.R")
  writeLines(
    c(
      sprintf('setwd(%s)', deparse(repo_root)),
      sprintf('source(%s)', deparse(file.path(repo_root, "tools", "prepare-b1-drac-dispatch.R"))),
      'cat("LOADED:", exists("b1_make_full_manifest"), "\\n")'
    ),
    caller
  )

  out <- suppressWarnings(system2(
    Sys.which("Rscript"), c("--vanilla", shQuote(caller)),
    stdout = TRUE, stderr = TRUE
  ))
  expect_true(
    any(grepl("LOADED: TRUE", out, fixed = TRUE)),
    info = paste0("helper failed to self-locate:\n", paste(out, collapse = "\n"))
  )
})

test_that("the dispatch helper reports a usable error when its sibling is missing", {
  skip_on_cran()
  skip_if_not(file.exists(dispatch_path), "top-level tools are excluded from the tarball")

  # Copy the helper somewhere with no sibling contract file. It must fail with a
  # message naming what it looked for, not an opaque connection error.
  lone_dir <- withr::local_tempdir()
  file.copy(dispatch_path, file.path(lone_dir, "prepare-b1-drac-dispatch.R"))
  expect_error(
    withr::with_dir(lone_dir, source("prepare-b1-drac-dispatch.R")),
    "b1-breadth-contract\\.R"
  )
})
