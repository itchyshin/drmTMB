#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R [options]",
      "",
      "Options:",
      "  --n-rep=N                 Number of replicate seeds to run (default: 150).",
      "  --seed-start=N            First replicate index for generated/top-up seeds (default: 1).",
      "  --seed-base=N             Seed base; seed = seed_base + replicate_index (default: 791000).",
      "  --providers=a,b,c         Providers to run (default: phylo,spatial,animal,relmat).",
      "  --output-dir=PATH         Artifact directory.",
      "  --overwrite=true          Replace an existing artifact directory.",
      "  --write-dashboard=false   Do not overwrite the dashboard result sidecar.",
      "",
      sep = "\n"
    )
  )
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

`%num_arg%` <- function(x, y) {
  if (is.null(x)) y else as.numeric(x)
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

n_rep <- as.integer(arg_value("n-rep", "150"))
if (!is.finite(n_rep) || n_rep < 1L) {
  stop("`--n-rep` must be a positive integer.", call. = FALSE)
}
seed_start <- as.integer(arg_value("seed-start", "1"))
if (!is.finite(seed_start) || seed_start < 1L) {
  stop("`--seed-start` must be a positive integer.", call. = FALSE)
}
seed_base <- as.integer(arg_value("seed-base", "791000"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)

default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-gaussian-mu-slope-coverage-pregrid-local"
)
artifact_dir <- normalizePath(
  arg_value("output-dir", default_artifact_dir),
  mustWork = FALSE
)
if (dir.exists(artifact_dir) && !overwrite) {
  stop(
    "`output-dir` already exists. Use --overwrite=true to replace it: ",
    artifact_dir,
    call. = FALSE
  )
}
if (dir.exists(artifact_dir) && overwrite) {
  unlink(artifact_dir, recursive = TRUE)
}
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
pregrid_rule_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-dry-run.tsv"
)
seed_manifest_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-gaussian-mu-slope-interval-probe-local",
  "structured-re-gaussian-mu-slope-pregrid-seed-manifest.tsv"
)
dashboard_result_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-results.tsv"
)
seed_manifest_copy_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-seed-manifest.tsv"
)

replicate_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv"
)
fit_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-fit-status.tsv"
)
target_summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-target-summary.tsv"
)
provider_summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-provider-summary.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-mu-slope-coverage-pregrid-run-log.tsv"
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

