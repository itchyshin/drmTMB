#!/usr/bin/env Rscript
# Summarise the held full scalar-A1 profile-versus-bootstrap campaign. The
# primary coverage estimand is all attempted outer fits: unavailable intervals
# count as noncoverage while their frequency is reported separately.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: analyse_profile_vs_bootstrap.R <result_dir>", call. = FALSE)
result_dir <- args[[1L]]
file_arg <- grep("^--file=", commandArgs(), value = TRUE)
script_dir <- if (length(file_arg)) dirname(normalizePath(sub("^--file=", "", file_arg[[1L]]))) else getwd()
source(file.path(script_dir, "a1_profile_common.R"))

files <- list.files(
  result_dir,
  pattern = "^g(10|25|50)_n10_sd05_o[0-9]{4}\\.csv$",
  full.names = TRUE
)
if (!length(files)) stop("No campaign CSV files found.", call. = FALSE)
manifest_path <- file.path(result_dir, "campaign-manifest.txt")
if (!file.exists(manifest_path)) {
  stop("Campaign manifest is missing; refusing to analyse unauthenticated shards.", call. = FALSE)
}
manifest_lines <- readLines(manifest_path, warn = FALSE)
manifest <- stats::setNames(
  sub("^[^=]+=", "", manifest_lines[grepl("=", manifest_lines)]),
  sub("=.*$", "", manifest_lines[grepl("=", manifest_lines)])
)
required_manifest <- c(
  "package_commit", "runner_sha256", "helper_sha256", "launcher_sha256",
  "R_boot", "outer_attempts_per_cell", "workers", "started_utc", "completed_utc"
)
if (!all(required_manifest %in% names(manifest)) ||
    !identical(manifest[["R_boot"]], "999") ||
    !identical(manifest[["outer_attempts_per_cell"]], "1000") ||
    !identical(manifest[["workers"]], "100")) {
  stop("Campaign manifest is incomplete or violates the frozen full-run contract.", call. = FALSE)
}
x <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
cells <- c("g10_n10_sd05", "g25_n10_sd05", "g50_n10_sd05")
if (nrow(x) != 3000L || !identical(sort(unique(x$cell_id)), cells) ||
    any(table(x$cell_id) != 1000L) || anyDuplicated(x[c("cell_id", "seed")])) {
  stop("Expected exactly 1,000 unique seeded attempts in each frozen cell.", call. = FALSE)
}
if (anyNA(x$source_hash) || anyNA(x$helper_hash) ||
    length(unique(x$source_hash)) != 1L || length(unique(x$helper_hash)) != 1L ||
    anyNA(x$package_commit) || length(unique(x$package_commit)) != 1L) {
  stop("Campaign provenance is incomplete or inconsistent.", call. = FALSE)
}
if (!identical(unique(x$source_hash), unname(manifest[["runner_sha256"]])) ||
    !identical(unique(x$helper_hash), unname(manifest[["helper_sha256"]])) ||
    !identical(unique(x$package_commit), unname(manifest[["package_commit"]]))) {
  stop("Campaign-row provenance does not match the completed launch manifest.", call. = FALSE)
}

summarise_method <- function(one, method) {
  covered <- one[[paste0(method, "_covers")]]
  status <- one[[paste0(method, "_status")]]
  width <- one[[paste0(method, "_width")]]
  exact <- a1_exact_binomial(covered)
  data.frame(
    cell_id = unique(one$cell_id), method = method,
    n_attempted = exact$n, n_valid_interval = exact$n_valid_interval,
    n_unavailable_interval = exact$n_unavailable_interval,
    coverage_all_attempts = exact$coverage,
    coverage_lo = exact$coverage_lo, coverage_hi = exact$coverage_hi,
    n_lower_miss = sum(one[[paste0(method, "_miss_direction")]] == "lower", na.rm = TRUE),
    n_upper_miss = sum(one[[paste0(method, "_miss_direction")]] == "upper", na.rm = TRUE),
    median_width = stats::median(width, na.rm = TRUE),
    mean_width = mean(width, na.rm = TRUE),
    n_boundary = if (identical(method, "profile")) sum(one$profile_boundary %in% TRUE, na.rm = TRUE) else NA_integer_,
    stringsAsFactors = FALSE
  )
}

summary <- do.call(rbind, lapply(cells, function(cell) {
  one <- x[x$cell_id == cell, , drop = FALSE]
  do.call(rbind, lapply(c("bootstrap", "profile", "wald"), function(method) summarise_method(one, method)))
}))

paired_summary <- do.call(rbind, lapply(cells, function(cell) {
  one <- x[x$cell_id == cell, , drop = FALSE]
  bootstrap <- one$bootstrap_covers
  profile <- one$profile_covers
  if (anyNA(bootstrap) || anyNA(profile)) {
    stop("Paired profile-versus-bootstrap comparison requires all-attempt interval outcomes.",
         call. = FALSE)
  }
  d <- as.integer(profile) - as.integer(bootstrap)
  se <- sqrt(stats::var(d) / length(d))
  data.frame(
    cell_id = cell,
    n_attempted = length(d),
    bootstrap_only = sum(d == -1L),
    profile_only = sum(d == 1L),
    coverage_difference = mean(d),
    difference_lo = mean(d) - stats::qnorm(0.975) * se,
    difference_hi = mean(d) + stats::qnorm(0.975) * se,
    ci_method = "paired normal approximation",
    stringsAsFactors = FALSE
  )
}))

profile_endpoint_summary <- do.call(rbind, lapply(cells, function(cell) {
  one <- x[x$cell_id == cell, , drop = FALSE]
  data.frame(
    cell_id = cell,
    n_profile_endpoint = sum(one$profile_engine == "endpoint", na.rm = TRUE),
    n_profile_boundary = sum(one$profile_boundary %in% TRUE, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}))
print(summary, row.names = FALSE)
print(paired_summary, row.names = FALSE)
write.csv(summary, file.path(result_dir, "profile_vs_bootstrap_summary.csv"), row.names = FALSE)
write.csv(paired_summary, file.path(result_dir, "profile_vs_bootstrap_paired.csv"), row.names = FALSE)
write.csv(profile_endpoint_summary, file.path(result_dir, "profile_endpoint_summary.csv"), row.names = FALSE)
