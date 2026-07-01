`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)

if (any(args %in% c("--help", "-h"))) {
  cat(paste(
    "Usage: Rscript tools/summarize-structured-re-q2-retained-denominator-review-decision.R [options]",
    "",
    "Builds a Fisher/Rose/Grace decision table for q2 SR150 review synthesis rows.",
    "The output is blocker/no-promotion evidence only; it never edits support cells.",
    "",
    "Options:",
    "  --pregrid=PATH     17-row target-level pregrid result TSV.",
    "  --synthesis=PATH   5-row cell-level review synthesis TSV.",
    "  --output=PATH      5-row decision TSV.",
    "  --overwrite=true   Replace an existing output path.",
    "",
    sep = "\n"
  ))
  quit(status = 0)
}

arg_value <- function(name, default = NULL) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (length(hit) == 0L) {
    return(default)
  }
  sub(prefix, "", hit[[length(hit)]], fixed = TRUE)
}

arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root_candidates <- c(
  Sys.getenv("DRMTMB_REPO_ROOT", ""),
  file.path(dirname(script_file), ".."),
  getwd(),
  file.path(getwd(), ".."),
  file.path(getwd(), "..", "..")
)
repo_root_candidates <- repo_root_candidates[nzchar(repo_root_candidates)]
repo_root <- NA_character_
for (candidate in repo_root_candidates) {
  candidate <- normalizePath(candidate, winslash = "/", mustWork = FALSE)
  if (file.exists(file.path(candidate, "DESCRIPTION"))) {
    repo_root <- candidate
    break
  }
}
if (is.na(repo_root)) {
  stop("Cannot locate drmTMB repo root.", call. = FALSE)
}

rel_path <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"), "", path)
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
pregrid_path <- normalizePath(
  arg_value(
    "pregrid",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-pregrid-results.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
synthesis_path <- normalizePath(
  arg_value(
    "synthesis",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-review-synthesis.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
output_path <- normalizePath(
  arg_value(
    "output",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-review-decision.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
overwrite <- arg_flag("overwrite", FALSE)

if (file.exists(output_path) && !overwrite) {
  stop("Output exists; pass --overwrite=true to replace it: ", output_path, call. = FALSE)
}

pregrid <- read_tsv(pregrid_path)
synthesis <- read_tsv(synthesis_path)

required_pregrid <- c(
  "cell_id",
  "estimand",
  "n_rep",
  "n_pdhess",
  "n_wald_finite",
  "n_profile_finite",
  "wald_coverage",
  "wald_coverage_mcse",
  "profile_coverage",
  "profile_coverage_mcse",
  "wald_lower_miss",
  "wald_upper_miss",
  "profile_lower_miss",
  "profile_upper_miss"
)
missing_pregrid <- setdiff(required_pregrid, names(pregrid))
if (length(missing_pregrid) > 0L) {
  stop(
    "q2 retained-denominator pregrid result TSV is missing fields: ",
    paste(missing_pregrid, collapse = ", "),
    call. = FALSE
  )
}

required_synthesis <- c(
  "cell_id",
  "review_state",
  "denominator_summary",
  "target_status_summary",
  "promotion_decision"
)
missing_synthesis <- setdiff(required_synthesis, names(synthesis))
if (length(missing_synthesis) > 0L) {
  stop(
    "q2 retained-denominator review synthesis TSV is missing fields: ",
    paste(missing_synthesis, collapse = ", "),
    call. = FALSE
  )
}
if (nrow(synthesis) != 5L) {
  stop("q2 retained-denominator review synthesis TSV must have 5 rows.", call. = FALSE)
}
if (!all(synthesis$promotion_decision == "do_not_promote")) {
  stop("q2 retained-denominator review synthesis rows must not promote support cells.", call. = FALSE)
}

cell_order <- c(
  "qseries_phylo_q2_mu1_mu2_intercept",
  "qseries_spatial_q2_mu1_mu2_intercept",
  "qseries_animal_q2_mu1_mu2_intercept",
  "qseries_relmat_q2_mu1_mu2_intercept",
  "qseries_phylo_q2_plus_q2_intercept"
)

decision_status_for <- function(cell_id, review_state) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return("fisher_rose_grace_pdhess_shape_blocked_no_topup")
  }
  if (grepl("profile_finiteness", review_state, fixed = TRUE)) {
    return("fisher_rose_grace_profile_finiteness_shape_blocked_no_topup")
  }
  if (grepl("wald_finiteness", review_state, fixed = TRUE)) {
    return("fisher_rose_grace_wald_finiteness_shape_blocked_no_topup")
  }
  "fisher_rose_grace_shape_blocked_no_topup"
}

topup_decision_for <- function(cell_id, decision_status) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(
      "blocked_no_topup_until_pdHess_pattern_interval_shape_and_held_sigma1/sigma2_correlation_route_are_repaired"
    )
  }
  if (grepl("profile_finiteness", decision_status, fixed = TRUE)) {
    return("blocked_no_topup_until_profile_finiteness_and_interval_shape_repaired")
  }
  if (grepl("wald_finiteness", decision_status, fixed = TRUE)) {
    return("blocked_no_topup_until_wald_finiteness_and_interval_shape_repaired")
  }
  "blocked_no_topup_until_interval_shape_repaired"
}

flagged_targets <- function(x) {
  flags <- character()
  for (i in seq_len(nrow(x))) {
    row <- x[i, , drop = FALSE]
    target_flags <- character()
    if (as.integer(row$n_pdhess) < as.integer(row$n_rep)) {
      target_flags <- c(target_flags, paste0("pdHess=", row$n_pdhess, "/", row$n_rep))
    }
    if (as.integer(row$n_wald_finite) < as.integer(row$n_rep)) {
      target_flags <- c(target_flags, paste0("wald_finite=", row$n_wald_finite, "/", row$n_rep))
    }
    if (as.integer(row$n_profile_finite) < as.integer(row$n_rep)) {
      target_flags <- c(target_flags, paste0("profile_finite=", row$n_profile_finite, "/", row$n_rep))
    }
    if (as.numeric(row$wald_coverage) < 0.93) {
      target_flags <- c(target_flags, paste0("wald_coverage=", row$wald_coverage))
    }
    if (as.numeric(row$profile_coverage) < 0.93) {
      target_flags <- c(target_flags, paste0("profile_coverage=", row$profile_coverage))
    }
    if (length(target_flags) > 0L) {
      flags <- c(flags, paste0(row$estimand, "[", paste(target_flags, collapse = ","), "]"))
    }
  }
  paste(flags, collapse = ";")
}

finite_signal <- function(x) {
  paste(
    paste0(
      x$estimand,
      ":pdHess=",
      x$n_pdhess,
      "/",
      x$n_rep,
      ",wald=",
      x$n_wald_finite,
      "/",
      x$n_rep,
      ",profile=",
      x$n_profile_finite,
      "/",
      x$n_rep
    ),
    collapse = ";"
  )
}

miss_signal <- function(x) {
  paste(
    paste0(
      x$estimand,
      ":wald_lu=",
      x$wald_lower_miss,
      "/",
      x$wald_upper_miss,
      ",profile_lu=",
      x$profile_lower_miss,
      "/",
      x$profile_upper_miss
    ),
    collapse = ";"
  )
}

next_gate_for <- function(cell_id, decision_status) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(paste(
      "Do not submit Totoro, Nibi, Rorqual, Trillium, or other DRAC top-up",
      "jobs for this cell until the pdHess 745/750 pattern, q2-plus interval",
      "shape, and held sigma1/sigma2 correlation route have a repair design;",
      "then rerun a small retained-denominator smoke before any support-cell",
      "status edit."
    ))
  }
  if (grepl("profile_finiteness", decision_status, fixed = TRUE)) {
    return(paste(
      "Do not submit Totoro, Nibi, Rorqual, Trillium, or other DRAC top-up",
      "jobs until the direct-correlation profile-finiteness loss and interval",
      "undercoverage have a repair design; then rerun a small retained-denominator",
      "smoke before any support-cell status edit."
    ))
  }
  if (grepl("wald_finiteness", decision_status, fixed = TRUE)) {
    return(paste(
      "Do not submit Totoro, Nibi, Rorqual, Trillium, or other DRAC top-up",
      "jobs until the direct-correlation Wald/profile finiteness loss and",
      "interval undercoverage have a repair design; then rerun a small",
      "retained-denominator smoke before any support-cell status edit."
    ))
  }
  paste(
    "Do not submit Totoro, Nibi, Rorqual, Trillium, or other DRAC top-up jobs",
    "until q2 intercept interval-shape undercoverage is repaired; then rerun a",
    "small retained-denominator smoke before any support-cell status edit."
  )
}

claim_boundary_for <- function(cell_id) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(paste(
      "Fisher/Rose/Grace decision blocks q2-plus-q2 top-up and promotes exactly",
      "no Q-Series row; pdHess, interval-shape, and held sigma1/sigma2",
      "correlation repair are required before more compute; this does not claim",
      "interval_status, coverage_status, inference_ready, supported, q2",
      "inheritance, q4/q8, non-Gaussian intervals, REML, AI-REML, bridge",
      "support, or public support."
    ))
  }
  paste(
    "Fisher/Rose/Grace decision blocks q2 intercept top-up and promotes exactly",
    "no Q-Series row; interval-shape and finite-interval repair are required",
    "before more compute; this does not claim interval_status, coverage_status,",
    "inference_ready, supported, q2 slope inheritance, q2-plus-q2, q4/q8,",
    "non-Gaussian intervals, REML, AI-REML, bridge support, or public support."
  )
}

rows <- lapply(cell_order, function(cell_id) {
  x <- pregrid[pregrid$cell_id == cell_id, , drop = FALSE]
  s <- synthesis[synthesis$cell_id == cell_id, , drop = FALSE]
  if (nrow(x) == 0L || nrow(s) != 1L) {
    stop("Missing q2 decision inputs for ", cell_id, call. = FALSE)
  }
  decision_status <- decision_status_for(cell_id, s$review_state)
  all_coverages <- c(as.numeric(x$wald_coverage), as.numeric(x$profile_coverage))
  all_mcses <- c(as.numeric(x$wald_coverage_mcse), as.numeric(x$profile_coverage_mcse))
  data.frame(
    decision_id = paste0("q2_retained_denominator_decision_", cell_id),
    cell_id = cell_id,
    review_state = s$review_state,
    decision_status = decision_status,
    fisher_decision = paste(
      "block_topup_for_inference; SR150 shows target-level undercoverage or",
      "finite-interval loss, so MCSE top-up alone would not justify promotion"
    ),
    rose_decision = paste(
      "keep_status_unpromoted; decision is blocker evidence and must not be",
      "summarized as interval_status, coverage_status, inference_ready, or supported"
    ),
    grace_decision = paste(
      "block_cluster_compute_until_repair_contract; Totoro/Nibi/Rorqual/Trillium",
      "top-up needs exact target, seed, denominator, interval, and artifact policy"
    ),
    topup_decision = topup_decision_for(cell_id, decision_status),
    status_edit_decision = "do_not_promote_keep_point_fit_planned_planned",
    min_coverage = sprintf("%.4f", min(all_coverages, na.rm = TRUE)),
    max_coverage_mcse = sprintf("%.6f", max(all_mcses, na.rm = TRUE)),
    denominator_signal = s$denominator_summary,
    finite_signal = finite_signal(x),
    miss_balance_signal = miss_signal(x),
    blocker_targets = flagged_targets(x),
    evidence_url = rel_path(synthesis_path),
    source_review_synthesis = rel_path(synthesis_path),
    source_pregrid_results = rel_path(pregrid_path),
    claim_boundary = claim_boundary_for(cell_id),
    next_gate = next_gate_for(cell_id, decision_status),
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
write_tsv(out, output_path)
message("Wrote q2 retained-denominator review decision to ", rel_path(output_path))
