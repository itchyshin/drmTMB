#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
script_arg <- commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))]
script <- normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
root <- normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
source(file.path(root, "tools", "spatial-q2-confidence-eye-common.R"))
opts <- ce_parse_args(args)
required <- c("setup-job", "array-job", "run-root", "packet")
if (!all(required %in% names(opts))) {
  stop("Required: --setup-job --array-job --run-root --packet", call. = FALSE)
}
packet <- ce_validate_packet(opts$packet)
run_root <- normalizePath(opts[["run-root"]], mustWork = TRUE)

fields <- "JobIDRaw,State,ElapsedRaw,TotalCPU,MaxRSS,ExitCode,NodeList"
sacct <- system2(
  "sacct",
  c("-j", paste(opts[["setup-job"]], opts[["array-job"]], sep = ","),
    "--parsable2", "--noheader", paste0("--format=", fields)),
  stdout = TRUE
)
lines <- strsplit(sacct, "\\|", fixed = FALSE)
lines <- lines[vapply(lines, length, integer(1L)) >= 7L]
scheduler <- as.data.frame(do.call(rbind, lapply(lines, `[`, seq_len(7L))), stringsAsFactors = FALSE)
names(scheduler) <- strsplit(fields, ",", fixed = TRUE)[[1L]]
ce_atomic_write_tsv(scheduler, file.path(run_root, "receipts", "sacct.tsv"))

slurm_bytes <- function(x) {
  x <- trimws(as.character(x))
  if (!nzchar(x)) return(NA_real_)
  unit <- substring(x, nchar(x))
  multiplier <- switch(unit, K = 1024, M = 1024^2, G = 1024^3, T = 1024^4, 1)
  number <- if (unit %in% c("K", "M", "G", "T")) {
    substring(x, 1L, nchar(x) - 1L)
  } else {
    x
  }
  suppressWarnings(as.numeric(number)) * multiplier
}

array_pattern <- paste0("^", opts[["array-job"]], "_[0-9]+$")
tasks <- scheduler[grepl(array_pattern, scheduler$JobIDRaw), , drop = FALSE]
elapsed <- suppressWarnings(as.numeric(tasks$ElapsedRaw))
completed <- sum(tasks$State == "COMPLETED")
median_elapsed <- stats::median(elapsed, na.rm = TRUE)
p90_elapsed <- unname(stats::quantile(elapsed, 0.90, na.rm = TRUE))
projected_cpu_hours <- median_elapsed * 1500 / 3600
projected_wall_hours <- p90_elapsed * ceiling(1500 / 100) / 3600
rss_values <- vapply(scheduler$MaxRSS, slurm_bytes, numeric(1L))
max_rss_bytes <- if (all(!is.finite(rss_values))) NA_real_ else max(rss_values, na.rm = TRUE)
receipt <- data.frame(
  source_sha = packet$source_sha,
  packet_sha256 = packet$packet_sha256,
  setup_job_id = opts[["setup-job"]],
  array_job_id = opts[["array-job"]],
  array_contract = "1-60%60",
  expected_array_tasks = 60L,
  observed_array_tasks = nrow(tasks),
  completed_array_tasks = completed,
  median_elapsed_seconds = median_elapsed,
  p90_elapsed_seconds = p90_elapsed,
  max_rss_bytes = max_rss_bytes,
  projected_full_concurrency = 100L,
  projected_full_cpu_hours = projected_cpu_hours,
  projected_full_wall_hours = projected_wall_hours,
  within_cpu_hour_bound = is.finite(projected_cpu_hours) && projected_cpu_hours <= 2000,
  within_wall_hour_bound = is.finite(projected_wall_hours) && projected_wall_hours <= 12,
  recorded_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
ce_atomic_write_tsv(receipt, file.path(run_root, "receipts", "resource-projection.tsv"))
message("wrote scheduler receipt under ", file.path(run_root, "receipts"))
