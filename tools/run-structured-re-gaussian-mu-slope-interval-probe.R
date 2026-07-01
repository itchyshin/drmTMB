#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-gaussian-mu-slope-interval-probe-local"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

admission_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-mu-slope-admission-audit.tsv"
)
pregrid_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-dry-run.tsv"
)
probe_results_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-interval-probe-results.tsv"
)
probe_summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-interval-probe-summary.tsv"
)
seed_manifest_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-interval-probe-seed-manifest.tsv"
)
pregrid_seed_manifest_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-pregrid-seed-manifest.tsv"
)
pregrid_cell_manifest_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-pregrid-cell-manifest.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-interval-probe-run-log.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

source_local <- function(path) {
  source(file.path(repo_root, path), local = .GlobalEnv)
}

suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))
for (path in c(
  "inst/sim/R/sim_registry.R",
  "inst/sim/R/sim_utils.R",
  "inst/sim/R/sim_runner.R",
  "inst/sim/R/sim_aggregate.R",
  "inst/sim/R/sim_uncertainty.R",
  "inst/sim/dgp/sim_dgp_phylo_mu_slope.R",
  "inst/sim/fit/sim_summarise_phylo_mu_slope.R",
  "inst/sim/run/sim_run_phylo_mu_slope_smoke.R",
  "inst/sim/dgp/sim_dgp_spatial_mu_slope.R",
  "inst/sim/fit/sim_summarise_spatial_mu_slope.R",
  "inst/sim/run/sim_run_spatial_mu_slope_smoke.R",
  "inst/sim/dgp/sim_dgp_animal_mu_slope.R",
  "inst/sim/fit/sim_summarise_animal_mu_slope.R",
  "inst/sim/run/sim_run_animal_mu_slope_smoke.R",
  "inst/sim/dgp/sim_dgp_relmat_mu_slope.R",
  "inst/sim/fit/sim_summarise_relmat_mu_slope.R",
  "inst/sim/run/sim_run_relmat_mu_slope_smoke.R"
)) {
  source_local(path)
}

