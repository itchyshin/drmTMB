args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 6L) {
  stop(paste(
    "Usage: mr-g5-reconcile-cohort.R <target-manifests.rds> <g4-records.rds>",
    "<receipt-dir> <route-id[,route-id,...]> <cohort-name> <output.rds>"
  ), call. = FALSE)
}

manifest_path <- args[[1L]]
g4_path <- args[[2L]]
receipt_dir <- args[[3L]]
route_ids <- strsplit(args[[4L]], ",", fixed = TRUE)[[1L]]
cohort_name <- args[[5L]]
output_path <- args[[6L]]
if (!dir.exists(receipt_dir)) stop("G5 receipt directory does not exist.", call. = FALSE)

library(drmTMB)
runner_path <- Sys.getenv("MR_G5_RUNNER_PATH", unset = system.file("sim/R/sim_missing_response_g4g5.R", package = "drmTMB"))
if (!nzchar(runner_path) || !file.exists(runner_path)) stop("The G4/G5 runner source is unavailable.", call. = FALSE)
source(runner_path)

paths <- sort(list.files(receipt_dir, pattern = "\\.rds$", full.names = TRUE))
if (!length(paths)) stop("G5 receipt directory contains no RDS files.", call. = FALSE)
expected_registry <- mr_g5_registry_from_g4(readRDS(manifest_path), readRDS(g4_path))
registry <- mr_g5_select_routes(expected_registry, route_ids)
mr_g5_validate_cohort_registry(registry, expected_registry)
records <- mr_g5_reconcile_checkpoints(paths, registry)
summary <- mr_g5_summarise_attempts(records)
calibration <- mr_g5_calibration_gate(summary)
mr_g5_validate_calibration(calibration)
provenance <- mr_g5_provenance_receipt(runner_path, manifest_path, g4_path, paths)
mr_g5_validate_provenance(provenance)
artifact <- list(
  schema_version = "mr-g4g5-v2", cohort = cohort_name, records = records,
  summary = summary, calibration = calibration, registry = registry,
  expected_registry = expected_registry,
  expected_cell_count = nrow(expected_registry$cells),
  provenance = provenance, created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
saveRDS(artifact, output_path)
print(summary)
print(calibration[, c("route_id", "parm", "information_rung", "coverage", "calibration_status", "calibration_reason")])
