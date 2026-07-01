#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite=true" %in% args

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
dashboard_dir <- file.path(root, "docs/dev-log/dashboard")
artifact_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local"
)

support_path <- file.path(
  dashboard_dir,
  "structured-re-q-series-support-cells.tsv"
)
audit_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-status-audit.tsv"
)
out_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-row-selection.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-row-selection.tsv"
)

if ((file.exists(out_path) || file.exists(artifact_path)) && !overwrite) {
  stop("Output exists; pass --overwrite=true to replace it.", call. = FALSE)
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = ""
  )
}

rel_path <- function(path) {
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", root), "/?"), "", path)
}

support <- read_tsv(support_path)
audit <- read_tsv(audit_path)
rows <- merge(
  audit,
  support,
  by = "cell_id",
  suffixes = c("_audit", "_cell"),
  all.x = TRUE,
  sort = FALSE
)
rows <- rows[rows$widget_state == "gaussian_lowq_gate_required", , drop = FALSE]

if (nrow(rows) != 24L) {
  stop("Expected 24 Gaussian low-q gate rows before exclusions.", call. = FALSE)
}

blocked_mu_slope <- grepl("_q1_mu_one_slope$", rows$cell_id)
rows <- rows[!blocked_mu_slope, , drop = FALSE]
if (nrow(rows) != 20L) {
  stop("Expected 20 Gaussian low-q point/fixture rows.", call. = FALSE)
}

classify_row <- function(cell_id) {
  if (grepl("_q1_mu_intercept$", cell_id)) {
    return("first_smoke_candidate_location_intercept")
  }
  if (grepl("_q1_sigma_intercept$", cell_id)) {
    return("scale_interval_design_hold")
  }
  if (grepl("_q1_mu_sigma_", cell_id)) {
    return("matched_mu_sigma_design_hold")
  }
  if (
    grepl("_q2_mu1_mu2_intercept$", cell_id) ||
      grepl("_q2_plus_q2_intercept$", cell_id)
  ) {
    return("q2_intercept_contract_hold")
  }
  if (
    cell_id %in%
      c(
        "qseries_phylo_interaction_q1_mu",
        "qseries_phylo_direct_sd_univariate"
      )
  ) {
    return("special_target_contract_hold")
  }
  stop("Unhandled Gaussian low-q row: ", cell_id, call. = FALSE)
}

row_selection_class <- vapply(rows$cell_id, classify_row, character(1L))

selection_status <- ifelse(
  row_selection_class == "first_smoke_candidate_location_intercept",
  "ready_for_local_dry_run",
  ifelse(
    row_selection_class == "scale_interval_design_hold",
    "local_smoke_completed_review_pending",
    "hold_until_row_contract"
  )
)
run_mode <- ifelse(
  row_selection_class == "first_smoke_candidate_location_intercept",
  "local_dry_run_then_totoro_fiia_smoke",
  ifelse(
    row_selection_class == "scale_interval_design_hold",
    "fisher_gauss_rose_review_before_host_escalation",
    "no_compute_until_contract"
  )
)
allowed_hosts <- ifelse(
  row_selection_class == "first_smoke_candidate_location_intercept",
  "local for n=2 dry-run; Totoro/FIIA for n=5 smoke after Fisher/Rose contract review",
  ifelse(
    row_selection_class == "scale_interval_design_hold",
    "local n=5 route smoke after Fisher/Gauss contract; Totoro/FIIA only after local pass and review",
    "local design and fixture review only"
  )
)
blocked_hosts <- ifelse(
  row_selection_class == "first_smoke_candidate_location_intercept",
  "Nibi/Rorqual/DRAC before local dry-run, Totoro/FIIA smoke, and Fisher/Rose sign-off",
  ifelse(
    row_selection_class == "scale_interval_design_hold",
    "Totoro/FIIA before local sigma smoke pass; Nibi/Rorqual/DRAC before Fisher/Gauss/Rose review and retained-denominator design",
    "Totoro/FIIA/Nibi/Rorqual/DRAC until the row-specific contract is accepted"
  )
)
first_smoke_n_rep <- ifelse(
  row_selection_class %in%
    c("first_smoke_candidate_location_intercept", "scale_interval_design_hold"),
  "5",
  "0"
)

