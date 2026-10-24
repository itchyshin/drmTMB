repo <- normalizePath(file.path(dirname(sub("--file=", "", commandArgs()[grep("--file=", commandArgs())][[1L]])), "../.."), mustWork = TRUE)
source(file.path(repo, "tools", "cmr_recovery_campaign.R"), local = TRUE)

manifest_path <- file.path(repo, "docs", "dev-log", "cmr", "fixtures", "recovery-manifest-v7.json")
manifest <- cmr_v7_load_manifest(manifest_path)$manifest

stopifnot(identical(cmr_v7_expected_seed(manifest, "pre_run", "m1_fixed_covariate", 1L), 20361008L))
stopifnot(identical(cmr_v7_expected_seed(manifest, "pilot", "m1_fixed_covariate", 1001L), 30362008L))
stopifnot(identical(cmr_v7_plan(manifest, "pre_run", "m1_fixed_covariate"), 1:2))
stopifnot(identical(cmr_v7_plan(manifest, "pilot", "m5_selection_pair"), 1001:1010))

expect_error <- function(expr, pattern) {
  error <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}
expect_error(cmr_v7_plan(manifest, "pre_run", "m5_sd_zero_slopes"), "primary cell")
expect_error(cmr_v7_plan(manifest, "pilot", "m5_sd_pair_nonzero_slopes", 1000:1010), "authorized range")
expect_error(cmr_v7_plan(manifest, "screen", "m1_fixed_covariate"), "pre_run and pilot")

scratch <- tempfile("cmr-v7-campaign-test-")
dir.create(scratch)
on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
source_root <- file.path(scratch, "source")
dir.create(source_root)
dir.create(file.path(source_root, "tools"))
source_file <- file.path(source_root, "candidate.R")
writeLines("candidate", source_file)
sd_helper <- file.path(source_root, "tools", "cmr_sd_recovery_extract.R")
file.copy(file.path(repo, "tools", "cmr_sd_recovery_extract.R"), sd_helper)
source_manifest <- file.path(scratch, "source-manifest.json")
source_entries <- setNames(list(cmr_v7_sha256(source_file), cmr_v7_sha256(sd_helper)),
  c("candidate.R", "tools/cmr_sd_recovery_extract.R"))
writeLines(as.character(jsonlite::toJSON(source_entries,
  auto_unbox = TRUE)), source_manifest)
outside_file <- file.path(scratch, "outside.R")
writeLines("outside", outside_file)
traversal_manifest <- file.path(scratch, "traversal-manifest.json")
writeLines(as.character(jsonlite::toJSON(list(`../outside.R` = cmr_v7_sha256(outside_file)),
  auto_unbox = TRUE)), traversal_manifest)
expect_error(cmr_v7_validate_source_manifest(source_root, traversal_manifest), "escapes source root")
output_dir <- file.path(scratch, "run")
mock_attempt <- function(directory, cell, seed, stage, replicate) {
  list(status = "usable", usable = TRUE, fit_attempted = TRUE, converged = TRUE,
    gradient_norm = 1e-8, generator_metadata = list(
      sha256 = list(histories.csv = paste(rep("a", 64L), collapse = "")),
      rows = list(histories = 1L)))
}
summary <- cmr_v7_run_cell(manifest_path, source_root, source_manifest,
  file.path(repo, "tools", "cmr_recovery_generate.py"),
  dirname(system.file(package = "drmTMB")), "pre_run", "m1_fixed_covariate",
  output_dir, replicates = 1L, attempt_fn = mock_attempt)
stopifnot(identical(summary$scheduled, 1L), identical(summary$attempted, 1L),
          identical(summary$usable, 1L), identical(summary$qualification, FALSE))
records <- readLines(file.path(output_dir, "attempts.jsonl"), warn = FALSE)
stopifnot(length(records) == 2L,
  identical(jsonlite::fromJSON(records[[2L]], simplifyVector = FALSE)$generated_sha256$histories.csv,
            paste(rep("a", 64L), collapse = "")))

sd_output_dir <- file.path(scratch, "sd-run")
sd_attempt <- function(...) {
  helper <- get("cmr_sd_recovery_coefficients", envir = parent.frame(), inherits = FALSE)
  stopifnot(is.function(helper))
  mock_attempt(...)
}
sd_summary <- cmr_v7_run_cell(manifest_path, source_root, source_manifest,
  file.path(repo, "tools", "cmr_recovery_generate.py"),
  dirname(system.file(package = "drmTMB")), "pre_run", "m5_sd_pair_nonzero_slopes",
  sd_output_dir, replicates = 1L, attempt_fn = sd_attempt)
stopifnot(identical(sd_summary$scheduled, 1L), identical(sd_summary$attempted, 1L),
  identical(sd_summary$usable, 1L))

error_output_dir <- file.path(scratch, "error-run")
error_summary <- cmr_v7_run_cell(manifest_path, source_root, source_manifest,
  file.path(repo, "tools", "cmr_recovery_generate.py"),
  dirname(system.file(package = "drmTMB")), "pre_run", "m1_fixed_covariate",
  error_output_dir, replicates = 1L,
  attempt_fn = function(...) stop("fixture attempt failure", call. = FALSE))
error_records <- readLines(file.path(error_output_dir, "attempts.jsonl"), warn = FALSE)
error_attempt <- jsonlite::fromJSON(error_records[[2L]], simplifyVector = FALSE)
stopifnot(identical(error_summary$scheduled, 1L),
  identical(error_summary$attempted, 0L), identical(error_summary$usable, 0L),
  identical(error_attempt$failure_stage, "pre_fit_admission"),
  grepl("fixture attempt failure", error_attempt$failure_message))

cat("CMR v7 campaign authorization and journal: 17 assertions passed\n")
