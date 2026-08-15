#!/usr/bin/env Rscript

# Promote one exact structured-q1 target from the retained twelve-target batch.
# A failed sibling is evidence about that sibling only; it never erases a valid
# direct-target receipt.  The registry's execution_authority remains the gate.

q1_targetwise_stop <- function(...) stop(..., call. = FALSE)

q1_targetwise_args <- function(args) {
  keyed <- args[grepl("^--[A-Za-z][A-Za-z-]*=", args)]
  if (length(setdiff(args, c(keyed, "--write")))) q1_targetwise_stop("Arguments must use --name=value syntax (except --write).")
  values <- sub("^[^=]+=", "", keyed)
  names(values) <- sub("^--([^=]+)=.*$", "\\1", keyed)
  needed <- c("ledger-dir", "attempts", "target-id", "date", "goal-authorized")
  missing <- setdiff(needed, names(values))
  if (length(missing)) q1_targetwise_stop("Missing: --", paste(missing, collapse = ", --"), "=.")
  if (!identical(values[["goal-authorized"]], "lane-b-144-goal")) q1_targetwise_stop("Requires --goal-authorized=lane-b-144-goal.")
  if (length(setdiff(names(values), needed))) q1_targetwise_stop("Unsupported arguments.")
  values
}

q1_targetwise_control <- function(root) {
  path <- file.path(root, "docs/dev-log/evidence/2026-07-28-lane-b-k12-dense-lss-direct-sd-control.tsv")
  if (!file.exists(path)) q1_targetwise_stop("Missing retained K=12 non-covering control.")
  x <- utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
  needed <- c("surface", "layer", "known_v_type", "interval_status", "conf.status", "complete_profile", "usable_and_covering")
  if (!all(needed %in% names(x)) || nrow(x) != 2L || !all(x$surface == "meta_v_lss") ||
      !all(x$layer == "LSS") || !all(x$known_v_type == "dense") ||
      !all(x$interval_status == "incomplete") || !all(x$conf.status == "clamp_limited") ||
      !all(x$complete_profile == 0L) || !all(x$usable_and_covering == 0L)) {
    q1_targetwise_stop("K=12 control must remain dense-LSS, clamp-limited, incomplete, and non-covering.")
  }
}

q1_targetwise_validate_attempts <- function(root, attempts, target_id) {
  # The validator uses base R plus `stats::setNames()` through the ordinary
  # interactive search path; retain that path when it is sourced here.
  validator <- new.env(parent = globalenv())
  sys.source(file.path(root, "tools/validate-lane-b-q1-expanded-whole-cell-contracts.R"), envir = validator)
  contracts <- validator$lane_b_q1_expanded_read_validate(root)
  if (nrow(attempts) != nrow(contracts) || anyDuplicated(attempts$target_id) ||
      !identical(as.character(attempts$target_id), as.character(contracts$target_id))) {
    q1_targetwise_stop("All-attempt input must retain exactly the ordered twelve-target q1-expanded denominator.")
  }
  hit_contract <- contracts[contracts$target_id == target_id, , drop = FALSE]
  hit <- attempts[attempts$target_id == target_id, , drop = FALSE]
  if (nrow(hit_contract) != 1L || !isTRUE(hit_contract$execution_authority[[1L]])) q1_targetwise_stop("Target lacks explicit execution authority.")
  if (nrow(hit) != 1L || !identical(hit$attempt_status[[1L]], "receipt_passed") || !file.exists(hit$receipt_path[[1L]])) q1_targetwise_stop("Target lacks one retained passing receipt.")
  receipt <- utils::read.delim(hit$receipt_path[[1L]], check.names = FALSE, stringsAsFactors = FALSE)
  needed <- c("cell_id", "target_id", "dgp_id", "source_sha", "conf_status", "profile_engine", "estimate", "lower", "upper", "convergence", "pdHess", "profile_boundary", "clamp_limited", "trace_complete", "failure_reason", "trace_path", "interval_path", "trace_sha256", "interval_sha256")
  if (nrow(receipt) != 1L || !all(needed %in% names(receipt)) ||
      !identical(receipt$cell_id[[1L]], hit_contract$cell_id[[1L]]) || !identical(receipt$target_id[[1L]], target_id) ||
      !identical(receipt$dgp_id[[1L]], hit_contract$dgp_id[[1L]]) || !identical(receipt$source_sha[[1L]], hit$source_sha[[1L]]) ||
      !identical(receipt$conf_status[[1L]], "profile") || !identical(receipt$profile_engine[[1L]], "tmbprofile") ||
      !isTRUE(receipt$trace_complete[[1L]]) || isTRUE(receipt$profile_boundary[[1L]]) || isTRUE(receipt$clamp_limited[[1L]]) ||
      receipt$convergence[[1L]] != 0L || !isTRUE(receipt$pdHess[[1L]]) || !all(is.finite(unlist(receipt[c("estimate", "lower", "upper")]))) ||
      receipt$lower[[1L]] >= receipt$upper[[1L]] || receipt$estimate[[1L]] < receipt$lower[[1L]] || receipt$estimate[[1L]] > receipt$upper[[1L]] ||
      (!is.na(receipt$failure_reason[[1L]]) && nzchar(receipt$failure_reason[[1L]]))) q1_targetwise_stop("Receipt fails the complete unclamped targetwise profile contract.")
  list(contract = hit_contract, attempt = hit, receipt = receipt)
}