required_preconditions <- character(nrow(rows))
next_gate <- character(nrow(rows))
for (i in seq_len(nrow(rows))) {
  klass <- row_selection_class[[i]]
  required_preconditions[[i]] <- switch(
    klass,
    first_smoke_candidate_location_intercept = paste(
      "Freeze q1 mu-intercept interval channel, denominator, finite-interval rule,",
      "one-sided miss table, and non-claims before any smoke."
    ),
    scale_interval_design_hold = paste(
      "Use structured-re-gaussian-lowq-sigma-intercept-route-contract.tsv;",
      "raw log-SD Wald is the candidate first channel, endpoint profile is",
      "diagnostic only, and the location-axis bias+t correction is forbidden."
    ),
    matched_mu_sigma_design_hold = paste(
      "Split mu and sigma targets first; do not bundle location and scale",
      "claims in one smoke."
    ),
    q2_intercept_contract_hold = paste(
      "Separate endpoint SD targets from covariance/correlation targets before",
      "any q2 interval smoke."
    ),
    special_target_contract_hold = paste(
      "Resolve direct-SD versus derived-correlation or phylo_interaction syntax",
      "contract before runtime work."
    )
  )
  next_gate[[i]] <- switch(
    klass,
    first_smoke_candidate_location_intercept = paste(
      "Run local n=2 dry-run; if finite intervals and denominator retention pass,",
      "run Totoro/FIIA n=5 smoke; DRAC remains blocked until smoke passes and",
      "Fisher/Rose sign off."
    ),
    scale_interval_design_hold = paste(
      "Write/run a local n=5 direct sigma-SD smoke with small_sample_df=none",
      "and bias_correct=none, retain all attempted rows, boundary rows, profile",
      "failures, one-sided misses, and warnings, then require Fisher/Gauss/Rose",
      "review before Totoro/FIIA, Nibi/Rorqual, denominator, or status work."
    ),
    matched_mu_sigma_design_hold = paste(
      "Choose a single endpoint target and denominator first; matched mu+sigma",
      "does not inherit q1 mu or sigma evidence."
    ),
    q2_intercept_contract_hold = paste(
      if (grepl("_q2_plus_q2_intercept$", rows$cell_id[[i]])) {
        paste(
          "Write q2-plus-q2 row-specific contract before smoke;",
          "Totoro/FIIA/Nibi/Rorqual/DRAC remain blocked."
        )
      } else {
        paste(
          "Use row-specific contract",
          "structured-re-q2-intercept-interval-contract.tsv; run local",
          "deterministic q2 intercept smoke only after Fisher/Rose review;",
          "Totoro/FIIA are smoke-only and Nibi/Rorqual/DRAC remain blocked."
        )
      }
    ),
    special_target_contract_hold = paste(
      "Write special target contract before row-specific smoke or status edit."
    )
  )
}

provider <- rows$structure_provider
provider[provider == ""] <- "ordinary"

summary <- data.frame(
  selection_id = paste0("gaussian_lowq_row_selection_", rows$cell_id),
  cell_id = rows$cell_id,
  structure_provider = provider,
  dimension_pattern = rows$dimension_pattern,
  endpoint_set = rows$endpoint_set,
  slope_class = rows$slope_class,
  formula_cell = rows$formula_cell,
  row_selection_class = row_selection_class,
  selection_status = selection_status,
  run_mode = run_mode,
  allowed_hosts = allowed_hosts,
  blocked_hosts = blocked_hosts,
  required_preconditions = required_preconditions,
  first_smoke_n_rep = first_smoke_n_rep,
  linked_fit_status = rows$linked_fit_status,
  linked_interval_status = rows$linked_interval_status,
  linked_coverage_status = rows$linked_coverage_status,
  promotion_decision = "do_not_promote",
  evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-row-selection.md",
  artifact_dir = rel_path(artifact_dir),
  claim_boundary = paste(
    "Gaussian low-q row-selection contract only; this promotes exactly no Q-Series row;",
    "selection status is not interval_status, coverage_status, inference_ready, supported,",
    "sigma, q2, q4/q8, non-Gaussian, REML, AI-REML, bridge support, or public support."
  ),
  next_gate = next_gate,
  stringsAsFactors = FALSE
)

mu_intercept_rows <- summary$row_selection_class ==
  "first_smoke_candidate_location_intercept"
