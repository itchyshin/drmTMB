#!/usr/bin/env Rscript
# Authenticate and summarise the isolated clean g=10 provenance rerun.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: analyse_profile_clean_g10.R <result_dir>", call. = FALSE)
result_dir <- args[[1L]]
file_arg <- grep("^--file=", commandArgs(), value = TRUE)
script_dir <- if (length(file_arg)) dirname(normalizePath(sub("^--file=", "", file_arg[[1L]]))) else getwd()
source(file.path(script_dir, "a1_profile_common.R"))

manifest_path <- file.path(result_dir, "campaign-manifest.txt")
if (!file.exists(manifest_path)) stop("Campaign manifest is missing.", call. = FALSE)
manifest_lines <- readLines(manifest_path, warn = FALSE)
manifest <- stats::setNames(
  sub("^[^=]+=", "", manifest_lines[grepl("=", manifest_lines)]),
  sub("=.*$", "", manifest_lines[grepl("=", manifest_lines)])
)
required <- c("run_kind", "package_commit", "package_tarball_sha256", "runner_sha256", "helper_sha256",
              "launcher_sha256", "R_boot", "outer_attempts", "workers", "cell_id",
              "started_utc", "completed_utc")
if (!all(required %in% names(manifest)) ||
    !identical(manifest[["run_kind"]], "clean_g10_provenance_rerun") ||
    !identical(manifest[["R_boot"]], "999") ||
    !identical(manifest[["outer_attempts"]], "1000") ||
    !identical(manifest[["workers"]], "100") ||
    !identical(manifest[["cell_id"]], "g10_n10_sd05")) {
  stop("Manifest does not describe the authorised clean g=10 rerun.", call. = FALSE)
}

files <- list.files(result_dir, pattern = "^g10_n10_sd05_o[0-9]{4}\\.csv$", full.names = TRUE)
if (length(files) != 100L) stop("Expected exactly 100 clean g=10 shard files.", call. = FALSE)
x <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
if (nrow(x) != 1000L || !identical(unique(x$cell_id), "g10_n10_sd05") ||
    anyDuplicated(x[c("cell_id", "seed")])) {
  stop("Expected exactly 1,000 unique clean g=10 attempts.", call. = FALSE)
}
if (length(unique(x$source_hash)) != 1L || length(unique(x$helper_hash)) != 1L ||
    length(unique(x$package_commit)) != 1L ||
    !identical(unique(x$source_hash), unname(manifest[["runner_sha256"]])) ||
    !identical(unique(x$helper_hash), unname(manifest[["helper_sha256"]])) ||
    !identical(unique(x$package_commit), unname(manifest[["package_commit"]]))) {
  stop("Clean rerun row provenance does not match its manifest.", call. = FALSE)
}

summary <- do.call(rbind, lapply(c("bootstrap", "profile", "wald"), function(method) {
  exact <- a1_exact_binomial(x[[paste0(method, "_covers")]])
  data.frame(
    method = method, n_attempted = exact$n,
    n_valid_interval = exact$n_valid_interval,
    n_unavailable_interval = exact$n_unavailable_interval,
    coverage_all_attempts = exact$coverage,
    coverage_lo = exact$coverage_lo, coverage_hi = exact$coverage_hi,
    n_lower_miss = sum(x[[paste0(method, "_miss_direction")]] == "lower", na.rm = TRUE),
    n_upper_miss = sum(x[[paste0(method, "_miss_direction")]] == "upper", na.rm = TRUE),
    n_profile_boundary = if (identical(method, "profile")) sum(x$profile_boundary %in% TRUE) else NA_integer_,
    stringsAsFactors = FALSE
  )
}))
print(summary, row.names = FALSE)
write.csv(summary, file.path(result_dir, "clean_g10_summary.csv"), row.names = FALSE)
