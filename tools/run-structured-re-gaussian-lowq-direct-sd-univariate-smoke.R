#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-gaussian-lowq-direct-sd-univariate-smoke.R [options]",
      "",
      "Options:",
      "  --n-rep=N                         Replicates per direct-SD target (default: 1).",
      "  --seed-base=N                     Base seed for the two target streams (default: 2026062901).",
      "  --host-class=CLASS                Host class label (default: local_rehearsal).",
      "  --host-name=NAME                  Host name label (default: Sys.info()[['nodename']]).",
      "  --profile-endpoint-max-eval=N     Endpoint profile evaluation budget (default: 12).",
      "  --output-dir=PATH                 Artifact directory.",
      "  --overwrite=true                  Replace an existing artifact directory.",
      "  --write-dashboard=true            Write the dashboard summary sidecar.",
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

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
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

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

rel_path <- function(path) {
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"), "", path)
}

fmt4 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.4f", x))
}

fmt6 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.6f", x))
}

mcse_proportion <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  p <- mean(x)
  sqrt(p * (1 - p) / length(x))
}

numeric_or_na <- function(x) {
  if (length(x) == 0L || is.null(x) || !is.finite(x)) {
    return(NA_real_)
  }
  unname(x[[1L]])
}

n_rep <- as.integer(arg_value("n-rep", "1"))
if (!is.finite(n_rep) || n_rep < 1L) {
  stop("`--n-rep` must be a positive integer.", call. = FALSE)
}
seed_base <- as.integer(arg_value("seed-base", "2026062901"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
profile_endpoint_max_eval <- as.integer(arg_value(
  "profile-endpoint-max-eval",
  "12"
))
if (
  !is.finite(profile_endpoint_max_eval) ||
    profile_endpoint_max_eval < 1L
) {
  stop(
    "`--profile-endpoint-max-eval` must be a positive integer.",
    call. = FALSE
  )
}
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)
host_class <- arg_value("host-class", "local_rehearsal")
host_name <- arg_value("host-name", unname(Sys.info()[["nodename"]]))

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
special_contract_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-special-target-contract.tsv"
)
row_selection_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-row-selection.tsv"
)
dashboard_summary_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-direct-sd-univariate-smoke.tsv"
)
default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-gaussian-lowq-direct-sd-univariate-smoke-local"
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

summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-direct-sd-univariate-smoke.tsv"
)
replicate_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-direct-sd-univariate-smoke-replicates.tsv"
)
seed_manifest_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-direct-sd-univariate-smoke-seed-manifest.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))

special_contract <- read_tsv(special_contract_path)
row_selection <- read_tsv(row_selection_path)
cell_id <- "qseries_phylo_direct_sd_univariate"
contract_row <- special_contract[
  special_contract$cell_id == cell_id,
  ,
  drop = FALSE
]
selection_row <- row_selection[row_selection$cell_id == cell_id, , drop = FALSE]
if (nrow(contract_row) != 1L || nrow(selection_row) != 1L) {
  stop(
    "Special target and row-selection sidecars must contain the direct-SD cell.",
    call. = FALSE
  )
}

target_specs <- list(
  mu = list(
    target_axis = "mu",
    target_kind = "direct_sd_mu_intercept",
    endpoint_member = "mu:(Intercept)",
    estimand = "structured SD for mu intercept",
    direct_sd_target = "sd:mu:phylo(1 | species)",
    formula_cell = "phylo(1 | species, tree = tree) in mu",
    truth_sd_mu = 0.45,
    truth_sd_sigma = 0,
    beta_mu_intercept = 0.20,
    beta_mu_x = 0.40,
    beta_sigma_intercept = -1.00
  ),
  sigma = list(
    target_axis = "sigma",
    target_kind = "direct_sd_sigma_intercept",
    endpoint_member = "sigma:(Intercept)",
    estimand = "structured SD for sigma intercept",
    direct_sd_target = "sd:sigma:phylo(1 | species)",
    formula_cell = "phylo(1 | species, tree = tree) in sigma",
    truth_sd_mu = 0,
    truth_sd_sigma = 0.20,
    beta_mu_intercept = 0.20,
    beta_mu_x = 0.40,
    beta_sigma_intercept = -1.00
  )
)