q2_intercept_rows <- grepl("_q2_mu1_mu2_intercept$", summary$cell_id)
q2_plus_rows <- summary$cell_id == "qseries_phylo_q2_plus_q2_intercept"
mu_sigma_intercept_rows <- grepl(
  "_q1_mu_sigma_intercept$",
  summary$cell_id
)
mu_sigma_intercept_diagnostic_rows <- mu_sigma_intercept_rows &
  summary$structure_provider == "phylo"
mu_sigma_intercept_n5_blocked_rows <- mu_sigma_intercept_rows &
  summary$structure_provider %in% c("spatial", "animal", "relmat")
mu_sigma_one_slope_rows <- grepl(
  "_q1_mu_sigma_one_slope$",
  summary$cell_id
)
mu_sigma_one_slope_phylo_rows <- mu_sigma_one_slope_rows &
  summary$structure_provider == "phylo"
mu_sigma_one_slope_spatial_rows <- mu_sigma_one_slope_rows &
  summary$structure_provider == "spatial"
mu_sigma_one_slope_animal_rows <- mu_sigma_one_slope_rows &
  summary$structure_provider == "animal"
mu_sigma_one_slope_relmat_rows <- mu_sigma_one_slope_rows &
  summary$structure_provider == "relmat"

summary$selection_status[mu_intercept_rows] <-
  "animal_mu_boundary_profile_hard_seed_blocked"
summary$run_mode[mu_intercept_rows] <-
  "boundary_profile_blocker_no_topup"
summary$allowed_hosts[mu_intercept_rows] <-
  "Local artifact review only for structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.tsv; Totoro, Nibi, Rorqual, Trillium, and DRAC top-up are blocked until Fisher/Gauss/Rose accept a new animal q1 mu interval route."
summary$blocked_hosts[mu_intercept_rows] <-
  "Do not top up on Totoro, Nibi, Rorqual, Trillium, or DRAC: SR475 retained-denominator evidence has hard seeds 812407 and 812444 with wald_at_boundary, endpoint profile, tmbprofile 0/2 finite, boundary/profile blockers, and upper misses requiring a new animal q1 mu interval route before any mixed-host denominator or status work."
summary$required_preconditions[mu_intercept_rows] <- paste(
  "Use structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.tsv;",
  "SR475 retained-denominator evidence isolates hard seeds 812407 and 812444;",
  "the current route retains wald_at_boundary, endpoint profile diagnostics,",
  "tmbprofile 0/2 finite signal, boundary/profile blockers, and upper misses.",
  "Support cells stay point_fit/planned/planned and this is not interval or",
  "coverage evidence."
)
summary$next_gate[mu_intercept_rows] <- paste(
  "Do not top up this animal q1 mu route. Fisher/Gauss/Rose must design and",
  "review a new animal q1 mu interval route that explains the boundary/profile",
  "blocker, endpoint profile behaviour, tmbprofile 0/2 finite signal, hard",
  "seeds 812407 and 812444, wald_at_boundary rows, upper misses, and",
  "mixed-host denominator rules before any Totoro, Nibi, Rorqual, Trillium,",
  "DRAC, TSV promotion, inference_ready, supported, or public-support claim."
)
summary$evidence_url[mu_intercept_rows] <- paste0(
  "docs/dev-log/dashboard/",
  "structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.tsv"
)
summary$claim_boundary[mu_intercept_rows] <- paste(
  "Gaussian low-q row-selection contract only; this promotes exactly no",
  "Q-Series row. The animal q1 mu boundary/profile hard-seed blocker keeps the",
  "support cell point_fit/planned/planned with no interval_status or",
  "coverage_status promotion. It is not inference_ready, supported, q1 sigma,",
  "matched mu+sigma, q2, q4/q8, non-Gaussian interval evidence, REML,",
  "AI-REML, bridge support, mixed-host denominator evidence, or public support."
)

summary$selection_status[mu_sigma_intercept_diagnostic_rows] <-
  "mu_sigma_smoke_diagnostic_blocked"
summary$run_mode[mu_sigma_intercept_diagnostic_rows] <-
  "fisher_noether_rose_boundary_correlation_review"
summary$selection_status[mu_sigma_intercept_n5_blocked_rows] <-
  "mu_sigma_n5_correlation_boundary_blocked"
summary$run_mode[mu_sigma_intercept_n5_blocked_rows] <-
  "boundary_correlation_blocker_no_topup"
summary$allowed_hosts[mu_sigma_intercept_rows] <-
  "local only for completed n=1 and n=5 target smoke review; no Totoro/FIIA, Nibi/Rorqual, Trillium, or DRAC top-up from the current matched mu+sigma Wald route"
