args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  stop(paste(
    "Usage: mr-g5-reconcile.R <target-manifests.rds> <g4-records.rds>",
    "<receipt-dir> <output.rds>"
  ), call. = FALSE)
}

manifest_path <- args[[1L]]
g4_path <- args[[2L]]
receipt_dir <- args[[3L]]
output_path <- args[[4L]]
if (!dir.exists(receipt_dir)) stop("G5 receipt directory does not exist.", call. = FALSE)

library(drmTMB)
runner_path <- Sys.getenv(
  "MR_G5_RUNNER_PATH",
  unset = system.file("sim/R/sim_missing_response_g4g5.R", package = "drmTMB")
)
if (!nzchar(runner_path) || !file.exists(runner_path)) {
  stop("The G4/G5 runner source is unavailable.", call. = FALSE)
}
source(runner_path)

paths <- sort(list.files(receipt_dir, pattern = "\\.rds$", full.names = TRUE))
if (!length(paths)) stop("G5 receipt directory contains no RDS files.", call. = FALSE)

target_manifests <- readRDS(manifest_path)
g4_records <- readRDS(g4_path)
registry <- mr_g5_registry_from_g4(target_manifests, g4_records)
cohort_routes <- c("gaussian", "biv_gaussian")
registry$cells <- registry$cells[registry$cells$route_id %in% cohort_routes, , drop = FALSE]
registry$seeds <- registry$seeds[registry$seeds$cell_id %in% registry$cells$cell_id, , drop = FALSE]
if (!nrow(registry$cells)) stop("No G5-eligible Gaussian-cohort cells exist.", call. = FALSE)

records <- mr_g5_reconcile_checkpoints(paths, registry)
summary <- mr_g5_summarise_attempts(records)
calibration <- mr_g5_calibration_gate(summary)
mr_g5_validate_calibration(calibration)
provenance <- mr_g5_provenance_receipt(
  runner_path = runner_path, manifest_path = manifest_path, g4_path = g4_path,
  receipt_paths = paths
)
mr_g5_validate_provenance(provenance)
artifact <- list(
  schema_version = "mr-g4g5-v2",
  cohort = "gaussian_and_bivariate_gaussian",
  records = records,
  summary = summary,
  calibration = calibration,
  registry = registry,
  provenance = provenance,
  created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
saveRDS(artifact, output_path)
print(summary)
print(calibration[, c("route_id", "parm", "information_rung", "coverage",
  "calibration_status", "calibration_reason")])
