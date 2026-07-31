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
  expect_match(script, "aoi2-bnb-fixed-r3/logs/%x-%A_%a.out")
  expect_match(script, 'RUN_ROOT="/project/def-snakagaw/snakagaw/drmTMB-aoi2/2026-07-29-aoi2-bnb-fixed-r3"')
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

test_that("AOI-2 runner records diagnostics before the prediction fence", {
  script_path <- file.path(
    testthat::test_path(), "..", "..", "tools",
    "run-aoi2-bernoulli-nb2-recovery.R"
  )
  script <- paste(readLines(script_path, warn = FALSE), collapse = "\n")
  payload_position <- regexpr("drm_pair_aoi2_diagnostic_payload", script, fixed = TRUE)
  prediction_position <- regexpr("prediction <- tryCatch", script, fixed = TRUE)

  expect_gt(payload_position, 0L)
  expect_gt(prediction_position, payload_position)
  expect_match(script, 'prediction_status = "not_attempted"')
  expect_match(script, 'base\\$prediction_status <- "unavailable"')
})