summary$blocked_hosts[mu_sigma_intercept_rows] <-
  "Totoro/FIIA, Nibi/Rorqual, Trillium, or DRAC before a replacement correlation interval route or explicit target-split design; any mixed-host denominator; any status promotion"
summary$required_preconditions[mu_sigma_intercept_rows] <- paste(
  "Use structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv;",
  "local n=1 target smoke completed for direct sd_mu, direct sd_sigma,",
  "and mu-sigma correlation targets; phylo nonusable boundary/correlation",
  "interval stays diagnostic-blocked; spatial/animal/relmat n=5 local",
  "denominator smoke is recorded in",
  "2026-06-30-gaussian-lowq-mu-sigma-intercept-n5-local and blocks top-up",
  "because the mu-sigma correlation target is boundary/nonfinite while direct",
  "sd_mu and direct sd_sigma are target-split diagnostics; support cells stay",
  "point_fit/planned/planned;",
  "matched mu+sigma does not inherit q1 mu, q1 sigma, q2, q4/q8,",
  "or non-Gaussian evidence."
)
summary$next_gate[mu_sigma_intercept_diagnostic_rows] <- paste(
  "Review structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv;",
  "n=1 is local target smoke only, not coverage; Fisher/Noether/Rose must",
  "classify the phylo nonusable boundary/correlation blocker and retain it",
  "with target-specific denominator rules before any Totoro/FIIA replicated",
  "smoke; Nibi/Rorqual/DRAC remain blocked before denominator work and no",
  "status promotion is allowed."
)
summary$next_gate[mu_sigma_intercept_n5_blocked_rows] <- paste(
  "Use the local n=5 matched mu+sigma denominator smoke in",
  "docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-sigma-intercept-n5-local;",
  "this n=5 blocker is not coverage and no status promotion is allowed;",
  "spatial has finite interval rate 0.5333 with pdHess 12/15 and correlation",
  "usable 0/5, while animal and relmat have finite interval rate 0.8000 with",
  "correlation usable 2/5; Fisher/Noether/Rose must design a replacement",
  "correlation interval route or target-split decision before any Totoro/FIIA,",
  "Nibi/Rorqual, Trillium, DRAC, coverage, TSV promotion, inference_ready,",
  "or supported claim."
)
summary$first_smoke_n_rep[mu_sigma_intercept_rows] <- "1"
summary$evidence_url[mu_sigma_intercept_rows] <- paste0(
  "docs/dev-log/dashboard/",
  "structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv"
)
summary$first_smoke_n_rep[mu_sigma_intercept_n5_blocked_rows] <- "5"
summary$evidence_url[mu_sigma_intercept_n5_blocked_rows] <- paste0(
  "docs/dev-log/simulation-artifacts/",
  "2026-06-30-gaussian-lowq-mu-sigma-intercept-n5-local/",
  "structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv"
)

summary$selection_status[mu_sigma_one_slope_phylo_rows] <-
  "mu_sigma_slope_mixed_interval_review_pending"
summary$run_mode[mu_sigma_one_slope_phylo_rows] <-
  "fisher_noether_rose_mixed_target_review"
summary$selection_status[mu_sigma_one_slope_spatial_rows] <-
  "mu_sigma_slope_spatial_boundary_blocked"
summary$run_mode[mu_sigma_one_slope_spatial_rows] <-
  "fisher_gauss_rose_spatial_boundary_review"
summary$selection_status[mu_sigma_one_slope_animal_rows] <-
  "mu_sigma_slope_bootstrap_boundary_blocked"
summary$run_mode[mu_sigma_one_slope_animal_rows] <-
  "fisher_noether_rose_bootstrap_boundary_review"
summary$selection_status[mu_sigma_one_slope_relmat_rows] <-
  "mu_sigma_slope_profile_failure_review_pending"
summary$run_mode[mu_sigma_one_slope_relmat_rows] <-
  "fisher_noether_rose_profile_failure_review"
summary$allowed_hosts[mu_sigma_one_slope_rows] <-
  "local only for existing readiness and diagnostic sidecar review; no Totoro/FIIA/Nibi/Rorqual/DRAC compute until Fisher/Noether/Rose accept target-specific denominators"
