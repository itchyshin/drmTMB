# Issue #1249 (docs half): the installed package should expose a single help
# page that states when to pin BLAS/OpenMP/TMB threads versus using outer
# parallel backends.

test_that("the drmTMB-parallel help topic documents nested thread pinning", {
  rd_path <- testthat::test_path("../../R/parallel-docs.R")
  if (file.exists(rd_path)) {
    rd <- paste(readLines(rd_path, warn = FALSE), collapse = "\n")
  } else {
    help_txt <- utils::help(
      "drmTMB-parallel",
      package = "drmTMB",
      help_type = "text",
      try.all.packages = FALSE
    )
    skip_if(inherits(help_txt, "try-error"), "drmTMB-parallel help not installed")
    rd <- paste(as.character(help_txt), collapse = "\n")
  }

  for (needle in c(
    "OPENBLAS_NUM_THREADS",
    "MKL_NUM_THREADS",
    "TMB_NTHREADS",
    "OMP_NUM_THREADS",
    "Do not nest parallel layers",
    "built without OpenMP"
  )) {
    expect_true(grepl(needle, rd, fixed = TRUE), info = needle)
  }
})