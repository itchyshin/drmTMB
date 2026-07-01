`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)

if (any(args %in% c("--help", "-h"))) {
  cat(paste(
    "Usage: Rscript tools/summarize-structured-re-q2-retained-denominator-review.R [options]",
    "",
    "Builds a cell-level review synthesis for the q2 SR150 retained-denominator pregrid.",
    "The output is review/no-promotion evidence only; it never edits support cells.",
    "",
    "Options:",
    "  --input=PATH       17-row target-level pregrid result TSV.",
    "  --output=PATH      5-row cell-level review synthesis TSV.",
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
input_path <- normalizePath(
  arg_value(
    "input",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-pregrid-results.tsv"
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
      "structured-re-q2-retained-denominator-review-synthesis.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
overwrite <- arg_flag("overwrite", FALSE)

if (file.exists(output_path) && !overwrite) {
  stop("Output exists; pass --overwrite=true to replace it: ", output_path, call. = FALSE)
}

pregrid <- read_tsv(input_path)
required <- c(
  "cell_id",
  "provider",
  "design_family",
  "target_kind",
  "estimand",
  "n_rep",
  "n_fit_ok",
  "n_converged",
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
  "profile_upper_miss",
  "pregrid_status",
  "promotion_decision",
  "source_artifact_dir",
  "slurm_cluster_name",
  "slurm_job_id"
)
missing <- setdiff(required, names(pregrid))
if (length(missing) > 0L) {
  stop(
    "q2 retained-denominator pregrid result TSV is missing fields: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}
if (nrow(pregrid) != 17L) {
  stop("q2 retained-denominator pregrid result TSV must have 17 rows.", call. = FALSE)
}
if (!all(pregrid$promotion_decision == "do_not_promote")) {
  stop("q2 retained-denominator pregrid rows must not promote support cells.", call. = FALSE)
}

status_for_cell <- function(x) {
  statuses <- unique(x$pregrid_status)
  if (any(grepl("convergence_or_pdhess", statuses, fixed = TRUE))) {
    return("sr150_pdhess_review_required_no_promotion")
  }
  if (any(grepl("wald_finiteness", statuses, fixed = TRUE))) {
    return("sr150_wald_finiteness_review_required_no_promotion")
  }
  if (any(grepl("profile_finiteness", statuses, fixed = TRUE))) {
    return("sr150_profile_finiteness_review_required_no_promotion")
  }
  "sr150_topup_or_shape_review_required_no_promotion"
}

target_summary <- function(x) {
  counts <- sort(table(x$pregrid_status), decreasing = TRUE)
  paste(paste0(names(counts), "=", as.integer(counts)), collapse = ";")
}

coverage_summary <- function(x) {
  paste(
    paste0(
      x$estimand,
      ":wald=",
      x$wald_coverage,
      "(mcse=",
      x$wald_coverage_mcse,
      "),profile=",
      x$profile_coverage,
      "(mcse=",
      x$profile_coverage_mcse,
      ")"
    ),
    collapse = ";"
  )
}

finite_summary <- function(x) {
  paste(
    paste0(
      x$estimand,
      ":wald_finite=",
      x$n_wald_finite,
      "/",
      x$n_rep,
      ",profile_finite=",
      x$n_profile_finite,
      "/",
      x$n_rep
    ),
    collapse = ";"
  )
}

miss_summary <- function(x) {
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

next_gate_for <- function(cell_id, review_state) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(paste(
      "Fisher/Rose/Grace review must resolve the retained 149/150 pdHess",
      "pattern across the five pregrid targets, decide whether any exact",
      "within-block target merits top-up, and repair or explain the held",
      "sigma1/sigma2 correlation profile-failure target before any further",
      "pregrid, top-up, interval_status, coverage_status, inference_ready,",
      "supported, or public-support edit; support-cell status edit remains",
      "blocked inside the no-promotion boundary."
    ))
  }
  if (grepl("wald_finiteness", review_state, fixed = TRUE)) {
    return(paste(
      "Fisher/Rose/Grace review must explain the retained Wald-finiteness",
      "loss in the direct-correlation target, inspect one-sided misses and raw",
      "replicate warnings, then decide blocker versus exact-target top-up;",
      "no support-cell status edit before that review; preserve the",
      "no-promotion boundary."
    ))
  }
  if (grepl("profile_finiteness", review_state, fixed = TRUE)) {
    return(paste(
      "Fisher/Rose/Grace review must explain the retained profile-finiteness",
      "loss in the direct-correlation target, inspect one-sided misses and raw",
      "replicate warnings, then decide blocker versus exact-target top-up;",
      "no support-cell status edit before that review; preserve the",
      "no-promotion boundary."
    ))
  }
  paste(
    "Fisher/Rose/Grace review must inspect retained denominator, convergence,",
    "pdHess, finite Wald/profile rates, one-sided misses, MCSE, and raw",
    "replicate warnings before deciding exact-target top-up versus blocker;",
    "no support-cell status edit before that review; preserve the",
    "no-promotion boundary."
  )
}

claim_boundary_for <- function(cell_id) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(paste(
      "This q2-plus-q2 synthesis promotes exactly no Q-Series row; SR150",
      "Rorqual retained-denominator evidence covers five ready within-block",
      "targets only, leaves the sigma1/sigma2 correlation repair-held, does not",
      "cover cross-block correlations, and does not claim interval_status,",
      "coverage_status, inference_ready, supported, q2-only inheritance, q4/q8,",
      "non-Gaussian intervals, REML, AI-REML, bridge support, or public support."
    ))
  }
  paste(
    "This q2-intercept synthesis promotes exactly no Q-Series row; SR150",
    "Rorqual retained-denominator evidence covers endpoint SD and",
    "direct-correlation targets as separate targets, treats MCSE <= 0.01 as a",
    "top-up/review target, and does not claim interval_status, coverage_status,",
    "inference_ready, supported, q2 slope inheritance, q2-plus-q2, q4/q8,",
    "non-Gaussian intervals, REML, AI-REML, bridge support, or public support."
  )
}

cell_order <- c(
  "qseries_phylo_q2_mu1_mu2_intercept",
  "qseries_spatial_q2_mu1_mu2_intercept",
  "qseries_animal_q2_mu1_mu2_intercept",
  "qseries_relmat_q2_mu1_mu2_intercept",
  "qseries_phylo_q2_plus_q2_intercept"
)

rows <- lapply(cell_order, function(cell_id) {
  x <- pregrid[pregrid$cell_id == cell_id, , drop = FALSE]
  if (nrow(x) == 0L) {
    stop("Missing q2 retained-denominator pregrid rows for ", cell_id, call. = FALSE)
  }
  review_state <- status_for_cell(x)
  data.frame(
    synthesis_id = paste0("q2_retained_denominator_review_", cell_id),
    cell_id = cell_id,
    design_family = paste(unique(x$design_family), collapse = ";"),
    provider = paste(unique(x$provider), collapse = ";"),
    n_targets = nrow(x),
    target_status_summary = target_summary(x),
    denominator_summary = paste0(
      "SR150 retained denominator; fit_ok=",
      sum(as.integer(x$n_fit_ok)),
      "/",
      sum(as.integer(x$n_rep)),
      "; converged=",
      sum(as.integer(x$n_converged)),
      "/",
      sum(as.integer(x$n_rep)),
      "; pdHess=",
      sum(as.integer(x$n_pdhess)),
      "/",
      sum(as.integer(x$n_rep)),
      "; host=Rorqual; jobs=",
      paste(sort(unique(x$slurm_job_id)), collapse = ",")
    ),
    finite_interval_summary = finite_summary(x),
    coverage_summary = coverage_summary(x),
    miss_balance_summary = miss_summary(x),
    review_state = review_state,
    promotion_decision = "do_not_promote",
    source_pregrid_results = rel_path(input_path),
    evidence_url = rel_path(input_path),
    claim_boundary = claim_boundary_for(cell_id),
    next_gate = next_gate_for(cell_id, review_state),
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
write_tsv(out, output_path)
message("Wrote q2 retained-denominator review synthesis to ", rel_path(output_path))