summary$blocked_hosts[mu_sigma_one_slope_rows] <- paste(
  "Totoro/FIIA/Nibi/Rorqual/DRAC blocked before Fisher/Noether/Rose review,",
  "target-specific denominator, and replicated smoke design"
)
summary$required_preconditions[mu_sigma_one_slope_rows] <- paste(
  "Use structured-re-mu-sigma-slope-readiness.tsv,",
  "structured-re-mu-sigma-slope-interval-diagnostic-status.tsv, and",
  "structured-re-mu-sigma-slope-interval-stability-probe.tsv; existing",
  "diagnostic-only evidence covers point/fixture readiness and finite/nonfinite",
  "interval shapes; the target set remains direct sd_mu, direct sd_sigma, and",
  "mu-sigma correlation components; phylo is mixed finite/bootstrap-boundary,",
  "spatial has a strong-probe spatial boundary/nonfinite blocker, animal is all",
  "diagnostic bootstrap-boundary, and relmat has a profile-failure review",
  "target; support cells stay point_fit/planned/planned; matched mu+sigma",
  "one-slope does not inherit q1 mu, q1 sigma, q2, q4/q8, non-Gaussian, REML,",
  "AI-REML, or public-support evidence."
)
summary$next_gate[mu_sigma_one_slope_phylo_rows] <- paste(
  "Fisher/Noether/Rose must split direct sd_mu, direct sd_sigma, and",
  "mu-sigma correlation targets, retain the mixed finite/bootstrap-boundary",
  "diagnostic rows, choose the interval channel and denominator, and decide",
  "whether a local n=1/n=5 replicated smoke is worth running before any",
  "Totoro/FIIA, Nibi/Rorqual/DRAC, coverage, TSV promotion, inference_ready,",
  "or supported claim."
)
summary$next_gate[mu_sigma_one_slope_spatial_rows] <- paste(
  "Fisher/Gauss/Rose must diagnose the fixed-covariance spatial",
  "boundary/profile failures and strong-probe spatial boundary/nonfinite",
  "targets before any replicated smoke; do not spend Totoro/FIIA,",
  "Nibi/Rorqual/DRAC, coverage, TSV promotion, inference_ready, or supported",
  "claim on this row."
)
summary$next_gate[mu_sigma_one_slope_animal_rows] <- paste(
  "Fisher/Noether/Rose must diagnose why all four local diagnostic targets are",
  "bootstrap-only finite boundary rows before any replicated smoke; do not",
  "spend Totoro/FIIA, Nibi/Rorqual/DRAC, coverage, TSV promotion,",
  "inference_ready, or supported claim on this row."
)
summary$next_gate[mu_sigma_one_slope_relmat_rows] <- paste(
  "Fisher/Noether/Rose must split the relmat finite, bootstrap-boundary, and",
  "profile-failure targets before choosing any interval channel or denominator;",
  "do not spend Totoro/FIIA, Nibi/Rorqual/DRAC, coverage, TSV promotion,",
  "inference_ready, or supported claim on this row."
)
summary$first_smoke_n_rep[mu_sigma_one_slope_rows] <- "0"
summary$evidence_url[mu_sigma_one_slope_rows] <- paste0(
  "docs/dev-log/dashboard/",
  "structured-re-mu-sigma-slope-interval-diagnostic-status.tsv"
)

summary$selection_status[q2_intercept_rows] <-
  "q2_retained_denominator_design_ready_no_promotion"
summary$selection_status[q2_plus_rows] <-
  "q2_retained_denominator_design_ready_with_profile_blocker"
summary$run_mode[q2_intercept_rows] <-
  "nibi_retained_denominator_pregrid_ready"
summary$run_mode[q2_plus_rows] <-
  "q2_plus_sr150_pregrid_ready_except_sigma_correlation_profile_repair"
summary$first_smoke_n_rep[q2_intercept_rows] <- "32"
summary$first_smoke_n_rep[q2_plus_rows] <- "16"
summary$allowed_hosts[q2_intercept_rows | q2_plus_rows] <-
  "Nibi primary for SR150 retained-denominator pregrid only under structured-re-q2-retained-denominator-design.tsv; Rorqual is confirmation or overflow under the same seed manifest; Totoro/FIIA remain optional smoke-only hosts if access is restored"
summary$blocked_hosts[q2_intercept_rows] <-
  "Any Nibi/Rorqual/DRAC denominator work that omits structured-re-q2-retained-denominator-design.tsv, mixes hosts without a new seed manifest, or bundles q2 slopes, q2-plus-q2 failed targets, q1, q4/q8, non-Gaussian, REML, AI-REML, bridge support, public support, or supported claims"
