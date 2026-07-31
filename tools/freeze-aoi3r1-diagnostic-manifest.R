#!/usr/bin/env Rscript

# Freeze, rather than derive at run time, every fresh AOI-3R1 diagnostic seed.
args <- commandArgs(trailingOnly = TRUE)
value <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) != 1L) stop("Supply exactly one --", name, "=VALUE.", call. = FALSE)
  sub(paste0("^--", name, "="), "", hit)
}
out_dir <- value("out-dir")
source_sha <- value("source-sha")
if (!grepl("^[0-9a-f]{40}$", source_sha) || dir.exists(out_dir) || file.exists(out_dir)) {
  stop("Manifest requires a new directory and a 40-character source SHA.", call. = FALSE)
}
dir.create(out_dir, recursive = TRUE)
formula_ids <- c("additive", "mixed", "factor_interaction", "numeric_interaction", "transformation")
rows <- list(); k <- 0L
for (formula_index in seq_along(formula_ids)) for (outer_id in 1:3) {
  k <- k + 1L
  rows[[k]] <- data.frame(attempt_type = "outer", formula_id = formula_ids[[formula_index]], n = 720L,
    outer_id = outer_id, inner_id = NA_integer_, seed = 1800000000L + formula_index * 10000L + outer_id,
    source_sha = source_sha, stringsAsFactors = FALSE)
  for (inner_id in 1:3) {
    k <- k + 1L
    rows[[k]] <- data.frame(attempt_type = "inner", formula_id = formula_ids[[formula_index]], n = 720L,
      outer_id = outer_id, inner_id = inner_id, seed = 1900000000L + formula_index * 10000L + outer_id * 100L + inner_id,
      source_sha = source_sha, stringsAsFactors = FALSE)
  }
}
manifest <- do.call(rbind, rows)
if (nrow(manifest) != 60L || anyDuplicated(manifest$seed)) stop("Internal manifest generation failure.", call. = FALSE)
utils::write.csv(manifest, file.path(out_dir, "manifest.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
