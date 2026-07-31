args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop("Usage: mr-g5-drac-array.R <manifest.rds> <g4-records.rds> <array-index>", call. = FALSE)
}
manifest_path <- args[[1L]]
g4_path <- args[[2L]]
array_index <- as.integer(args[[3L]])
if (!is.finite(array_index) || array_index < 1L) stop("Array index must be positive.", call. = FALSE)

library(drmTMB)
runner_path <- system.file("sim/R/sim_missing_response_g4g5.R", package = "drmTMB")
if (!nzchar(runner_path)) stop("Installed drmTMB lacks the G4/G5 runner.", call. = FALSE)
source(runner_path)
manifest <- readRDS(manifest_path)
g4_records <- readRDS(g4_path)
registry <- mr_g5_registry_from_g4(manifest, g4_records)
cohort <- registry$cells$route_id %in% c("gaussian", "biv_gaussian")
cells <- registry$cells[cohort, , drop = FALSE]
if (array_index > nrow(cells)) stop("Array index exceeds Gaussian cohort size.", call. = FALSE)
cell <- cells[array_index, , drop = FALSE]
registry$cells <- cell
registry$seeds <- registry$seeds[registry$seeds$cell_id == cell$cell_id, , drop = FALSE]
out_dir <- Sys.getenv("MR_G5_OUT_DIR", unset = ".")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
stem <- gsub("[^A-Za-z0-9_.-]", "_", paste(cell$route_id, cell$parm, cell$information_rung, sep = "-"))
out_path <- file.path(out_dir, paste0("g5-", stem, ".rds"))
records <- mr_g5_run_campaign(registry, trace = TRUE, checkpoint_path = out_path)
mr_g5_validate_campaign(records, registry)
print(mr_g5_summarise_attempts(records))