summary$blocked_hosts[q2_plus_rows] <- paste(
  "Any Nibi/Rorqual/DRAC denominator work that omits",
  "structured-re-q2-retained-denominator-design.tsv; the q2-plus-q2",
  "sigma1/sigma2 correlation profile-failure target requires repair before",
  "pregrid, cross-block correlations remain blocked, and q2-only location,",
  "q4/q8, non-Gaussian, REML, AI-REML, bridge support, public support,",
  "inference_ready, supported, and status promotion claims remain blocked"
)
summary$required_preconditions[q2_intercept_rows] <- paste(
  "Use structured-re-q2-intercept-interval-contract.tsv; local deterministic",
  "q2 intercept smoke passed for all 12 direct-SD/correlation targets;",
  "Fisher/Rose signed off next smoke; endpoint SD and correlation targets",
  "remain separate; structured-re-q-series-smoke-substitution-contract.tsv",
  "smoke-substitution contract allowed the Nibi substitute-host n=5",
  "q2 intercept smoke imported here;",
  "Fisher/Rose reviewed the substitute-host artifact;",
  "structured-re-q2-retained-denominator-design.tsv now names interval",
  "channel, retained denominator, MCSE target, one-sided misses, artifacts,",
  "hosts, stop rules, and no-promotion boundaries."
)
summary$required_preconditions[q2_plus_rows] <- paste(
  "Use structured-re-q2-plus-q2-intercept-contract.tsv; same-target fixture",
  "parity is covered; local deterministic q2-plus-q2 smoke passed for six",
  "within-block targets; Fisher/Rose signed off next smoke; cross-block",
  "correlations remain blocked; structured-re-q-series-smoke-substitution-contract.tsv",
  "smoke-substitution contract allowed the Nibi substitute-host n=5",
  "q2-plus-q2 smoke imported here;",
  "Fisher/Rose reviewed the substitute-host artifact;",
  "structured-re-q2-retained-denominator-design.tsv now names interval",
  "channel, retained denominator, MCSE target, one-sided misses, artifacts,",
  "hosts, stop rules, and no-promotion boundaries while retaining the",
  "sigma1/sigma2 correlation profile-failure blocker."
)
summary$next_gate[q2_intercept_rows] <- paste(
  "Run only the q2 intercept target rows marked sr150_pregrid_ready_no_promotion",
  "in structured-re-q2-retained-denominator-design.tsv; retain all attempted",
  "rows, keep bootstrap accounting explicit, endpoint SD and correlation",
  "targets separate, report one-sided misses and MCSE <= 0.01 as a top-up",
  "target, and make no status promotion before Fisher/Rose/Grace review."
)
summary$next_gate[q2_plus_rows] <- paste(
  "Run only q2-plus-q2 target rows marked sr150_pregrid_ready_no_promotion in",
  "structured-re-q2-retained-denominator-design.tsv; repair or explain the",
  "sigma1/sigma2 correlation profile-failure blocker before any pregrid for",
  "that target; cross-block correlations stay blocked, sigma-side targets do",
  "not inherit the location-axis bias+t default, and no status promotion is",
  "allowed before Fisher/Rose/Grace review."
)
summary$evidence_url[q2_intercept_rows | q2_plus_rows] <-
  "docs/dev-log/dashboard/structured-re-q2-retained-denominator-design.tsv"

sigma_intercept_rows <- summary$row_selection_class ==
  "scale_interval_design_hold"
sigma_intercept_diagnostic_rows <- sigma_intercept_rows &
  summary$structure_provider %in% c("phylo", "spatial")
sigma_intercept_route_rows <- sigma_intercept_rows &
  summary$structure_provider %in% c("animal", "relmat")
direct_sd_special_rows <- summary$cell_id ==
  "qseries_phylo_direct_sd_univariate"
phylo_interaction_special_rows <-
  summary$cell_id == "qseries_phylo_interaction_q1_mu"
summary$selection_status[sigma_intercept_diagnostic_rows] <-
  "sigma_smoke_diagnostic_blocked"
summary$selection_status[sigma_intercept_route_rows] <-
  "sigma_profile_channel_upper_tail_blocked"
summary$run_mode[sigma_intercept_diagnostic_rows] <-
  "fisher_gauss_rose_boundary_profile_review"
