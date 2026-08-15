#!/usr/bin/env Rscript
q2scale_stop <- function(...) stop(..., call. = FALSE)
q2scale_hash <- function(path) { command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"; out <- system2(command, if (command == "sha256sum") path else c("-a", "256", path), stdout = TRUE); sub("\\s.*$", "", out[[1L]]) }
q2scale_read_validate <- function(root = normalizePath(".", mustWork = TRUE)) {
  path <- file.path(root, "docs/dev-log/interval-campaign-bindings/2026-07-29-q2plus-phylo-scale-canonical-contracts.tsv")
  x <- utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
  expected_cells <- c("mc-0091", "mc-0092")
  expected_targets <- c("mc-0091::sd:mu:sigma1:phylo(1 | pl | species)", "mc-0092::sd:mu:sigma2:phylo(1 | pl | species)")
  if (nrow(x) != 2L || anyDuplicated(x$cell_id) || anyDuplicated(x$target_id) || !identical(x$cell_id, expected_cells) || !identical(x$target_id, expected_targets) || any(x$dgp_id != "qseries_phylo_q2_plus_q2_intercept") || any(x$seed != 823001L) || any(x$execution_information_rung != "low") || !all(x$execution_authority)) q2scale_stop("q2-plus scale contract must retain two exact authorized sigma targets.")
  adapter <- file.path(root, "tools/lane-b-q2plus-phylo-production-adapter.R"); upstream <- file.path(root, "tools/run-structured-re-q2-plus-q2-intercept-smoke.R")
  if (!all(x$source_adapter_sha256 == q2scale_hash(adapter)) || !all(x$upstream_source_sha256 == q2scale_hash(upstream))) q2scale_stop("q2-plus scale source hash drift.")
  x
}
if (sys.nframe() == 0L) { q2scale_read_validate(); message("Validated two exact q2-plus phylo scale contracts.") }