make_data <- function(spec, seed, replicate_index) {
  set.seed(seed)
  n_group <- 8L
  n_each <- 8L
  tree <- ape::rcoal(n_group)
  tree$tip.label <- paste0("sp_", seq_len(n_group))
  storage.mode(tree$edge) <- "double"
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  levels <- rownames(K)
  L <- t(chol(K))
  effect_mu <- as.vector(L %*% stats::rnorm(n_group, sd = spec$truth_sd_mu))
  effect_sigma <- as.vector(
    L %*% stats::rnorm(n_group, sd = spec$truth_sd_sigma)
  )
  names(effect_mu) <- levels
  names(effect_sigma) <- levels
  species <- rep(levels, each = n_each)
  x <- stats::rnorm(length(species))
  sigma <- exp(spec$beta_sigma_intercept + effect_sigma[species])
  y <- spec$beta_mu_intercept +
    spec$beta_mu_x * x +
    effect_mu[species] +
    stats::rnorm(length(species), sd = sigma)
  dat <- data.frame(y = unname(y), x = x, species = species)
  attr(dat, "truth") <- c(
    list(
      tree = tree,
      seed = seed,
      replicate_index = replicate_index,
      n_group = n_group,
      n_each = n_each
    ),
    spec
  )
  dat
}

fit_direct_sd <- function(spec, dat) {
  truth <- attr(dat, "truth", exact = TRUE)
  tree <- truth$tree
  control <- drm_control(
    keep_tmb_object = TRUE,
    optimizer = list(eval.max = 500, iter.max = 500)
  )
  if (identical(spec$target_axis, "mu")) {
    return(
      drmTMB(
        bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
        family = gaussian(),
        data = dat,
        control = control
      )
    )
  }
  drmTMB(
    bf(y ~ x, sigma ~ phylo(1 | species, tree = tree)),
    family = gaussian(),
    data = dat,
    control = control
  )
}

find_interval_row <- function(ci, target) {
  if (is.null(ci)) {
    return(NULL)
  }
  hit <- ci$parm == target
  if (!any(hit)) {
    hit <- grepl(target, ci$parm, fixed = TRUE)
  }
  if (!any(hit) && grepl("^sd:sigma:", target)) {
    target_with_dpar <- sub("^sd:sigma:", "sd:sigma:sigma:", target)
    hit <- ci$parm == target_with_dpar
    if (!any(hit)) {
      hit <- grepl(target_with_dpar, ci$parm, fixed = TRUE)
    }
  }
  if (!any(hit)) {
    return(NULL)
  }
  ci[which(hit)[[1L]], , drop = FALSE]
}

sdr_cov_available <- function(fit) {
  if (is.null(fit) || is.null(fit$sdr)) {
    return(FALSE)
  }
  cov_fixed <- tryCatch(fit$sdr$cov.fixed, error = function(e) NULL)
  !is.null(cov_fixed) && length(cov_fixed) > 0L && all(is.finite(cov_fixed))
}

estimate_for_target <- function(fit, spec) {
  if (is.null(fit) || is.null(fit$sdpars[[spec$target_axis]])) {
    return(NA_real_)
  }
  values <- fit$sdpars[[spec$target_axis]]
  if ("phylo(1 | species)" %in% names(values)) {
    return(numeric_or_na(unname(values[["phylo(1 | species)"]])))
  }
  numeric_or_na(unname(values[[1L]]))
}

truth_for_target <- function(spec) {
  if (identical(spec$target_axis, "mu")) {
    return(spec$truth_sd_mu)
  }
  spec$truth_sd_sigma
}

