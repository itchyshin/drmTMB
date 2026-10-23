#!/usr/bin/env Rscript
# Exact-row promotion for mc-0494 only after both retained direct q1 profile
# receipts pass.  This script cannot broaden the claim beyond the two targets.

lane_b_student_promote_stop <- function(...) stop(..., call. = FALSE)
lane_b_student_promote_hash <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"; out <- system2(command, if (identical(command, "sha256sum")) path else c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (!length(out) || !grepl("^[0-9a-f]{64}\\s", out[[1L]])) lane_b_student_promote_stop("Cannot hash ", path)
  sub("\\s.*$", "", out[[1L]])
}
lane_b_student_promote_control <- function(root) {
  x <- utils::read.delim(file.path(root, "docs", "dev-log", "evidence", "2026-07-28-lane-b-k12-dense-lss-direct-sd-control.tsv"), check.names = FALSE, stringsAsFactors = FALSE)
  if (nrow(x) != 2L || any(x$interval_status != "incomplete") || any(x$usable_and_covering != 0L)) lane_b_student_promote_stop("K12 control is not fail-closed.")
}
lane_b_student_promote_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  keyed <- args[grepl("^--[A-Za-z][A-Za-z-]*=", args)]
  value <- sub("^[^=]+=", "", keyed); names(value) <- sub("^--([^=]+)=.*$", "\\1", keyed)
  required <- c("ledger-dir", "date", "goal-authorized")
  if (!"--write" %in% args || !setequal(names(value), required) || !identical(value[["goal-authorized"]], "lane-b-144-goal")) lane_b_student_promote_stop("Requires --write, --ledger-dir, --date, and --goal-authorized=lane-b-144-goal.")
  root <- normalizePath(".", mustWork = TRUE); lane_b_student_promote_control(root)
  source(file.path(root, "tools", "validate-lane-b-student-spatial-q1-highinfo-contracts.R"), local = TRUE); contracts <- lane_b_student_spatial_read_validate(root)
  sha <- paste(system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE), collapse = "")
  receipt_dir <- file.path(root, "docs", "dev-log", "interval-feasibility", "results", sha, "student-spatial-q1-highinfo", "mc-0494")
  files <- list.files(receipt_dir, pattern = "receipt\\.tsv$", full.names = TRUE)
  receipts <- lapply(files, function(path) utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE))
  hit <- receipts[match(contracts$target_id, vapply(receipts, function(x) as.character(x$target_id[[1L]]), character(1L)))]
  if (length(hit) != 2L || any(vapply(hit, is.null, logical(1L)))) lane_b_student_promote_stop("Both exact retained target receipts are required.")
  for (i in seq_along(hit)) {
    x <- hit[[i]]
    pass <- nrow(x) == 1L && identical(x$cell_id[[1L]], "mc-0494") && identical(x$target_id[[1L]], contracts$target_id[[i]]) && identical(x$dgp_id[[1L]], contracts$dgp_id[[i]]) && identical(x$source_sha[[1L]], sha) && identical(x$conf_status[[1L]], "profile") && identical(x$profile_engine[[1L]], "tmbprofile") && isTRUE(x$trace_complete[[1L]]) && !isTRUE(x$profile_boundary[[1L]]) && !isTRUE(x$clamp_limited[[1L]]) && x$convergence[[1L]] == 0L && isTRUE(x$pdHess[[1L]]) && all(is.finite(unlist(x[c("estimate", "lower", "upper")]))) && x$lower[[1L]] < x$upper[[1L]] && x$estimate[[1L]] >= x$lower[[1L]] && x$estimate[[1L]] <= x$upper[[1L]] && (is.na(x$failure_reason[[1L]]) || !nzchar(x$failure_reason[[1L]])) && identical(lane_b_student_promote_hash(x$trace_path[[1L]]), x$trace_sha256[[1L]]) && identical(lane_b_student_promote_hash(x$interval_path[[1L]]), x$interval_sha256[[1L]])
    if (!pass) lane_b_student_promote_stop("Receipt fails complete unclamped contract: ", contracts$target_id[[i]])
  }
  ledger <- value[["ledger-dir"]]; cells_path <- file.path(ledger, "cells.tsv"); evidence_path <- file.path(ledger, "evidence.tsv"); transitions_path <- file.path(ledger, "transitions.tsv")
  cells <- utils::read.delim(cells_path, check.names = FALSE, stringsAsFactors = FALSE); i <- match("mc-0494", cells$cell_id)
  evidence_id <- "ev-mc-0494-student-spatial-q1-highinfo-profile"; transition_id <- "tr-mc-0494-student-spatial-q1-highinfo-profile"
  if (is.na(i) || cells$evidence_tier[[i]] != "point_fit_recovery") lane_b_student_promote_stop("mc-0494 is not uniquely point-fit recoverable.")
  evidence <- utils::read.delim(evidence_path, check.names = FALSE, stringsAsFactors = FALSE); transitions <- utils::read.delim(transitions_path, check.names = FALSE, stringsAsFactors = FALSE)
  if (evidence_id %in% evidence$evidence_id || transition_id %in% transitions$transition_id) lane_b_student_promote_stop("Promotion identifiers already exist.")
  boundary <- "interval_feasible only for mc-0494 x its two exact direct Student spatial mu SD targets x the frozen n32 x 20 high-information fixture, each with a retained complete unclamped tmbprofile receipt. This establishes neither whole-formula, other target, provider-wide, family-wide, coverage, calibration, inference-ready, public, nor API support."
  cells$evidence_tier[[i]] <- "interval_feasible"; cells$primary_evidence_id[[i]] <- evidence_id; cells$claim_boundary[[i]] <- boundary; cells$next_gate[[i]] <- "Coverage/calibration require a separate pre-registered evidence arc."; cells$updated_commit[[i]] <- sha; cells$updated_date[[i]] <- value[["date"]]; cells$notes[[i]] <- boundary
  raw <- readLines(cells_path, warn = FALSE); header <- strsplit(raw[[1L]], "\t", fixed = TRUE)[[1L]]; line <- which(vapply(raw[-1L], function(z) strsplit(z, "\t", fixed = TRUE)[[1L]][[1L]] == "mc-0494", logical(1L))) + 1L; values <- strsplit(raw[[line]], "\t", fixed = TRUE)[[1L]]; changed <- c("evidence_tier", "primary_evidence_id", "claim_boundary", "next_gate", "updated_commit", "updated_date", "notes"); values[match(changed, header)] <- as.character(cells[i, changed]); raw[[line]] <- paste(values, collapse = "\t"); writeLines(raw, cells_path)
  receipt_paths <- files[match(contracts$target_id, vapply(receipts, function(x) as.character(x$target_id[[1L]]), character(1L)))]
  row <- data.frame(evidence_id = evidence_id, cell_id = "mc-0494", evidence_class = "contract_test", path_or_url = paste(receipt_paths, collapse = ";"), commit_sha = sha, run_id = "Lane B Student spatial q1 high-information target pair", command = "Rscript tools/promote-lane-b-student-spatial-q1-highinfo-profile-receipts.R --write --goal-authorized=lane-b-144-goal", result = "Two retained complete unclamped tmbprofile receipts, each finite and ordered with convergence 0 and pdHess TRUE.", replicates = "One fixed-seed n32 x 20 profile per exact direct target.", reviewed_by = "Codex Lane B mechanical gate", review_date = value[["date"]], claim_boundary = boundary, stringsAsFactors = FALSE)
  transition <- data.frame(transition_id = transition_id, cell_id = "mc-0494", from_work_status = cells$work_status[[i]], to_work_status = cells$work_status[[i]], evidence_ids = evidence_id, reason = "Approved Lane-B 144-goal: both exact Student spatial target receipts passed.", actor = "Codex Lane B", commit_sha = sha, date = value[["date"]], stringsAsFactors = FALSE)
  append <- function(path, x) utils::write.table(x, path, sep = "\t", row.names = FALSE, col.names = FALSE, quote = TRUE, append = TRUE, na = "")
  append(evidence_path, row); append(transitions_path, transition); message("Promoted mc-0494 with two exact high-information profile receipts.")
}
`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
if (sys.nframe() == 0L) lane_b_student_promote_main()
