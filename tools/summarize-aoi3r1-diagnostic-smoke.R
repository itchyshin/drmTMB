#!/usr/bin/env Rscript

# AOI-3R1 is a diagnostic completeness gate, not an availability or inference
# gate. Non-interior and unavailable results are retained as evidence.
args <- commandArgs(trailingOnly = TRUE)
value <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) != 1L) stop("Supply exactly one --", name, "=VALUE.", call. = FALSE)
  sub(paste0("^--", name, "="), "", hit)
}
result_dir <- value("result-dir")
manifest_path <- value("seed-manifest")
out_dir <- value("out-dir")
if (dir.exists(out_dir) || file.exists(out_dir)) stop("Refusing to overwrite diagnostic summary.", call. = FALSE)
manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
paths <- Sys.glob(file.path(result_dir, "shards", "*", "outer-attempts.csv"))
if (!length(paths)) stop("No AOI-3R1 output shards found.", call. = FALSE)
read_union <- function(paths) {
  tables <- lapply(paths, utils::read.csv, check.names = FALSE, stringsAsFactors = FALSE)
  columns <- unique(unlist(lapply(tables, names), use.names = FALSE))
  tables <- lapply(tables, function(table) {
    missing <- setdiff(columns, names(table))
    for (column in missing) table[[column]] <- NA
    table[, columns, drop = FALSE]
  })
  do.call(rbind, tables)
}
outer <- read_union(paths)
inner_paths <- sub("outer-attempts.csv$", "inner-attempts.csv", paths)
inner <- read_union(inner_paths)
expected_outer <- manifest[manifest$attempt_type == "outer", ]
expected_inner <- manifest[manifest$attempt_type == "inner", ]
outer_key <- paste(outer$formula_id, outer$outer_id, outer$outer_seed)
inner_key <- paste(inner$formula_id, inner$outer_id, inner$inner_id, inner$inner_seed)
expected_outer_key <- paste(expected_outer$formula_id, expected_outer$outer_id, expected_outer$seed)
expected_inner_key <- paste(expected_inner$formula_id, expected_inner$outer_id, expected_inner$inner_id, expected_inner$seed)
required_payload <- c("diagnostic_version", "diagnostic_status", "diagnostic_sandwich_status")
complete <- nrow(outer) == 15L && nrow(inner) == 45L &&
  setequal(outer_key, expected_outer_key) && setequal(inner_key, expected_inner_key) &&
  length(unique(outer$source_sha)) == 1L && all(required_payload %in% names(outer)) &&
  all(!is.na(outer$diagnostic_version))
dir.create(out_dir, recursive = TRUE)
utils::write.csv(outer, file.path(out_dir, "outer-attempts.csv"), row.names = FALSE)
utils::write.csv(inner, file.path(out_dir, "inner-attempts.csv"), row.names = FALSE)
utils::write.csv(as.data.frame(table(outer$formula_id, outer$outer_status, outer$sandwich_status), stringsAsFactors = FALSE), file.path(out_dir, "outer-statuses.csv"), row.names = FALSE)
utils::write.csv(as.data.frame(table(inner$formula_id, inner$inner_status, inner$sandwich_status), stringsAsFactors = FALSE), file.path(out_dir, "inner-statuses.csv"), row.names = FALSE)
writeLines(if (complete) "AOI3R1_DIAGNOSTIC_COMPLETE" else "AOI3R1_DIAGNOSTIC_INVALID", file.path(out_dir, "decision.txt"))
if (!complete) quit(status = 1L)