run_one <- function(spec, replicate_index, seed) {
  warnings <- character()
  fit_error <- NA_character_
  confint_error <- NA_character_
  profile_error <- NA_character_
  profile_message <- NA_character_
  started <- proc.time()[["elapsed"]]
  dat <- tryCatch(
    withCallingHandlers(
      make_data(spec, seed, replicate_index),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )

  fit <- NULL
  ci <- NULL
  profile_ci <- NULL
  if (inherits(dat, "error")) {
    fit_error <- conditionMessage(dat)
  } else {
    fit <- tryCatch(
      withCallingHandlers(
        fit_direct_sd(spec, dat),
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
        confint(
          fit,
          parm = spec$direct_sd_target,
          method = "wald",
          small_sample_df = "none",
          bias_correct = "none"
        ),
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

  if (!is.null(fit)) {
    profile_ci <- tryCatch(
      withCallingHandlers(
        confint(
          fit,
          parm = spec$direct_sd_target,
          method = "profile",
          profile_engine = "endpoint",
          profile_endpoint_max_eval = profile_endpoint_max_eval
        ),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    if (inherits(profile_ci, "error")) {
      profile_error <- conditionMessage(profile_ci)
      profile_message <- profile_error
      profile_ci <- NULL
    }
  }

  elapsed <- proc.time()[["elapsed"]] - started
  fit_ok <- !is.null(fit)
  converged <- fit_ok && isTRUE(fit$opt$convergence == 0)
  pdhess <- fit_ok && isTRUE(fit$sdr$pdHess)
  sdreport_ok <- sdr_cov_available(fit)
  confint_ok <- !is.null(ci)
  interval_row <- find_interval_row(ci, spec$direct_sd_target)
  profile_row <- find_interval_row(profile_ci, spec$direct_sd_target)
  conf_status <- if (is.null(interval_row)) {
    if (!fit_ok) {
      "fit_failed"
    } else if (!pdhess) {
      "not_run_pdhess_false"
    } else if (!sdreport_ok) {
      "sdreport_cov_unavailable"
    } else if (!confint_ok) {
      "confint_failed"
    } else {
      "interval_target_missing"
    }
  } else {
    interval_row$conf.status[[1L]]
  }
  lower <- if (is.null(interval_row)) NA_real_ else interval_row$lower[[1L]]
  upper <- if (is.null(interval_row)) NA_real_ else interval_row$upper[[1L]]
  usable_interval <- identical(conf_status, "wald") &&
    is.finite(lower) &&
    is.finite(upper)
  truth_value <- truth_for_target(spec)
  covered <- if (usable_interval) {
    lower <= truth_value && truth_value <= upper
  } else {
    NA
  }
  lower_miss <- if (usable_interval) truth_value < lower else NA
  upper_miss <- if (usable_interval) truth_value > upper else NA

  profile_status <- if (is.null(profile_row)) {
    if (!fit_ok) {
      "fit_failed"
    } else if (is.na(profile_error)) {
      "profile_target_missing"
    } else {
      "profile_failed"
    }
  } else {
    profile_row$conf.status[[1L]]
  }
  profile_lower <- if (is.null(profile_row)) {
    NA_real_
  } else {
    profile_row$lower[[1L]]
  }
  profile_upper <- if (is.null(profile_row)) {
    NA_real_
  } else {
    profile_row$upper[[1L]]
  }
  profile_finite <- is.finite(profile_lower) && is.finite(profile_upper)
  profile_ok <- identical(profile_status, "profile") && profile_finite
  if (!is.null(profile_row) && "profile.message" %in% names(profile_row)) {
    profile_message <- profile_row$profile.message[[1L]]
  }

  data.frame(
    smoke_id = paste0(
      "gaussian_lowq_direct_sd_univariate_smoke_",
      spec$target_axis,
      "_rep",
      replicate_index
    ),
    cell_id = cell_id,
    target_axis = spec$target_axis,
    target_kind = spec$target_kind,
    endpoint_member = spec$endpoint_member,
    estimand = spec$estimand,
    formula_cell = spec$formula_cell,
    replicate_index = replicate_index,
    seed = seed,
    interval_channel = "raw_log_sd_wald_z;small_sample_df_none;bias_correct_none",
    profile_channel = "endpoint_profile_diagnostic_only",
    source_contract_id = contract_row$contract_id[[1L]],
    source_contract = rel_path(special_contract_path),
    source_row_selection = rel_path(row_selection_path),
    direct_sd_target = spec$direct_sd_target,
    wald_parameter = if (is.null(interval_row)) {
      spec$direct_sd_target
    } else {
      interval_row$parm[[1L]]
    },
    profile_parameter = if (is.null(profile_row)) {
      spec$direct_sd_target
    } else {
      profile_row$parm[[1L]]
    },
    truth_value = truth_value,
    n_group = 8L,
    n_each = 8L,
    beta_mu_intercept = spec$beta_mu_intercept,
    beta_mu_x = spec$beta_mu_x,
    beta_sigma_intercept = spec$beta_sigma_intercept,
    truth_sd_mu_intercept = spec$truth_sd_mu,
    truth_sd_sigma_intercept = spec$truth_sd_sigma,
    fit_ok = fit_ok,
    converged = converged,
    pdHess = pdhess,
    sdreport_cov_available = sdreport_ok,
    confint_ok = confint_ok,
    small_sample_df = "none",
    bias_correct = "none",
    conf_status = conf_status,
    usable_interval = usable_interval,
    estimate = estimate_for_target(fit, spec),
    conf.low = lower,
    conf.high = upper,
    covered = covered,
    lower_miss = lower_miss,
    upper_miss = upper_miss,
    profile_ok = profile_ok,
    profile_status = profile_status,
    profile_engine = "endpoint",
    profile_endpoint_max_eval = profile_endpoint_max_eval,
    profile.low = profile_lower,
    profile.high = profile_upper,
    profile_finite = profile_finite,
    profile_message = profile_message,
    nobs = if (fit_ok) stats::nobs(fit) else NA_integer_,
    elapsed = elapsed,
    warning_count = length(unique(warnings)),
    warnings = paste(unique(warnings), collapse = " | "),
    fit_error = fit_error,
    confint_error = confint_error,
    profile_error = profile_error,
    host_class = host_class,
    host_name = host_name,
    stringsAsFactors = FALSE
  )
}

seed_manifest <- do.call(
  rbind,
  lapply(seq_along(target_specs), function(i) {
    spec <- target_specs[[i]]
    data.frame(
      target_axis = spec$target_axis,
      replicate_index = seq_len(n_rep),
      seed = seed_base + (i - 1L) + seq_len(n_rep),
      seed_role = "gaussian_lowq_direct_sd_univariate_smoke",
      execution_status = "executed",
      source_contract = rel_path(special_contract_path),
      host_class = host_class,
      host_name = host_name,
      stringsAsFactors = FALSE
    )
  })
)
write_tsv(seed_manifest, seed_manifest_path)

replicate_rows <- vector("list", length(target_specs) * n_rep)
row_i <- 1L
for (i in seq_along(target_specs)) {
  spec <- target_specs[[i]]
  for (replicate_index in seq_len(n_rep)) {
    seed <- seed_base + (i - 1L) + replicate_index
    replicate_rows[[row_i]] <- run_one(spec, replicate_index, seed)
    row_i <- row_i + 1L
  }
}
replicates <- do.call(rbind, replicate_rows)
row.names(replicates) <- NULL

summaries <- lapply(target_specs, function(spec) {
  x <- replicates[replicates$target_axis == spec$target_axis, , drop = FALSE]
  support_clear <- all(x$fit_ok) &&
    all(x$converged) &&
    all(x$pdHess) &&
    all(x$sdreport_cov_available) &&
    all(x$usable_interval) &&
    all(x$profile_ok)
  n_usable <- sum(x$usable_interval)
  covered <- x$covered[x$usable_interval]
  coverage <- if (length(covered) == 0L) NA_real_ else mean(covered)
  status <- if (support_clear) {
    paste0("local_direct_sd_", spec$target_axis, "_axis_smoke_passed")
  } else {
    paste0("local_direct_sd_", spec$target_axis, "_axis_diagnostic_blocked")
  }
  blockers <- unique(c(
    if (any(!x$fit_ok)) "fit_failed",
    if (any(!x$converged)) "nonconverged",
    if (any(!x$pdHess)) "pdhess_false",
    if (any(!x$sdreport_cov_available)) "sdreport_cov_unavailable",
    if (any(!x$usable_interval)) "nonusable_wald_interval",
    if (any(!x$profile_finite)) "profile_nonfinite_or_failed",
    if (any(x$warning_count > 0L)) "warnings_recorded"
  ))
  if (length(blockers) == 0L) {
    blockers <- "none"
  }
  data.frame(
    smoke_id = paste0(
      "gaussian_lowq_direct_sd_univariate_smoke_",
      spec$target_axis
    ),
    cell_id = cell_id,
    target_axis = spec$target_axis,
    target_kind = spec$target_kind,
    endpoint_member = spec$endpoint_member,
    estimand = spec$estimand,
    direct_sd_target = spec$direct_sd_target,
    source_contract_id = contract_row$contract_id[[1L]],
    source_contract = rel_path(special_contract_path),
    source_row_selection = rel_path(row_selection_path),
    artifact_dir = rel_path(artifact_dir),
    n_rep = length(unique(x$replicate_index)),
    n_fit_ok = sum(x$fit_ok),
    n_converged = sum(x$converged),
    n_pdhess = sum(x$pdHess),
    n_sdreport_cov_available = sum(x$sdreport_cov_available),
    n_confint_ok = sum(x$confint_ok),
    n_usable_wald_intervals = n_usable,
    finite_wald_interval_rate = fmt4(mean(x$usable_interval)),
    n_covered = if (length(covered) == 0L) 0L else sum(covered),
    coverage = fmt4(coverage),
    coverage_mcse = fmt6(mcse_proportion(covered)),
    lower_miss = sum(x$lower_miss, na.rm = TRUE),
    upper_miss = sum(x$upper_miss, na.rm = TRUE),
    n_profile_ok = sum(x$profile_ok),
    n_profile_finite = sum(x$profile_finite),
    n_profile_failed = sum(!x$profile_ok),
    n_boundary_rows = sum(grepl("boundary", x$conf_status, fixed = TRUE)),
    n_warning_replicates = sum(x$warning_count > 0L),
    smoke_status = status,
    blocker_signal = paste(blockers, collapse = ";"),
    review_decision = "fisher_noether_rose_target_split_review_required",
    promotion_decision = "do_not_promote",
    evidence_url = rel_path(artifact_dir),
    claim_boundary = paste(
      "Gaussian low-q direct-SD univariate local smoke only;",
      "this promotes exactly no Q-Series row;",
      paste0(
        "n=",
        length(unique(x$replicate_index)),
        " is not coverage evidence;"
      ),
      "direct mu-axis and sigma-axis SD targets are retained separately;",
      "raw Wald uses small_sample_df=none and bias_correct=none;",
      "endpoint profile rows are diagnostic only;",
      "boundary, profile-budget, warning, and failed rows are retained;",
      "derived correlations and phylogenetic-signal summaries are excluded;",
      "no fit_status, interval_status, coverage_status, inference_ready,",
      "supported, q2, q4/q8, non-Gaussian, REML, AI-REML, bridge support,",
      "public support, Totoro/FIIA, Nibi/Rorqual, or DRAC denominator claim."
    ),
    next_gate = paste(
      "Fisher/Noether/Rose must review the target split before any host",
      "escalation; mu-axis direct SD passed this local smoke while sigma-axis",
      "direct SD is retained as boundary/profile-budget diagnostic evidence;",
      "choose a target-specific denominator and one-sided miss policy before",
      "Totoro/FIIA or Nibi/Rorqual work; keep the support cell",
      "point_fit/interval_feasible/planned."
    ),
    host_class = host_class,
    host_name = host_name,
    stringsAsFactors = FALSE
  )
})
summary <- do.call(rbind, summaries)
row.names(summary) <- NULL

write_tsv(replicates, replicate_path)
write_tsv(summary, summary_path)
if (write_dashboard) {
  write_tsv(summary, dashboard_summary_path)
}
writeLines(capture.output(sessionInfo()), session_info_path)
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) paste("git-sha-unavailable:", conditionMessage(e))
)
writeLines(git_sha, git_sha_path)

message(
  "Wrote ",
  nrow(summary),
  " Gaussian low-q direct-SD univariate smoke summary rows to ",
  rel_path(summary_path)
)
if (write_dashboard) {
  message("Updated dashboard sidecar: ", rel_path(dashboard_summary_path))
}
message(
  "Wrote ",
  nrow(replicates),
  " replicate rows to ",
  rel_path(replicate_path)
)
