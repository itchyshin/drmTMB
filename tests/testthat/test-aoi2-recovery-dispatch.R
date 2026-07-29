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
  expect_match(script, "aoi2-bnb-fixed-r2/logs/%x-%A_%a.out")
  expect_match(script, 'RUN_ROOT="/project/def-snakagaw/snakagaw/drmTMB-aoi2/2026-07-29-aoi2-bnb-fixed-r2"')
  expect_match(script, 'export AOI2_SOURCE_SHA="\\$\\(cat "\\$SOURCE/.aoi2-source-sha"\\)"')
})

test_that("AOI-2 analysis rejects malformed design provenance", {
  script_path <- file.path(
    testthat::test_path(), "..", "..", "tools",
    "summarize-aoi2-bernoulli-nb2-recovery.R"
  )
  script <- paste(readLines(script_path, warn = FALSE), collapse = "\n")
  expect_match(script, "Campaign contains an unknown AOI-2 formula_id")
  expect_match(script, "Campaign contains an absent or malformed source SHA")
  expect_match(script, "fingerprint_matches")
})
