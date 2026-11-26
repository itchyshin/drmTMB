test_that("the drmTMB-parallel help topic documents nested thread pinning", {
  rd_path <- drm_pkg_path("man/drmTMB-parallel.Rd")
  rd <- paste(readLines(rd_path, warn = FALSE), collapse = "\n")
  for (needle in c(
    "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "TMB_NTHREADS", "OMP_NUM_THREADS",
    "Do not nest parallel layers", "built without OpenMP"
  )) {
    expect_true(grepl(needle, rd, fixed = TRUE), info = needle)
  }
})
