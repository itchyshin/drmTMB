`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)

if (any(args %in% c("--help", "-h"))) {
  cat(paste(
    "Usage: Rscript tools/summarize-structured-re-q2-retained-denominator-repair-contract.R [options]",
    "",
    "Builds a Fisher/Rose/Grace repair-contract table for q2 retained-denominator",
    "review decisions. The output permits only small repair smokes; it never",
    "promotes support cells or authorizes SR475/SR1000 top-up by itself.",
    "",
    "Options:",
    "  --decision=PATH    5-row q2 review-decision TSV.",
    "  --pregrid=PATH     17-row target-level pregrid result TSV.",
    "  --output=PATH      5-row repair-contract TSV.",
    "  --sync-dashboard=true",
    "                     Point q2 dashboard rows at the repair contract while",
    "                     keeping support cells point_fit/planned/planned.",
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
decision_path <- normalizePath(
  arg_value(
    "decision",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-review-decision.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
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
output_path <- normalizePath(
  arg_value(
    "output",
    file.path(
      dashboard_dir,
      "structured-re-q2-retained-denominator-repair-contract.tsv"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
overwrite <- arg_flag("overwrite", FALSE)
sync_dashboard <- arg_flag("sync-dashboard", FALSE)

if (file.exists(output_path) && !overwrite) {
  stop(
    "Output exists; pass --overwrite=true to replace it: ",
    output_path,
    call. = FALSE
  )
}

decision <- read_tsv(decision_path)
pregrid <- read_tsv(pregrid_path)

required_decision <- c(
  "cell_id",
  "decision_status",
  "topup_decision",
  "status_edit_decision",
  "min_coverage",
  "max_coverage_mcse",
  "blocker_targets",
  "source_review_synthesis",
  "source_pregrid_results"
)
missing_decision <- setdiff(required_decision, names(decision))
if (length(missing_decision) > 0L) {
  stop(
    "q2 review-decision TSV is missing fields: ",
    paste(missing_decision, collapse = ", "),
    call. = FALSE
  )
}
if (nrow(decision) != 5L) {
  stop("q2 review-decision TSV must have 5 rows.", call. = FALSE)
}
if (
  !all(
    decision$status_edit_decision ==
      "do_not_promote_keep_point_fit_planned_planned"
  )
) {
  stop(
    "q2 review-decision rows must not authorize status edits.",
    call. = FALSE
  )
}

required_pregrid <- c("cell_id", "estimand", "target_kind")
missing_pregrid <- setdiff(required_pregrid, names(pregrid))
if (length(missing_pregrid) > 0L) {
  stop(
    "q2 retained-denominator pregrid result TSV is missing fields: ",
    paste(missing_pregrid, collapse = ", "),
    call. = FALSE
  )
}

cell_order <- c(
  "qseries_phylo_q2_mu1_mu2_intercept",
  "qseries_spatial_q2_mu1_mu2_intercept",
  "qseries_animal_q2_mu1_mu2_intercept",
  "qseries_relmat_q2_mu1_mu2_intercept",
  "qseries_phylo_q2_plus_q2_intercept"
)

provider_for <- function(cell_id) {
  sub("^qseries_([^_]+)_.*$", "\\1", cell_id)
}

smoke_n_rep_for <- function(cell_id) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(16L)
  }
  32L
}

seed_start_for <- function(cell_id) {
  switch(
    cell_id,
    qseries_phylo_q2_mu1_mu2_intercept = 920001L,
    qseries_spatial_q2_mu1_mu2_intercept = 921001L,
    qseries_animal_q2_mu1_mu2_intercept = 922001L,
    qseries_relmat_q2_mu1_mu2_intercept = 923001L,
    qseries_phylo_q2_plus_q2_intercept = 924001L,
    stop("Unknown q2 repair cell: ", cell_id, call. = FALSE)
  )
}

repair_focus_for <- function(cell_id, decision_status) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(
      "pdHess_pattern_interval_shape_and_held_sigma1_sigma2_correlation_route"
    )
  }
  if (grepl("profile_finiteness", decision_status, fixed = TRUE)) {
    return("direct_correlation_profile_finiteness_and_interval_shape")
  }
  if (grepl("wald_finiteness", decision_status, fixed = TRUE)) {
    return("direct_correlation_wald_profile_finiteness_and_interval_shape")
  }
  "interval_shape_undercoverage"
}

interval_repair_for <- function(cell_id) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(paste(
      "location-SD targets compare default bias+t Wald, endpoint profile, and",
      "a skew-aware/profile-calibrated candidate; sigma-SD targets stay raw",
      "sigma-side with no location-axis bias+t default; direct correlations",
      "require finite profile/Wald sidecars; held sigma1/sigma2 correlation route",
      "must be repaired or explicitly blocked before top-up"
    ))
  }
  paste(
    "location-axis SD targets compare default bias+t Wald, endpoint profile,",
    "and a skew-aware/profile-calibrated candidate; direct correlation target",
    "requires finite profile/Wald sidecars; endpoint SD evidence does not",
    "promote direct-correlation intervals"
  )
}

finite_policy_for <- function(cell_id) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(paste(
      "retain all attempted rows; report fit_ok, convergence, pdHess, Wald",
      "finite, profile finite, warning rows, and finite interval fraction by",
      "target; no survivor-only coverage; q2-plus repair smoke must explain",
      "the retained 745/750 pdHess pattern before any top-up"
    ))
  }
  paste(
    "retain all attempted rows; report fit_ok, convergence, pdHess, Wald",
    "finite, profile finite, warning rows, and finite interval fraction by",
    "target; no survivor-only coverage; direct-correlation finite losses",
    "block top-up until repaired or explicitly classified"
  )
}

held_targets_for <- function(cell_id) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(
      "held_cor_sigma1_sigma2_intercept;cross_block_correlations_not_targets"
    )
  }
  "none"
}

next_gate_for <- function(cell_id, smoke_n_rep) {
  if (identical(cell_id, "qseries_phylo_q2_plus_q2_intercept")) {
    return(paste(
      "Design a named q2-plus interval-repair route first, then run one small",
      " repair smoke with n_rep=",
      smoke_n_rep,
      " on Totoro or one DRAC host only after source/run-root checks pass; review",
      " pdHess, finite profile/Wald rates, held sigma1/sigma2 correlation route,",
      " and one-sided misses before any SR475/SR1000 top-up or support-cell edit.",
      sep = ""
    ))
  }
  paste(
    "Design a named interval-repair route first, then run one target-scoped",
    " small repair smoke with n_rep=",
    smoke_n_rep,
    " on Totoro or one DRAC host only after source/run-root checks pass; review",
    " finite profile/Wald rates, interval-shape changes, and one-sided misses",
    " before any SR475/SR1000 top-up or support-cell edit.",
    sep = ""
  )
}

artifact_requirements <- paste(
  "raw_replicate_tsv",
  "per_target_summary",
  "seed_manifest",
  "run_log",
  "sessionInfo.txt",
  "git-sha.txt",
  "module-list.txt",
  "scheduler_stdout_stderr_when_slurm",
  "exact_command_lines",
  "seff.txt_when_available",
  "cleanup_note_for_totoro_workers",
  sep = ";"
)

allowed_hosts <- paste(
  "Totoro for small repair smoke only, default 50 workers and <=100 workers",
  "maximum with cleanup; Nibi or Rorqual for one-host SLURM smoke after source",
  "and run-root checks; local artifact replay; Trillium only with",
  "--allow-trillium=true plus synced source/run-root, row-specific command,",
  "seed manifest, module list, and host-separated provenance"
)

blocked_hosts <- paste(
  "Trillium without explicit source/run-root/provenance review and",
  "--allow-trillium=true; FIIA until alias is configured; any mixed-host",
  "denominator; any SR475/SR1000",
  "top-up before repair-smoke review; any support-cell status edit before",
  "Fisher/Rose/Grace approval"
)

rows <- lapply(cell_order, function(cell_id) {
  d <- decision[decision$cell_id == cell_id, , drop = FALSE]
  x <- pregrid[pregrid$cell_id == cell_id, , drop = FALSE]
  if (nrow(d) != 1L || nrow(x) == 0L) {
    stop("Missing q2 repair-contract inputs for ", cell_id, call. = FALSE)
  }
  smoke_n_rep <- smoke_n_rep_for(cell_id)
  seed_start <- seed_start_for(cell_id)
  seed_end <- seed_start + smoke_n_rep - 1L
  repair_targets <- paste(unique(x$estimand), collapse = ";")
  data.frame(
    repair_id = paste0("q2_retained_denominator_repair_contract_", cell_id),
    cell_id = cell_id,
    provider = provider_for(cell_id),
    repair_status = "fisher_rose_grace_repair_contract_ready_no_promotion",
    source_decision = rel_path(decision_path),
    source_review_synthesis = d$source_review_synthesis,
    source_pregrid_results = d$source_pregrid_results,
    source_decision_status = d$decision_status,
    source_topup_decision = d$topup_decision,
    repair_focus = repair_focus_for(cell_id, d$decision_status),
    repair_targets = repair_targets,
    primary_blocker_targets = d$blocker_targets,
    held_or_blocked_targets = held_targets_for(cell_id),
    interval_repair_plan = interval_repair_for(cell_id),
    denominator_policy = paste(
      "all_attempted_replicates_retained; fit/convergence/pdHess/finite",
      "interval rows retained; coverage reported only with retained denominator;",
      "no survivor-only coverage; no neighbouring-row inheritance"
    ),
    finite_interval_policy = finite_policy_for(cell_id),
    one_sided_miss_policy = paste(
      "report lower and upper misses by target and interval channel; block",
      "promotion on severe lower/upper imbalance or target-level hard negative;",
      "do not use MCSE top-up to hide interval-shape defects"
    ),
    smoke_n_rep = as.character(smoke_n_rep),
    smoke_seed_range = paste0(seed_start, "-", seed_end),
    topup_policy = paste(
      "no SR475/SR1000 top-up until the small repair smoke passes Fisher/Rose/Grace",
      "review; after passing smoke, top up only exact targets with acceptable",
      "finite denominators and miss-balance diagnostics"
    ),
    allowed_hosts = allowed_hosts,
    blocked_hosts = blocked_hosts,
    artifact_requirements = artifact_requirements,
    status_edit_policy = "do_not_promote_keep_point_fit_planned_planned",
    claim_boundary = paste(
      "Repair contract only; this promotes exactly no Q-Series row and does not",
      "claim interval_status, coverage_status, inference_ready, supported, q2",
      "slope inheritance, q2-plus inheritance, q4/q8, non-Gaussian intervals,",
      "REML, AI-REML, bridge support, or public support."
    ),
    next_gate = next_gate_for(cell_id, smoke_n_rep),
    stringsAsFactors = FALSE
  )
})

out <- do.call(rbind, rows)
write_tsv(out, output_path)
message(
  "Wrote q2 retained-denominator repair contract to ",
  rel_path(output_path)
)

if (sync_dashboard) {
  output_rel <- rel_path(output_path)
  decision_rel <- rel_path(decision_path)
  pregrid_rel <- rel_path(pregrid_path)

  support_path <- file.path(
    dashboard_dir,
    "structured-re-q-series-support-cells.tsv"
  )
  lowq_path <- file.path(
    dashboard_dir,
    "structured-re-gaussian-lowq-status-audit.tsv"
  )
  selection_path <- file.path(
    dashboard_dir,
    "structured-re-gaussian-lowq-row-selection.tsv"
  )
  closure_path <- file.path(
    dashboard_dir,
    "structured-re-q-series-closure-triage.tsv"
  )

  support <- read_tsv(support_path)
  support_idx <- match(out$cell_id, support$cell_id)
  if (anyNA(support_idx)) {
    stop(
      "Support-cell TSV is missing repair-contract cells: ",
      paste(out$cell_id[is.na(support_idx)], collapse = ", "),
      call. = FALSE
    )
  }
  for (field in c("fit_status", "interval_status", "coverage_status")) {
    if (!field %in% names(support)) {
      stop("Support-cell TSV is missing field: ", field, call. = FALSE)
    }
  }
  support$evidence_url[support_idx] <- output_rel
  support$claim_boundary[support_idx] <- out$claim_boundary
  support$denominator_policy[
    support_idx
  ] <- "repair_contract_ready_not_coverage"
  support$next_gate[support_idx] <- out$next_gate
  support$fit_status[support_idx] <- "point_fit"
  support$interval_status[support_idx] <- "planned"
  support$coverage_status[support_idx] <- "planned"
  write_tsv(support, support_path)

  lowq <- read_tsv(lowq_path)
  lowq_idx <- match(out$cell_id, lowq$cell_id)
  if (anyNA(lowq_idx)) {
    stop(
      "Gaussian low-q audit TSV is missing repair-contract cells: ",
      paste(out$cell_id[is.na(lowq_idx)], collapse = ", "),
      call. = FALSE
    )
  }
  lowq$evidence_basis[lowq_idx] <- paste(
    "Fisher/Rose/Grace repair contract from",
    output_rel,
    "source decision",
    decision_rel,
    "source synthesis",
    out$source_review_synthesis,
    "source pregrid",
    pregrid_rel,
    "primary blockers:",
    out$primary_blocker_targets
  )
  lowq$inference_signal[lowq_idx] <- paste(
    out$repair_status,
    out$repair_focus,
    paste0("small repair smoke n_rep=", out$smoke_n_rep),
    paste0("seeds=", out$smoke_seed_range),
    "named interval-repair route required before top-up; no interval_status, coverage_status,",
    "inference_ready, supported, top-up, or status-promotion claim"
  )
  lowq$evidence_url[lowq_idx] <- output_rel
  lowq$claim_boundary[lowq_idx] <- out$claim_boundary
  lowq$next_gate[lowq_idx] <- out$next_gate
  lowq$linked_fit_status[lowq_idx] <- "point_fit"
  lowq$linked_interval_status[lowq_idx] <- "planned"
  lowq$linked_coverage_status[lowq_idx] <- "planned"
  lowq$promotion_decision[lowq_idx] <- "do_not_promote"
  write_tsv(lowq, lowq_path)

  selection <- read_tsv(selection_path)
  selection_idx <- match(out$cell_id, selection$cell_id)
  if (anyNA(selection_idx)) {
    stop(
      "Gaussian low-q row-selection TSV is missing repair-contract cells: ",
      paste(out$cell_id[is.na(selection_idx)], collapse = ", "),
      call. = FALSE
    )
  }
  selection$selection_status[selection_idx] <- out$repair_status
  selection$run_mode[
    selection_idx
  ] <- "q2_named_interval_repair_design_first"
  selection$allowed_hosts[selection_idx] <- out$allowed_hosts
  selection$blocked_hosts[selection_idx] <- out$blocked_hosts
  selection$required_preconditions[selection_idx] <- paste(
    "Use",
    output_rel,
    "source decision",
    decision_rel,
    "source synthesis",
    out$source_review_synthesis,
    "source pregrid",
    pregrid_rel,
    "exact smoke seeds",
    out$smoke_seed_range,
    "repair targets",
    out$repair_targets,
    "primary blockers",
    out$primary_blocker_targets,
    "design a named interval-repair route before top-up; support cells remain",
    "point_fit/planned/planned; no-promotion boundary is active."
  )
  selection$first_smoke_n_rep[selection_idx] <- out$smoke_n_rep
  selection$linked_fit_status[selection_idx] <- "point_fit"
  selection$linked_interval_status[selection_idx] <- "planned"
  selection$linked_coverage_status[selection_idx] <- "planned"
  selection$promotion_decision[selection_idx] <- "do_not_promote"
  selection$evidence_url[selection_idx] <- output_rel
  selection$claim_boundary[selection_idx] <- paste(
    "Gaussian low-q row-selection contract only; this promotes exactly no",
    "Q-Series row; selection status is not interval_status, coverage_status,",
    "inference_ready, supported, sigma, q2, q4/q8, non-Gaussian, REML, AI-REML,",
    "bridge support, or public support; repair contract evidence permits only",
    "the declared small repair smoke."
  )
  selection$next_gate[selection_idx] <- out$next_gate
  write_tsv(selection, selection_path)

  closure <- read_tsv(closure_path)
  closure_idx <- match(
    "qseries_closure_gaussian_lowq_gate_required",
    closure$triage_id
  )
  if (is.na(closure_idx)) {
    stop(
      "Closure triage TSV is missing qseries_closure_gaussian_lowq_gate_required.",
      call. = FALSE
    )
  }
  closure$status_meaning[closure_idx] <- paste(
    "Gaussian low-q gate rows include q2 retained-denominator cells with a",
    "Fisher/Rose/Grace repair contract in",
    output_rel,
    "named interval-repair route is required before top-up; support cells remain point_fit/planned/planned",
    "and no row is inference_ready or supported from this contract."
  )
  closure$next_action[closure_idx] <- paste(
    "Design named q2 interval-repair routes under",
    output_rel,
    "then run target-scoped small repair smokes on Totoro or one DRAC host after source/run-root checks pass; use Totoro around",
    "50 workers and <=100 maximum with cleanup; Nibi or Rorqual are eligible",
    "one-host SLURM choices; Trillium requires --allow-trillium=true plus",
    "synced source/run-root and row-specific provenance; continue separate q1 sigma and other",
    "low-q repairs."
  )
  closure$promotion_boundary[closure_idx] <- paste(
    "The q2 repair contract is not interval_status, coverage_status,",
    "inference_ready, supported, q2-slope inheritance, q2-plus inheritance,",
    "q4/q8, non-Gaussian interval, REML, AI-REML, bridge, or public support."
  )
  write_tsv(closure, closure_path)
  message("Synced q2 repair-contract dashboard rows.")
}