summary$run_mode[sigma_intercept_route_rows] <-
  "profile_channel_blocker_no_topup"
summary$allowed_hosts[sigma_intercept_diagnostic_rows] <-
  "local only for completed n=5 smoke review; Totoro/FIIA only after Fisher/Gauss/Rose accept the retained local smoke and provider-specific blocker ledger"
summary$allowed_hosts[sigma_intercept_route_rows] <- paste(
  "Local review only against structured-re-gaussian-lowq-sigma-profile-route-review.tsv;",
  "host escalation to Totoro/DRAC, Nibi/Rorqual, and SR1000 top-up is",
  "blocked until Fisher/Gauss/Rose accept a new q1 sigma interval route."
)
summary$blocked_hosts[sigma_intercept_diagnostic_rows] <-
  "Totoro/FIIA before Fisher/Gauss/Rose review of boundary/profile/warning ledgers; Nibi/Rorqual/DRAC before retained-denominator design"
summary$blocked_hosts[sigma_intercept_route_rows] <- paste(
  "Do not top up on Totoro/DRAC, Nibi/Rorqual, SR475, or SR1000: the profile",
  "channel review reports endpoint budget 48, endpoint zero-boundary,",
  "tmbprofile 0/5 finite, and upper-tail miss imbalance under the current",
  "q1 sigma route."
)
summary$required_preconditions[sigma_intercept_diagnostic_rows] <- paste(
  "Use structured-re-gaussian-lowq-sigma-intercept-route-contract.tsv;",
  "local n=5 direct sigma-SD smoke completed with raw log-SD Wald,",
  "small_sample_df=none, and bias_correct=none; endpoint profile diagnostics,",
  "boundary rows, profile failures, one-sided misses, and warnings are",
  "retained; support cells stay point_fit/planned/planned."
)
summary$required_preconditions[sigma_intercept_route_rows] <- paste(
  "Use structured-re-gaussian-lowq-sigma-profile-route-review.tsv and",
  "structured-re-gaussian-lowq-sigma-intercept-route-contract.tsv; the",
  "profile-channel review retains endpoint budget 48, endpoint zero-boundary,",
  "tmbprofile 0/5 finite, upper-tail miss imbalance, and SR1000/top-up",
  "blockers. Support cells stay point_fit/planned/planned."
)
summary$next_gate[sigma_intercept_diagnostic_rows] <- paste(
  "Review structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv;",
  "phylo has one wald_at_boundary row, spatial has three wald_at_boundary rows,",
  "endpoint-profile warnings are retained, and phylo/spatial remain",
  "diagnostic-blocked while animal/relmat have a separate SR150 route blocker;",
  "keep this as no-promotion evidence until Fisher/Gauss/Rose accept a retained",
  "denominator plan, one-sided miss policy, warning policy, and host-escalation",
  "rule."
)
summary$next_gate[sigma_intercept_route_rows] <- paste(
  "Do not top up this q1 sigma profile channel. Fisher/Gauss/Rose must design",
  "a new q1 sigma interval route that explains endpoint budget 48, endpoint",
  "zero-boundary, tmbprofile 0/5 finite, upper-tail miss imbalance, SR1000",
  "eligibility, denominator rules, and warning policy before any Totoro/DRAC,",
  "Nibi/Rorqual, TSV promotion, inference_ready, supported, or public-support",
  "claim."
)
summary$evidence_url[sigma_intercept_diagnostic_rows] <- paste0(
  "docs/dev-log/dashboard/",
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv"
)
summary$evidence_url[sigma_intercept_route_rows] <- paste0(
  "docs/dev-log/dashboard/",
  "structured-re-gaussian-lowq-sigma-profile-route-review.tsv"
)
summary$claim_boundary[sigma_intercept_route_rows] <- paste(
  "Gaussian low-q row-selection contract only; this promotes exactly no",
  "Q-Series row. The animal/relmat q1 sigma profile-channel review is",
  "diagnostic only and a hard negative for the current interval route, not",
  "evidence that the animal or relmat model cells are unsupported. Support",
  "cells remain point_fit/planned/planned; selection status is not",
  "interval_status, coverage_status, inference_ready, supported,",
  "denominator-pass, q1 mu, matched mu+sigma, q2, q4/q8, non-Gaussian, REML,",
  "AI-REML, bridge support, or public support."
)