provider_specs <- list(
  phylo = list(
    cell_id = "qseries_phylo_q1_mu_one_slope",
    formula_cell = "phylo(1 + x | species, tree = tree) in mu",
    source_task = "phylo_mu_slope",
    condition = phase18_phylo_mu_slope_conditions(
      n_tip = 8L,
      n_each = 7L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_phylo_mu_slope_cell,
    fit = phase18_fit_phylo_mu_slope,
    provider_prefix = "phylo",
    provider_boundary = ""
  ),
  spatial = list(
    cell_id = "qseries_spatial_q1_mu_one_slope",
    formula_cell = "spatial(1 + x | site, coords = coords) in mu",
    source_task = "spatial_mu_slope",
    condition = phase18_spatial_mu_slope_conditions(
      n_site = 12L,
      n_each = 8L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_spatial_mu_slope_cell,
    fit = phase18_fit_spatial_mu_slope,
    provider_prefix = "fixed-covariance spatial",
    provider_boundary = " no range-estimating spatial support,"
  ),
  animal = list(
    cell_id = "qseries_animal_q1_mu_one_slope",
    formula_cell = "animal(1 + x | id, A = A) in mu",
    source_task = "animal_mu_slope",
    condition = phase18_animal_mu_slope_conditions(
      n_id = 8L,
      n_each = 7L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_animal_mu_slope_cell,
    fit = phase18_fit_animal_mu_slope,
    provider_prefix = "animal A-matrix",
    provider_boundary = " no pedigree/Ainv bridge marshalling,"
  ),
  relmat = list(
    cell_id = "qseries_relmat_q1_mu_one_slope",
    formula_cell = "relmat(1 + x | id, K = K) in mu",
    source_task = "relmat_mu_slope",
    condition = phase18_relmat_mu_slope_conditions(
      n_id = 8L,
      n_each = 7L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_relmat_mu_slope_cell,
    fit = phase18_fit_relmat_mu_slope,
    provider_prefix = "relmat K-matrix",
    provider_boundary = " no Q bridge marshalling,"
  )
)

n_probe_replicates <- 2L
provider_names <- names(provider_specs)
seed_manifest <- do.call(rbind, lapply(seq_along(provider_names), function(i) {
  provider <- provider_names[[i]]
  data.frame(
    probe_cell_id = sprintf(
      "gaussian_mu_slope_interval_probe_%s_rep%03d",
      provider,
      seq_len(n_probe_replicates)
    ),
    provider = provider,
    replicate = seq_len(n_probe_replicates),
    seed = 790000L + i * 100L + seq_len(n_probe_replicates),
    seed_role = "gaussian_mu_slope_interval_probe",
    source_task = provider_specs[[provider]]$source_task,
    execution_status = "planned",
    stringsAsFactors = FALSE
  )
}))

endpoint_member_from_parm <- function(parm) {
  if (grepl("\\(1 \\|", parm, fixed = FALSE)) {
    return("mu:(Intercept)")
  }
  if (grepl("\\(0 \\+ x \\|", parm, fixed = FALSE)) {
    return("mu:x")
  }
  "unknown"
}

direct_sd_target_from_endpoint <- function(endpoint_member) {
  switch(
    endpoint_member,
    "mu:(Intercept)" = "sd_mu_intercept",
    "mu:x" = "sd_mu_x",
    "sd_mu_unknown"
  )
}

target_token <- function(endpoint_member) {
  switch(
    endpoint_member,
    "mu:(Intercept)" = "mu_intercept",
    "mu:x" = "mu_x",
    "mu_unknown"
  )
}

probe_one <- function(provider, spec, replicate, seed) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  dat <- withCallingHandlers(
    spec$dgp(
      spec$condition,
      seed = seed,
      cell_id = sprintf("gaussian_mu_slope_interval_probe_%s", provider),
      replicate = replicate
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  fit <- withCallingHandlers(
    spec$fit(dat, spec$condition),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  ci <- withCallingHandlers(
    tryCatch(confint(fit), error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  if (inherits(ci, "error")) {
    return(data.frame(
      probe_id = sprintf("gaussian_mu_slope_interval_probe_%s_rep%03d", provider, replicate),
      cell_id = spec$cell_id,
      provider = provider,
      source_task = spec$source_task,
      replicate = replicate,
      seed = seed,
      parameter = "sd:mu:*",
      endpoint_member = "unknown",
      direct_sd_target = "sd_mu_unknown",
      truth = NA_real_,
      estimate = NA_real_,
      conf.low = NA_real_,
      conf.high = NA_real_,
      conf.level = NA_real_,
      interval_method = "confint_default",
      interval_scale = "response",
      conf.status = "failed",
      finite_interval = FALSE,
      covered = FALSE,
      lower_miss = FALSE,
      upper_miss = FALSE,
      convergence = fit$opt$convergence %||% NA_integer_,
      converged = isTRUE((fit$opt$convergence %||% NA_integer_) == 0L),
      pdHess = isTRUE(fit$sdr$pdHess),
      nobs = stats::nobs(fit),
      elapsed = elapsed,
      warning_count = length(warnings),
      warnings = paste(warnings, collapse = " | "),
      interval_message = conditionMessage(ci),
      stringsAsFactors = FALSE
    ))
  }

  sd_rows <- grepl(paste0("^sd:mu:", provider), ci$parm)
  truth <- attr(dat, "truth", exact = TRUE)$sd
  sd_est <- fit$sdpars$mu
  out <- ci[sd_rows, , drop = FALSE]
  endpoint_member <- vapply(out$parm, endpoint_member_from_parm, character(1L))
  truth_names <- sub("^sd:mu:", "", out$parm)
  truth_value <- unname(truth[truth_names])
  estimate_value <- unname(sd_est[truth_names])
  finite_interval <- is.finite(out$lower) & is.finite(out$upper)
  covered <- finite_interval & out$lower <= truth_value & truth_value <= out$upper
  data.frame(
    probe_id = sprintf("gaussian_mu_slope_interval_probe_%s_rep%03d", provider, replicate),
    cell_id = spec$cell_id,
    provider = provider,
    source_task = spec$source_task,
    replicate = replicate,
    seed = seed,
    parameter = out$parm,
    endpoint_member = endpoint_member,
    direct_sd_target = vapply(endpoint_member, direct_sd_target_from_endpoint, character(1L)),
    truth = truth_value,
    estimate = estimate_value,
    conf.low = out$lower,
    conf.high = out$upper,
    conf.level = out$level,
    interval_method = paste0("confint_default_", out$method),
    interval_scale = out$scale,
    conf.status = out$conf.status,
    finite_interval = finite_interval,
    covered = covered,
    lower_miss = finite_interval & truth_value < out$lower,
    upper_miss = finite_interval & truth_value > out$upper,
    convergence = fit$opt$convergence %||% NA_integer_,
    converged = isTRUE((fit$opt$convergence %||% NA_integer_) == 0L),
    pdHess = isTRUE(fit$sdr$pdHess),
    nobs = stats::nobs(fit),
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(unique(warnings), collapse = " | "),
    interval_message = out$profile.message %||% NA_character_,
    stringsAsFactors = FALSE
  )
}

results <- do.call(rbind, lapply(seq_len(nrow(seed_manifest)), function(i) {
  row <- seed_manifest[i, , drop = FALSE]
  provider <- row$provider[[1L]]
  out <- probe_one(
    provider = provider,
    spec = provider_specs[[provider]],
    replicate = row$replicate[[1L]],
    seed = row$seed[[1L]]
  )
  seed_manifest$execution_status[[i]] <<- "executed"
  out
}))

summary_by_target <- aggregate(
  cbind(
    finite_interval = results$finite_interval,
    covered = results$covered,
    lower_miss = results$lower_miss,
    upper_miss = results$upper_miss,
    converged = results$converged,
    pdHess = results$pdHess
  ),
  by = results[c("cell_id", "provider", "source_task", "endpoint_member", "direct_sd_target")],
  FUN = sum
)
n_by_target <- aggregate(
  results$probe_id,
  by = results[c("cell_id", "provider", "source_task", "endpoint_member", "direct_sd_target")],
  FUN = length
)
names(n_by_target)[names(n_by_target) == "x"] <- "n_probe_replicates"
boundary_by_target <- aggregate(
  grepl("boundary", results$conf.status, fixed = TRUE),
  by = results[c("cell_id", "provider", "source_task", "endpoint_member", "direct_sd_target")],
  FUN = sum
)
names(boundary_by_target)[names(boundary_by_target) == "x"] <- "n_wald_boundary"
summary_by_target <- merge(
  n_by_target,
  summary_by_target,
  by = c("cell_id", "provider", "source_task", "endpoint_member", "direct_sd_target"),
  sort = FALSE
)
summary_by_target <- merge(
  summary_by_target,
  boundary_by_target,
  by = c("cell_id", "provider", "source_task", "endpoint_member", "direct_sd_target"),
  sort = FALSE
)
summary_by_target$interval_probe_status <- ifelse(
  summary_by_target$finite_interval == summary_by_target$n_probe_replicates &
    summary_by_target$n_wald_boundary == 0L,
  "finite_interval_probe_passed",
  "boundary_or_nonfinite_interval_caveat"
)
summary_by_target$current_denominator_action <- ifelse(
  summary_by_target$interval_probe_status == "finite_interval_probe_passed",
  "eligible_for_pregrid_with_retention",
  "visible_holdout_until_boundary_reconciled"
)

summary_by_cell <- aggregate(
  cbind(
    n_probe_replicates = summary_by_target$n_probe_replicates,
    finite_interval = summary_by_target$finite_interval,
    covered = summary_by_target$covered,
    lower_miss = summary_by_target$lower_miss,
    upper_miss = summary_by_target$upper_miss,
    converged = summary_by_target$converged,
    pdHess = summary_by_target$pdHess,
    n_wald_boundary = summary_by_target$n_wald_boundary
  ),
  by = summary_by_target[c("cell_id", "provider", "source_task")],
  FUN = sum
)
summary_by_cell$n_targets <- as.integer(table(summary_by_target$cell_id)[summary_by_cell$cell_id])
summary_by_cell$n_interval_rows <- summary_by_cell$n_probe_replicates
summary_by_cell$interval_probe_status <- ifelse(
  summary_by_cell$finite_interval == summary_by_cell$n_interval_rows &
    summary_by_cell$n_wald_boundary == 0L,
  "finite_interval_probe_passed",
  "boundary_or_nonfinite_interval_caveat"
)
summary_by_cell$widget_state <- ifelse(
  summary_by_cell$interval_probe_status == "finite_interval_probe_passed",
  "mu_slope_pregrid_planned",
  "admission_blocked"
)

n_pregrid_replicates <- 150L
nominal_coverage <- 0.95
mcse_threshold <- 0.01
nominal_mcse <- sqrt(nominal_coverage * (1 - nominal_coverage) / n_pregrid_replicates)
replicates_for_threshold <- ceiling(
  nominal_coverage * (1 - nominal_coverage) / mcse_threshold^2 - 1e-12
)
pregrid_seed_manifest <- data.frame(
  replicate_index = seq_len(n_pregrid_replicates),
  seed = 791000L + seq_len(n_pregrid_replicates),
  seed_role = "predeclared_gaussian_mu_slope_pregrid",
  source_probe = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-probe-local/structured-re-gaussian-mu-slope-interval-probe-summary.tsv",
  execution_status = "not_executed",
  stringsAsFactors = FALSE
)
eligible_targets <- summary_by_target[
  summary_by_target$current_denominator_action == "eligible_for_pregrid_with_retention",
  ,
  drop = FALSE
]
pregrid_cells <- do.call(rbind, lapply(seq_len(nrow(eligible_targets)), function(i) {
  target <- eligible_targets[i, , drop = FALSE]
  data.frame(
    pregrid_cell_id = sprintf(
      "gaussian_mu_slope_pregrid_%s_%s_rep%03d",
      target$provider[[1L]],
      target_token(target$endpoint_member[[1L]]),
      pregrid_seed_manifest$replicate_index
    ),
    replicate_index = pregrid_seed_manifest$replicate_index,
    seed = pregrid_seed_manifest$seed,
    cell_id = target$cell_id,
    provider = target$provider,
    endpoint_member = target$endpoint_member,
    direct_sd_target = target$direct_sd_target,
    interval_methods = "confint_default_bias_t_location_sd",
    current_denominator_action = target$current_denominator_action,
    retention_policy = paste(
      "retain_nonconverged_fits;retain_non_pdhess_fits;",
      "retain_nonfinite_intervals;record_boundary_wald_status",
      sep = ""
    ),
    execution_status = "not_executed",
    coverage_evaluable = "FALSE",
    stringsAsFactors = FALSE
  )
}))

admission_rows <- do.call(rbind, lapply(seq_len(nrow(summary_by_cell)), function(i) {
  row <- summary_by_cell[i, , drop = FALSE]
  spec <- provider_specs[[row$provider[[1L]]]]
  blocked <- row$widget_state[[1L]] == "admission_blocked"
  data.frame(
    audit_id = paste0("gaussian_mu_slope_admission_", row$provider),
    cell_id = row$cell_id,
    provider = row$provider,
    source_task = row$source_task,
    formula_cell = spec$formula_cell,
    source_smoke_status = "docs/dev-log/dashboard/structured-re-gaussian-mu-slope-smoke-status.tsv",
    source_interval_probe = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-probe-local/structured-re-gaussian-mu-slope-interval-probe-summary.tsv",
    n_targets = row$n_targets,
    n_probe_replicates = n_probe_replicates,
    n_interval_rows = row$n_interval_rows,
    n_converged_rows = row$converged,
    n_pdhess_rows = row$pdHess,
    n_finite_intervals = row$finite_interval,
    n_wald_boundary = row$n_wald_boundary,
    n_covered = row$covered,
    n_lower_miss = row$lower_miss,
    n_upper_miss = row$upper_miss,
    widget_state = row$widget_state,
    admission_status = if (blocked) {
      "boundary_caveat_before_denominator"
    } else {
      "interval_probe_passed_pregrid_planned"
    },
    evidence_basis = sprintf(
      "%s/%s finite default confint intervals; %s/%s converged and pdHess TRUE; %s boundary Wald statuses.",
      row$finite_interval,
      row$n_interval_rows,
      row$converged,
      row$n_interval_rows,
      row$n_wald_boundary
    ),
    stability_signal = "fit_stable_in_local_probe",
    inference_signal = "not_inference_ready_pregrid_not_executed",
    linked_fit_status = "point_fit",
    linked_interval_status = "planned",
    linked_coverage_status = "planned",
    promotion_decision = "do_not_promote",
    evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-interval-probe.md",
    claim_boundary = clean_text(paste(
      spec$provider_prefix,
      "Gaussian q1 mu one-slope interval probe only;",
      spec$provider_boundary,
      "no coverage-evaluable denominator evidence, calibrated coverage,",
      "inference_ready, supported, q2/q4/q8, sigma, non-Gaussian, REML,",
      "AI-REML, broad bridge support, or public support promoted."
    )),
    next_gate = if (blocked) {
      "Diagnose the boundary Wald interval before the cell-level denominator grid; target-level pregrid can proceed only for clean direct-SD targets."
    } else {
      "Run the retained-outcome SR150 pregrid manifest, then top up to MCSE <= 0.01 before any inference_ready wording."
    },
    stringsAsFactors = FALSE
  )
}))

pregrid_rows <- do.call(rbind, lapply(seq_len(nrow(summary_by_target)), function(i) {
  row <- summary_by_target[i, , drop = FALSE]
  spec <- provider_specs[[row$provider[[1L]]]]
  eligible <- row$current_denominator_action[[1L]] == "eligible_for_pregrid_with_retention"
  data.frame(
    pregrid_id = paste0(
      "gaussian_mu_slope_pregrid_",
      row$provider,
      "_",
      target_token(row$endpoint_member)
    ),
    cell_id = row$cell_id,
    formula_cell = spec$formula_cell,
    provider = row$provider,
    target_kind = "direct_sd",
    endpoint_member = row$endpoint_member,
    direct_sd_target = row$direct_sd_target,
    source_probe = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-probe-local/structured-re-gaussian-mu-slope-interval-probe-summary.tsv",
    source_seed_manifest = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-probe-local/structured-re-gaussian-mu-slope-pregrid-seed-manifest.tsv",
    source_cell_manifest = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-probe-local/structured-re-gaussian-mu-slope-pregrid-cell-manifest.tsv",
    current_denominator_action = row$current_denominator_action,
    denominator_role = if (eligible) "pregrid_target" else "visible_holdout",
    planned_replicates = if (eligible) n_pregrid_replicates else 0L,
    planned_cells = if (eligible) n_pregrid_replicates else 0L,
    seed_manifest_rows = nrow(pregrid_seed_manifest),
    target_cell_manifest_rows = if (eligible) n_pregrid_replicates else 0L,
    total_cell_manifest_rows = if (is.null(pregrid_cells)) 0L else nrow(pregrid_cells),
    nominal_coverage = sprintf("%.2f", nominal_coverage),
    nominal_mcse_at_150 = sprintf("%.6f", nominal_mcse),
    replicates_for_mcse_threshold = replicates_for_threshold,
    mcse_threshold = sprintf("%.2f", mcse_threshold),
    mcse_threshold_status = "not_met_by_sr150",
    interval_methods = "confint_default_bias_t_location_sd",
    retention_policy = paste(
      "retain_nonconverged_fits;retain_non_pdhess_fits;",
      "retain_nonfinite_intervals;record_boundary_wald_status",
      sep = ""
    ),
    execution_status = "not_executed",
    coverage_evaluable = "FALSE",
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-interval-probe.md",
    claim_boundary = clean_text(paste(
      spec$provider_prefix,
      "Gaussian q1 mu one-slope coverage pre-grid dry-run only;",
      spec$provider_boundary,
      "no coverage-evaluable denominator evidence, calibrated coverage,",
      "inference_ready, supported, q2/q4/q8, sigma, non-Gaussian, REML,",
      "AI-REML, broad bridge support, DRAC execution, or SR150 readiness",
      "promoted."
    )),
    next_gate = if (eligible) {
      "Execute only after review of this dry-run manifest; retain all outcomes and do not use SR150 for coverage wording because nominal MCSE is above 0.01."
    } else {
      "Reconcile the boundary/nonfinite interval probe before adding this target to the executable pre-grid cell manifest."
    },
    stringsAsFactors = FALSE
  )
}))

run_log <- data.frame(
  artifact = c(
    "probe_results",
    "probe_summary",
    "seed_manifest",
    "pregrid_seed_manifest",
    "pregrid_cell_manifest",
    "admission_audit",
    "pregrid_dry_run"
  ),
  path = c(
    probe_results_path,
    probe_summary_path,
    seed_manifest_path,
    pregrid_seed_manifest_path,
    pregrid_cell_manifest_path,
    admission_path,
    pregrid_path
  ),
  rows = c(
    nrow(results),
    nrow(summary_by_target),
    nrow(seed_manifest),
    nrow(pregrid_seed_manifest),
    if (is.null(pregrid_cells)) 0L else nrow(pregrid_cells),
    nrow(admission_rows),
    nrow(pregrid_rows)
  ),
  stringsAsFactors = FALSE
)
run_log$path <- sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"), "", run_log$path)

write_tsv(seed_manifest, seed_manifest_path)
write_tsv(results, probe_results_path)
write_tsv(summary_by_target, probe_summary_path)
write_tsv(pregrid_seed_manifest, pregrid_seed_manifest_path)
write_tsv(pregrid_cells, pregrid_cell_manifest_path)
write_tsv(admission_rows, admission_path)
write_tsv(pregrid_rows, pregrid_path)
write_tsv(run_log, run_log_path)

capture.output(utils::sessionInfo(), file = session_info_path)
old_wd <- setwd(repo_root)
on.exit(setwd(old_wd), add = TRUE)
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) conditionMessage(e)
)
writeLines(git_sha, git_sha_path)

cat("wrote ", admission_path, " with ", nrow(admission_rows), " rows\n", sep = "")
cat("wrote ", pregrid_path, " with ", nrow(pregrid_rows), " rows\n", sep = "")
cat("wrote ", probe_results_path, " with ", nrow(results), " rows\n", sep = "")
cat("wrote ", pregrid_cell_manifest_path, " with ", nrow(pregrid_cells), " rows\n", sep = "")