q1_targetwise_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  values <- q1_targetwise_args(args)
  root <- normalizePath(".", mustWork = TRUE)
  q1_targetwise_control(root)
  attempts <- utils::read.delim(values[["attempts"]], check.names = FALSE, stringsAsFactors = FALSE)
  checked <- q1_targetwise_validate_attempts(root, attempts, values[["target-id"]])
  ledger <- values[["ledger-dir"]]
  paths <- file.path(ledger, c("cells.tsv", "evidence.tsv", "transitions.tsv")); names(paths) <- c("cells", "evidence", "transitions")
  cells <- utils::read.delim(paths[["cells"]], check.names = FALSE, stringsAsFactors = FALSE)
  evidence <- utils::read.delim(paths[["evidence"]], check.names = FALSE, stringsAsFactors = FALSE)
  transitions <- utils::read.delim(paths[["transitions"]], check.names = FALSE, stringsAsFactors = FALSE)
  cell <- checked$contract$cell_id[[1L]]; i <- match(cell, cells$cell_id)
  if (is.na(i) || !cells$evidence_tier[[i]] %in% c("point_fit_recovery", "interval_feasible")) q1_targetwise_stop(cell, " is not eligible for targetwise interval promotion.")
  ev <- paste0("ev-", cell, "-q1-expanded-targetwise-profile-low")
  tr <- paste0("tr-", cell, "-q1-expanded-targetwise-profile-low")
  sibling_note <- if (identical(values[["target-id"]], "mc-0248::sd:mu:relmat(1 | id)")) {
    "The sibling mc-0248::sd:mu:relmat(0 + x | id) remains profile_failed and point-fit only."
  } else {
    "No whole-formula, sibling-target, provider-wide, or family-wide claim follows from this one target receipt."
  }
  boundary <- paste("interval_feasible only for the named cell x direct target x frozen low-rung fixture with an exact retained unclamped tmbprofile receipt.", sibling_note, "Coverage, calibration, inference readiness, and public interval support were not evaluated.")
  existing <- ev %in% evidence$evidence_id || tr %in% transitions$transition_id
  if (existing) {
    if (ev %in% evidence$evidence_id && tr %in% transitions$transition_id && cells$evidence_tier[[i]] == "interval_feasible") {
      message("Exact targetwise q1 receipt is already promoted: ", cell, ".")
      return(invisible(checked))
    }
    q1_targetwise_stop("Partial or conflicting targetwise promotion identifiers for ", cell, ".")
  }
  if (!"--write" %in% args) return(invisible(checked))
  cells$evidence_tier[[i]] <- "interval_feasible"; cells$primary_evidence_id[[i]] <- ev; cells$claim_boundary[[i]] <- boundary; cells$next_gate[[i]] <- "Coverage/calibration and any broader formula, provider, or sibling target claim require a separate pre-registered evidence arc."; cells$updated_commit[[i]] <- checked$receipt$source_sha[[1L]]; cells$updated_date[[i]] <- values[["date"]]; cells$notes[[i]] <- boundary
  inserted_evidence <- data.frame(evidence_id = ev, cell_id = cell, evidence_class = "contract_test", path_or_url = checked$attempt$receipt_path[[1L]], commit_sha = checked$receipt$source_sha[[1L]], run_id = "Lane B q1-expanded targetwise retained profile batch", command = "Rscript tools/promote-lane-b-q1-expanded-targetwise-profile-receipt.R --target-id=<exact target> --goal-authorized=lane-b-144-goal", result = "Complete unclamped tmbprofile receipt with finite ordered endpoints, convergence 0, pdHess TRUE, and retained trace/interval hashes.", replicates = "One fixed-seed low-rung targetwise receipt in the retained twelve-target batch; failed siblings remain retained and non-promoted.", reviewed_by = "Codex Lane B targetwise mechanical gate", review_date = values[["date"]], claim_boundary = boundary, stringsAsFactors = FALSE)
  inserted_transition <- data.frame(transition_id = tr, cell_id = cell, from_work_status = cells$work_status[[i]], to_work_status = cells$work_status[[i]], evidence_ids = ev, reason = "Active Lane-B 144-goal authority: targetwise exact retained q1 profile receipt meets interval-feasible contract; failed sibling withheld.", actor = "Codex Lane B targetwise mechanical gate", commit_sha = checked$receipt$source_sha[[1L]], date = values[["date"]], stringsAsFactors = FALSE)
  raw <- readLines(paths[["cells"]], warn = FALSE, encoding = "UTF-8"); header <- strsplit(raw[[1L]], "\t", fixed = TRUE)[[1L]]; line <- which(vapply(raw[-1L], function(x) strsplit(x, "\t", fixed = TRUE)[[1L]][[1L]] == cell, logical(1L))) + 1L
  if (length(line) != 1L) q1_targetwise_stop("Cannot patch unique cell row: ", cell)
  changed <- c("evidence_tier", "primary_evidence_id", "claim_boundary", "next_gate", "updated_commit", "updated_date", "notes"); fields <- strsplit(raw[[line]], "\t", fixed = TRUE)[[1L]]; fields[match(changed, header)] <- as.character(cells[i, changed]); raw[[line]] <- paste(fields, collapse = "\t"); writeLines(raw, paths[["cells"]], useBytes = TRUE)
  append_rows <- function(path, x) { tmp <- tempfile(); utils::write.table(x, tmp, sep = "\t", row.names = FALSE, col.names = FALSE, quote = TRUE, na = ""); write(paste(readLines(tmp, warn = FALSE), collapse = "\n"), file = path, append = TRUE) }
  append_rows(paths[["evidence"]], inserted_evidence); append_rows(paths[["transitions"]], inserted_transition)
  message("Promoted one exact targetwise q1 receipt: ", cell, ".")
}

if (sys.nframe() == 0L) q1_targetwise_main()