summary$selection_status[direct_sd_special_rows] <-
  "direct_sd_local_smoke_target_split_review_pending"
summary$run_mode[direct_sd_special_rows] <-
  "fisher_noether_rose_direct_sd_target_split_review"
summary$first_smoke_n_rep[direct_sd_special_rows] <- 1L
summary$allowed_hosts[direct_sd_special_rows] <-
  "local n=1 target-split smoke completed; no Totoro/FIIA/Nibi/Rorqual/DRAC compute until Fisher/Noether/Rose accept the retained direct-SD target split"
summary$blocked_hosts[direct_sd_special_rows] <-
  "Totoro/FIIA/Nibi/Rorqual/DRAC blocked before direct-SD target-split review, retained denominator, one-sided miss policy, and no-promotion smoke design"
summary$required_preconditions[direct_sd_special_rows] <- paste(
  "Use structured-re-gaussian-lowq-direct-sd-univariate-smoke.tsv,",
  "structured-re-gaussian-lowq-special-target-contract.tsv and",
  "phylo-profile-loglik-status.tsv; direct SD profile targets are",
  "interval_feasible; local n=1 smoke retained a clean mu-axis direct SD",
  "target and a sigma-axis boundary/profile-budget blocker; derived",
  "correlation targets remain separate, coverage remains planned, and",
  "support cell stays",
  "point_fit/interval_feasible/planned."
)
summary$next_gate[direct_sd_special_rows] <- paste(
  "Fisher/Noether/Rose must review the retained target split: mu-axis direct",
  "SD passed the local smoke, sigma-axis direct SD is boundary/profile-budget",
  "blocked; choose the direct SD interval channel, retained denominator,",
  "one-sided miss ledger, and derived-correlation exclusion before any",
  "Totoro/FIIA/Nibi/Rorqual/DRAC compute, no status promotion, TSV promotion,",
  "inference_ready, or supported claim."
)
summary$evidence_url[direct_sd_special_rows] <- paste0(
  "docs/dev-log/dashboard/",
  "structured-re-gaussian-lowq-direct-sd-univariate-smoke.tsv"
)

summary$selection_status[phylo_interaction_special_rows] <-
  "phylo_interaction_provider_boundary_no_interval_route"
summary$run_mode[phylo_interaction_special_rows] <-
  "no_compute_provider_boundary_hold"
summary$allowed_hosts[phylo_interaction_special_rows] <-
  "local provider-boundary design only; no Totoro/FIIA/Nibi/Rorqual/DRAC compute until a row-specific q1 pair-field interval route is written and reviewed"
summary$blocked_hosts[phylo_interaction_special_rows] <-
  "Totoro/FIIA/Nibi/Rorqual/DRAC blocked because bridge unsupported and no shared phylo or row-specific interval route is banked for the phylo_interaction q1 pair-level field"
summary$required_preconditions[phylo_interaction_special_rows] <- paste(
  "Use structured-re-gaussian-lowq-special-target-contract.tsv and",
  "tests/testthat/test-structured-effects.R; phylo_interaction is a q1",
  "pair-level field, not ordinary q1, not phylo(1 | species), and not a q2 or",
  "q4 endpoint covariance family; it pairs two clades and has no single",
  "structured group count; bridge unsupported, no shared phylo or row-specific",
  "interval route is banked, coverage remains planned, and support cell stays",
  "point_fit/planned/planned."
)
summary$next_gate[phylo_interaction_special_rows] <- paste(
  "Only reopen interval work by writing a Boole/Fisher/Rose-reviewed",
  "row-specific Gaussian q1 phylo_interaction interval design that names the",
  "target, denominator, one-sided misses, bridge exclusion, and blocked",
  "neighbours; until then keep smoke, host escalation, q2 and q4 endpoint",
  "covariance, non-Gaussian, REML, AI-REML, public support, TSV promotion,",
  "inference_ready, and supported claims blocked."
)
summary$evidence_url[phylo_interaction_special_rows] <- paste0(
  "docs/dev-log/dashboard/",
  "structured-re-gaussian-lowq-special-target-contract.tsv"
)

summary <- summary[order(summary$row_selection_class, summary$cell_id), ]
row.names(summary) <- NULL

write_tsv(summary, out_path)
write_tsv(summary, artifact_path)

message(
  "Wrote ",
  nrow(summary),
  " Gaussian low-q row-selection rows to ",
  rel_path(out_path)
)
