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

files <- list.files(result_dir, pattern = "\\.csv$", full.names = TRUE)
if (!length(files)) stop("No campaign CSV files found.", call. = FALSE)
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

summarise_method <- function(one, method) {
  covered <- one[[paste0(method, "_covers")]]
  status <- one[[paste0(method, "_status")]]
  exact <- a1_exact_binomial(covered)
  data.frame(
    cell_id = unique(one$cell_id), method = method,
    n_attempted = exact$n, n_valid_interval = exact$n_valid_interval,
    n_unavailable_interval = exact$n_unavailable_interval,
    coverage_all_attempts = exact$coverage,
    coverage_lo = exact$coverage_lo, coverage_hi = exact$coverage_hi,
    n_lower_miss = sum(one[[paste0(method, "_miss_direction")]] == "lower", na.rm = TRUE),
    n_upper_miss = sum(one[[paste0(method, "_miss_direction")]] == "upper", na.rm = TRUE),
    n_boundary = if (identical(method, "profile")) sum(one$profile_boundary %in% TRUE, na.rm = TRUE) else NA_integer_,
    stringsAsFactors = FALSE
  )
}

summary <- do.call(rbind, lapply(cells, function(cell) {
  one <- x[x$cell_id == cell, , drop = FALSE]
  do.call(rbind, lapply(c("bootstrap", "profile", "wald"), function(method) summarise_method(one, method)))
}))
print(summary, row.names = FALSE)
write.csv(summary, file.path(result_dir, "profile_vs_bootstrap_summary.csv"), row.names = FALSE)