mcse_proportion <- function(x) {
  if (!is.logical(x) || length(x) == 0L || anyNA(x)) {
    return(NA_real_)
  }
  p <- mean(x)
  sqrt(p * (1 - p) / length(x))
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
    condition = phase18_phylo_mu_slope_conditions(
      n_tip = 8L,
      n_each = 7L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_phylo_mu_slope_cell,
    fit = phase18_fit_phylo_mu_slope
  ),
  spatial = list(
    condition = phase18_spatial_mu_slope_conditions(
      n_site = 12L,
      n_each = 8L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_spatial_mu_slope_cell,
    fit = phase18_fit_spatial_mu_slope
  ),
  animal = list(
    condition = phase18_animal_mu_slope_conditions(
      n_id = 8L,
      n_each = 7L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_animal_mu_slope_cell,
    fit = phase18_fit_animal_mu_slope
  ),
  relmat = list(
    condition = phase18_relmat_mu_slope_conditions(
      n_id = 8L,
      n_each = 7L
    )[1L, , drop = FALSE],
    dgp = phase18_dgp_relmat_mu_slope_cell,
    fit = phase18_fit_relmat_mu_slope
  )
)

provider_boundary <- c(
  phylo = "",
  spatial = " no range-estimating spatial support,",
  animal = " no pedigree/Ainv bridge marshalling,",
  relmat = " no Q bridge marshalling,"
)
provider_label <- c(
  phylo = "phylo",
  spatial = "fixed-covariance spatial",
  animal = "animal A-matrix",
  relmat = "relmat K-matrix"
)

pregrid_rule <- utils::read.delim(
  pregrid_rule_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

provider_arg <- arg_value(
  "providers",
  paste(names(provider_specs), collapse = ",")
)
selected_providers <- trimws(strsplit(provider_arg, ",", fixed = TRUE)[[1L]])
selected_providers <- selected_providers[nzchar(selected_providers)]
unknown_providers <- setdiff(selected_providers, names(provider_specs))
if (length(selected_providers) == 0L || length(unknown_providers) > 0L) {
  stop(
    "`--providers` must be a comma-separated subset of: ",
    paste(names(provider_specs), collapse = ", "),
    call. = FALSE
  )
}
provider_specs <- provider_specs[selected_providers]

source_seed_manifest <- utils::read.delim(
  seed_manifest_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
seed_manifest_source_label <- sub(
  paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"),
  "",
  seed_manifest_path
)
requested_index <- seq(from = seed_start, length.out = n_rep)
if (
  seed_start == 1L &&
    max(requested_index) <= nrow(source_seed_manifest) &&
    all(
      source_seed_manifest$replicate_index[requested_index] == requested_index
    )
) {
  seed_manifest <- source_seed_manifest[requested_index, , drop = FALSE]
} else {
  seed_manifest <- data.frame(
    replicate_index = requested_index,
    seed = seed_base + requested_index,
    seed_role = "generated_gaussian_mu_slope_pregrid_topup",
    source_probe = seed_manifest_source_label,
    execution_status = "not_executed",
    stringsAsFactors = FALSE
  )
}
write_tsv(seed_manifest, seed_manifest_copy_path)

target_parameter <- function(provider, endpoint_member) {
  stem <- switch(
    endpoint_member,
    "mu:(Intercept)" = "1",
    "mu:x" = "0 + x",
    stop("Unknown endpoint member: ", endpoint_member, call. = FALSE)
  )
  paste0("sd:mu:", provider, "(", stem, " |")
}

find_interval_row <- function(ci, provider, endpoint_member) {
  pattern <- target_parameter(provider, endpoint_member)
  hit <- grepl(pattern, ci$parm, fixed = TRUE)
  if (!any(hit)) {
    return(NULL)
  }
  ci[which(hit)[[1L]], , drop = FALSE]
}

run_provider_replicate <- function(provider, replicate_index, seed, targets) {
  spec <- provider_specs[[provider]]
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  fit <- NULL
  ci <- NULL
  fit_error <- NA_character_
  confint_error <- NA_character_
  dat <- tryCatch(
    withCallingHandlers(
      spec$dgp(
        spec$condition,
        seed = seed,
        cell_id = sprintf("gaussian_mu_slope_pregrid_%s", provider),
        replicate = replicate_index
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  if (inherits(dat, "error")) {
    fit_error <- conditionMessage(dat)
  } else {
    fit <- tryCatch(
      withCallingHandlers(
        spec$fit(dat, spec$condition),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    if (inherits(fit, "error")) {
      fit_error <- conditionMessage(fit)
      fit <- NULL
    }
  }
  if (!is.null(fit)) {
    ci <- tryCatch(
      withCallingHandlers(
        confint(fit),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    if (inherits(ci, "error")) {
      confint_error <- conditionMessage(ci)
      ci <- NULL
    }
  }
  elapsed <- proc.time()[["elapsed"]] - started
  fit_ok <- !is.null(fit)
  converged <- fit_ok && isTRUE(fit$opt$convergence == 0)
  pdhess <- fit_ok && isTRUE(fit$sdr$pdHess)
  truth <- if (inherits(dat, "data.frame")) {
    attr(dat, "truth", exact = TRUE)$sd
  } else {
    NULL
  }
  estimates <- if (fit_ok) fit$sdpars$mu else NULL

  fit_row <- data.frame(
    provider = provider,
    replicate_index = replicate_index,
    seed = seed,
    fit_ok = fit_ok,
    converged = converged,
    convergence = if (fit_ok) fit$opt$convergence else NA_integer_,
    pdHess = pdhess,
    confint_ok = !is.null(ci),
    nobs = if (fit_ok) stats::nobs(fit) else NA_integer_,
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(unique(warnings), collapse = " | "),
    fit_error = fit_error,
    confint_error = confint_error,
    stringsAsFactors = FALSE
  )

  replicate_rows <- lapply(seq_len(nrow(targets)), function(i) {
    target <- targets[i, , drop = FALSE]
    eligible <- target$current_denominator_action[[1L]] ==
      "eligible_for_pregrid_with_retention"
    if (!eligible) {
      return(data.frame(
        cell_id = target$cell_id,
        provider = provider,
        endpoint_member = target$endpoint_member,
        direct_sd_target = target$direct_sd_target,
        replicate_index = replicate_index,
        seed = seed,
        denominator_action = target$current_denominator_action,
        denominator_role = target$denominator_role,
        coverage_evaluable = FALSE,
        fit_ok = fit_ok,
        converged = converged,
        pdHess = pdhess,
        confint_ok = !is.null(ci),
        parameter = NA_character_,
        truth = NA_real_,
        estimate = NA_real_,
        conf.low = NA_real_,
        conf.high = NA_real_,
        conf.level = NA_real_,
        conf.status = "not_requested_holdout",
        interval_status = "not_requested_holdout",
        usable_interval = FALSE,
        covered = FALSE,
        lower_miss = FALSE,
        upper_miss = FALSE,
        warning_count = length(warnings),
        warnings = paste(unique(warnings), collapse = " | "),
        interval_message = "visible holdout until boundary interval is reconciled",
        stringsAsFactors = FALSE
      ))
    }

    if (!fit_ok) {
      interval_status <- "fit_failed"
      interval_row <- NULL
    } else if (!converged) {
      interval_status <- "nonconverged_fit"
      interval_row <- NULL
    } else if (!pdhess) {
      interval_status <- "non_pdhess_fit"
      interval_row <- NULL
    } else if (is.null(ci)) {
      interval_status <- "confint_failed"
      interval_row <- NULL
    } else {
      interval_row <- find_interval_row(
        ci,
        provider,
        target$endpoint_member[[1L]]
      )
      interval_status <- if (is.null(interval_row)) {
        "interval_target_missing"
      } else if (!identical(interval_row$conf.status[[1L]], "wald")) {
        "boundary_or_nonwald_status"
      } else if (
        !is.finite(interval_row$lower[[1L]]) ||
          !is.finite(interval_row$upper[[1L]])
      ) {
        "nonfinite_interval"
      } else {
        "ok"
      }
    }

    parameter <- if (is.null(interval_row)) {
      NA_character_
    } else {
      interval_row$parm[[1L]]
    }
    truth_name <- if (is.na(parameter)) {
      NA_character_
    } else {
      sub("^sd:mu:", "", parameter)
    }
    truth_value <- if (
      !is.null(truth) && !is.na(truth_name) && truth_name %in% names(truth)
    ) {
      unname(truth[[truth_name]])
    } else {
      NA_real_
    }
    estimate_value <- if (
      !is.null(estimates) &&
        !is.na(truth_name) &&
        truth_name %in% names(estimates)
    ) {
      unname(estimates[[truth_name]])
    } else {
      NA_real_
    }
    lower <- if (is.null(interval_row)) NA_real_ else interval_row$lower[[1L]]
    upper <- if (is.null(interval_row)) NA_real_ else interval_row$upper[[1L]]
    usable <- identical(interval_status, "ok")
    covered <- usable && lower <= truth_value && truth_value <= upper

    data.frame(
      cell_id = target$cell_id,
      provider = provider,
      endpoint_member = target$endpoint_member,
      direct_sd_target = target$direct_sd_target,
      replicate_index = replicate_index,
      seed = seed,
      denominator_action = target$current_denominator_action,
      denominator_role = target$denominator_role,
      coverage_evaluable = TRUE,
      fit_ok = fit_ok,
      converged = converged,
      pdHess = pdhess,
      confint_ok = !is.null(ci),
      parameter = parameter,
      truth = truth_value,
      estimate = estimate_value,
      conf.low = lower,
      conf.high = upper,
      conf.level = if (is.null(interval_row)) {
        NA_real_
      } else {
        interval_row$level[[1L]]
      },
      conf.status = if (is.null(interval_row)) {
        interval_status
      } else {
        interval_row$conf.status[[1L]]
      },
      interval_status = interval_status,
      usable_interval = usable,
      covered = covered,
      lower_miss = usable && truth_value < lower,
      upper_miss = usable && truth_value > upper,
      warning_count = length(warnings),
      warnings = paste(unique(warnings), collapse = " | "),
      interval_message = if (is.null(interval_row)) {
        confint_error %||% fit_error %||% interval_status
      } else {
        interval_row$profile.message[[1L]] %||% ""
      },
      stringsAsFactors = FALSE
    )
  })

  list(
    fit = fit_row,
    replicates = do.call(rbind, replicate_rows)
  )
}

all_fits <- list()
all_replicates <- list()
counter <- 0L
for (provider in names(provider_specs)) {
  targets <- pregrid_rule[pregrid_rule$provider == provider, , drop = FALSE]
  for (i in seq_len(nrow(seed_manifest))) {
    counter <- counter + 1L
    out <- run_provider_replicate(
      provider = provider,
      replicate_index = seed_manifest$replicate_index[[i]],
      seed = seed_manifest$seed[[i]],
      targets = targets
    )
    all_fits[[counter]] <- out$fit
    all_replicates[[counter]] <- out$replicates
  }
}

fits <- do.call(rbind, all_fits)
replicates <- do.call(rbind, all_replicates)

summarise_target <- function(x) {
  evaluable <- x$coverage_evaluable
  y <- x[evaluable, , drop = FALSE]
  if (nrow(y) == 0L) {
    return(data.frame(
      n_total = nrow(x),
      n_coverage_evaluable = 0L,
      n_fit_ok = sum(x$fit_ok),
      n_converged = sum(x$converged),
      n_pdhess = sum(x$pdHess),
      n_confint_ok = sum(x$confint_ok),
      n_usable_interval = 0L,
      finite_interval_rate = NA_real_,
      n_covered = 0L,
      coverage_all = NA_real_,
      coverage_all_mcse = NA_real_,
      coverage_interval_available = NA_real_,
      n_lower_miss = 0L,
      n_upper_miss = 0L,
      n_unusable_interval = nrow(x),
      n_boundary_or_nonwald = sum(grepl("boundary", x$interval_status)),
      stringsAsFactors = FALSE
    ))
  }
  covered_all <- as.logical(y$covered)
  usable <- as.logical(y$usable_interval)
  data.frame(
    n_total = nrow(y),
    n_coverage_evaluable = nrow(y),
    n_fit_ok = sum(y$fit_ok),
    n_converged = sum(y$converged),
    n_pdhess = sum(y$pdHess),
    n_confint_ok = sum(y$confint_ok),
    n_usable_interval = sum(usable),
    finite_interval_rate = mean(usable),
    n_covered = sum(covered_all),
    coverage_all = mean(covered_all),
    coverage_all_mcse = mcse_proportion(covered_all),
    coverage_interval_available = if (any(usable)) {
      mean(y$covered[usable])
    } else {
      NA_real_
    },
    n_lower_miss = sum(y$lower_miss),
    n_upper_miss = sum(y$upper_miss),
    n_unusable_interval = sum(!usable),
    n_boundary_or_nonwald = sum(
      y$interval_status == "boundary_or_nonwald_status"
    ),
    stringsAsFactors = FALSE
  )
}

group_cols <- c(
  "cell_id",
  "provider",
  "endpoint_member",
  "direct_sd_target",
  "denominator_action",
  "denominator_role"
)
split_key <- interaction(replicates[group_cols], drop = TRUE, lex.order = TRUE)
pieces <- split(replicates, split_key)
target_summary <- do.call(
  rbind,
  lapply(pieces, function(x) {
    data.frame(
      x[1L, group_cols, drop = FALSE],
      summarise_target(x),
      check.names = FALSE
    )
  })
)
row.names(target_summary) <- NULL
target_summary$mcse_status <- ifelse(
  is.na(target_summary$coverage_all_mcse),
  "not_coverage_evaluable",
  ifelse(target_summary$coverage_all_mcse <= 0.01, "mcse_met", "topup_required")
)
target_summary$target_gate <- ifelse(
  target_summary$denominator_action != "eligible_for_pregrid_with_retention",
  "visible_holdout",
  ifelse(
    target_summary$finite_interval_rate >= 0.95 &
      target_summary$n_boundary_or_nonwald == 0L &
      target_summary$coverage_all >= 0.90,
    "target_pregrid_passed_topup_required",
    "target_pregrid_blocked"
  )
)

provider_summary <- do.call(
  rbind,
  lapply(split(target_summary, target_summary$cell_id), function(x) {
    eligible <- x$denominator_action == "eligible_for_pregrid_with_retention"
    y <- x[eligible, , drop = FALSE]
    has_holdout <- any(!eligible)
    target_gate <- if (nrow(y) == 0L) {
      "no_eligible_targets"
    } else if (any(y$target_gate == "target_pregrid_blocked")) {
      "pregrid_blocked"
    } else if (has_holdout) {
      "partial_pregrid_holdout"
    } else {
      "pregrid_passed_topup_required"
    }
    widget_state <- switch(
      target_gate,
      pregrid_passed_topup_required = "topup_required",
      partial_pregrid_holdout = "admission_blocked",
      pregrid_blocked = "mu_slope_pregrid_blocked",
      "admission_blocked"
    )
    data.frame(
      cell_id = x$cell_id[[1L]],
      provider = x$provider[[1L]],
      n_targets = nrow(x),
      n_eligible_targets = sum(eligible),
      n_holdout_targets = sum(!eligible),
      n_total_target_replicates = sum(y$n_total),
      n_usable_intervals = sum(y$n_usable_interval),
      min_finite_interval_rate = if (nrow(y) == 0L) {
        NA_real_
      } else {
        min(y$finite_interval_rate)
      },
      min_coverage_all = if (nrow(y) == 0L) NA_real_ else min(y$coverage_all),
      max_coverage_all = if (nrow(y) == 0L) NA_real_ else max(y$coverage_all),
      max_coverage_mcse = if (nrow(y) == 0L) {
        NA_real_
      } else {
        max(y$coverage_all_mcse)
      },
      n_lower_miss = sum(y$n_lower_miss),
      n_upper_miss = sum(y$n_upper_miss),
      target_gate = target_gate,
      widget_state = widget_state,
      stringsAsFactors = FALSE
    )
  })
)
row.names(provider_summary) <- NULL

dashboard_rows <- do.call(
  rbind,
  lapply(seq_len(nrow(provider_summary)), function(i) {
    row <- provider_summary[i, , drop = FALSE]
    target_rows <- target_summary[
      target_summary$cell_id == row$cell_id,
      ,
      drop = FALSE
    ]
    evidence_basis <- sprintf(
      "%s/%s usable intervals across %s eligible target-replicates; coverage range %.3f-%.3f; miss counts lower=%s upper=%s.",
      row$n_usable_intervals,
      row$n_total_target_replicates,
      row$n_total_target_replicates,
      row$min_coverage_all,
      row$max_coverage_all,
      row$n_lower_miss,
      row$n_upper_miss
    )
    if (row$n_holdout_targets > 0L) {
      evidence_basis <- paste(
        evidence_basis,
        sprintf(
          "%s target endpoint remains a visible holdout.",
          row$n_holdout_targets
        )
      )
    }
    provider <- row$provider[[1L]]
    data.frame(
      result_id = paste0("gaussian_mu_slope_pregrid_result_", provider),
      cell_id = row$cell_id,
      provider = provider,
      n_targets = row$n_targets,
      n_eligible_targets = row$n_eligible_targets,
      n_holdout_targets = row$n_holdout_targets,
      n_rep = n_rep,
      n_total_target_replicates = row$n_total_target_replicates,
      n_usable_intervals = row$n_usable_intervals,
      min_finite_interval_rate = sprintf("%.4f", row$min_finite_interval_rate),
      min_coverage_all = sprintf("%.4f", row$min_coverage_all),
      max_coverage_all = sprintf("%.4f", row$max_coverage_all),
      max_coverage_mcse = sprintf("%.6f", row$max_coverage_mcse),
      n_lower_miss = row$n_lower_miss,
      n_upper_miss = row$n_upper_miss,
      target_gate = row$target_gate,
      widget_state = row$widget_state,
      evidence_basis = evidence_basis,
      stability_signal = "retained_pregrid_fit_interval_accounting",
      inference_signal = "not_inference_ready_sr150_mcse_above_0.01",
      linked_fit_status = "point_fit",
      linked_interval_status = "planned",
      linked_coverage_status = "planned",
      promotion_decision = "do_not_promote",
      evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-coverage-pregrid.md",
      artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-coverage-pregrid-local",
      claim_boundary = clean_text(paste(
        provider_label[[provider]],
        "Gaussian q1 mu one-slope SR150 coverage pregrid only;",
        provider_boundary[[provider]],
        "no MCSE-qualified coverage, inference_ready, supported, q2/q4/q8,",
        "sigma, non-Gaussian, REML, AI-REML, broad bridge support, or public",
        "support promoted."
      )),
      next_gate = if (
        row$target_gate[[1L]] == "pregrid_passed_topup_required"
      ) {
        "Top up retained-outcome target coverage to MCSE <= 0.01 and audit one-sided misses before any inference_ready wording."
      } else if (row$target_gate[[1L]] == "partial_pregrid_holdout") {
        "Diagnose the visible holdout target before cell-level promotion; the clean target can be topped up separately."
      } else {
        "Resolve finite-interval, boundary, or low retained-coverage failures before any top-up or inference_ready wording."
      },
      stringsAsFactors = FALSE
    )
  })
)

write_tsv(fits, fit_path)
write_tsv(replicates, replicate_path)
write_tsv(target_summary, target_summary_path)
write_tsv(provider_summary, provider_summary_path)
if (write_dashboard) {
  write_tsv(dashboard_rows, dashboard_result_path)
}

run_log <- data.frame(
  artifact = c(
    "seed_manifest",
    "fit_status",
    "replicates",
    "target_summary",
    "provider_summary",
    "dashboard_results"
  ),
  path = c(
    seed_manifest_copy_path,
    fit_path,
    replicate_path,
    target_summary_path,
    provider_summary_path,
    if (write_dashboard) dashboard_result_path else "not_written"
  ),
  rows = c(
    nrow(seed_manifest),
    nrow(fits),
    nrow(replicates),
    nrow(target_summary),
    nrow(provider_summary),
    if (write_dashboard) nrow(dashboard_rows) else 0L
  ),
  stringsAsFactors = FALSE
)
run_log$path <- sub(
  paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"),
  "",
  run_log$path
)
write_tsv(run_log, run_log_path)
capture.output(utils::sessionInfo(), file = session_info_path)
old_wd <- setwd(repo_root)
on.exit(setwd(old_wd), add = TRUE)
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) conditionMessage(e)
)
writeLines(git_sha, git_sha_path)

if (write_dashboard) {
  cat(
    "wrote ",
    dashboard_result_path,
    " with ",
    nrow(dashboard_rows),
    " rows\n",
    sep = ""
  )
}
cat(
  "wrote ",
  target_summary_path,
  " with ",
  nrow(target_summary),
  " rows\n",
  sep = ""
)
cat("wrote ", replicate_path, " with ", nrow(replicates), " rows\n", sep = "")
