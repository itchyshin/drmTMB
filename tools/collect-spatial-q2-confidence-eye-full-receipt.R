#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
script_arg <- commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))]
script <- normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
root <- normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
source(file.path(root, "tools", "spatial-q2-confidence-eye-common.R"))
opts <- ce_parse_args(args)
required <- c("setup-job", "array-job", "run-root", "packet", "raw")
if (!all(required %in% names(opts))) {
  stop("Required: --setup-job --array-job --run-root --packet --raw", call. = FALSE)
}
packet <- ce_validate_packet(opts$packet)
run_root <- normalizePath(opts[["run-root"]], mustWork = TRUE)
raw_paths <- list.files(opts$raw, pattern = "^full-[LMH]-[0-9]{3}\\.tsv$", full.names = TRUE)
if (length(raw_paths) != 1500L) stop("Expected exactly 1,500 full raw files.", call. = FALSE)
raw_rows <- do.call(rbind, lapply(raw_paths, function(path) {
  utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
}))
if (nrow(raw_rows) != 4500L || any(raw_rows$slurm_array_job_id != opts[["array-job"]])) {
  stop("Raw scheduler provenance does not match the full array.", call. = FALSE)
}
task_ids <- sort(unique(as.integer(raw_rows$slurm_array_task_id)))
if (!identical(task_ids, seq_len(1500L))) {
  stop("Raw scheduler task IDs do not cover exactly 1:1500.", call. = FALSE)
}
child_jobs <- unique(as.character(raw_rows$slurm_job_id))
if (length(child_jobs) != 1500L || any(!nzchar(child_jobs))) {
  stop("Expected exactly 1,500 recorded child SLURM job IDs.", call. = FALSE)
}

fields <- "JobIDRaw,State,ElapsedRaw,TotalCPU,MaxRSS,ExitCode,NodeList,Start,End"
chunks <- split(child_jobs, ceiling(seq_along(child_jobs) / 100L))
sacct <- unlist(lapply(c(list(opts[["setup-job"]]), chunks), function(ids) {
  system2(
    "sacct",
    c("-j", paste(ids, collapse = ","), "--parsable2", "--noheader",
      paste0("--format=", fields)),
    stdout = TRUE
  )
}), use.names = FALSE)
lines <- strsplit(sacct, "\\|", fixed = FALSE)
lines <- lines[vapply(lines, length, integer(1L)) >= 9L]
scheduler <- as.data.frame(do.call(rbind, lapply(lines, `[`, seq_len(9L))), stringsAsFactors = FALSE)
names(scheduler) <- strsplit(fields, ",", fixed = TRUE)[[1L]]
scheduler <- scheduler[!duplicated(scheduler$JobIDRaw), , drop = FALSE]
ce_atomic_write_tsv(scheduler, file.path(run_root, "receipts", "sacct.tsv"))

slurm_bytes <- function(x) {
  x <- trimws(as.character(x))
  if (!nzchar(x)) return(NA_real_)
  unit <- substring(x, nchar(x))
  multiplier <- switch(unit, K = 1024, M = 1024^2, G = 1024^3, T = 1024^4, 1)
  number <- if (unit %in% c("K", "M", "G", "T")) substring(x, 1L, nchar(x) - 1L) else x
  suppressWarnings(as.numeric(number)) * multiplier
}

tasks <- scheduler[scheduler$JobIDRaw %in% child_jobs, , drop = FALSE]
if (nrow(tasks) != 1500L || !setequal(tasks$JobIDRaw, child_jobs) ||
    anyDuplicated(tasks$JobIDRaw)) {
  stop("Scheduler accounting does not contain exactly the 1,500 recorded child jobs.", call. = FALSE)
}
if (any(tasks$State != "COMPLETED") || any(tasks$ExitCode != "0:0")) {
  stop("At least one recorded full-array child is not COMPLETED with exit 0:0.", call. = FALSE)
}
elapsed <- suppressWarnings(as.numeric(tasks$ElapsedRaw))
rss_values <- vapply(scheduler$MaxRSS, slurm_bytes, numeric(1L))
starts <- as.POSIXct(tasks$Start, tz = "UTC")
ends <- as.POSIXct(tasks$End, tz = "UTC")
receipt <- data.frame(
  source_sha = packet$source_sha,
  packet_sha256 = packet$packet_sha256,
  setup_job_id = opts[["setup-job"]],
  array_job_id = opts[["array-job"]],
  array_contract = "1-1500%100",
  expected_array_tasks = 1500L,
  observed_array_tasks = nrow(tasks),
  completed_array_tasks = sum(tasks$State == "COMPLETED"),
  median_elapsed_seconds = stats::median(elapsed, na.rm = TRUE),
  p90_elapsed_seconds = unname(stats::quantile(elapsed, 0.90, na.rm = TRUE)),
  max_elapsed_seconds = max(elapsed, na.rm = TRUE),
  max_rss_bytes = if (all(!is.finite(rss_values))) NA_real_ else max(rss_values, na.rm = TRUE),
  actual_task_cpu_hours_upper = sum(elapsed, na.rm = TRUE) / 3600,
  actual_array_wall_hours = as.numeric(difftime(max(ends, na.rm = TRUE), min(starts, na.rm = TRUE), units = "hours")),
  recorded_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
ce_atomic_write_tsv(receipt, file.path(run_root, "receipts", "resource-actual.tsv"))
ce_reconcile("full", opts$raw, file.path(run_root, "reconciled"), packet)
writeLines(
  c(
    paste0("source_sha=", packet$source_sha),
    paste0("packet_sha256=", packet$packet_sha256),
    paste0("array_job_id=", opts[["array-job"]]),
    "scheduler_children=1500",
    "scheduler_state=COMPLETED",
    "scheduler_exit=0:0",
    "raw_task_ids=1:1500",
    "reconciliation=complete"
  ),
  file.path(run_root, "receipts", "full-closeout-complete.txt"),
  useBytes = TRUE
)
message("wrote full scheduler receipt under ", file.path(run_root, "receipts"))
