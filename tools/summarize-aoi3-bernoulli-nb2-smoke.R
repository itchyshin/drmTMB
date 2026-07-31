#!/usr/bin/env Rscript

# Fail-closed AOI-3 local-smoke reducer. This makes no calibration or public
# inference claim; it only decides whether the frozen DRAC campaign may stage.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) != 1L) stop("Supply exactly one --", name, "=VALUE.", call. = FALSE)
  sub(paste0("^--", name, "="), "", hit)
}
input_root <- arg_value("input-root")
out_dir <- arg_value("out-dir")
if (!dir.exists(input_root) || dir.exists(out_dir) || file.exists(out_dir)) stop("Input root must exist and output root must be new.", call. = FALSE)
outer_paths <- list.files(input_root, pattern = "^outer-attempts\\.csv$", recursive = TRUE, full.names = TRUE)
inner_paths <- list.files(input_root, pattern = "^inner-attempts\\.csv$", recursive = TRUE, full.names = TRUE)
if (length(outer_paths) != 5L || length(inner_paths) != 5L) stop("AOI-3 smoke requires exactly five outer and five inner files.", call. = FALSE)
bind_union <- function(paths) {
  tables <- lapply(paths, utils::read.csv, check.names = FALSE, stringsAsFactors = FALSE)
  columns <- unique(unlist(lapply(tables, names), use.names = FALSE))
  tables <- lapply(tables, function(table) {
    missing <- setdiff(columns, names(table))
    for (name in missing) table[[name]] <- NA
    table[columns]
  })
  do.call(rbind, tables)
}
outer <- bind_union(outer_paths)
inner <- bind_union(inner_paths)
needed_outer <- c("formula_id", "n", "strength", "outer_id", "source_sha", "outer_status", "sandwich_status", grep("^sandwich_se_", names(outer), value = TRUE))
if (!all(needed_outer %in% names(outer)) || !all(c("formula_id", "outer_id", "inner_id", "inner_status", "sandwich_status", "source_sha") %in% names(inner))) stop("AOI-3 smoke CSV schema is incomplete.", call. = FALSE)
expected_formulae <- c("additive", "mixed", "factor_interaction", "numeric_interaction", "transformation")
valid_outer <- nrow(outer) == 5L && identical(sort(outer$formula_id), sort(expected_formulae)) && all(outer$n == 720L) && all(outer$strength == "interior") && all(outer$outer_id == 1L) && all(outer$outer_status == "interior") && all(outer$sandwich_status == "ok") && all(vapply(outer[grep("^sandwich_se_", names(outer), value = TRUE)], function(x) all(is.finite(x) & x > 0), logical(1)))
valid_inner <- nrow(inner) == 35L && all(inner$inner_status == "interior") && all(inner$sandwich_status == "ok") && all(vapply(split(inner$inner_id, inner$formula_id), function(x) identical(sort(x), seq_len(7L)), logical(1)))
one_sha <- length(unique(c(outer$source_sha, inner$source_sha))) == 1L && grepl("^[0-9a-f]{40}$", unique(c(outer$source_sha, inner$source_sha))[[1L]])
decision <- if (valid_outer && valid_inner && one_sha) "AOI3_LOCAL_SMOKE_PASS_STAGE_DRAC_ALLOWED" else "AOI3_LOCAL_SMOKE_FAIL_DRAC_BLOCKED"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(outer, file.path(out_dir, "outer-attempts.csv"), row.names = FALSE)
utils::write.csv(inner, file.path(out_dir, "inner-attempts.csv"), row.names = FALSE)
writeLines(c(decision, paste0("source_sha=", unique(c(outer$source_sha, inner$source_sha))[[1L]])), file.path(out_dir, "decision.txt"))
message(decision)
