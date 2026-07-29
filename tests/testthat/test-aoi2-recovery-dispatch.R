test_that("AOI-2 Rorqual dispatch preserves immutable result paths", {
  script_path <- file.path(
    testthat::test_path(), "..", "..", "tools", "slurm",
    "aoi2-bernoulli-nb2-recovery-rorqual.sbatch"
  )
  lines <- readLines(script_path, warn = FALSE)
  script <- paste(lines, collapse = "\n")
  expect_match(script, 'if \\[ -e "\\$RESULT_DIR" \\]')
  expect_false(any(grepl('mkdir -p .*"\\$RESULT_DIR"', lines)))
  expect_match(script, "--array=1-60%4")
})
