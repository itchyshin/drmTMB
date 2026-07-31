#!/usr/bin/env Rscript

# Replay a frozen AOI-2 diagnostic manifest locally. The manifest is the
# sampling authority; this runner must not select, replace, or resample seeds.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) != 1L) {
    stop(sprintf("Supply exactly one --%s=VALUE.", name), call. = FALSE)
  }
  sub(paste0("^--", name, "="), "", hit)
}

manifest_path <- arg_value("manifest")
out_dir <- arg_value("out-dir")
workers <- suppressWarnings(as.integer(arg_value("workers")))
if (!file.exists(manifest_path)) stop("`manifest` does not exist.", call. = FALSE)
if (file.exists(out_dir)) stop("Refusing to overwrite an AOI-2 diagnostic replay directory.", call. = FALSE)
if (!is.finite(workers) || workers < 1L) stop("`workers` must be a positive integer.", call. = FALSE)

manifest <- utils::read.csv(manifest_path, check.names = FALSE, stringsAsFactors = FALSE)
required <- c(
  "formula_id", "n", "replicate", "seed", "source_sha", "fingerprint",
  "original_status", "diagnostic_stratum", "sampling_seed", "selection_order"
)
missing <- setdiff(required, names(manifest))
if (length(missing)) {
  stop(sprintf("Diagnostic manifest is missing required fields: %s", paste(missing, collapse = ", ")),
    call. = FALSE)
}
if (anyDuplicated(paste(manifest$formula_id, manifest$n, manifest$replicate, sep = ":"))) {
  stop("Diagnostic manifest contains duplicate formula/n/replicate keys.", call. = FALSE)
}
if (!all(manifest$original_status %in% c("interior", "near_boundary", "unavailable"))) {
  stop("Diagnostic manifest contains an unsupported original status.", call. = FALSE)
}
if (!all(manifest$diagnostic_stratum %in% c("interior", "near_boundary", "boundary_unresolved"))) {
  stop("Diagnostic manifest contains an unsupported diagnostic stratum.", call. = FALSE)
}
if (!all(grepl("^[0-9a-f]{40}$", manifest$source_sha))) {
  stop("Diagnostic manifest contains an invalid retained campaign SHA.", call. = FALSE)
}

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) stop("Cannot locate the diagnostic replay runner.", call. = FALSE)
runner <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)),
  "run-aoi2-bernoulli-nb2-recovery.R"), mustWork = TRUE)

run_one <- function(index) {
  row <- manifest[index, , drop = FALSE]
  label <- sprintf("%s-n%d-r%d", row$formula_id, row$n, row$replicate)
  result_dir <- file.path(out_dir, "results", label)
  command <- c(
    runner,
    paste0("--out-dir=", result_dir),
    paste0("--formula-id=", row$formula_id),
    paste0("--n=", row$n),
    paste0("--replicate-start=", row$replicate),
    paste0("--replicate-end=", row$replicate)
  )
  status <- system2("Rscript", command)
  data.frame(
    formula_id = row$formula_id, n = row$n, replicate = row$replicate,
    seed = row$seed, original_status = row$original_status,
    diagnostic_stratum = row$diagnostic_stratum, exit_status = status,
    result_dir = normalizePath(result_dir, mustWork = FALSE),
    stringsAsFactors = FALSE
  )
}

results <- if (.Platform$OS.type == "unix" && workers > 1L) {
  parallel::mclapply(seq_len(nrow(manifest)), run_one, mc.cores = workers)
} else {
  lapply(seq_len(nrow(manifest)), run_one)
}
results <- do.call(rbind, results)
if (any(results$exit_status != 0L)) {
  utils::write.csv(results, file.path(out_dir, "dispatch.csv"), row.names = FALSE)
  stop("One or more diagnostic replay attempts failed; see dispatch.csv.", call. = FALSE)
}
utils::write.csv(manifest, file.path(out_dir, "manifest.csv"), row.names = FALSE)
utils::write.csv(results, file.path(out_dir, "dispatch.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
