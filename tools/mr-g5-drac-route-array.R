args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% c(4L, 5L)) {
  stop("Usage: mr-g5-drac-route-array.R <manifest.rds> <g4-records.rds> <route-id> <array-index> [smoke-attempts]", call. = FALSE)
}
manifest_path <- args[[1L]]
g4_path <- args[[2L]]
route_id <- args[[3L]]
array_index <- as.integer(args[[4L]])
smoke_attempts <- if (length(args) == 5L) as.integer(args[[5L]]) else NA_integer_
if (!is.finite(array_index) || array_index < 1L) stop("Array index must be positive.", call. = FALSE)
if (!is.na(smoke_attempts) && (!is.finite(smoke_attempts) || smoke_attempts < 1L || smoke_attempts > 3L)) {
  stop("DRAC smoke must retain one to three explicit attempts.", call. = FALSE)
}

library(drmTMB)

# Design declaration (#982) -- REQUIRED, fail closed.
#
# These runners execute under `Rscript --vanilla`, so no .Rprofile can supply the
# DGP design.  A campaign that does not state its design produced exactly the
# situation #982 records: an artifact whose provenance could only be inferred
# from its own results.  Declare it explicitly or do not run.
mr_centre <- Sys.getenv("MR_G5_CENTRE_RANDOM_EFFECTS", unset = NA_character_)
if (is.na(mr_centre) || !toupper(mr_centre) %in% c("TRUE", "FALSE")) {
  stop("Set MR_G5_CENTRE_RANDOM_EFFECTS to TRUE (frozen v1 design) or FALSE (uncentred v2). ",
       "It is recorded on every record and the reconcilers refuse to merge disagreeing designs.",
       call. = FALSE)
}
options(drmTMB.mr_g4g5_centre_random_effects = identical(toupper(mr_centre), "TRUE"))
runner_path <- Sys.getenv("MR_G5_RUNNER_PATH", unset = system.file("sim/R/sim_missing_response_g4g5.R", package = "drmTMB"))
if (!nzchar(runner_path) || !file.exists(runner_path)) stop("The G4/G5 runner source is unavailable.", call. = FALSE)
source(runner_path)
registry <- mr_g5_registry_from_g4(readRDS(manifest_path), readRDS(g4_path))
registry <- mr_g5_select_routes(registry, route_id)
if (array_index > nrow(registry$cells)) stop("Array index exceeds selected G5 route size.", call. = FALSE)
cell <- registry$cells[array_index, , drop = FALSE]
registry$cells <- cell
registry$seeds <- registry$seeds[registry$seeds$cell_id == cell$cell_id, , drop = FALSE]
out_dir <- Sys.getenv("MR_G5_OUT_DIR", unset = ".")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
stem <- gsub("[^A-Za-z0-9_.-]", "_", paste(cell$route_id, cell$parm, cell$information_rung, sep = "-"))
out_path <- file.path(out_dir, paste0("g5-", stem, ".rds"))
if (is.na(smoke_attempts)) {
  records <- mr_g5_run_campaign(registry, trace = TRUE, checkpoint_path = out_path)
  mr_g5_validate_campaign(records, registry)
  print(mr_g5_summarise_attempts(records))
} else {
  smoke_seeds <- registry$seeds[seq_len(smoke_attempts), , drop = FALSE]
  records <- do.call(rbind, lapply(seq_len(nrow(smoke_seeds)), function(i) {
    mr_g5_run_attempt(cell, seed = smoke_seeds$seed[[i]], replicate = smoke_seeds$replicate[[i]], trace = TRUE)
  }))
  invisible(lapply(seq_len(nrow(records)), function(i) mr_g5_validate_record(records[i, , drop = FALSE])))
  saveRDS(records, out_path)
  print(records)
}
